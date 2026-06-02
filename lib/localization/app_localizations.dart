class AppLocalizations {
  const AppLocalizations(this.localeCode);

  final String localeCode;

  static const _values = {
    'en': {
      'appName': 'Doormart Delivery',
      'browseProducts': 'Browse products',
      'cart': 'Cart',
    },
    'ta': {
      'appName': 'டோர்மார்ட் டெலிவரி',
      'browseProducts': 'பொருட்களை பார்க்க',
      'cart': 'வண்டி',
    },
  };

  String text(String key) =>
      _values[localeCode]?[key] ?? _values['en']![key] ?? key;
}
