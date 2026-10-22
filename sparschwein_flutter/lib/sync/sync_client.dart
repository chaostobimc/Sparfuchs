import 'dart:convert';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class SyncException implements Exception {
  const SyncException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SyncOperation {
  const SyncOperation({
    required this.operationId,
    required this.entity,
    required this.recordId,
    required this.modifiedAt,
    required this.deleted,
    required this.payload,
  });

  final String operationId;
  final String entity;
  final String recordId;
  final int modifiedAt;
  final bool deleted;
  final Map<String, dynamic>? payload;

  factory SyncOperation.create({
    required String entity,
    required String recordId,
    required bool deleted,
    Map<String, dynamic>? payload,
  }) {
    return SyncOperation(
      operationId: _createOperationId(),
      entity: entity,
      recordId: recordId,
      modifiedAt: DateTime.now().toUtc().millisecondsSinceEpoch,
      deleted: deleted,
      payload: payload,
    );
  }

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      operationId: json['operationId'] as String,
      entity: json['entity'] as String,
      recordId: json['recordId'] as String,
      modifiedAt: (json['modifiedAt'] as num).toInt(),
      deleted: json['deleted'] as bool,
      payload: json['payload'] == null
          ? null
          : Map<String, dynamic>.from(json['payload'] as Map),
    );
  }

  Map<String, dynamic> toJson() => {
        'operationId': operationId,
        'entity': entity,
        'recordId': recordId,
        'modifiedAt': modifiedAt,
        'deleted': deleted,
        'payload': payload,
      };

  SyncVersion get version => SyncVersion(
        modifiedAt: modifiedAt,
        operationId: operationId,
        deleted: deleted,
      );
}

class SyncVersion {
  const SyncVersion({
    required this.modifiedAt,
    required this.operationId,
    required this.deleted,
  });

  final int modifiedAt;
  final String operationId;
  final bool deleted;

  bool isNewerThan(SyncVersion? other) {
    if (other == null) return true;
    if (modifiedAt != other.modifiedAt) return modifiedAt > other.modifiedAt;
    return operationId.compareTo(other.operationId) > 0;
  }

  factory SyncVersion.fromJson(Map<String, dynamic> json) => SyncVersion(
        modifiedAt: (json['modifiedAt'] as num).toInt(),
        operationId: json['operationId'] as String,
        deleted: json['deleted'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'modifiedAt': modifiedAt,
        'operationId': operationId,
        'deleted': deleted,
      };
}

class RemoteSyncRecord {
  const RemoteSyncRecord({
    required this.entity,
    required this.recordId,
    required this.version,
    required this.payload,
  });

  final String entity;
  final String recordId;
  final SyncVersion version;
  final Map<String, dynamic>? payload;

  factory RemoteSyncRecord.fromJson(Map<String, dynamic> json) => RemoteSyncRecord(
        entity: json['entity'] as String,
        recordId: json['recordId'] as String,
        version: SyncVersion.fromJson(json),
        payload: json['payload'] == null
            ? null
            : Map<String, dynamic>.from(json['payload'] as Map),
      );
}

class SyncResponse {
  const SyncResponse({
    required this.acknowledgedOperationIds,
    required this.records,
  });

  final Set<String> acknowledgedOperationIds;
  final List<RemoteSyncRecord> records;

  factory SyncResponse.fromJson(Map<String, dynamic> json) {
    if (json['protocolVersion'] != 1) {
      throw const SyncException('Die Version des Raspberry-Pi-Dienstes passt nicht zur App.');
    }
    return SyncResponse(
      acknowledgedOperationIds:
          (json['acknowledgedOperationIds'] as List<dynamic>).cast<String>().toSet(),
      records: (json['records'] as List<dynamic>)
          .map((record) => RemoteSyncRecord.fromJson(
                Map<String, dynamic>.from(record as Map),
              ))
          .toList(),
    );
  }
}

class LocalSyncClient {
  LocalSyncClient({required this.ipAddress, required this.token});

  static const int port = 8765;
  static const Duration requestTimeout = Duration(seconds: 5);

  final String ipAddress;
  final String token;
  final http.Client _httpClient = http.Client();

  static bool isValidToken(String value) =>
      RegExp(r'^[A-Za-z0-9_-]{32,128}$').hasMatch(value);

  static bool isPrivateIpv4(String value) {
    final parts = value.trim().split('.');
    if (parts.length != 4) return false;
    final octets = <int>[];
    for (final part in parts) {
      final octet = int.tryParse(part);
      if (octet == null || octet < 0 || octet > 255 || octet.toString() != part) {
        return false;
      }
      octets.add(octet);
    }
    return octets[0] == 10 ||
        (octets[0] == 172 && octets[1] >= 16 && octets[1] <= 31) ||
        (octets[0] == 192 && octets[1] == 168) ||
        (octets[0] == 169 && octets[1] == 254);
  }

  static Future<bool> isOnLocalTransport() async {
    final transports = await Connectivity().checkConnectivity();
    return transports.contains(ConnectivityResult.wifi) ||
        transports.contains(ConnectivityResult.ethernet);
  }

  Future<SyncResponse> synchronize(List<SyncOperation> operations) async {
    if (!isPrivateIpv4(ipAddress)) {
      throw const SyncException('Bitte eine private IPv4-Adresse des Raspberry Pi eintragen.');
    }
    if (!isValidToken(token)) {
      throw const SyncException('Der Synchronisierungstoken ist ungültig.');
    }
    if (!await isOnLocalTransport()) {
      throw const SyncException('Synchronisierung nur über WLAN oder Ethernet.');
    }

    final uri = Uri(
      scheme: 'http',
      host: ipAddress.trim(),
      port: port,
      path: '/api/sync',
    );
    late final http.Response response;
    try {
      response = await _httpClient
          .post(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'operations': operations.map((operation) => operation.toJson()).toList(),
            }),
          )
          .timeout(requestTimeout);
    } on Exception catch (error) {
      throw SyncException('Raspberry Pi im Heimnetz nicht erreichbar: $error');
    }

    if (response.statusCode == 401) {
      throw const SyncException('Der Synchronisierungstoken stimmt nicht.');
    }
    if (response.statusCode != 200) {
      throw SyncException('Raspberry-Pi-Dienst meldet HTTP ${response.statusCode}.');
    }

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return SyncResponse.fromJson(Map<String, dynamic>.from(decoded as Map));
    } on FormatException {
      throw const SyncException('Ungültige Antwort vom Raspberry Pi.');
    } on TypeError {
      throw const SyncException('Ungültige Antwort vom Raspberry Pi.');
    }
  }

  void close() => _httpClient.close();
}

String _createOperationId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}
