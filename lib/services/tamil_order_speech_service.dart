import 'package:flutter_tts/flutter_tts.dart';

import '../models/order_model.dart';
import 'tamil_speech_platform.dart';

class TamilVoiceUnavailableException implements Exception {
  const TamilVoiceUnavailableException();

  @override
  String toString() =>
      'Tamil voice is not available. Install or enable a Tamil (India) voice in the device Text-to-speech settings.';
}

class TamilOrderSpeechService {
  TamilOrderSpeechService() {
    _tts.setLanguage('ta-IN');
    _tts.setSpeechRate(0.42);
    _tts.setPitch(1.0);
  }

  final FlutterTts _tts = FlutterTts();

  static const _products = <String, String>{
    'aachi': 'ஆச்சி',
    'aachi idly powder': 'ஆச்சி இட்லி பொடி',
    'idly powder': 'இட்லி பொடி',
    'pani puri': 'பானி பூரி',
    'rice': 'அரிசி',
    'wheat': 'கோதுமை',
    'sugar': 'சர்க்கரை',
    'salt': 'உப்பு',
    'oil': 'எண்ணெய்',
    'milk': 'பால்',
    'curd': 'தயிர்',
    'biscuit': 'பிஸ்கட்',
    'cookies': 'குக்கீஸ்',
    'tomato': 'தக்காளி',
    'potato': 'உருளைக்கிழங்கு',
    'onion': 'வெங்காயம்',
    'garlic': 'பூண்டு',
    'ginger': 'இஞ்சி',
    'carrot': 'கேரட்',
    'cucumber': 'வெள்ளரிக்காய்',
    'banana': 'வாழைப்பழம்',
    'apple': 'ஆப்பிள்',
    'bread': 'பிரெட்',
    'soap': 'சோப்பு',
    'shampoo': 'ஷாம்பு',
    'detergent': 'சலவைத் தூள்',
    'tea': 'தேநீர்',
    'coffee': 'காபி',
    'dal': 'பருப்பு',
    'masala': 'மசாலா',
    'water': 'தண்ணீர்',
  };

  static const _units = <String, String>{
    'pcs': 'துண்டு',
    'piece': 'துண்டு',
    'pieces': 'துண்டுகள்',
    'pack': 'பாக்கெட்',
    'packs': 'பாக்கெட்டுகள்',
    'kg': 'கிலோ',
    'g': 'கிராம்',
    'gm': 'கிராம்',
    'l': 'லிட்டர்',
    'ml': 'மில்லிலிட்டர்',
    'bottle': 'பாட்டில்',
    'box': 'பெட்டி',
    'dozen': 'டஜன்',
    'bundle': 'கட்டு',
  };

  static const _numbers = <String>[
    'பூஜ்ஜியம்',
    'ஒன்று',
    'இரண்டு',
    'மூன்று',
    'நான்கு',
    'ஐந்து',
    'ஆறு',
    'ஏழு',
    'எட்டு',
    'ஒன்பது',
    'பத்து',
    'பதினொன்று',
    'பன்னிரண்டு',
    'பதிமூன்று',
    'பதினான்கு',
    'பதினைந்து',
    'பதினாறு',
    'பதினேழு',
    'பதினெட்டு',
    'பத்தொன்பது',
    'இருபது',
  ];

  static const _tens = <String>[
    '',
    '',
    'இருபது',
    'முப்பது',
    'நாற்பது',
    'ஐம்பது',
    'அறுபது',
    'எழுபது',
    'எண்பது',
    'தொண்ணூறு',
  ];

  String number(int value) {
    final n = value < 0 ? 0 : value;
    if (n <= 20) return _numbers[n];
    if (n < 100)
      return '${_tens[n ~/ 10]}${n % 10 == 0 ? '' : ' ${_numbers[n % 10]}'}';
    if (n < 1000)
      return '${n == 100 ? 'நூறு' : '${_numbers[n ~/ 100]} நூறு'}${n % 100 == 0 ? '' : ' ${number(n % 100)}'}';
    if (n < 100000)
      return '${number(n ~/ 1000)} ஆயிரம்${n % 1000 == 0 ? '' : ' ${number(n % 1000)}'}';
    if (n < 10000000)
      return '${number(n ~/ 100000)} லட்சம்${n % 100000 == 0 ? '' : ' ${number(n % 100000)}'}';
    return '${number(n ~/ 10000000)} கோடி${n % 10000000 == 0 ? '' : ' ${number(n % 10000000)}'}';
  }

