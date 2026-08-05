class AddressModel {
  const AddressModel({
    required this.id,
    required this.label,
    required this.line1,
    required this.city,
    required this.pincode,
  });
  final String id;
  final String label;
  final String line1;
  final String city;
  final String pincode;

  String get shortAddress => '$city, $pincode';

  String get fullAddress => '$line1, $city $pincode';

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      label: json['label'] as String? ?? 'Address',
      line1: json['line1'] as String? ?? '',
      city: json['city'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
    );
  }
}
