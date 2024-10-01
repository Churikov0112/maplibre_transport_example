import 'package:flutter/widgets.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../transport/transport_layer.dart';

part 'map_screen_presenter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapLibreMapController? mapController;
  // LatLngBounds bbox = LatLngBounds(
  //   southwest: const LatLng(59.611179, 29.769598),
  //   northeast: const LatLng(60.437365, 30.957203),
  // );
  // double? zoom = 8.0;

  @override
  Widget build(BuildContext context) {
    return MapScreenPresenter(
      child: Stack(
        children: [
          MapLibreMap(
            styleString: "https://map.91.team/styles/starlight/style.json",
            initialCameraPosition: const CameraPosition(target: LatLng(59.9386, 30.3141), zoom: 16),
            trackCameraPosition: true,
            onMapCreated: (controller) {
              mapController = controller;
              setState(() {});
            },
          ),
          if (mapController != null) TransportLayer(mapController: mapController!),
        ],
      ),
    );
  }
}
