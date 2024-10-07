import 'package:flutter/widgets.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:rxdart/subjects.dart';

import '../transport/transport_layer.dart';

part 'map_screen_presenter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  Widget build(BuildContext context) {
    return MapScreenPresenter(
      child: Builder(builder: (context) {
        final presenter = MapScreenPresenter.of(context);

        return Stack(
          children: [
            MapLibreMap(
              styleString: "https://map.91.team/styles/starlight/style.json",
              initialCameraPosition: const CameraPosition(target: LatLng(59.936521, 30.500014), zoom: 16),
              trackCameraPosition: true,
              onCameraIdle: () async {
                final bbox = await presenter.mapController?.getVisibleRegion();
                final zoom = presenter.mapController?.cameraPosition?.zoom;
                if (bbox != null && zoom != null) {
                  presenter.setBbox(bbox, zoom);
                }
              },
              onMapCreated: (controller) {
                presenter.mapController = controller;
                setState(() {});
              },
            ),
            if (presenter.mapController != null) TransportLayer(mapController: presenter.mapController!),
          ],
        );
      }),
    );
  }
}
