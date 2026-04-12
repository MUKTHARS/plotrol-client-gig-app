import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:plotrol/globalWidgets/flutter_toast.dart';

class LocationMap extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final void Function()? refreshLocation;

  const LocationMap({
    Key? key,
    required this.initialLatitude,
    required this.initialLongitude,
    this.refreshLocation,
  }) : super(key: key);

  @override
  _LocationMapState createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  late MapController _mapController;
  late double _latitude;
  late double _longitude;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      _mapController.move(LatLng(_latitude, _longitude), 14.0);
      if (widget.refreshLocation != null) {
        widget.refreshLocation!();
      } // Call the provided callback function
    } catch (e) {
      Toast.showToast(
        "Failed to get current location: $e",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map View')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              maxZoom: 45,
              minZoom: 10,
              initialCenter: LatLng(_latitude, _longitude),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.plotrol',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(_latitude, _longitude),
                    child: const Icon(
                      Icons.location_pin,
                      size: 40,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Latitude/Longitude Display
          Positioned(
            bottom: widget.refreshLocation != null ? 80 : 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                'Lat: ${_latitude.toStringAsFixed(5)}\nLong: ${_longitude.toStringAsFixed(5)}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          // Floating Action Button
          if (widget.refreshLocation != null)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: _getCurrentLocation,
                child: const Icon(Icons.my_location),
              ),
            ),
        ],
      ),
    );
  }
}
