class UserAddress {
  final int id;
  final int userId;
  final String title;
  final String address;
  final String? cityProvince;
  final String phone;
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  UserAddress({
    required this.id,
    required this.userId,
    required this.title,
    required this.address,
    this.cityProvince,
    required this.phone,
    required this.isDefault,
    this.latitude,
    this.longitude,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['id'],
      userId: json['user_id'] ?? 0,
      title: json['title'] ?? '',
      address: json['address'] ?? '',
      cityProvince: json['city_province'],
      phone: json['phone'] ?? '',
      isDefault: json['is_default'] == 1 || json['is_default'] == true,
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'address': address,
      'city_province': cityProvince,
      'phone': phone,
      'is_default': isDefault,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
