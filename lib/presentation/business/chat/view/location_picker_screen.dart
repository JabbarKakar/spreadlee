import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:spreadlee/core/constant.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/style_manager.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'dart:io' show Platform;

class LocationPickerScreen extends StatefulWidget {
  final String chatId;
  final String userId;
  final String userRole;

  const LocationPickerScreen({
    Key? key,
    required this.chatId,
    required this.userId,
    required this.userRole,
  }) : super(key: key);

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  final TextEditingController _searchController = TextEditingController();
  LatLng _selectedLocation = const LatLng(0, 0);
  bool _isLoading = true;
  bool _isLoadingSend = false;
  String? _currentAddress;
  Set<Marker> _markers = {};
  bool _hasLocationPermission = false;
  bool _isInitialized = false;
  BitmapDescriptor? _customMarkerIcon;

  @override
  void initState() {
    super.initState();
    debugPrint('LocationPickerScreen: initState called');
    _loadCustomMarkerIcon();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isInitialized) {
        _initializeLocation();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _isInitialized = false;
    super.dispose();
  }

  Future<void> _loadCustomMarkerIcon() async {
    _customMarkerIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/800px-Google_Maps_pin.svg.png',
    );
  }

  Future<void> _initializeLocation() async {
    if (!mounted || _isInitialized) return;

    try {
      debugPrint('LocationPickerScreen: Starting location initialization');

      // First check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('LocationPickerScreen: Location services are disabled');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Please enable location services in your device settings'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pop(context);
          return;
        }
      }

      // Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('LocationPickerScreen: Permission denied');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Location permission is required to use this feature'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
            Navigator.pop(context);
            return;
          }
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('LocationPickerScreen: Permission permanently denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location permission is permanently denied. Please enable it in settings.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pop(context);
          return;
        }
      }

      // Get current location with timeout
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Location request timed out');
          },
        );
      } catch (e) {
        debugPrint('LocationPickerScreen: Error getting location: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error getting your location. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
        return;
      }

      if (!mounted) return;

      debugPrint('LocationPickerScreen: Location obtained successfully');
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _markers = {
          Marker(
            markerId: const MarkerId('selected_location'),
            position: _selectedLocation,
            icon: _customMarkerIcon ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        };
        _hasLocationPermission = true;
        _isLoading = false;
        _isInitialized = true;
      });

      // Update the address for the current location
      _updateCurrentAddress(_selectedLocation);

      // Move camera to current location
      try {
        final controller = await _mapController.future;
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLocation, 15),
        );
      } catch (e) {
        debugPrint('LocationPickerScreen: Error moving camera: $e');
        // Don't show error to user for camera movement
      }
    } catch (e, stackTrace) {
      debugPrint('LocationPickerScreen: Error in initialization: $e');
      debugPrint('LocationPickerScreen: Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        const  SnackBar(
            content: Text('LocationPickerScreen: Error moving camera'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          _isLoading = false;
          _isInitialized = false;
        });
      }
    }
  }

  Future<void> _sendLocation() async {
    if (_isLoadingSend || !mounted) return;

    setState(() => _isLoadingSend = true);

    // Add a safety timer to ensure _isLoadingSend is reset after 10 seconds
    Timer? safetyTimer;
    safetyTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _isLoadingSend) {
        debugPrint('=== Safety timer triggered, resetting _isLoadingSend ===');
        setState(() => _isLoadingSend = false);
      }
    });

    try {
      final location = {
        'latitude': _selectedLocation.latitude,
        'longitude': _selectedLocation.longitude,
        'address': _currentAddress ??
            '${_selectedLocation.latitude}, ${_selectedLocation.longitude}',
      };

      debugPrint('=== Location data prepared: $location ===');

      // Add a small delay to ensure the location data is properly prepared
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        debugPrint('=== Navigating back to chat with location data ===');
        Navigator.pop(context, {
          'success': true,
          'location': location,
        });
      }
    } catch (e) {
      debugPrint('Error preparing location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        const  SnackBar(
            content: Text('Error preparing location:'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      safetyTimer.cancel();
      if (mounted) {
        setState(() => _isLoadingSend = false);
      }
    }
  }

  void _updateMapLocation(LatLng newLocation) {
    setState(() {
      _selectedLocation = newLocation;
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedLocation,
          icon: _customMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };
    });

    // Update current address when location changes
    _updateCurrentAddress(newLocation);

    _mapController.future.then((controller) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation, 15),
      );
    });
  }

  void _updateCurrentAddress(LatLng location) {
    // Create a simple address format from coordinates
    final lat = location.latitude.toStringAsFixed(6);
    final lng = location.longitude.toStringAsFixed(6);
    _currentAddress = 'Lat: $lat, Lng: $lng';
  }

  String get _apiKey {
    if (kIsWeb) {
      return 'AIzaSyCwnYv-gKGSOfBC39jumICyG-i6NpD7FNQ'; // Web API key
    } else if (Platform.isIOS) {
      return 'AIzaSyDkRFkgfxFkrItRxPvGZgQZtvLzDgDRnwI'; // iOS API key
    } else {
      return 'AIzaSyD_E5XgsM4XPMRALj6SODpJGjP0M8HOwQw'; // Android API key
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: _isLoadingSend ? null : () => Navigator.pop(context),
        ),
        title: GooglePlaceAutoCompleteTextField(
          googleAPIKey: _apiKey,
          textEditingController: _searchController,
          inputDecoration: InputDecoration(
            hintText: 'Search location...',
            hintStyle:
                getRegularStyle(color: ColorManager.gray500, fontSize: 14),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
          debounceTime: 800,
          countries: const ['us', 'ca', 'gb'],
          itemClick: (Prediction prediction) {
            // Handle location selection
            final lat = double.parse(prediction.lat ?? '0');
            final lng = double.parse(prediction.lng ?? '0');
            final newLocation = LatLng(lat, lng);
            _updateMapLocation(newLocation);
            _searchController.text = prediction.description ?? '';
            // Set the address from the search result
            _currentAddress = prediction.description ?? '';
          },
          getPlaceDetailWithLatLng: (Prediction prediction) {
            // This is called after getting lat/lng details
            final lat = double.parse(prediction.lat ?? '0');
            final lng = double.parse(prediction.lng ?? '0');
            final newLocation = LatLng(lat, lng);
            _updateMapLocation(newLocation);
            // Set the address from the search result
            _currentAddress = prediction.description ?? '';
          },
          isLatLngRequired: true,
          boxDecoration: const BoxDecoration(
            color: Colors.transparent,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _selectedLocation,
                          zoom: 14.0,
                        ),
                        onMapCreated: (controller) {
                          _mapController.complete(controller);
                        },
                        markers: _markers,
                        onCameraMove: (position) {
                          if (mounted) {
                            setState(() {
                              _selectedLocation = position.target;
                              _markers = {
                                Marker(
                                  markerId: const MarkerId('selected_location'),
                                  position: _selectedLocation,
                                  icon: _customMarkerIcon ??
                                      BitmapDescriptor.defaultMarkerWithHue(
                                          BitmapDescriptor.hueRed),
                                ),
                              };
                            });
                            // Update address when camera moves
                            _updateCurrentAddress(_selectedLocation);
                          }
                        },
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        compassEnabled: false,
                        trafficEnabled: false,
                        mapType: MapType.normal,
                        gestureRecognizers: const {},
                      ),
                      if (kIsWeb)
                        Align(
                          alignment: const AlignmentDirectional(0.0, 0.0),
                          child: Container(
                            width: 25.0,
                            height: 80.0,
                            decoration: const BoxDecoration(),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.asset(
                                    'assets/images/800px-Google_Maps_pin.svg.png',
                                    height: 40.0,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 40),
                            child: Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Send',
                        style: getMediumStyle(
                          color: ColorManager.gray500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 2),
                      _isLoadingSend
                          ? const SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(),
                            )
                          : ElevatedButton(
                              onPressed: _isLoadingSend ? null : _sendLocation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorManager.blueLight800,
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(12),
                              ),
                              child: const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