  String amount(double value) {
    final rupees = value.floor();
    final paise = ((value - rupees) * 100).round();
    return '${number(rupees)} ரூபாய்${paise == 0 ? '' : ' ${number(paise)} பைசா'}';
  }

  String productName(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (_products.containsKey(normalized)) return _products[normalized]!;
    return normalized
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => _products[word] ?? _transliterate(word))
        .join(' ');
  }

  String _transliterate(String word) {
    const sounds = <String, String>{
      'kh': 'க', 'ph': 'ஃப', 'th': 'த்', 'sh': 'ஷ்', 'ch': 'ச்',
      'oo': 'ஊ', 'ee': 'ஈ', 'aa': 'ஆ', 'ai': 'ஐ', 'ou': 'ஔ',
      'a': 'அ', 'e': 'எ', 'i': 'இ', 'o': 'ஒ', 'u': 'உ', 'k': 'க்',
      'g': 'க்', 'c': 'க்', 'q': 'க்', 'j': 'ஜ்', 't': 'ட்', 'd': 'ட்',
      'p': 'ப்', 'b': 'ப்', 'f': 'ஃப்', 'v': 'வ்', 'w': 'வ்', 's': 'ஸ்',
      'z': 'ஸ்', 'h': 'ஹ்', 'l': 'ல்', 'r': 'ர்', 'm': 'ம்', 'n': 'ன்',
      'y': 'ய்',
    };
    final token = word.toLowerCase();
    final result = StringBuffer();
    var index = 0;
    while (index < token.length) {
      String? matched;
      for (final sound in sounds.keys) {
        if (token.startsWith(sound, index) &&
            (matched == null || sound.length > matched.length)) {
          matched = sound;
        }
      }
      if (matched == null) {
        result.write(token[index]);
        index++;
      } else {
        result.write(sounds[matched]);
        index += matched.length;
      }
    }
    return result.toString();
  }

  String unit(String value) => _units[value.toLowerCase().trim()] ?? 'பொருள்';

  Future<void> _selectTamilVoice() async {
    final voices = await _tts.getVoices;
    if (voices is! List) throw const TamilVoiceUnavailableException();

    final tamilVoices = voices.whereType<Map>().where((voice) {
      final locale = '${voice['locale'] ?? voice['language'] ?? ''}'
          .toLowerCase()
          .replaceAll('_', '-');
      return locale == 'ta-in' || locale.startsWith('ta-');
    }).toList();

    if (tamilVoices.isEmpty) throw const TamilVoiceUnavailableException();

    tamilVoices.sort((a, b) {
      int score(Map voice) {
        final locale = '${voice['locale'] ?? voice['language'] ?? ''}'
            .toLowerCase()
            .replaceAll('_', '-');
        final name = '${voice['name'] ?? ''}'.toLowerCase();
        return (locale == 'ta-in' ? 10 : 0) +
            (name.contains('google') ? 3 : 0) +
            (name.contains('india') ? 2 : 0);
      }

      return score(b).compareTo(score(a));
    });

    final voice = tamilVoices.first;
    await _tts.setVoice({
      'name': '${voice['name'] ?? ''}',
      'locale': '${voice['locale'] ?? voice['language'] ?? 'ta-IN'}',
    });
  }

  Future<void> speak(OrderModel order) async {
    final itemText = order.products
        .asMap()
        .entries
        .map((entry) {
          final product = entry.value;
          final quantity = entry.key < order.quantities.length
              ? order.quantities[entry.key]
              : 1;
          final price = product.price;
          return '${productName(product.name)}, ${number(quantity)} ${unit(product.unit)}, விலை ${amount(price)}';
        })
        .join('. ');
    final payment =
        order.paymentMethod.toLowerCase().contains('cod') ||
            order.paymentMethod.toLowerCase().contains('cash')
        ? 'டெலிவரியின் போது பணம் செலுத்த வேண்டும்'
        : 'ஆன்லைனில் பணம் செலுத்தப்பட்டுள்ளது';
    final text =
        'புதிய ஆர்டர் வந்துள்ளது. ${itemText.isEmpty ? 'பொருள் விவரங்கள் இல்லை' : itemText}. மொத்தம் ${amount(order.total)}. $payment.';
    if (await speakTamilOnWeb(text)) return;
    await _tts.stop();
    await _tts.setLanguage('ta-IN');
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    await _selectTamilVoice();
    await _tts.awaitSpeakCompletion(true);
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await stopTamilWebSpeech();
    await _tts.stop();
  }
}
