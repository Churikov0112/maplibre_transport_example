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
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
