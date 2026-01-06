// lib/screens/explore_map.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps; // mobile
import 'package:flutter_map/flutter_map.dart' as fmap;                  // web
import 'package:latlong2/latlong.dart' as latlng;

import '../providers_sessions.dart';          // <-- Auth + Firestore providers
import '../models/sleep_session.dart';

class ExploreMapScreen extends ConsumerWidget {
  const ExploreMapScreen({super.key});

  bool get _isMobile =>
      !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

    return auth.when(
      loading: () => const SafeArea(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => SafeArea(child: Center(child: Text('Auth error: $e'))),
      data: (user) {
        if (user == null) {
          return const SafeArea(
            child: Center(child: Text('Please sign in to view the map.')),
          );
        }

        // 🔑 Read sessions from Firestore (same UI as before)
        final sessionsAsync = ref.watch(sessionsStreamProviderFamily(user.uid));

        return sessionsAsync.when(
          loading: () => const SafeArea(child: Center(child: CircularProgressIndicator())),
          error: (e, _) => SafeArea(child: Center(child: Text('Error: $e'))),
          data: (List<SleepSession> sessions) {
            final withCoords =
            sessions.where((s) => s.lat != null && s.lng != null).toList();

            Widget body;
            if (withCoords.isEmpty) {
              body = const Center(
                child: Text('No markers yet. Log a session with location enabled.'),
              );
            } else if (_isMobile) {
              // Android/iOS: Google Maps
              final gMarkers = withCoords
                  .map((s) => gmaps.Marker(
                markerId: gmaps.MarkerId(s.id),
                position: gmaps.LatLng(s.lat!, s.lng!),
                infoWindow: gmaps.InfoWindow(
                  title: 'Sleep ${s.durationHours.toStringAsFixed(1)}h',
                ),
              ))
                  .toSet();

              final first = withCoords.first;
              body = gmaps.GoogleMap(
                initialCameraPosition: gmaps.CameraPosition(
                  target: gmaps.LatLng(first.lat!, first.lng!),
                  zoom: 11,
                ),
                markers: gMarkers,
              );
            } else {
              // Web: OpenStreetMap (no API key)
              final first = withCoords.first;
              final markers = withCoords
                  .map((s) => fmap.Marker(
                point: latlng.LatLng(s.lat!, s.lng!),
                width: 42,
                height: 42,
                child: Tooltip(
                  message:
                  'Sleep ${s.durationHours.toStringAsFixed(1)}h',
                  child: const Icon(Icons.location_on, size: 36),
                ),
              ))
                  .toList();

              body = fmap.FlutterMap(
                options: fmap.MapOptions(
                  initialCenter: latlng.LatLng(first.lat!, first.lng!),
                  initialZoom: 11,
                ),
                children: [
                  fmap.TileLayer(
                    urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.dreamshield',
                  ),
                ]..add(fmap.MarkerLayer(markers: markers)),
              );
            }

            return SafeArea(
              child: Column(
                children: [
                  const ListTile(
                    title: Text('Sleep Spots Map'),
                    subtitle:
                    Text('Markers appear for sessions saved with location'),
                  ),
                  Expanded(child: body),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
