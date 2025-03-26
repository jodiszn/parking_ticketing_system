import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'entry.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          isFromDate ? _fromDate ?? DateTime.now() : _toDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          // Reset toDate if it's before new fromDate
          if (_toDate != null && _toDate!.isBefore(picked)) {
            _toDate = null;
          }
        } else {
          _toDate = picked;
        }
      });
    }
  }

  Map<String, dynamic> _calculateSales(List<Entry> entries) {
    if (_fromDate == null || _toDate == null) {
      return {
        'motorcycle': {'count': 0, 'total': 0.0},
        'car': {'count': 0, 'total': 0.0},
        'overall': {'count': 0, 'total': 0.0},
      };
    }

    final filtered =
        entries.where((entry) {
          return entry.exitTime != null &&
              entry.exitTime!.isAfter(
                _fromDate!.subtract(const Duration(days: 1)),
              ) &&
              entry.exitTime!.isBefore(_toDate!.add(const Duration(days: 1)));
        }).toList();

    final motorcycles = filtered.where((e) => e.vehicleType == 'Motorcycle');
    final cars = filtered.where((e) => e.vehicleType == 'Car');

    return {
      'motorcycle': {
        'count': motorcycles.length,
        'total': motorcycles.fold(0.0, (sum, e) => sum + e.calculateFee()),
      },
      'car': {
        'count': cars.length,
        'total': cars.fold(0.0, (sum, e) => sum + e.calculateFee()),
      },
      'overall': {
        'count': filtered.length,
        'total':
            motorcycles.fold(0.0, (sum, e) => sum + e.calculateFee()) +
            cars.fold(0.0, (sum, e) => sum + e.calculateFee()),
      },
    };
  }

  Widget _buildDateSelector(String label, DateTime? date, bool isFromDate) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _selectDate(context, isFromDate),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.white70),
                  const SizedBox(width: 8),
                  Text(
                    date == null
                        ? 'Select Date'
                        : DateFormat('yyyy-MM-dd').format(date),
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(String type, int count, double total) {
    final isMotorcycle = type == 'Motorcycle';
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isMotorcycle ? Colors.orange[100] : Colors.blue[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            isMotorcycle ? Icons.motorcycle : Icons.directions_car,
            color: isMotorcycle ? Colors.orange[800] : Colors.blue[800],
          ),
        ),
        title: Text(
          type,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isMotorcycle ? Colors.orange[800] : Colors.blue[800],
          ),
        ),
        subtitle: Text('$count ${count == 1 ? 'vehicle' : 'vehicles'} exited'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const Text(
              'pesos',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(double total, int motorcycleCount, int carCount) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'TOTAL SALES',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${total.toStringAsFixed(2)} pesos',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Icon(
                      Icons.motorcycle,
                      color: Colors.orange,
                      size: 30,
                    ),
                    Text('$motorcycleCount'),
                  ],
                ),
                Column(
                  children: [
                    const Icon(
                      Icons.directions_car,
                      color: Colors.blue,
                      size: 30,
                    ),
                    Text('$carCount'),
                  ],
                ),
                Column(
                  children: [
                    const Icon(Icons.list_alt, color: Colors.green, size: 30),
                    Text('${motorcycleCount + carCount}'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildDateSelector('From', _fromDate, true),
                    const SizedBox(width: 16),
                    _buildDateSelector('To', _toDate, false),
                  ],
                ),
              ),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: Hive.box<Entry>('entriesBox').listenable(),
                  builder: (context, Box<Entry> box, _) {
                    final salesData = _calculateSales(box.values.toList());

                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          if (_fromDate != null && _toDate != null) ...[
                            _buildTotalCard(
                              salesData['overall']['total'],
                              salesData['motorcycle']['count'],
                              salesData['car']['count'],
                            ),
                            _buildVehicleCard(
                              'Motorcycle',
                              salesData['motorcycle']['count'],
                              salesData['motorcycle']['total'],
                            ),
                            _buildVehicleCard(
                              'Car',
                              salesData['car']['count'],
                              salesData['car']['total'],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Showing sales from ${DateFormat('MMM d, y').format(_fromDate!)} '
                                'to ${DateFormat('MMM d, y').format(_toDate!)}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          ] else
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.only(top: 100),
                                child: Text(
                                  'Please select date range',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
