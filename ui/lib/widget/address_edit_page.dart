import 'package:flutter/material.dart';
import '../l10n/language_service.dart';
import 'map_picker_page.dart';
import '../core/models/user_address.dart';
import '../features/address/data/user_address_service.dart';
import '../features/menu/presentation/pages/menu_page.dart';

class AddressEditPage extends StatefulWidget {
  final UserAddress? initialUserAddress;
  final String? initialAddress;
  final String? initialPhone;
  const AddressEditPage({super.key, this.initialUserAddress, this.initialAddress, this.initialPhone});

  @override
  State<AddressEditPage> createState() => _AddressEditPageState();
}

class _AddressEditPageState extends State<AddressEditPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isLoadingAddresses = true;
  List<UserAddress> _savedAddresses = [];
  double? _selectedLat;
  double? _selectedLng;
  
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialUserAddress?.title ?? "Sok San");
    _phoneController = TextEditingController(text: widget.initialUserAddress?.phone ?? widget.initialPhone ?? "012 345 678");
    _addressController = TextEditingController(text: widget.initialUserAddress?.address ?? widget.initialAddress ?? "ផ្ទះលេខ ១២៣, ផ្លូវកម្ពុជាក្រោម");
    _cityController = TextEditingController(text: widget.initialUserAddress?.cityProvince ?? "ភ្នំពេញ");
    _selectedLat = widget.initialUserAddress?.latitude;
    _selectedLng = widget.initialUserAddress?.longitude;
    _fetchSavedAddresses();
  }

  Future<void> _fetchSavedAddresses() async {
    final addresses = await UserAddressService().getAddresses();
    if (mounted) {
      setState(() {
        _savedAddresses = addresses;
        _isLoadingAddresses = false;
      });
    }
  }

  void _onAddressSelected(UserAddress address) {
    setState(() {
      _nameController.text = address.title;
      _phoneController.text = address.phone;
      _addressController.text = address.address;
      _cityController.text = address.cityProvince ?? "";
      _selectedLat = address.latitude;
      _selectedLng = address.longitude;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Light Gray Bg
      drawer: const SideMenuDrawer(),
      appBar: AppBar(
        title: Text(
          LanguageService().translate('edit_address'),
          style: const TextStyle(
            fontFamily: 'Hanuman',
            fontWeight: FontWeight.bold,
            color: Color(0xFF5a7335),
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF5a7335)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              _buildSectionTitle(LanguageService().translate('contact_info')),
              _buildTextField(LanguageService().translate('name_label'), _nameController, Icons.person_outline),
              const SizedBox(height: 15),
              _buildTextField(LanguageService().translate('phone_label'), _phoneController, Icons.phone_outlined, keyboardType: TextInputType.phone),
              
              const SizedBox(height: 25),
              _buildSectionTitle(LanguageService().translate('delivery_location')),
              _buildTextField(LanguageService().translate('address_label'), _addressController, Icons.location_on_outlined),
              const SizedBox(height: 15),
              _buildTextField(LanguageService().translate('city_label'), _cityController, Icons.location_city_outlined),
              
              const SizedBox(height: 20),
              
              InkWell(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MapPickerPage()),
                  );
                  if (result != null && result is Map<String, dynamic>) {
                    setState(() {
                      _addressController.text = result['address'];
                      _selectedLat = result['latitude'];
                      _selectedLng = result['longitude'];
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5a7335).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF5a7335).withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.location_on, color: Color(0xFF5a7335), size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  LanguageService().translate('delivery_to'),
                                  style: TextStyle(
                                    fontFamily: 'Hanuman',
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _addressController.text.isNotEmpty 
                                      ? _addressController.text 
                                      : LanguageService().translate('choose_on_map'),
                                  style: const TextStyle(
                                    fontFamily: 'Hanuman',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_selectedLat != null && _selectedLng != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    "Lat: ${_selectedLat?.toStringAsFixed(6)}, Lng: ${_selectedLng?.toStringAsFixed(6)}",
                                    style: TextStyle(
                                      fontFamily: 'Hanuman',
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.map_outlined, color: Color(0xFF5a7335), size: 20),
                          const SizedBox(width: 12),
                          Text(
                            LanguageService().translate('choose_on_map'),
                            style: const TextStyle(
                              fontFamily: 'Hanuman',
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5a7335),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFF5a7335)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              if (_savedAddresses.isNotEmpty) ...[
                const SizedBox(height: 25),
                _buildSectionTitle(LanguageService().translate('saved_addresses') ?? "Saved Addresses"),
                Container(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _savedAddresses.length,
                    itemBuilder: (context, index) {
                      final address = _savedAddresses[index];
                      return GestureDetector(
                        onTap: () => _onAddressSelected(address),
                        child: Container(
                          width: 150,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _addressController.text == address.address 
                                  ? const Color(0xFF5a7335) 
                                  : Colors.grey[300]!,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                address.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                address.address,
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        _isSaving = true;
                      });

                      final newAddressData = UserAddress(
                        id: widget.initialUserAddress?.id ?? 0,
                        userId: widget.initialUserAddress?.userId ?? 0,
                        title: _nameController.text.trim(),
                        address: _addressController.text.trim(),
                        cityProvince: _cityController.text.trim(),
                        phone: _phoneController.text.trim(),
                        isDefault: true,
                        latitude: _selectedLat,
                        longitude: _selectedLng,
                      );

                      UserAddress? savedAddress;
                      final service = UserAddressService();

                      if (widget.initialUserAddress != null) {
                        savedAddress = await service.updateAddress(widget.initialUserAddress!.id, newAddressData);
                      } else {
                        savedAddress = await service.storeAddress(newAddressData);
                      }

                      if (mounted) {
                        setState(() {
                          _isSaving = false;
                        });
                        if (savedAddress != null) {
                          // Return true signal so CartPage forces a reload
                          Navigator.pop(context, {'success': true});
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to save address. Please try again.')),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5a7335),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving 
                      ? const SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          LanguageService().translate('save_btn'),
                          style: const TextStyle(
                            fontFamily: 'Hanuman',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 5),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Hanuman',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF5a7335),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType}) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(fontFamily: 'Hanuman', fontSize: 16, color: theme.textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500], fontFamily: 'Hanuman'),
          prefixIcon: Icon(icon, color: const Color(0xFF5a7335)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'សូមបំពេញព័ត៌មាននេះ'; // Please fill this info
          }
          return null;
        },
      ),
    );
  }
}