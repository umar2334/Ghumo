import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// Keeps tiles you have already viewed on the device so they still show when
/// you lose signal. This only caches normal browsing: public tile servers
/// prohibit bulk area downloads.
class CachedTileProvider extends TileProvider {
  CachedTileProvider();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return CachedNetworkImageProvider(getTileUrl(coordinates, options), headers: headers);
  }
}
