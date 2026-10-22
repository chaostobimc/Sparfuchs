#!/usr/bin/env python3
"""LAN-only SQLite sync service for the Sparschwein Flutter app."""

from __future__ import annotations

import hmac
import json
import math
import os
import re
import sqlite3
from datetime import date
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any

SERVICE_NAME = "sparschwein-sync"
PROTOCOL_VERSION = 1
MAX_REQUEST_BYTES = 1_000_000
MAX_OPERATIONS = 200
_ID_RE = re.compile(r"^[A-Za-z0-9_-]{1,128}$")
_ENTRY_TYPES = {"Cashback", "Rabatt", "Gratisartikel", "Fundstück", "Sonstiges"}
_ENTRY_FIELDS = {"id", "amount", "title", "store", "type", "date", "note"}


class SyncError(ValueError):
    """An invalid sync request."""


def _validate_entry(record_id: str, payload: Any) -> dict[str, Any]:
    if not isinstance(payload, dict) or set(payload) - _ENTRY_FIELDS:
        raise SyncError("Invalid entry payload")
    if payload.get("id") != record_id:
        raise SyncError("Entry id does not match record id")

    amount = payload.get("amount")
    if isinstance(amount, bool) or not isinstance(amount, (int, float)):
        raise SyncError("Entry amount must be numeric")
    if amount <= 0 or amount > 1_000_000_000 or not math.isfinite(amount):
        raise SyncError("Entry amount is outside the allowed range")

    title = payload.get("title")
    store = payload.get("store", "Sonstiges")
    entry_type = payload.get("type")
    entry_date = payload.get("date")
    note = payload.get("note", "")
    if not isinstance(title, str) or not title.strip() or len(title) > 80:
        raise SyncError("Entry title must contain 1 to 80 characters")
    if not isinstance(store, str) or len(store) > 64:
        raise SyncError("Invalid store")
    if not isinstance(entry_type, str) or entry_type not in _ENTRY_TYPES:
        raise SyncError("Invalid entry type")
    if not isinstance(entry_date, str):
        raise SyncError("Invalid entry date")
    try:
        date.fromisoformat(entry_date)
    except ValueError as error:
        raise SyncError("Invalid entry date") from error
    if not isinstance(note, str) or len(note) > 70:
        raise SyncError("Invalid note")

    return {
        "id": record_id,
        "amount": round(float(amount), 2),
        "title": title.strip(),
        "store": store,
        "type": entry_type,
        "date": entry_date,
        "note": note,
    }


def _validate_operation(operation: Any) -> dict[str, Any]:
    if not isinstance(operation, dict):
        raise SyncError("Each operation must be an object")

    operation_id = operation.get("operationId")
    entity = operation.get("entity")
    record_id = operation.get("recordId")
    modified_at = operation.get("modifiedAt")
    deleted = operation.get("deleted")
    payload = operation.get("payload")

    if not isinstance(operation_id, str) or not _ID_RE.fullmatch(operation_id):
        raise SyncError("Invalid operation id")
    if not isinstance(entity, str) or entity not in {"entry", "goal"}:
        raise SyncError("Invalid entity")
    if not isinstance(record_id, str) or not _ID_RE.fullmatch(record_id):
        raise SyncError("Invalid record id")
    if type(modified_at) is not int or not 0 <= modified_at <= 9_223_372_036_854_775_807:
        raise SyncError("Invalid modifiedAt timestamp")
    if type(deleted) is not bool:
        raise SyncError("Invalid deleted flag")

    if entity == "entry":
        if deleted:
            payload = None
        else:
            payload = _validate_entry(record_id, payload)
    else:
        if record_id != "monthly":
            raise SyncError("Invalid goal id")
        if deleted:
            payload = None
        else:
            if not isinstance(payload, dict):
                raise SyncError("Invalid goal payload")
            amount = payload.get("amount")
            if isinstance(amount, bool) or not isinstance(amount, (int, float)):
                raise SyncError("Goal amount must be numeric")
            if amount < 0 or amount > 1_000_000_000 or not math.isfinite(amount):
                raise SyncError("Goal amount is outside the allowed range")
            payload = {"amount": round(float(amount), 2)}

    return {
        "operationId": operation_id,
        "entity": entity,
        "recordId": record_id,
        "modifiedAt": modified_at,
        "deleted": deleted,
        "payload": payload,
    }


