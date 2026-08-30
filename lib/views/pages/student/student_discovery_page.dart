import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/foundation.dart';
import '../../../viewmodels/all_viewmodels.dart';

// Mess data structure for the map
class _MessPin {
  final String name;
  final String rating;
  final String distance;
  final String fee;
  final double lat;
  final double lng;
  final String phone;
  final String nextMeal;
  final String messId;

  const _MessPin({
    required this.name,
    required this.rating,
    required this.distance,
    required this.fee,
    required this.lat,
    required this.lng,
    required this.phone,
    required this.nextMeal,
    required this.messId,
  });
}

class StudentDiscoveryPage extends ConsumerStatefulWidget {
  const StudentDiscoveryPage({super.key});

  @override
  ConsumerState<StudentDiscoveryPage> createState() => _StudentDiscoveryPageState();
}

class _StudentDiscoveryPageState extends ConsumerState<StudentDiscoveryPage> {
  GoogleMapController? _mapController;
  _MessPin? _selectedMess;
  LatLng _initialPosition = const LatLng(26.9124, 75.7873); // Default: Jaipur
  bool _locationLoaded = false; 
  final Set<Marker> _markers = {};
  List<_MessPin> _allMesses = [];

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
    _fetchMesses();
  }

  Future<void> _fetchMesses() async {
    final messes = await ref.read(appServiceProvider).getAllListedMesses();
    final pins = messes.map((m) {
      return _MessPin(
        messId: m.messId,
        name: m.name,
        rating: '4.5', // Placeholder
        distance: 'Nearby', // Needs geo calculation
        fee: '₹${m.monthlyFee.toStringAsFixed(0)}/mo',
        lat: m.gpsLat,
        lng: m.gpsLng,
        phone: m.ownerPhone,
        nextMeal: 'Click to view menu',
      );
    }).toList();

    if (mounted) {
      setState(() {
        _allMesses = pins;
        _buildMarkers();
      });
    }
  }

  void _buildMarkers() {
    _markers.clear();
    for (final mess in _allMesses) {
      _markers.add(Marker(
        markerId: MarkerId(mess.name),
        position: LatLng(mess.lat, mess.lng),
        infoWindow: InfoWindow(title: mess.name, snippet: '${mess.rating} ⭐'),
        onTap: () => setState(() => _selectedMess = mess),
      ));
    }
  }

  Future<void> _loadUserLocation() async {
    if (kIsWeb) return; // Geolocator may have issues or not needed for dummy web map
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition();
      if (!_locationLoaded) {
        if (mounted) {
          setState(() {
            _initialPosition = LatLng(pos.latitude, pos.longitude);
            _locationLoaded = true;
          });
        }
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_initialPosition, 15),
        );
      } else {
        if (mounted) {
          setState(() => _initialPosition = LatLng(pos.latitude, pos.longitude));
        }
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_initialPosition, 15),
        );
      }
    } catch (_) {}
  }

  /// Opens native Google Maps app with destination using the official deep-link format.
  /// Uses: https://www.google.com/maps/dir/?api=1&destination=LAT,LNG
  /// This does NOT use the paid Google Directions API - it hands off to the native app.
  Future<void> _openNativeDirections(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps. Please install the app.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Real Google Map
          kIsWeb
              ? Container(
                  color: const Color(0xFFF3F4F6),
                  child: Center(
                    child: Text(
                      'Map view is unavailable on Web without API Key.\nPlease test on a real device or emulator.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: const Color(0xFF6B7280)),
                    ),
                  ),
                )
              : GoogleMap(
                  onMapCreated: (c) => _mapController = c,
                  initialCameraPosition: CameraPosition(
                    target: _initialPosition,
                    zoom: 14,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  onTap: (_) => setState(() => _selectedMess = null),
                ),

          // Search bar at top
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                        hintText: 'Search mess by name or area...',
                        hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // My location button
                GestureDetector(
                  onTap: _loadUserLocation,
                  child: Container(
                    width: 46, height: 46,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                    ),
                    child: const Icon(Icons.my_location_rounded, color: Color(0xFF22C55E), size: 22),
                  ),
                ),
              ]),
            ),
          ),

          // Bottom sheet: selected mess card or nearby messes list
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _selectedMess != null
                  ? _buildSelectedMessCard(_selectedMess!)
                  : _buildNearbyList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedMessCard(_MessPin mess) {
    return Container(
      key: ValueKey(mess.name),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.restaurant, color: Color(0xFF16A34A), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(mess.name,
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
            Text('${mess.rating} ⭐  •  ${mess.distance} away  •  ${mess.fee}',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
          ])),
          GestureDetector(
            onTap: () => setState(() => _selectedMess = null),
            child: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
          ),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            const Icon(Icons.restaurant_menu, color: Color(0xFF16A34A), size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(mess.nextMeal,
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF166534)))),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final uri = Uri.parse('tel:${mess.phone}');
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
              icon: const Icon(Icons.call_rounded, size: 18),
              label: Text('Call', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF22C55E),
                side: const BorderSide(color: Color(0xFF22C55E)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              // Opens native Google Maps via official deep-link format
              // https://www.google.com/maps/dir/?api=1&destination=LAT,LNG
              // Does NOT use the paid Google Directions API
              onPressed: () => _openNativeDirections(mess.lat, mess.lng),
              icon: const Icon(Icons.directions_rounded, size: 18, color: Colors.white),
              label: Text('Directions', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildNearbyList() {
    return Container(
      key: const ValueKey('nearby'),
      height: 220,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text('Nearby Messes',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _allMesses.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final mess = _allMesses[i];
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedMess = mess);
                  if (!kIsWeb) {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(LatLng(mess.lat, mess.lng), 16),
                    );
                  }
                },
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(mess.name,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
                    const SizedBox(height: 4),
                    Text('${mess.rating} ⭐  •  ${mess.distance}',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280))),
                    Text(mess.fee,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF16A34A))),
                  ]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }
}
