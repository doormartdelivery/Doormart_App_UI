import 'dart:html' as html;

Future<bool> speakTamilOnWeb(String text) async {
  final synthesis = html.window.speechSynthesis;
  if (synthesis == null) return false;
  synthesis.cancel();

  final utterance = html.SpeechSynthesisUtterance(text);
  utterance.lang = 'ta-IN';
  utterance.rate = 0.9;
  utterance.pitch = 1.0;
  html.SpeechSynthesisVoice? tamilVoice;
  for (final voice in synthesis.getVoices()) {
    if ((voice.lang ?? '').toLowerCase().startsWith('ta')) {
      tamilVoice = voice;
      break;
    }
  }
  if (tamilVoice != null) utterance.voice = tamilVoice;
  synthesis.speak(utterance);
  return true;
}

Future<void> stopTamilWebSpeech() async {
  html.window.speechSynthesis?.cancel();
}
