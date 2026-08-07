import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  StreamSubscription<UserAccelerometerEvent>? _accelSubscription;

  /// Mendeteksi akselerasi/hentakan awal (G-Force) untuk memicu auto-start
  void startAccelStream({
    required double threshold,
    required Function() onLaunchDetected,
  }) {
    _accelSubscription = userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
      // Menghitung besaran vektor akselerasi linier (tanpa gravitasi)
      double gForce = (event.x * event.x + event.y * event.y + event.z * event.z);
      
      // Jika hentakan melebihi ambang batas threshold (misal 3.0 m/s²)
      if (gForce > (threshold * threshold)) {
        onLaunchDetected();
      }
    });
  }

  /// Menghentikan pemantauan sensor
  void stopAccelStream() {
    _accelSubscription?.cancel();
    _accelSubscription = null;
  }
}