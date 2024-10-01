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
  Stream<LatLngBounds> get profileSubject$ => _bboxSubject.stream;

  void setBbox(LatLngBounds newBbox) {
    _bboxSubject.add(newBbox);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
