import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../l10n/language_service.dart';

class MapPickerPage extends StatefulWidget {
  final LatLng? initialLocation;

  const MapPickerPage({super.key, this.initialLocation});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  GoogleMapController? _mapController;
  final LatLng _defaultLocation = const LatLng(11.5564, 104.9282); // Phnom Penh
  late LatLng _selectedLocation;
  String _address = "";
  bool _isLoading = false;

  // Cambodia Bounds
  final CameraTargetBounds _cambodiaBounds = CameraTargetBounds(
    LatLngBounds(
      southwest: const LatLng(9.9, 102.3),
      northeast: const LatLng(14.7, 107.8),
    ),
  );

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation ?? _defaultLocation;
    
    if (widget.initialLocation != null) {
      _getAddressFromLatLng(_selectedLocation);
    } else {
      _determinePosition();
    }
  }

  Future<void> _determinePosition() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Just use default location if service disabled
         _updateLocation(_defaultLocation);
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
           // Just use default location
           _updateLocation(_defaultLocation);
           return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
         // Just use default location
         _updateLocation(_defaultLocation);
         return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      // Check if location is inside Cambodia
      if (position.latitude < 9.9 || position.latitude > 14.7 || 
          position.longitude < 102.3 || position.longitude > 107.8) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Location outside Cambodia. Defaulting to Phnom Penh."))
           );
         }
         _updateLocation(_defaultLocation);
      } else {
        _updateLocation(LatLng(position.latitude, position.longitude));
      }
      
    } catch (e) {
      debugPrint("Error getting location: $e");
       _updateLocation(_defaultLocation);
    }
  }

  void _updateLocation(LatLng location) {
    if (!mounted) return;
    
    setState(() {
      _selectedLocation = location;
      _isLoading = false;
    });
    
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(location),
    );
    _getAddressFromLatLng(location);
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        if (mounted) {
          setState(() {
            _address = "${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}";
          });
        }
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          LanguageService().translate('select_location'),
          style: const TextStyle(fontFamily: 'Hanuman', fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _determinePosition,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 15,
            ),
            cameraTargetBounds: _cambodiaBounds, // Restrict to Cambodia
            minMaxZoomPreference: const MinMaxZoomPreference(7, 20), // Restrict zoom out
            onTap: (position) {
              setState(() => _selectedLocation = position);
              _getAddressFromLatLng(position);
            },
            markers: {
              Marker(
                markerId: const MarkerId('selected-location'),
                position: _selectedLocation,
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    LanguageService().translate('confirm_location'),
                    style: const TextStyle(
                      fontFamily: 'Hanuman',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLoading ? LanguageService().translate('current_location') + "..." : (_address.isEmpty ? LanguageService().translate('search_location') : _address),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () {
                        Navigator.pop(context, {
                          'address': _address.isEmpty ? "${_selectedLocation.latitude}, ${_selectedLocation.longitude}" : _address,
                          'latitude': _selectedLocation.latitude,
                          'longitude': _selectedLocation.longitude,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5a7335),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                             LanguageService().translate('confirm_location'),
                            style: const TextStyle(
                              fontFamily: 'Hanuman',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
