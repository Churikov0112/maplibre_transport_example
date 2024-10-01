import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:maplibre_transport_example/map/transport/data/transport_animation_service.dart';

import '../ui/map_screen.dart';
import 'data/transport_data_service.dart';
import 'models/models.dart';

const _kTransportGeoJsonSourceId = "transport_geo_json_source_id";
const _kTransportSymbolLayerId = "transport_symbol_layer_id";

class TransportLayer extends StatefulWidget {
  const TransportLayer({
    required this.mapController,
    super.key,
  });

  final MapLibreMapController mapController;

  @override
  State<TransportLayer> createState() => _TransportLayerState();
}

class _TransportLayerState extends State<TransportLayer> {
  late final TransportDataServiceMock _transportDataServiceMock;
  late final TransportAnimationService _transportAnimationService;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      final presenter = MapScreenPresenter.of(context);

      _transportDataServiceMock = TransportDataServiceMock();
      _transportAnimationService = TransportAnimationService(
        transportDataServiceMock: _transportDataServiceMock,
        onAnimationTick: _updateLayer,
      );
      presenter.bboxSubject$.listen((bbox) {
        _transportAnimationService.setBBox(bbox);
      });
      presenter.zoomSubject$.listen((zoom) {
        _transportAnimationService.setZoom(zoom);
      });
      await _addLayer();

      _transportAnimationService.start();
    });
  }

  // TODO вынести в изолят
  Map<String, dynamic> getGeoJsonTransportData(List<VehicleMovement> vehicleMovements) {
    return {
      'type': 'FeatureCollection',
      'features': [
        for (final vm in vehicleMovements) vm.toGeoJsonFeature(),
      ],
    };
  }

  Future<void> _addLayer() async {
    await widget.mapController.addGeoJsonSource(
      _kTransportGeoJsonSourceId,
      <String, dynamic>{
        'type': 'FeatureCollection',
        'features': [],
      },
    );
    await widget.mapController.addSymbolLayer(
      _kTransportGeoJsonSourceId,
      _kTransportSymbolLayerId,
      const SymbolLayerProperties(
        iconImage: "assets/raster/bus_point.png",
      ),
    );
  }

  Future<void> _updateLayer(List<VehicleMovement> vehicles) async {
    await widget.mapController.setGeoJsonSource(
      _kTransportGeoJsonSourceId,
      getGeoJsonTransportData(vehicles),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
