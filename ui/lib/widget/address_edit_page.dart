import 'package:flutter/material.dart';
import '../l10n/language_service.dart';
import '../core/widgets/global_loader.dart';
import 'map_picker_page.dart';
import '../core/models/user_address.dart';
import '../features/address/data/user_address_service.dart';
import '../features/menu/presentation/pages/menu_page.dart';

class AddressEditPage extends StatefulWidget {
  final UserAddress? initialUserAddress;
  final String? initialAddress;
  final String? initialPhone;
  const AddressEditPage(
      {super.key,
      this.initialUserAddress,
      this.initialAddress,
      this.initialPhone});

  @override
  State<AddressEditPage> createState() => _AddressEditPageState();
}

class _AddressEditPageState extends State<AddressEditPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isLoadingAddresses = true;
  bool _isDefault = false;
  List<UserAddress> _savedAddresses = [];
  double? _selectedLat;
  double? _selectedLng;

  late TextEditingController _titleController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;

  static const _green = Color(0xFF5a7335);
  static const _greenLight = Color(0xFF7aad45);

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.initialUserAddress?.title ?? '');
    _phoneController = TextEditingController(
        text:
            widget.initialUserAddress?.phone ?? widget.initialPhone ?? '');
    _addressController = TextEditingController(
        text: widget.initialUserAddress?.address ??
            widget.initialAddress ??
            '');
    _cityController = TextEditingController(
        text: widget.initialUserAddress?.cityProvince ?? '');
    _isDefault = widget.initialUserAddress?.isDefault ?? false;
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
      _titleController.text = address.title;
      _phoneController.text = address.phone;
      _addressController.text = address.address;
      _cityController.text = address.cityProvince ?? '';
      _isDefault = address.isDefault;
      _selectedLat = address.latitude;
      _selectedLng = address.longitude;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF5F7F0),
      appBar: AppBar(
        title: Text(
          LanguageService().translate('edit_address') ?? 'កែប្រែអាស័យដ្ឋាន',
          style: const TextStyle(
            fontFamily: 'Hanuman',
            fontWeight: FontWeight.bold,
            color: _green,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _green, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Contact Info Card ────────────────────────────────────────
              _sectionHeader(Icons.person_rounded,
                  LanguageService().translate('contact_info') ?? 'ព័ត៌មានទំនាក់ទំនង'),
              const SizedBox(height: 12),
              _buildCard(
                children: [
                  _buildField(
                    controller: _titleController,
                    label: LanguageService().translate('name_label') ?? 'ឈ្មោះ',
                    icon: Icons.badge_outlined,
                    hint: 'Sok San',
                  ),
                  _divider(),
                  _buildField(
                    controller: _phoneController,
                    label: LanguageService().translate('phone_label') ?? 'លេខទូរសព្ទ',
                    icon: Icons.phone_outlined,
                    hint: '012 345 678',
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ─── Delivery Location Card ───────────────────────────────────
              _sectionHeader(Icons.location_on_rounded,
                  LanguageService().translate('delivery_location') ?? 'ទីតាំងដឹកជញ្ជូន'),
              const SizedBox(height: 12),
              _buildCard(
                children: [
                  _buildField(
                    controller: _addressController,
                    label: LanguageService().translate('address_label') ?? 'អាស័យដ្ឋាន',
                    icon: Icons.location_on_outlined,
                    hint: 'ផ្ទះ, ផ្លូវ...',
                    maxLines: 2,
                  ),
                  _divider(),
                  _buildField(
                    controller: _cityController,
                    label: LanguageService().translate('city_label') ?? 'ខេត្ត / ក្រុង',
                    icon: Icons.apartment_outlined,
                    hint: 'ភ្នំពេញ',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ─── Map Picker ───────────────────────────────────────────────
              _buildMapCard(isDark),

              const SizedBox(height: 16),

              // ─── Default Toggle ───────────────────────────────────────────
              _buildDefaultToggle(isDark),

              const SizedBox(height: 24),

              // ─── Saved Addresses ──────────────────────────────────────────
              if (_isLoadingAddresses)
                const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: GlobalLoader(size: 24),
                ))
              else if (_savedAddresses.isNotEmpty) ...[
                _sectionHeader(Icons.bookmark_rounded,
                    LanguageService().translate('saved_addresses') ?? 'អាស័យដ្ឋានដែលបានរក្សា'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 105,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _savedAddresses.length,
                    itemBuilder: (context, index) =>
                        _buildSavedAddressChip(_savedAddresses[index]),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ─── Save Button ──────────────────────────────────────────────
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Section Header ──────────────────────────────────────────────────────
  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_green, _greenLight]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Hanuman',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: _green,
          ),
        ),
      ],
    );
  }

  // ─── Card Wrapper ─────────────────────────────────────────────────────────
  Widget _buildCard({required List<Widget> children}) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 56);

  // ─── Input Field ──────────────────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
          fontFamily: 'Hanuman',
          fontSize: 15,
          color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        labelStyle:
            TextStyle(color: Colors.grey[500], fontFamily: 'Hanuman', fontSize: 13),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 12),
          child: Icon(icon, color: _green, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        border: InputBorder.none,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (v) =>
          (v == null || v.isEmpty) ? 'សូមបំពេញព័ត៌មាននេះ' : null,
    );
  }

  // ─── Map Card ─────────────────────────────────────────────────────────────
  Widget _buildMapCard(bool isDark) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MapPickerPage()),
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
          color: isDark
              ? const Color(0xFF1e2a14)
              : const Color(0xFF5a7335).withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _green.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      color: _green, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LanguageService().translate('delivery_to') ?? 'ដឹកជញ្ជូនទៅ',
                        style: TextStyle(
                            fontFamily: 'Hanuman',
                            fontSize: 11,
                            color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _addressController.text.isNotEmpty
                            ? _addressController.text
                            : LanguageService().translate('choose_on_map') ??
                                'ជ្រើសរើសនៅលើផែនទី',
                        style: const TextStyle(
                          fontFamily: 'Hanuman',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_selectedLat != null && _selectedLng != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Lat: ${_selectedLat!.toStringAsFixed(6)}, Lng: ${_selectedLng!.toStringAsFixed(6)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.edit_outlined, color: Colors.grey, size: 18),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.map_outlined, color: _green, size: 18),
                const SizedBox(width: 10),
                Text(
                  LanguageService().translate('choose_on_map') ?? 'ជ្រើសរើសនៅលើផែនទី',
                  style: const TextStyle(
                    fontFamily: 'Hanuman',
                    fontWeight: FontWeight.bold,
                    color: _green,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, color: _green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Default Toggle ───────────────────────────────────────────────────────
  Widget _buildDefaultToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isDefault
                  ? _green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.star_rounded,
              color: _isDefault ? _green : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'កំណត់ជាលំនាំដើម',
                style: TextStyle(
                    fontFamily: 'Hanuman',
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
              Text(
                'ប្រើអាស័យដ្ឋាននេះដោយស្វ័យប្រវត្តិ',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
          const Spacer(),
          Switch.adaptive(
            value: _isDefault,
            onChanged: (v) => setState(() => _isDefault = v),
            activeColor: _green,
          ),
        ],
      ),
    );
  }

  // ─── Saved Address Chip ───────────────────────────────────────────────────
  Widget _buildSavedAddressChip(UserAddress address) {
    final isSelected = _addressController.text == address.address;
    return GestureDetector(
      onTap: () => _onAddressSelected(address),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 155,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? _green.withOpacity(0.08) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? _green : Colors.grey[300]!,
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  address.isDefault ? Icons.star_rounded : Icons.location_on_outlined,
                  color: isSelected ? _green : Colors.grey,
                  size: 15,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address.title,
                    style: TextStyle(
                      fontFamily: 'Hanuman',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected ? _green : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              address.address,
              style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              address.phone,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Save Button ──────────────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_green, _greenLight],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _green.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isSaving
            ? const GlobalLoader(size: 22, color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    LanguageService().translate('save_btn') ?? 'រក្សាទុក',
                    style: const TextStyle(
                      fontFamily: 'Hanuman',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ─── Save Logic ───────────────────────────────────────────────────────────
  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final newAddressData = UserAddress(
      id: widget.initialUserAddress?.id ?? 0,
      userId: widget.initialUserAddress?.userId ?? 0,
      title: _titleController.text.trim(),
      address: _addressController.text.trim(),
      cityProvince: _cityController.text.trim(),
      phone: _phoneController.text.trim(),
      isDefault: _isDefault,
      latitude: _selectedLat,
      longitude: _selectedLng,
    );

    final service = UserAddressService();
    final UserAddress? savedAddress = widget.initialUserAddress != null
        ? await service.updateAddress(widget.initialUserAddress!.id, newAddressData)
        : await service.storeAddress(newAddressData);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (savedAddress != null) {
      Navigator.pop(context, {'success': true});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save address. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}