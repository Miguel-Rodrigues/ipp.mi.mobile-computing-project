import 'dart:async';
import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// Plugin atualizado para enviar SMS
import 'package:send_message/send_message.dart';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  static const _prefsKeyPhone = 'emergency_phone';

  // Número default (se não houver nada guardado)
  static const String _defaultEmergencyPhone = '+351968195986';

  final _phoneController = TextEditingController();
  final _player = AudioPlayer();

  Timer? _holdTimer;
  int _holdSeconds = 0;

  bool _armed = false; // alarme ativo
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadPhone();
    _player.setReleaseMode(ReleaseMode.loop);
  }

  @override
  void dispose() {
    _stopHoldTimer();
    _stopAlarm();
    _player.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKeyPhone);

    final value = (saved == null || saved.trim().isEmpty)
        ? _defaultEmergencyPhone
        : saved.trim();

    if (!mounted) return;
    setState(() => _phoneController.text = value);
  }

  Future<void> _savePhone(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyPhone, value.trim());
  }

  void _startHoldTimer() {
    _stopHoldTimer();
    setState(() => _holdSeconds = 0);

    _holdTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      setState(() => _holdSeconds += 1);

      if (_holdSeconds >= 10) {
        _stopHoldTimer();
        await _toggleEmergency();
      }
    });
  }

  void _stopHoldTimer() {
    _holdTimer?.cancel();
    _holdTimer = null;
    if (mounted) setState(() => _holdSeconds = 0);
  }

  Future<void> _toggleEmergency() async {
    if (_sending) return;

    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showSnack('Define primeiro o número de emergência.');
      return;
    }

    setState(() => _sending = true);

    try {
      if (!_armed) {
        await _startAlarm();
        await _sendEmergencySms(phone);
        setState(() => _armed = true);
        _showSnack('Auxílio ativado. Alarme ligado.');
      } else {
        await _stopAlarm();
        setState(() => _armed = false);
        _showSnack('Auxílio desativado. Alarme desligado.');
      }
    } catch (e) {
      _showSnack('Erro: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _startAlarm() async {
    await _player.play(AssetSource('assets/alarm.mp3'), volume: 1.0);
  }

  Future<void> _stopAlarm() async {
    await _player.stop();
  }

  Future<Position?> _getLocationBestEffort() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _sendEmergencySms(String phone) async {
    final pos = await _getLocationBestEffort();

    final mapsLink = (pos == null)
        ? 'Localização indisponível (sem permissão/serviço).'
        : 'https://maps.google.com/?q=${pos.latitude},${pos.longitude}';

    final message = [
      'ALERTA DE EMERGÊNCIA',
      'Preciso de ajuda. Contacta-me o mais rápido possível.',
      'Localização: $mapsLink',
    ].join('\n');

    if (Platform.isAndroid) {
      final sent = await _trySendDirectAndroid(phone, message);
      if (!sent) {
        await _openSmsApp(phone, message);
      }
      return;
    }

    await _openSmsApp(phone, message);
  }

  Future<bool> _trySendDirectAndroid(String phone, String message) async {
    try {
      final can = await canSendSMS();
      if (!can) return false;

      await sendSMS(
        message: message,
        recipients: [phone],
        sendDirect: true,
      );

      _showSnack('SMS enviado (Android).');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _openSmsApp(String phone, String message) async {
    final uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': message},
    );

    final ok = await canLaunchUrl(uri);
    if (!ok) {
      throw Exception('Não foi possível abrir a app de SMS.');
    }
    await launchUrl(uri);
  }

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _armed ? 'Auxílio ATIVO' : 'Auxílio';
    final subtitle = _armed
        ? 'Para DESLIGAR, mantém pressionado 10s.'
        : 'Para ATIVAR, mantém pressionado 10s.';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // BACKGROUND IMAGE (muda para o teu asset)
          Image.asset(
            'assets/emergency_bg.png',
            fit: BoxFit.cover,
          ),

          // OVERLAY para legibilidade
          Container(
            color: Colors.black.withAlpha(76),
          ),

          // CONTEÚDO
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    elevation: 1,
                    color: Colors.white.withAlpha(235),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Número de emergência',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              hintText: 'Ex.: +351968195986',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: _savePhone,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            Platform.isAndroid
                                ? 'Android: tenta enviar SMS automaticamente.'
                                : 'iOS: abre a app de SMS com o texto preenchido.',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // “subtitle” com fundo para ler bem em cima da imagem
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(191),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        GestureDetector(
                          onLongPressStart: (_) => _startHoldTimer(),
                          onLongPressEnd: (_) => _stopHoldTimer(),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _armed
                                  ? Colors.red.shade700
                                  : Colors.orange.shade700,
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                  color: Colors.black.withAlpha(64),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _sending
                                  ? const SizedBox(
                                width: 36,
                                height: 36,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                                  : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _armed
                                        ? Icons.notifications_active
                                        : Icons.sos,
                                    color: Colors.white,
                                    size: 46,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _armed
                                        ? 'DESLIGAR\n(10s)'
                                        : 'ATIVAR\n(10s)',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  if (_holdTimer != null)
                                    Text(
                                      '$_holdSeconds / 10',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(191),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Atenção: isto não substitui os serviços de emergência.\nEm risco imediato, liga 112.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
