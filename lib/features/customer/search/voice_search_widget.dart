import 'dart:async';

import 'package:flutter/material.dart';

import 'voice_search_service.dart';
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
  final VoiceSearchService _voiceSearchService = VoiceSearchService();
  final FocusNode _focusNode = FocusNode();
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  Timer? _debounce;

  bool _listening = false;
  bool _speechReady = false;
  String _selectedLocaleId = 'en_US';
  final List<_VoiceLocaleOption> _localeOptions = const [
    _VoiceLocaleOption(label: 'English', localePrefix: 'en'),
    _VoiceLocaleOption(label: 'தமிழ்', localePrefix: 'ta'),
  ];

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    _voiceSearchService.stopListening();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _initializeSpeech() async {
    final hasPermission = await _voiceSearchService.requestPermissions();
    if (hasPermission == VoicePermissionResult.denied) {
      if (!mounted) return;
      setState(() => _speechReady = false);
      showToast(context, 'Microphone permission denied');
      return;
    }
    if (hasPermission == VoicePermissionResult.pluginMissing) {
      if (!mounted) return;
      setState(() => _speechReady = false);
      showToast(
        context,
        'Please fully restart the app to enable microphone access',
      );
      return;
    }

    final initialized = await _voiceSearchService.initialize(
      onStatus: _handleSpeechStatus,
      onError: _handleSpeechError,
    );
    final locales = await _voiceSearchService.locales();

    if (!mounted) return;
    setState(() {
      _speechReady = initialized;
      _selectedLocaleId = _pickLocaleId(locales, 'en') ?? _selectedLocaleId;
    });
    if (!initialized) {
      showToast(context, 'Speech recognition unavailable');
    }
  }

  String? _pickLocaleId(List<dynamic> locales, String languageCode) {
    for (final locale in locales) {
      final localeId = locale.localeId as String?;
      if (localeId != null &&
          localeId.toLowerCase().startsWith(languageCode.toLowerCase())) {
        return localeId;
      }
    }
    return locales.isNotEmpty ? locales.first.localeId as String? : null;
  }

  void _handleSpeechStatus(String status) {
    if (!mounted) return;
    setState(() {
      _listening = status == 'listening';
      if (status == 'done' && _controller.text.trim().isEmpty) {
        showToast(context, 'No speech detected');
      }
    });
  }

  void _handleSpeechError(String errorMessage) {
    if (!mounted) return;
    final normalized = errorMessage.toLowerCase();
    setState(() {
      _listening = false;
    });
    if (normalized.contains('permission')) {
      showToast(context, 'Microphone permission denied');
    } else if (normalized.contains('no match') ||
        normalized.contains('error_no_match')) {
      showToast(context, 'No speech detected');
    } else {
      showToast(context, 'Voice search unavailable');
    }
  }

  void _triggerSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      widget.onSearchChanged(query.trim());
    });
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _voiceSearchService.stopListening();
      return;
    }

    if (!_speechReady) {
      await _initializeSpeech();
      if (!_speechReady) return;
    }

    final localeId = _pickLocaleId(
      await _voiceSearchService.locales(),
      _selectedLocaleId.split('_').first,
    );
    if (localeId == null) {
      showToast(context, 'Speech recognition unavailable');
      return;
    }

    setState(() => _listening = true);
    await _voiceSearchService.startListening(
      localeId: localeId,
      onStatus: _handleSpeechStatus,
      onError: _handleSpeechError,
      onResult: (result) {
        final text = result.recognizedWords.trim();
        _controller.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
        _triggerSearch(text);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
                  focusNode: _focusNode,
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
              GestureDetector(
                onTap: _toggleListening,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 1, end: _listening ? 1.15 : 1),
                  duration: const Duration(milliseconds: 220),
                  builder: (context, scale, child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _listening
                          ? const Color(0xFFFFE3E3)
                          : const Color(0xFFF1F5F2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _listening ? Icons.mic : Icons.mic_none_rounded,
                      color: _listening
                          ? const Color(0xFFD92D20)
                          : const Color(0xFF14532D),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final option in _localeOptions)
              ChoiceChip(
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                label: Text(option.label),
                selected: _selectedLocaleId.toLowerCase().startsWith(
                  option.localePrefix.toLowerCase(),
                ),
                onSelected: (_) {
                  setState(() {
                    _selectedLocaleId = option.localePrefix == 'ta'
                        ? 'ta_IN'
                        : 'en_US';
                  });
                },
              ),
            if (_listening)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: _ListeningIndicator(),
              ),
          ],
        ),
      ],
    );
  }
}

class _ListeningIndicator extends StatefulWidget {
  const _ListeningIndicator();

  @override
  State<_ListeningIndicator> createState() => _ListeningIndicatorState();
}

class _ListeningIndicatorState extends State<_ListeningIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      child: const Text(
        'Listening...',
        textAlign: TextAlign.end,
        style: TextStyle(color: Color(0xFF14532D), fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _VoiceLocaleOption {
  const _VoiceLocaleOption({required this.label, required this.localePrefix});

  final String label;
  final String localePrefix;
}
