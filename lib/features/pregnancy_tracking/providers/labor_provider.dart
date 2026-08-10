import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/data/repositories/contraction_repository.dart';
import '../../../core/data/repositories/pregnancy_repository.dart';
import '../../../services/notification_service.dart';
import '../models/contraction_model.dart';
import '../../../core/services/analytics_service.dart';

class LaborProvider extends ChangeNotifier {
  final ContractionRepository _repository;
  final PregnancyRepository _pregnancyRepository;

  LaborProvider(this._repository, this._pregnancyRepository);

  List<ContractionEntry> _contractions = [];
  ContractionEntry? _activeContraction;
  bool _isLoading = false;
  String? _pregnancyId;
  String? _userId;

  List<ContractionEntry> get contractions => _contractions;
  ContractionEntry? get activeContraction => _activeContraction;
  bool get isLoading => _isLoading;
  bool get isActive => _activeContraction != null;

  Timer? _hapticTimer;

  Future<void> initialize(
    String userId, [
    String? pregnancyId,
    AppLocalizations? l10n,
  ]) async {
    _userId = userId;
    _isLoading = true;
    notifyListeners();

    try {
      if (pregnancyId == null) {
        final activePregnancy = await _pregnancyRepository.getPregnancy(userId);
        if (activePregnancy != null) {
          _pregnancyId = activePregnancy.id;
        }
      } else {
        _pregnancyId = pregnancyId;
      }

      if (_pregnancyId != null) {
        _contractions = await _repository.getContractions(_pregnancyId!);
        // Check if there's an ongoing contraction (one with no endTime)
        final last = await _repository.getLastContraction(_pregnancyId!);
        if (last != null && last.endTime == null) {
          _activeContraction = last;
          _startHaptics();
          if (l10n != null) {
            // Always ensure permissions are granted before showing the
            // recovered-contraction notification (covers the iOS case where
            // the user may not have been prompted yet, or the first run after
            // a fresh install where permissions haven't been requested).
            await NotificationService().requestPermissions();
            await NotificationService().showContractionTimerNotification(
              title: l10n.contraction_timer_title,
              subtitle: l10n.contraction_timer_subtitle,
              ongoingText: l10n.common_ongoing,
              startTime: last.startTime,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error initializing LaborProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startContraction([AppLocalizations? l10n]) async {
    if (_userId == null || _pregnancyId == null) return;
    if (_activeContraction != null) return;

    _activeContraction = ContractionEntry(
      userId: _userId!,
      pregnancyId: _pregnancyId!,
      startTime: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _startHaptics();
    if (l10n != null) {
      // Ensure notification permissions are granted before showing
      await NotificationService().requestPermissions();
      await NotificationService().showContractionTimerNotification(
        title: l10n.contraction_timer_title,
        subtitle: l10n.contraction_timer_subtitle,
        ongoingText: l10n.common_ongoing,
        startTime: _activeContraction!.startTime,
      );
    }
    notifyListeners();

    try {
      final pending = _activeContraction;
      if (pending != null) {
        await _repository.saveContraction(pending);
      }

      final synced = await _repository.getLastContraction(_pregnancyId!);
      if (synced != null && synced.endTime == null) {
        _activeContraction = synced;
      }
      _contractions = await _repository.getContractions(_pregnancyId!);
      notifyListeners();
    } catch (e) {
      debugPrint('Error starting contraction: $e');
    }
  }

  Future<void> cancelContraction() async {
    if (_activeContraction == null) return;
    await NotificationService().cancelContractionTimerNotification();

    try {
      if (_activeContraction!.id != null) {
        await _repository.deleteContraction(_activeContraction!.id!);
      } else {
        // Find the last contraction which might be the active one
        final last = await _repository.getLastContraction(_pregnancyId!);
        if (last != null && last.endTime == null && last.id != null) {
          await _repository.deleteContraction(last.id!);
        }
      }
      _activeContraction = null;
      _stopHaptics();
      _contractions = await _repository.getContractions(_pregnancyId!);
      notifyListeners();
    } catch (e) {
      debugPrint('Error canceling contraction: $e');
    }
  }

  Future<void> stopAndSaveContraction({
    ContractionIntensity? intensity,
    String? note,
  }) async {
    if (_activeContraction == null) return;
    await NotificationService().cancelContractionTimerNotification();

    final completed = _activeContraction!.copyWith(
      endTime: DateTime.now(),
      intensity: intensity,
      note: note,
      updatedAt: DateTime.now(),
    );

    try {
      await _repository.saveContraction(completed);
      _activeContraction = null;
      _stopHaptics();
      _contractions = await _repository.getContractions(_pregnancyId!);
      unawaited(AnalyticsService.instance.logContractionSession());
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving contraction: $e');
    }
  }

  Future<void> updateLastContractionIntensity(
    ContractionIntensity intensity,
  ) async {
    if (_contractions.isEmpty) return;

    final last = _contractions.first;
    final updated = last.copyWith(
      intensity: intensity,
      updatedAt: DateTime.now(),
    );

    try {
      await _repository.saveContraction(updated);
      _contractions = await _repository.getContractions(_pregnancyId!);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating intensity: $e');
    }
  }

  Future<void> deleteContraction(int id) async {
    try {
      await _repository.deleteContraction(id);
      _contractions = await _repository.getContractions(_pregnancyId!);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting contraction: $e');
    }
  }

  /// Resets in-memory contraction state without touching the DB.
  /// Used when a pregnancy is completed (baby born) — the contraction
  /// data stays in the database so it appears in pregnancy history.
  void resetState() {
    _contractions = [];
    _activeContraction = null;
    _pregnancyId = null;
    _stopHaptics();
    NotificationService().cancelContractionTimerNotification();
    notifyListeners();
  }

  /// Deletes all contraction data from the DB for a pregnancy AND resets
  /// in-memory state. Used when a pregnancy is fully removed (not archived).
  Future<void> deletePregnancyContractions(String pregnancyId) async {
    try {
      await _repository.deleteContractionsByPregnancy(pregnancyId);
      if (_pregnancyId == pregnancyId) {
        resetState();
      }
    } catch (e) {
      debugPrint('Error deleting contractions: $e');
    }
  }

  void _startHaptics() {
    _hapticTimer?.cancel();
    // Pulsing haptics every 2 seconds during active contraction
    _hapticTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      HapticFeedback.mediumImpact();
    });
  }

  void _stopHaptics() {
    _hapticTimer?.cancel();
    _hapticTimer = null;
  }

  @override
  void dispose() {
    _stopHaptics();
    super.dispose();
  }

  // 5-1-1 Rule Calculation
  bool get meets511Rule {
    if (_contractions.length < 3) return false;

    // Filter contractions from the last hour
    final now = DateTime.now();
    final lastHourContractions = _contractions
        .where(
          (c) => c.startTime.isAfter(now.subtract(const Duration(hours: 1))),
        )
        .toList();

    if (lastHourContractions.length < 3) return false;

    // Check average duration (must be >= 1 minute)
    final avgDuration =
        lastHourContractions
            .map((c) => c.duration.inSeconds)
            .reduce((a, b) => a + b) /
        lastHourContractions.length;

    if (avgDuration < 60) return false;

    // Check average frequency (start to start)
    final firstInHour = lastHourContractions.last;
    final lastInHour = lastHourContractions.first;

    final totalTimeSpan = lastInHour.startTime.difference(
      firstInHour.startTime,
    );
    final avgFrequency =
        totalTimeSpan.inMinutes / (lastHourContractions.length - 1);

    if (avgFrequency > 5) return false;

    if (totalTimeSpan.inMinutes < 45) return false;

    return true;
  }

  String laborStatus(AppLocalizations l10n) {
    if (meets511Rule) return l10n.contraction_timer_active_labor;
    if (_contractions.isEmpty) return l10n.contraction_timer_wait;
    return l10n.contraction_timer_early_labor;
  }
}
