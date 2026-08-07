import 'package:flutter/material.dart';
import '../services/db_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DbHelper _dbHelper = DbHelper();
  List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final data = await _dbHelper.getRecords();
    setState(() {
      _records = data;
    });
  }

  Future<void> _deleteRecord(int id, int index) async {
    final deletedItem = _records[index];
    await _dbHelper.deleteRecord(id);
    setState(() {
      _records.removeAt(index);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Catatan ${deletedItem['category']} dihapus'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _clearAllRecords() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Hapus Semua Riwayat?', style: TextStyle(color: Colors.white)),
        content: const Text('Tindakan ini tidak dapat dibatalkan.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('BATAL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('HAPUS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteAllRecords();
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('RIWAYAT CATATAN WAKTU', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.grey[900],
        actions: [
          if (_records.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
              onPressed: _clearAllRecords,
              tooltip: 'Hapus Semua',
            ),
        ],
      ),
      body: _records.isEmpty
          ? const Center(child: Text('Belum ada catatan waktu', style: TextStyle(color: Colors.white54, fontSize: 16)))
          : ListView.builder(
              itemCount: _records.length,
              itemBuilder: (context, index) {
                final item = _records[index];
                final int id = item['id'];

                return Dismissible(
                  key: Key(id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white, size: 28),
                  ),
                  onDismissed: (direction) {
                    _deleteRecord(id, index);
                  },
                  child: Card(
                    color: Colors.grey[900],
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${item['category']}',
                                style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                item['date_created'] ?? '',
                                style: const TextStyle(color: Colors.white38, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Waktu Akhir: ${item['time_seconds'].toStringAsFixed(2)}s | Max Speed: ${item['top_speed'].toStringAsFixed(1)} KM/H',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const Divider(color: Colors.white24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildCpHistoryTile('${item['cp1_dist']?.toInt() ?? 100}m', item['cp1_time'], item['cp1_speed']),
                              _buildCpHistoryTile('${item['cp2_dist']?.toInt() ?? 201}m', item['cp2_time'], item['cp2_speed']),
                              _buildCpHistoryTile('${item['cp3_dist']?.toInt() ?? 402}m', item['cp3_time'], item['cp3_speed']),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildCpHistoryTile(String label, dynamic time, dynamic speed) {
    double t = (time ?? 0.0).toDouble();
    double s = (speed ?? 0.0).toDouble();
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text('${t.toStringAsFixed(2)}s', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        Text('${s.toStringAsFixed(1)} km/h', style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
      ],
    );
  }
}