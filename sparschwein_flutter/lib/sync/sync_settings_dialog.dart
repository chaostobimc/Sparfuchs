import 'package:flutter/material.dart';

import '../app_theme.dart';
import 'sync_client.dart';

class SyncSettingsValue {
  const SyncSettingsValue({required this.ipAddress, required this.token});

  final String ipAddress;
  final String token;
}

class SyncSettingsDialog extends StatefulWidget {
  const SyncSettingsDialog({
    required this.initialIp,
    required this.initialToken,
    required this.statusText,
    required this.pendingCount,
    required this.onClose,
    required this.onSave,
    super.key,
  });

  final String initialIp;
  final String initialToken;
  final String statusText;
  final int pendingCount;
  final VoidCallback onClose;
  final void Function(String ip, String token) onSave;

  @override
  State<SyncSettingsDialog> createState() => _SyncSettingsDialogState();
}

class _SyncSettingsDialogState extends State<SyncSettingsDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _ipController;
  late final TextEditingController _tokenController;
  bool _isTesting = false;
  bool _showToken = false;
  String? _testMessage;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: widget.initialIp);
    _tokenController = TextEditingController(text: widget.initialToken);
  }

  @override
  void dispose() {
    _ipController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;
    final client = LocalSyncClient(
      ipAddress: _ipController.text.trim(),
      token: _tokenController.text.trim(),
    );
    setState(() {
      _isTesting = true;
      _testMessage = null;
    });
    try {
      final response = await client.synchronize(const []);
      if (!mounted) return;
      setState(() {
        _testMessage = 'Verbindung steht. ${response.records.length} Datensätze auf dem Pi.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _testMessage = error is SyncException ? error.message : 'Verbindung fehlgeschlagen.';
      });
    } finally {
      client.close();
      if (mounted) setState(() => _isTesting = false);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(_ipController.text.trim(), _tokenController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Raspberry-Pi-Synchronisierung'),
      content: SizedBox(
        width: 410,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _ipController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Private IP-Adresse',
                    hintText: '192.168.1.50',
                  ),
                  validator: (value) {
                    final ip = value?.trim() ?? '';
                    final token = _tokenController.text.trim();
                    if (ip.isEmpty && token.isEmpty) return null;
                    if (!LocalSyncClient.isPrivateIpv4(ip)) {
                      return 'Eine private IPv4-Adresse eintragen.';
                    }
                    if (token.isEmpty) return 'Den Pi-Token ebenfalls eintragen.';
                    return null;
                  },
                  onChanged: (_) => setState(() => _testMessage = null),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tokenController,
                  obscureText: !_showToken,
                  decoration: InputDecoration(
                    labelText: 'Token vom Raspberry Pi',
                    suffixIcon: IconButton(
                      tooltip: _showToken ? 'Token verbergen' : 'Token anzeigen',
                      onPressed: () => setState(() => _showToken = !_showToken),
                      icon: Icon(_showToken ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    ),
                  ),
                  validator: (value) {
                    final token = value?.trim() ?? '';
                    final ip = _ipController.text.trim();
                    if (ip.isEmpty && token.isEmpty) return null;
                    if (!LocalSyncClient.isValidToken(token)) {
                      return 'Der Token muss 32 bis 128 Zeichen ohne Sonderzeichen enthalten.';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() => _testMessage = null),
                ),
                const SizedBox(height: 12),
                const Text(
                  'API-Port 8765. Abgleich nur über WLAN oder Ethernet mit privater IPv4-Adresse; über Mobilfunk wird nicht synchronisiert.',
                  style: TextStyle(color: mutedColor, fontSize: 11, height: 1.4),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      _testMessage == null ? Icons.sync_alt_rounded : Icons.info_outline_rounded,
                      size: 17,
                      color: pinkStrongColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testMessage ?? widget.statusText,
                        style: const TextStyle(color: inkColor, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                if (widget.pendingCount > 0) ...[
                  const SizedBox(height: 5),
                  Text(
                    '${widget.pendingCount} Änderungen warten auf Abgleich.',
                    style: const TextStyle(color: mutedColor, fontSize: 10),
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isTesting ? null : _testConnection,
                  icon: _isTesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering_rounded, size: 17),
                  label: Text(_isTesting ? 'Prüfe Verbindung …' : 'Verbindung testen'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: pinkStrongColor,
                    side: const BorderSide(color: Color(0xFFECD3DD)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: widget.onClose, child: const Text('Schließen')),
        FilledButton(onPressed: _save, child: const Text('Speichern')),
      ],
    );
  }
}
