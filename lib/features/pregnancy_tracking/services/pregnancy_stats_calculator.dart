class GestationalAge {
  final int weeks;
  final int days;

  GestationalAge({required this.weeks, required this.days});

  @override
  String toString() => '$weeks weeks, $days days';
}

class PregnancyStatsCalculator {
  /// Calculates the Estimated Due Date (EDD) using Naegele's Rule.
  /// LMP + 9 months + 7 days, adjusted for average cycle length.
  DateTime calculateEDD(DateTime lmp, int averageCycleLength) {
    // Basic Naegele's Rule: LMP + 280 days (40 weeks)
    // Adjusted for cycle length: 280 + (cycleLength - 28)
    final totalDays = 280 + (averageCycleLength - 28);
    return lmp.add(Duration(days: totalDays));
  }

  /// Calculates the current gestational age based on LMP.
  GestationalAge calculateGestationalAge(DateTime lmp, {DateTime? today}) {
    final now = today ?? DateTime.now();
    final difference = now.difference(lmp).inDays;

    final weeks = difference ~/ 7;
    final days = difference % 7;

    return GestationalAge(weeks: weeks, days: days);
  }

  /// Calculates the progress percentage (0.0 to 1.0).
  double calculateProgressPercentage(
    DateTime lmp,
    DateTime edd, {
    DateTime? today,
  }) {
    final now = today ?? DateTime.now();
    final totalDuration = edd.difference(lmp).inDays;
    final elapsed = now.difference(lmp).inDays;

    if (totalDuration == 0) return 0.0;

    final progress = elapsed / totalDuration;
    return progress.clamp(0.0, 1.0);
  }

  /// Calculates days remaining until EDD.
  int calculateDaysRemaining(DateTime edd, {DateTime? today}) {
    final now = today ?? DateTime.now();
    final difference = edd.difference(now).inDays;
    return difference > 0 ? difference : 0;
  }
}
