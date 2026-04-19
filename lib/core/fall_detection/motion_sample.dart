import 'dart:math' as math;

class MotionSample {
  const MotionSample({
    required this.x,
    required this.y,
    required this.z,
    required this.capturedAt,
  });

  final double x;
  final double y;
  final double z;
  final DateTime capturedAt;

  double get magnitude => math.sqrt(x * x + y * y + z * z);
}