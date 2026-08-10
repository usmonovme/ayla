import '../../auth/models/user_model.dart';
import '../../../core/constants/app_constants.dart';
import 'dart:math';

/// Calculates the recommended weight gain based on ACOG guidelines.
class WeightGainCalculator {
  /// BMI Categories according to WHO and ACOG.
  static const double _bmiUnderweightMax = 18.5;
  static const double _bmiNormalMax = 25.0;
  static const double _bmiOverweightMax = 30.0;

  /// Recommended weekly weight gain (in kg) during 2nd and 3rd trimesters.
  /// Format: [min, max]
  static const Map<String, List<double>> _weeklyGainKg = {
    'underweight': [0.44, 0.58],
    'normal': [0.35, 0.50],
    'overweight': [0.23, 0.33],
    'obese': [0.17, 0.27],
  };

  /// First trimester assumed total gain is typically 0.5 to 2.0 kg.
  static const double _firstTrimesterGainMinKg = 0.5;
  static const double _firstTrimesterGainMaxKg = 2.0;

  /// Calculate exact BMI based on user preference units.
  static double? calculateBMI({
    required double? initialWeight,
    required double? height,
    required UserPreferences preferences,
  }) {
    if (initialWeight == null || height == null || height <= 0) return null;

    final weightKg = preferences.weightUnit == WeightUnit.lbs
        ? initialWeight * 0.453592
        : initialWeight;
    final heightCm = preferences.lengthUnit == LengthUnit.inch
        ? height * 2.54
        : height;

    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  /// Get BMI Category name based on BMI value.
  static String _getBMICategory(double? bmi) {
    if (bmi == null) return 'normal'; // Default fallback assumption
    if (bmi < _bmiUnderweightMax) return 'underweight';
    if (bmi < _bmiNormalMax) return 'normal';
    if (bmi < _bmiOverweightMax) return 'overweight';
    return 'obese';
  }

  /// Get the recommended minimum and maximum weight gain at a specific gestational day.
  /// Returns values in the user's preferred unit (kg or lbs).
  /// Format: [minWeightGain, maxWeightGain]
  static List<double> getRecommendedWeightGainRange({
    required int gestationalDays,
    required double? initialWeight,
    required double? height,
    required UserPreferences preferences,
  }) {
    final bmi = calculateBMI(
      initialWeight: initialWeight,
      height: height,
      preferences: preferences,
    );
    final category = _getBMICategory(bmi);

    final weeks = (gestationalDays / 7).floor();

    double minGainKg = 0.0;
    double maxGainKg = 0.0;

    if (weeks <= 13) {
      // Linear scaling over first 13 weeks up to the 1st trimester gain goal
      final progress = min(weeks / 13.0, 1.0);
      minGainKg = _firstTrimesterGainMinKg * progress;
      maxGainKg = _firstTrimesterGainMaxKg * progress;
    } else {
      // 1st trimester base gain plus weekly rate for subsequent weeks
      minGainKg = _firstTrimesterGainMinKg;
      maxGainKg = _firstTrimesterGainMaxKg;

      final excessWeeks = min(
        weeks - 13,
        29,
      ); // Assuming normal pregnancy up to 42w
      final weeklyMin = _weeklyGainKg[category]![0];
      final weeklyMax = _weeklyGainKg[category]![1];

      minGainKg += (excessWeeks * weeklyMin);
      maxGainKg += (excessWeeks * weeklyMax);
    }

    // Convert kg to user's unit
    final conversionFactor = preferences.weightUnit == WeightUnit.lbs
        ? 2.20462
        : 1.0;

    return [minGainKg * conversionFactor, maxGainKg * conversionFactor];
  }

  /// Helper to get a simple status text based on current gain vs recommended gain bounds.
  static String getStatusLabel(
    double currentGain,
    List<double> recommendedRange,
  ) {
    final minGain = recommendedRange[0];
    final maxGain = recommendedRange[1];

    if (currentGain < minGain) return 'under';
    if (currentGain > maxGain) return 'over';
    return 'on_track';
  }
}
