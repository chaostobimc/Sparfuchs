import tempfile
import unittest
from pathlib import Path

from server import SyncStore, SyncError


def entry_payload(entry_id="entry-1", amount=2.5):
    return {
        "id": entry_id,
        "amount": amount,
        "title": "Cashback",
        "store": "REWE",
        "type": "Cashback",
        "date": "2026-10-22",
        "note": "",
    }


def operation(operation_id, *, modified_at, deleted=False, payload=None):
    return {
        "operationId": operation_id,
        "entity": "entry",
        "recordId": "entry-1",
        "modifiedAt": modified_at,
        "deleted": deleted,
        "payload": payload,
    }


class SyncStoreTests(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.store = SyncStore(Path(self.temp_dir.name) / "sync.sqlite3")

    def tearDown(self):
        self.temp_dir.cleanup()

    def test_upsert_is_acknowledged_and_returned(self):
        response = self.store.apply([
            operation("create-1", modified_at=100, payload=entry_payload())
        ])
        self.assertEqual(response["acknowledgedOperationIds"], ["create-1"])
        self.assertEqual(response["records"][0]["payload"]["amount"], 2.5)
        self.assertFalse(response["records"][0]["deleted"])

    def test_duplicate_operation_is_idempotent(self):
        change = operation("create-1", modified_at=100, payload=entry_payload())
        self.store.apply([change])
        response = self.store.apply([change])
        self.assertEqual(len(response["records"]), 1)
        self.assertEqual(response["records"][0]["operationId"], "create-1")

    def test_later_delete_tombstone_wins_over_stale_create(self):
        self.store.apply([
            operation("delete-1", modified_at=200, deleted=True)
        ])
        response = self.store.apply([
            operation("create-1", modified_at=100, payload=entry_payload())
        ])
        record = response["records"][0]
        self.assertTrue(record["deleted"])
        self.assertEqual(record["operationId"], "delete-1")
        self.assertIsNone(record["payload"])

    def test_invalid_entry_is_rejected(self):
        invalid = entry_payload()
        invalid["type"] = []
        with self.assertRaises(SyncError):
            self.store.apply([
                operation("bad-1", modified_at=100, payload=invalid)
            ])

    def test_goal_record_can_be_synchronized(self):
        response = self.store.apply([
            {
                "operationId": "goal-1",
                "entity": "goal",
                "recordId": "monthly",
                "modifiedAt": 300,
                "deleted": False,
                "payload": {"amount": 75.0},
            }
        ])
        self.assertEqual(response["records"][0]["entity"], "goal")
        self.assertEqual(response["records"][0]["payload"], {"amount": 75.0})


if __name__ == "__main__":
    unittest.main()
