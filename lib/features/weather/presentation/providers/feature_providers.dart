import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/radar_remote_datasource.dart';
import '../../domain/entities/flood_info.dart';
import 'di_providers.dart';

/// River-discharge outlook. Invalidated by the weather controller on refresh.
final floodProvider = FutureProvider<FloodInfo?>(
    (ref) => ref.watch(getFloodProvider).call());

/// RainViewer radar manifest for the radar map.
final radarProvider = FutureProvider<RadarManifest?>(
    (ref) => ref.watch(radarRemoteProvider).fetch());
