import 'package:geolocator/geolocator.dart';

class CoarseLatLng {
  final double? lat;
  final double? lng;
  const CoarseLatLng(this.lat, this.lng);
}

class LocationService {
  Future<CoarseLatLng> getCoarseLatLng() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return const CoarseLatLng(null, null);
    }
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    );
    return CoarseLatLng(pos.latitude, pos.longitude);
  }
}
