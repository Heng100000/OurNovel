class ShippingRate {
  final int id;
  final int deliveryCompanyId;
  final String locationName;
  final double fee;
  final int? estimatedDays;

  ShippingRate({
    required this.id,
    required this.deliveryCompanyId,
    required this.locationName,
    required this.fee,
    required this.estimatedDays,
  });

  factory ShippingRate.fromJson(Map<String, dynamic> json) {
    return ShippingRate(
      id: json['id'],
      deliveryCompanyId: json['delivery_company_id'],
      locationName: json['location_name'],
      fee: double.tryParse(json['fee'].toString()) ?? 0.0,
      estimatedDays: json['estimated_days'] != null ? int.tryParse(json['estimated_days'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'delivery_company_id': deliveryCompanyId,
      'location_name': locationName,
      'fee': fee,
      'estimated_days': estimatedDays,
    };
  }
}

class DeliveryCompany {
  final int id;
  final String name;
  final String logoPath;
  final String contactPhone;
  final bool isActive;
  final List<ShippingRate> shippingRates;

  DeliveryCompany({
    required this.id,
    required this.name,
    required this.logoPath,
    required this.contactPhone,
    required this.isActive,
    required this.shippingRates,
  });

  factory DeliveryCompany.fromJson(Map<String, dynamic> json) {
    var list = json['shipping_rates'] as List? ?? [];
    List<ShippingRate> rates = list.map((i) => ShippingRate.fromJson(i)).toList();

    return DeliveryCompany(
      id: json['id'],
      name: json['name'],
      logoPath: json['logo_path'] ?? '',
      contactPhone: json['contact_phone'] ?? '',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      shippingRates: rates,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo_path': logoPath,
      'contact_phone': contactPhone,
      'is_active': isActive,
      'shipping_rates': shippingRates.map((x) => x.toJson()).toList(),
    };
  }
}
