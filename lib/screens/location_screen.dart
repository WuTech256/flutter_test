import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationScreen extends StatefulWidget {
  final String username; // ví dụ: "toanvd25062001"

  const LocationScreen({super.key, required this.username});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref();
  LatLng? _currentPosition;
  late final String _userPath;
  GoogleMapController? _mapController;
  Marker? _userMarker;

  @override
  void initState() {
    super.initState();
    _userPath = 'locations/${widget.username}';
    _listenToLocation();
  }

  /// Lắng nghe thay đổi từ Firebase realtime
  void _listenToLocation() {
    _ref.child(_userPath).onValue.listen((event) {
      final data = event.snapshot.value;
      if (data == null) return;

      try {
        final map = Map<String, dynamic>.from(data as Map);
        final lat = map['latitude'];
        final lon = map['longitude'];

        if (lat != null && lon != null) {
          final newPosition = LatLng(lat.toDouble(), lon.toDouble());

          setState(() {
            _currentPosition = newPosition;
            _userMarker = Marker(
              markerId: const MarkerId('user_marker'),
              position: newPosition,
              infoWindow: const InfoWindow(title: 'Vị trí từ Firebase'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            );
          });

          // Di chuyển camera khi có dữ liệu
          if (_mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLng(newPosition),
            );
          }
        }
      } catch (e) {
        debugPrint("Lỗi đọc tọa độ: $e");
      }
    });
  }

  /// Mở Google Maps ngoài app
  Future<void> _openInGoogleMaps() async {
    if (_currentPosition == null) return;

    final lat = _currentPosition!.latitude;
    final lon = _currentPosition!.longitude;
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lon");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở Google Maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Vị trí của ${widget.username}'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Hiển thị bản đồ
                Expanded(
                  child: GoogleMap(
                    onMapCreated: (controller) => _mapController = controller,
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition!,
                      zoom: 16,
                    ),
                    markers: _userMarker != null ? {_userMarker!} : {},
                    myLocationEnabled: false, // ❌ tắt chấm xanh của thiết bị
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                    mapType: MapType.normal,
                  ),
                ),

                // Hiển thị thông tin tọa độ
                Container(
                  padding: const EdgeInsets.all(16),
                  color: colorScheme.primaryContainer,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tọa độ hiện tại:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vĩ độ: ${_currentPosition!.latitude.toStringAsFixed(6)}\n'
                        'Kinh độ: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _openInGoogleMaps,
                          icon: const Icon(Icons.map),
                          label: const Text('Mở trên Google Maps'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
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
