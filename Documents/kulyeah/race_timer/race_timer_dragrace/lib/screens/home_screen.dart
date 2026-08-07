import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../services/gps_service.dart';
import '../services/sensor_service.dart';
import '../services/db_helper.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GpsService _gpsService = GpsService();
  final SensorService _sensorService = SensorService();
  final DbHelper _dbHelper = DbHelper();

  double _currentSpeed = 0.0;
  double _maxSpeed = 0.0;
  double _totalDistance = 0.0;
  double _gpsAccuracy = 0.0;
  Position? _previousPosition;

  bool _isGpsReady = false;
  bool _isTimerRunning = false;
  bool _autoStartMode = true;

  // Controller Jarak 3 Checkpoint
  final double _cp1Dist = 100.0; // Tetap 100m
  final TextEditingController _cp2Controller = TextEditingController(text: '201');
  final TextEditingController _cp3Controller = TextEditingController(text: '402');

  // Status Capaian Checkpoint (Time & Speed)
  double? _cp1Time, _cp1Speed;
  double? _cp2Time, _cp2Speed;
  double? _cp3Time, _cp3Speed;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _uiTimer;
  String _elapsedTime = '0.00 s';

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    bool hasPermission = await _gpsService.checkPermission();
    if (hasPermission) {
      setState(() => _isGpsReady = true);
      _startGpsTracker();
      _startSensorTracker();
    }
  }

  void _startGpsTracker() {
    _gpsService.startSpeedStream(
      onData: (double speed, Position pos) {
        setState(() {
          _currentSpeed = speed;
          _gpsAccuracy = pos.accuracy;
          if (_isTimerRunning && speed > _maxSpeed) {
            _maxSpeed = speed;
          }
        });

        if (_isTimerRunning) {
          if (_previousPosition != null) {
            double dist = Geolocator.distanceBetween(
              _previousPosition!.latitude,
              _previousPosition!.longitude,
              pos.latitude,
              pos.longitude,
            );
            _totalDistance += dist;
          }
          _previousPosition = pos;

          double currentTime = _stopwatch.elapsedMilliseconds / 1000.0;
          double cp2Target = double.tryParse(_cp2Controller.text) ?? 201.0;
          double cp3Target = double.tryParse(_cp3Controller.text) ?? 402.0;

          // Cek Checkpoint 1 (100m)
          if (_cp1Time == null && _totalDistance >= _cp1Dist) {
            setState(() {
              _cp1Time = currentTime;
              _cp1Speed = speed;
            });
          }

          // Cek Checkpoint 2 (Kustom)
          if (_cp2Time == null && _totalDistance >= cp2Target) {
            setState(() {
              _cp2Time = currentTime;
              _cp2Speed = speed;
            });
          }

          // Cek Checkpoint 3 (Kustom - Finish Line)
          if (_cp3Time == null && _totalDistance >= cp3Target) {
            setState(() {
              _cp3Time = currentTime;
              _cp3Speed = speed;
            });
            _finishRun();
          }
        }
      },
      onError: (err) => debugPrint('GPS Error: $err'),
    );
  }

  void _startSensorTracker() {
    _sensorService.startAccelStream(
      threshold: 3.0,
      onLaunchDetected: () {
        if (_autoStartMode && !_isTimerRunning && _currentSpeed < 5) {
          _startTimer();
        }
      },
    );
  }

  void _startTimer() {
    _stopwatch.reset();
    _stopwatch.start();
    _totalDistance = 0.0;
    _maxSpeed = 0.0;
    _previousPosition = null;

    // Reset data checkpoint
    setState(() {
      _cp1Time = _cp1Speed = null;
      _cp2Time = _cp2Speed = null;
      _cp3Time = _cp3Speed = null;
      _isTimerRunning = true;
      _elapsedTime = '0.00 s';
    });

    _uiTimer?.cancel();
    _uiTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (mounted && _isTimerRunning) {
        setState(() {
          _elapsedTime = (_stopwatch.elapsedMilliseconds / 1000.0).toStringAsFixed(2) + ' s';
        });
      }
    });
  }

  void _finishRun() async {
    _stopwatch.stop();
    _uiTimer?.cancel();

    double finalTime = _stopwatch.elapsedMilliseconds / 1000.0;
    double cp2Target = double.tryParse(_cp2Controller.text) ?? 201.0;
    double cp3Target = double.tryParse(_cp3Controller.text) ?? 402.0;

    setState(() {
      _isTimerRunning = false;
      _elapsedTime = finalTime.toStringAsFixed(2) + ' s';
    });

    // Simpan Rekor ke SQLite
    await _dbHelper.insertRecord({
      'category': '3-Stage Drag Race',
      'time_seconds': finalTime,
      'top_speed': _maxSpeed,
      'date_created': DateTime.now().toString().substring(0, 16),
      'cp1_dist': _cp1Dist,
      'cp1_time': _cp1Time ?? 0.0,
      'cp1_speed': _cp1Speed ?? 0.0,
      'cp2_dist': cp2Target,
      'cp2_time': _cp2Time ?? 0.0,
      'cp2_speed': _cp2Speed ?? 0.0,
      'cp3_dist': cp3Target,
      'cp3_time': _cp3Time ?? finalTime,
      'cp3_speed': _cp3Speed ?? _maxSpeed,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Uji Coba Selesai! Waktu Akhir: $_elapsedTime')),
      );
    }
  }

  Color _getAccuracyColor() {
    if (!_isGpsReady) return Colors.red;
    if (_gpsAccuracy <= 5.0) return Colors.greenAccent;
    if (_gpsAccuracy <= 15.0) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _cp2Controller.dispose();
    _cp3Controller.dispose();
    _gpsService.stopSpeedStream();
    _sensorService.stopAccelStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double cp2Target = double.tryParse(_cp2Controller.text) ?? 201.0;
    double cp3Target = double.tryParse(_cp3Controller.text) ?? 402.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('RACE TIMER DRAG RACE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.grey[900],
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.cyanAccent),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Status GPS
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _getAccuracyColor().withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.satellite_alt, color: _getAccuracyColor(), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _isGpsReady ? 'GPS: ±${_gpsAccuracy.toStringAsFixed(1)}m' : 'Searching GPS...',
                    style: TextStyle(color: _getAccuracyColor(), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // Form Pengaturan Jarak 3 Checkpoint
            Row(
              children: [
                // CP 1 (Fixed 100m)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: const [
                        Text('CP 1', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        SizedBox(height: 4),
                        Text('100 m', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // CP 2 (Input User)
                Expanded(
                  child: TextField(
                    controller: _cp2Controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'CP 2 (m)',
                      labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                      filled: true,
                      fillColor: Colors.grey[900],
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (val) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                // CP 3 (Input User)
                Expanded(
                  child: TextField(
                    controller: _cp3Controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'CP 3 (m)',
                      labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                      filled: true,
                      fillColor: Colors.grey[900],
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (val) => setState(() {}),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Speedometer Display
            Text(_currentSpeed.toStringAsFixed(0), style: const TextStyle(color: Colors.cyanAccent, fontSize: 80, fontWeight: FontWeight.bold)),
            const Text('KM/H', style: TextStyle(color: Colors.white70, fontSize: 18)),

            const SizedBox(height: 15),

            // Live Timer Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.cyanAccent),
              ),
              child: Text(_elapsedTime, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 20),

            // Live Table Telemetri 3 Checkpoint
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('HASIL TELEMETRI CHECKPOINT', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  const Divider(color: Colors.white24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCpTile('100m', _cp1Time, _cp1Speed),
                      _buildCpTile('${cp2Target.toInt()}m', _cp2Time, _cp2Speed),
                      _buildCpTile('${cp3Target.toInt()}m', _cp3Time, _cp3Speed),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isTimerRunning ? _finishRun : _startTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTimerRunning ? Colors.red : Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(_isTimerRunning ? 'STOP' : 'START MANUAL', style: const TextStyle(fontSize: 16, color: Colors.white)),
                ),
                Row(
                  children: [
                    const Text('Auto-Start', style: TextStyle(color: Colors.white)),
                    Switch(
                      value: _autoStartMode,
                      activeColor: Colors.cyanAccent,
                      onChanged: (val) => setState(() => _autoStartMode = val),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCpTile(String label, double? time, double? speed) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(time != null ? '${time.toStringAsFixed(2)}s' : '-.-- s', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(speed != null ? '${speed.toStringAsFixed(1)} km/h' : '-.- km/h', style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
      ],
    );
  }
}