import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Location _location;
  LocationData? _locationData;
  late Stream<LocationData> _locationStream;

  @override
  void initState() {
    _location = Location();
    super.initState();
  }

  Future<void> _getLocation() async {
    try {
      _locationData = await _location.getLocation();
      setState(() => _locationData = _locationData);
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Device Altitude')),
        body: Center(
          child: StreamBuilder<LocationData>(
              stream: _location.onLocationChanged,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Error');
                } else if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                debugPrint('${snapshot.data}');
                return Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      LocationDataWidget(title: 'Altitude', value: '${snapshot.data!.altitude ?? "Loading..."}'),
                      LocationDataWidget(title: 'Longitude', value: '${snapshot.data!.longitude ?? "Loading..."}'),
                      LocationDataWidget(title: 'Latitude', value: '${snapshot.data!.latitude ?? "Loading..."}'),
                      LocationDataWidget(title: 'Speed', value: '${snapshot.data!.speed ?? "Loading..."}'),
                      LocationDataWidget(title: 'Accuracy', value: '${snapshot.data!.accuracy ?? "Loading..."}'),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const MapScreen()),
                          ),
                          child: const Text('map'),
                        ),
                      ),
                    ],
                  ),
                );
              }),
        ),
      ),
    );
  }
}

class LocationDataWidget extends StatelessWidget {
  const LocationDataWidget({
    super.key,
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontSize: 20)),
      ],
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late Location _location;
  LocationData? _locationData;
  late Stream<LocationData> _locationStream;

  Future<LatLng> _getCurrentLocation() async {
    try {
      _locationData = await _location.getLocation();
      return LatLng(_locationData!.latitude!, _locationData!.longitude!);
    } catch (e) {
      print('Error: $e');
      return const LatLng(0, 0);
    }
  }

  @override
  void initState() {
    _location = Location();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          StreamBuilder<LocationData>(
            stream: _location.onLocationChanged,
            builder: (context, location) {
              if (location.hasError) {
                return const Text('Error');
              } else if (location.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final lat = location.data!.latitude ?? 0;
              final lng = location.data!.longitude ?? 0;
              final latLng = LatLng(lat, lng);
              final altitude = location.data!.altitude!.toStringAsFixed(2);
              final String title =
                  'Altitude: $altitude, Longitude: ${lat.toStringAsFixed(2)}, Latitude: ${lng.toStringAsFixed(2)}';
              return GoogleMap(
                initialCameraPosition: CameraPosition(target: latLng, zoom: 18),
                markers: {
                  Marker(
                    markerId: const MarkerId('currentLocation'),
                    position: latLng,
                    infoWindow: InfoWindow(title: title),
                  ),
                },
                circles: {
                  Circle(
                    circleId: const CircleId('currentLocation'),
                    center: const LatLng(31.0301867, 31.3614759),
                    radius: 50,
                    strokeWidth: 1,
                    fillColor: Colors.blue.withOpacity(0.2),
                    strokeColor: Colors.blue.withOpacity(0.9),
                  ),
                },
              );
            },
          ),
          // leading back button
          Positioned(
            top: 40,
            left: 20,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: const BackButton(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
