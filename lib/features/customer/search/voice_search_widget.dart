import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../widgets/toast_widget.dart';

class VoiceSearchWidget extends StatefulWidget {
  const VoiceSearchWidget({
    super.key,
    this.controller,
    required this.onSearchChanged,
    this.onSubmitted,
    this.hintText = 'Search products, categories, or keywords',
    this.autofocus = false,
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController? controller;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String>? onSubmitted;
  final String hintText;
  final bool autofocus;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  State<VoiceSearchWidget> createState() => _VoiceSearchWidgetState();
}

class _VoiceSearchWidgetState extends State<VoiceSearchWidget> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  Timer? _debounce;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _disposed = false;
  bool _isListening = false;

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _triggerSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (_disposed) return;
      widget.onSearchChanged(query.trim());
    });
  }

  Future<void> _toggleVoiceSearch() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    final microphonePermission = await Permission.microphone.request();
    if (!microphonePermission.isGranted) {
      if (mounted) {
        showToast(
          context,
          'Allow microphone access in Settings to use voice search',
        );
      }
      return;
    }

    final available = await _speech.initialize(
      onStatus: (status) {
        if (mounted && (status == 'done' || status == 'notListening')) {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _isListening = false);
          showToast(context, 'Voice search could not start: ${error.errorMsg}');
        }
      },
    );
    if (!available) {
      if (mounted) {
        showToast(context, 'Voice search is unavailable on this device');
      }
      return;
    }

    setState(() => _isListening = true);
    if (mounted) {
      showToast(context, 'Listening… say a product name');
    }
    await _speech.listen(
      onResult: (result) {
        final words = result.recognizedWords.trim();
        if (words.isEmpty) return;
        _controller.value = _controller.value.copyWith(
          text: words,
          selection: TextSelection.collapsed(offset: words.length),
          composing: TextRange.empty,
        );
        if (result.finalResult) {
          _triggerSearch(words);
        }
      },
      listenOptions: stt.SpeechListenOptions(
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF667064)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: widget.autofocus,
              readOnly: widget.readOnly,
              onTap: widget.onTap,
              onChanged: _triggerSearch,
              onSubmitted: widget.onSubmitted,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: InputBorder.none,
                hintStyle: const TextStyle(color: Color(0xFF667064)),
              ),
            ),
          ),
          IconButton(
            tooltip: _isListening ? 'Stop voice search' : 'Search by voice',
            onPressed: _toggleVoiceSearch,
            icon: Icon(
              _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: _isListening
                  ? const Color(0xFFE8541A)
                  : const Color(0xFF14532D),
            ),
          ),
          IconButton(
            tooltip: 'Search',
            onPressed: () {
              final query = _controller.text.trim();
              _triggerSearch(query);
              if (query.isEmpty) {
                showToast(context, 'Type something to search');
              }
            },
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF14532D),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
