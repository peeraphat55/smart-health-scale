class BmiRecord {
  final String? key;
  final DateTime timestamp;
  final double weight;
  final double height;
  final int heartRate;
  final double bmi;
  final String status;

  BmiRecord({
    this.key,
    required this.timestamp,
    required this.weight,
    required this.height,
    required this.heartRate,
    required this.bmi,
    required this.status,
  });
}