import 'dart:async';
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceSearchService {
  VoiceSearchService({SpeechToText? speech})
    : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;

  bool get isListening => _speech.isListening;

  Future<VoicePermissionResult> requestPermissions() async {
    try {
      final microphone = await Permission.microphone.request();
      if (!microphone.isGranted) {
        return VoicePermissionResult.denied;
      }

      if (Platform.isIOS) {
        final speech = await Permission.speech.request();
        if (!speech.isGranted) {
          return VoicePermissionResult.denied;
        }
      }
    } on MissingPluginException {
      return VoicePermissionResult.pluginMissing;
    } on PlatformException {
      return VoicePermissionResult.pluginMissing;
    }

    return VoicePermissionResult.granted;
  }

  Future<bool> initialize({
    required void Function(String status) onStatus,
    required void Function(String errorMessage) onError,
  }) async {
    return _speech.initialize(
      onStatus: onStatus,
      onError: (SpeechRecognitionError error) => onError(error.errorMsg),
      debugLogging: false,
    );
  }

  Future<List<dynamic>> locales() => _speech.locales();

  Future<void> startListening({
    required String localeId,
    required void Function(SpeechRecognitionResult result) onResult,
    required void Function(String status) onStatus,
    required void Function(String errorMessage) onError,
  }) async {
    if (_speech.isListening) {
      await _speech.stop();
    }

    await _speech.listen(
      onResult: onResult,
      onSoundLevelChange: (_) {},
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.search,
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(seconds: 12),
        pauseFor: const Duration(seconds: 3),
        localeId: localeId,
      ),
    );

    onStatus('listening');
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 50), () {
        if (!_speech.isListening) {
          onError('Speech recognition unavailable');
        }
      }),
    );
  }

  Future<void> stopListening() => _speech.stop();
}

enum VoicePermissionResult { granted, denied, pluginMissing }
