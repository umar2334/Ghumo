import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart' show TileProvider;
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';
import '../services/nearby_service.dart';
import '../services/routing_service.dart';
import '../services/weather_service.dart';
import 'app_store.dart';

class AppServices {
  AppServices({WeatherService? weather, RoutingService? routing, NearbyService? nearby, LocationService? location, this.tileProvider})
      : weather = weather ?? WeatherService(),
        routing = routing ?? RoutingService(),
        nearby = nearby ?? NearbyService(),
        location = location ?? LocationService();

  final WeatherService weather;
  final RoutingService routing;
  final NearbyService nearby;
  final LocationService location;

  /// Overrides map tile loading, for tests. Null uses the default provider.
  final TileProvider? tileProvider;
}

/// A place the map tab has been asked to show.
class MapTarget {
  const MapTarget(this.position, this.destinationId);
  final LatLng position;
  final String? destinationId;
}

/// Lets any screen switch tabs or open a place on the map.
class AppNavigation {
  final ValueNotifier<int> tab = ValueNotifier(0);
  final ValueNotifier<MapTarget?> mapTarget = ValueNotifier(null);

  static const mapTab = 1;
  static const plannerTab = 2;

  void showOnMap(MapTarget target) {
    mapTarget.value = target;
    tab.value = mapTab;
  }
}

/// Exposes the store and services. Dependents rebuild when the store changes.
class AppScope extends InheritedNotifier<AppStore> {
  const AppScope({
    super.key,
    required AppStore store,
    required this.services,
    required this.navigation,
    required super.child,
  }) : super(notifier: store);

  final AppServices services;
  final AppNavigation navigation;

  static AppScope _of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  static AppStore store(BuildContext context) => _of(context).notifier!;

  /// Store access for event handlers, without subscribing to rebuilds.
  static AppStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppServices servicesOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.services;

  static AppNavigation nav(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.navigation;
}
