import 'dart:async';
import 'package:geolocator/geolocator.dart';

class GpsService {
  StreamSubscription<Position>? _positionStreamSubscription;

  /// Memeriksa dan meminta izin akses lokasi dari pengguna
  Future<bool> checkPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Memulai pendengaran lokasi & kecepatan secara real-time
  void startSpeedStream({
    required Function(double speedKmh, Position position) onData,
    required Function(String error) onError,
  }) {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        // Kecepatan dari geolocator dalam m/s, dikonversi ke km/h
        double speedKmh = position.speed * 3.6;
        if (speedKmh < 0) speedKmh = 0;
        onData(speedKmh, position);
      },
      onError: (e) => onError(e.toString()),
    );
  }

  /// Menghentikan pemantauan GPS
  void stopSpeedStream() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }
}