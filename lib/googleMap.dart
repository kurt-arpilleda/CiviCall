import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:civicall/theme/app_theme.dart';

class LocationPickerDialog extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const LocationPickerDialog({
    Key? key,
    this.initialLat,
    this.initialLng,
  }) : super(key: key);

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  GoogleMapController? _controller;
  final Location _location = Location();
  LatLng _selectedLocation = const LatLng(14.1007, 121.0794);
  Set<Marker> _markers = {};
  bool _isLoadingLocation = false;
  bool _mapReady = false;
  MapType _mapType = MapType.normal;

  static const LatLng _calabarzonCenter = LatLng(14.1007, 121.0794);
  static const double _calabarzonZoom = 9.0;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLocation = LatLng(widget.initialLat!, widget.initialLng!);
    }
    _updateMarker(_selectedLocation);
  }

  void _updateMarker(LatLng position) {
    setState(() {
      _selectedLocation = position;
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Selected Location'),
        ),
      };
    });
  }

  void _toggleMapType() {
    setState(() {
      _mapType = _mapType == MapType.normal ? MapType.satellite : MapType.normal;
    });
  }

  Future<void> _goToMyLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      final locationData = await _location.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        final pos = LatLng(locationData.latitude!, locationData.longitude!);
        _updateMarker(pos);
        _controller?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: pos, zoom: 16.0),
          ),
        );
      }
    } catch (_) {}
    setState(() => _isLoadingLocation = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.78,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildMap()),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      decoration: const BoxDecoration(color: AppTheme.redPink),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pin Location',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Tap on the map to select a location',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: (controller) {
            _controller = controller;
            setState(() => _mapReady = true);
            if (widget.initialLat != null && widget.initialLng != null) {
              Future.delayed(const Duration(milliseconds: 300), () {
                _controller?.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: _selectedLocation, zoom: 15.0),
                  ),
                );
              });
            }
          },
          initialCameraPosition: CameraPosition(
            target: (widget.initialLat != null && widget.initialLng != null)
                ? _selectedLocation
                : _calabarzonCenter,
            zoom: (widget.initialLat != null && widget.initialLng != null)
                ? 15.0
                : _calabarzonZoom,
          ),
          markers: _markers,
          onTap: _updateMarker,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapType: _mapType,
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: Column(
            children: [
              _mapButton(
                icon: _isLoadingLocation
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.redPink,
                  ),
                )
                    : const Icon(Icons.my_location_rounded, color: AppTheme.redPink, size: 20),
                onTap: _isLoadingLocation ? null : _goToMyLocation,
              ),
              const SizedBox(height: 8),
              _mapButton(
                icon: const Icon(Icons.add_rounded, color: AppTheme.darkGray, size: 22),
                onTap: () => _controller?.animateCamera(CameraUpdate.zoomIn()),
              ),
              const SizedBox(height: 8),
              _mapButton(
                icon: const Icon(Icons.remove_rounded, color: AppTheme.darkGray, size: 22),
                onTap: () => _controller?.animateCamera(CameraUpdate.zoomOut()),
              ),
              const SizedBox(height: 8),
              _mapButton(
                icon: const Icon(Icons.explore_rounded, color: AppTheme.redPink, size: 20),
                onTap: () {
                  _controller?.animateCamera(
                    CameraUpdate.newCameraPosition(
                      const CameraPosition(target: _calabarzonCenter, zoom: _calabarzonZoom),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _mapButton(
                icon: Icon(
                  _mapType == MapType.normal ? Icons.satellite_alt : Icons.map,
                  color: AppTheme.redPink,
                  size: 20,
                ),
                onTap: _toggleMapType,
              ),
            ],
          ),
        ),
        Positioned(
          left: 12,
          bottom: 12,
          child: _mapButton(
            icon: const Icon(Icons.explore_rounded, color: AppTheme.redPink, size: 20),
            onTap: () {
              _controller?.animateCamera(
                CameraUpdate.newCameraPosition(
                  const CameraPosition(target: _calabarzonCenter, zoom: _calabarzonZoom),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _mapButton({required Widget icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: icon),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: AppTheme.darkGray.withOpacity(0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.darkGray, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _selectedLocation),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.redPink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_rounded, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Confirm Location',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
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

class LocationViewDialog extends StatefulWidget {
  final double lat;
  final double lng;

  const LocationViewDialog({
    Key? key,
    required this.lat,
    required this.lng,
  }) : super(key: key);

  @override
  State<LocationViewDialog> createState() => _LocationViewDialogState();
}

class _LocationViewDialogState extends State<LocationViewDialog> {
  MapType _mapType = MapType.normal;

  void _toggleMapType() {
    setState(() {
      _mapType = _mapType == MapType.normal ? MapType.satellite : MapType.normal;
    });
  }

  Future<void> _openInGoogleMaps() async {
    final Uri url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${widget.lat},${widget.lng}&travelmode=driving',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng location = LatLng(widget.lat, widget.lng);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
                decoration: const BoxDecoration(color: AppTheme.redPink),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pinned Location',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Tap directions to navigate there',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 20),
                      tooltip: 'Open in Google Maps',
                      onPressed: _openInGoogleMaps,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: location,
                        zoom: 15.0,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('view_only_location'),
                          position: location,
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                          infoWindow: const InfoWindow(title: 'Selected Location'),
                        ),
                      },
                      myLocationEnabled: false,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: true,
                      mapType: _mapType,
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: GestureDetector(
                        onTap: _toggleMapType,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              _mapType == MapType.normal ? Icons.satellite_alt : Icons.map,
                              color: AppTheme.redPink,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.darkGray,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: BorderSide(color: AppTheme.darkGray.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openInGoogleMaps,
                        icon: const Icon(Icons.directions_rounded, size: 16),
                        label: const Text('Directions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A73E8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}