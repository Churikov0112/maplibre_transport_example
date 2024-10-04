part of 'map_screen.dart';

class MapScreenPresenter extends StatefulWidget {
  static MapScreenPresenterState of(BuildContext context) {
    return context.findAncestorStateOfType<MapScreenPresenterState>()!;
  }

  final Widget child;

  const MapScreenPresenter({
    required this.child,
    super.key,
  });

  @override
  State<MapScreenPresenter> createState() => MapScreenPresenterState();
}

class MapScreenPresenterState extends State<MapScreenPresenter> {
  late final BehaviorSubject<LatLngBounds> _bboxSubject = BehaviorSubject();
  Stream<LatLngBounds> get bboxSubject$ => _bboxSubject.stream;

  late final BehaviorSubject<double> _zoomSubject = BehaviorSubject();
  Stream<double> get zoomSubject$ => _zoomSubject.stream;

  void setBbox(LatLngBounds newBbox, double zoom) {
    _bboxSubject.add(newBbox);
    _zoomSubject.add(zoom);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void deactivate() {
    _bboxSubject.close();
    _zoomSubject.close();
    // TODO dispose transport services
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