class SyncStore:
    def __init__(self, database_path: str | Path):
        self.database_path = Path(database_path)
        self.database_path.parent.mkdir(parents=True, exist_ok=True)
        self._initialize()

    def _connect(self) -> sqlite3.Connection:
        connection = sqlite3.connect(self.database_path, timeout=10)
        connection.row_factory = sqlite3.Row
        connection.execute("PRAGMA busy_timeout = 10000")
        return connection

    def _initialize(self) -> None:
        with self._connect() as connection:
            connection.execute("PRAGMA journal_mode = WAL")
            connection.execute(
                """
                CREATE TABLE IF NOT EXISTS records (
                    entity TEXT NOT NULL,
                    record_id TEXT NOT NULL,
                    modified_at INTEGER NOT NULL,
                    operation_id TEXT NOT NULL,
                    deleted INTEGER NOT NULL,
                    payload TEXT,
                    PRIMARY KEY (entity, record_id)
                )
                """
            )
            connection.execute(
                """
                CREATE TABLE IF NOT EXISTS applied_operations (
                    operation_id TEXT PRIMARY KEY,
                    applied_at INTEGER NOT NULL
                )
                """
            )

    def apply(self, raw_operations: Any) -> dict[str, Any]:
        if not isinstance(raw_operations, list) or len(raw_operations) > MAX_OPERATIONS:
            raise SyncError(f"operations must be a list of at most {MAX_OPERATIONS} items")
        operations = [_validate_operation(item) for item in raw_operations]
        acknowledgements: list[str] = []

        with self._connect() as connection:
            if operations:
                connection.execute("BEGIN IMMEDIATE")
            for operation in operations:
                operation_id = operation["operationId"]
                already_applied = connection.execute(
                    "SELECT 1 FROM applied_operations WHERE operation_id = ?",
                    (operation_id,),
                ).fetchone()
                if already_applied is None:
                    current = connection.execute(
                        """SELECT modified_at, operation_id FROM records
                           WHERE entity = ? AND record_id = ?""",
                        (operation["entity"], operation["recordId"]),
                    ).fetchone()
                    incoming_version = (operation["modifiedAt"], operation_id)
                    current_version = (
                        (current["modified_at"], current["operation_id"])
                        if current is not None
                        else None
                    )
                    if current_version is None or incoming_version > current_version:
                        encoded_payload = (
                            json.dumps(operation["payload"], ensure_ascii=False, separators=(",", ":"))
                            if operation["payload"] is not None
                            else None
                        )
                        connection.execute(
                            """INSERT INTO records
                               (entity, record_id, modified_at, operation_id, deleted, payload)
                               VALUES (?, ?, ?, ?, ?, ?)
                               ON CONFLICT(entity, record_id) DO UPDATE SET
                                 modified_at = excluded.modified_at,
                                 operation_id = excluded.operation_id,
                                 deleted = excluded.deleted,
                                 payload = excluded.payload""",
                            (
                                operation["entity"],
                                operation["recordId"],
                                operation["modifiedAt"],
                                operation_id,
                                int(operation["deleted"]),
                                encoded_payload,
                            ),
                        )
                    connection.execute(
                        "INSERT INTO applied_operations (operation_id, applied_at) VALUES (?, ?)",
                        (operation_id, _now_millis()),
                    )
                acknowledgements.append(operation_id)

            rows = connection.execute(
                """SELECT entity, record_id, modified_at, operation_id, deleted, payload
                   FROM records ORDER BY entity, record_id"""
            ).fetchall()

        records = [
            {
                "entity": row["entity"],
                "recordId": row["record_id"],
                "modifiedAt": row["modified_at"],
                "operationId": row["operation_id"],
                "deleted": bool(row["deleted"]),
                "payload": json.loads(row["payload"]) if row["payload"] is not None else None,
            }
            for row in rows
        ]
        return {
            "protocolVersion": PROTOCOL_VERSION,
            "acknowledgedOperationIds": acknowledgements,
            "records": records,
        }


def _now_millis() -> int:
    import time

    return int(time.time() * 1000)


class SyncRequestHandler(BaseHTTPRequestHandler):
    server_version = "SparschweinSync/1"
    protocol_version = "HTTP/1.1"

    def do_GET(self) -> None:  # noqa: N802 - stdlib handler method name
        if self.path != "/health":
            self._send_json(404, {"error": "not_found"})
            return
        self._send_json(200, {"status": "ok", "service": SERVICE_NAME, "protocolVersion": PROTOCOL_VERSION})

    def do_POST(self) -> None:  # noqa: N802 - stdlib handler method name
        if self.path != "/api/sync":
            self._send_json(404, {"error": "not_found"})
            return
        supplied_token = self.headers.get("Authorization", "")
        expected_token = f"Bearer {self.server.sync_token}"  # type: ignore[attr-defined]
        if not hmac.compare_digest(supplied_token, expected_token):
            self._send_json(401, {"error": "unauthorized"})
            return

        try:
            content_length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            self._send_json(400, {"error": "invalid_content_length"})
            return
        if content_length < 0 or content_length > MAX_REQUEST_BYTES:
            self._send_json(413, {"error": "request_too_large"})
            return

        try:
            request = json.loads(self.rfile.read(content_length))
            if not isinstance(request, dict):
                raise SyncError("Request body must be an object")
            response = self.server.sync_store.apply(request.get("operations", []))  # type: ignore[attr-defined]
        except (json.JSONDecodeError, UnicodeDecodeError):
            self._send_json(400, {"error": "invalid_json"})
            return
        except SyncError as error:
            self._send_json(400, {"error": "invalid_request", "message": str(error)})
            return
        except sqlite3.Error:
            self._send_json(503, {"error": "database_unavailable"})
            return

        self._send_json(200, response)

    def _send_json(self, status: int, value: dict[str, Any]) -> None:
        body = json.dumps(value, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format: str, *args: Any) -> None:
        print(f"{self.client_address[0]} - {format % args}")


def main() -> None:
    token = os.environ.get("SPARSCHWEIN_SYNC_TOKEN", "").strip()
    if len(token) < 32:
        raise SystemExit("Set SPARSCHWEIN_SYNC_TOKEN to a random value of at least 32 characters.")
    database_path = os.environ.get(
        "SPARSCHWEIN_SYNC_DATABASE",
        "/var/lib/sparschwein-sync/sparschwein.sqlite3",
    )
    host = os.environ.get("SPARSCHWEIN_SYNC_HOST", "0.0.0.0")
    port = int(os.environ.get("SPARSCHWEIN_SYNC_PORT", "8765"))
    if not 1024 <= port <= 65535:
        raise SystemExit("SPARSCHWEIN_SYNC_PORT must be between 1024 and 65535.")

    server = ThreadingHTTPServer((host, port), SyncRequestHandler)
    server.sync_token = token  # type: ignore[attr-defined]
    server.sync_store = SyncStore(database_path)  # type: ignore[attr-defined]
    print(f"{SERVICE_NAME} listening on {host}:{port}; database: {database_path}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
