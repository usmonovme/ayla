import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/data/repositories/pregnancy_repository.dart';
import '../../../core/data/repositories/weight_repository.dart';
import '../../../core/data/repositories/appointment_repository.dart';
import '../../../core/data/repositories/kick_repository.dart';
import '../../../core/data/repositories/symptom_repository.dart';
import '../services/checklist_repository.dart';
import '../models/pregnancy_model.dart';
import '../models/weight_entry_model.dart';
import '../models/appointment_model.dart';
import '../models/kick_session_model.dart';
import '../models/checklist_item_model.dart';
import '../data/persistent_checklists.dart';

class PregnancyProvider extends ChangeNotifier {
  final PregnancyRepository _pregnancyRepository;
  final WeightRepository? _weightRepository;
  final AppointmentRepository? _appointmentRepository;
  final KickRepository? _kickRepository;
  final SymptomRepository? _symptomRepository;
  final ChecklistRepository? _checklistRepository;
  final VoidCallback? onDataChanged;
  final Uuid _uuid = const Uuid();

  PregnancyProvider(
    this._pregnancyRepository, {
    WeightRepository? weightRepository,
    AppointmentRepository? appointmentRepository,
    KickRepository? kickRepository,
    SymptomRepository? symptomRepository,
    ChecklistRepository? checklistRepository,
    this.onDataChanged,
  }) : _weightRepository = weightRepository,
       _appointmentRepository = appointmentRepository,
       _kickRepository = kickRepository,
       _checklistRepository = checklistRepository,
       _symptomRepository = symptomRepository;

  Pregnancy? _pregnancy;
  bool _isLoading = false;
  bool _isInitialized = false;
  DateTime _lastUpdate = DateTime.now();

  Pregnancy? get pregnancy => _pregnancy;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isPregnant => _pregnancy != null && _pregnancy!.isActive;
  DateTime get lastUpdate => _lastUpdate;

  List<WeightEntry> _weights = [];
  List<Appointment> _appointments = [];
  List<KickSession> _kickSessions = [];
  List<Pregnancy> _history = [];
  List<ChecklistItem> _checklistItems = [];

  List<WeightEntry> get weights => _weights;
  List<Appointment> get appointments => _appointments;
  List<KickSession> get kickSessions => _kickSessions;
  List<Pregnancy> get history => _history;
  List<ChecklistItem> get checklistItems => _checklistItems;

  KickSession? _activeKickSession;
  KickSession? get activeKickSession => _activeKickSession;

  Map<int, List<WeightEntry>> _weeklyWeights = {};
  Map<int, List<Appointment>> _weeklyAppointments = {};

  Map<int, List<WeightEntry>> get weeklyWeights => _weeklyWeights;
  Map<int, List<Appointment>> get weeklyAppointments => _weeklyAppointments;

  /// Check if a specific date falls within any pregnancy (active or historical)
  String? getPregnancyIdForDate(DateTime date) {
    // 1. Check active pregnancy first
    if (_pregnancy != null &&
        date.isAfter(
          _pregnancy!.lastPeriodDate.subtract(const Duration(days: 1)),
        ) &&
        date.isBefore(
          (_pregnancy!.birthDate ?? _pregnancy!.estimatedDueDate).add(
            const Duration(days: 1),
          ),
        )) {
      return _pregnancy!.id;
    }

    // 2. Check historical pregnancies
    for (final p in _history) {
      if (date.isAfter(p.lastPeriodDate.subtract(const Duration(days: 1))) &&
          date.isBefore(
            (p.birthDate ?? p.estimatedDueDate).add(const Duration(days: 1)),
          )) {
        return p.id;
      }
    }

    return null;
  }

  /// Get the end date of the most recent pregnancy (active or historical)
  DateTime? getLatestPregnancyEndDate() {
    if (_pregnancy != null && !_pregnancy!.isActive) {
      return _pregnancy!.birthDate ?? _pregnancy!.estimatedDueDate;
    }

    if (_history.isNotEmpty) {
      final sorted = List<Pregnancy>.from(_history)
        ..sort(
          (a, b) => (b.birthDate ?? b.estimatedDueDate).compareTo(
            a.birthDate ?? a.estimatedDueDate,
          ),
        );
      final latest = sorted.first;
      return latest.birthDate ?? latest.estimatedDueDate;
    }

    return null;
  }

  Future<void> initialize(String userId) async {
    _isLoading = true;
    notifyListeners();

    // 1. Always fetch history first to ensure UI knows user status
    try {
      await fetchHistory(userId);
    } catch (e) {
      debugPrint('Error loading pregnancy history: $e');
    }

    // 2. Fetch active pregnancy
    try {
      _pregnancy = await _pregnancyRepository.getPregnancy(userId);
      if (_pregnancy != null && _pregnancy!.isActive) {
        await Future.wait([
          _fetchWeights(),
          _fetchAppointments(),
          _fetchKickSessions(),
          _fetchChecklistItems(),
        ]);
        _groupWeeklyData();
      }
      _isInitialized = true;
      _lastUpdate = DateTime.now();
    } catch (e) {
      debugPrint('Error loading active pregnancy: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _groupWeeklyData() {
    if (_pregnancy == null) return;

    // Group weights by pregnancy week from in-memory list
    _weeklyWeights = {};
    for (final entry in _weights) {
      final diff = entry.date.difference(_pregnancy!.lastPeriodDate).inDays;
      final week = (diff / 7).floor() + 1;
      if (week >= 1 && week <= 42) {
        _weeklyWeights.putIfAbsent(week, () => []).add(entry);
      }
    }

    _groupAppointmentsByWeek();
    notifyListeners();
  }

  void _groupAppointmentsByWeek() {
    if (_pregnancy == null) return;
    _weeklyAppointments = {};
    for (final appt in _appointments) {
      final diff = appt.date.difference(_pregnancy!.lastPeriodDate).inDays;
      final week = (diff / 7).floor() + 1;
      if (week >= 1 && week <= 42) {
        _weeklyAppointments.putIfAbsent(week, () => []).add(appt);
      }
    }
  }

  Future<void> _fetchWeights() async {
    if (_pregnancy == null || _weightRepository == null) return;
    try {
      _weights = await _weightRepository.getWeightEntries(_pregnancy!.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching weights: $e');
    }
  }

  Future<void> _fetchAppointments() async {
    if (_pregnancy == null || _appointmentRepository == null) return;
    try {
      _appointments = await _appointmentRepository.getAppointments(
        _pregnancy!.id,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
    }
  }

  Future<void> _fetchKickSessions() async {
    if (_pregnancy == null || _kickRepository == null) return;
    try {
      _kickSessions = await _kickRepository.getKickSessions(_pregnancy!.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching kick sessions: $e');
    }
  }

  Future<void> _fetchChecklistItems() async {
    if (_pregnancy == null || _checklistRepository == null) return;
    try {
      _checklistItems =
          await _checklistRepository.getChecklistItems(_pregnancy!.id);

      // Seed items if they don't exist yet
      if (_checklistItems.isEmpty) {
        final List<ChecklistItem> initialItems = [];
        PersistentChecklistData.checklists.forEach((category, keys) {
          for (final key in keys) {
            initialItems.add(
              ChecklistItem(
                pregnancyId: _pregnancy!.id,
                category: category,
                itemKey: key,
              ),
            );
          }
        });

        await _checklistRepository.saveChecklistItems(initialItems);
        _checklistItems =
            await _checklistRepository.getChecklistItems(_pregnancy!.id);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching checklist items: $e');
    }
  }

  Future<void> toggleChecklistItem(ChecklistItem item) async {
    if (_checklistRepository == null) return;

    final updatedItem = item.copyWith(isChecked: !item.isChecked);

    // Optimistic update
    final index = _checklistItems.indexWhere(
      (i) =>
          i.id == item.id ||
          (i.itemKey == item.itemKey && i.category == item.category),
    );
    if (index != -1) {
      _checklistItems[index] = updatedItem;
      notifyListeners();
    }

    try {
      await _checklistRepository.updateChecklistItem(updatedItem);
      // Refresh to be sure
      _checklistItems =
          await _checklistRepository.getChecklistItems(item.pregnancyId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating checklist item: $e');
    }
  }

  Future<void> fetchHistory(String userId) async {
    try {
      _history = await _pregnancyRepository.getAllPregnancies(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching history: $e');
    }
  }

  // --- Kick Counting ---

  void startKickSession() {
    if (_pregnancy == null) return;
    _activeKickSession = KickSession(
      userId: _pregnancy!.userId,
      pregnancyId: _pregnancy!.id,
      startTime: DateTime.now(),
      count: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  void recordKick() {
    if (_activeKickSession == null) return;
    _activeKickSession = _activeKickSession!.copyWith(
      count: _activeKickSession!.count + 1,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> stopAndSaveKickSession({String? note}) async {
    if (_activeKickSession == null || _kickRepository == null) return;

    final sessionToSave = _activeKickSession!.copyWith(
      endTime: DateTime.now(),
      note: note,
      updatedAt: DateTime.now(),
    );

    try {
      await _kickRepository.saveKickSession(sessionToSave);
      _activeKickSession = null;
      await _fetchKickSessions();
      unawaited(
        AnalyticsService.instance.logKickSession(
          kickCount: sessionToSave.count,
          durationSeconds: sessionToSave.duration.inSeconds,
        ),
      );
      _lastUpdate = DateTime.now();
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving kick session: $e');
      rethrow;
    }
  }

  void cancelKickSession() {
    _activeKickSession = null;
    notifyListeners();
  }

  Future<void> deleteKickSession(int id) async {
    if (_kickRepository == null) return;
    try {
      await _kickRepository.deleteKickSession(id);
      await _fetchKickSessions();
      _lastUpdate = DateTime.now();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting kick session: $e');
    }
  }

  Future<void> addWeight(double weight, DateTime date, {String? note}) async {
    if (_pregnancy == null || _weightRepository == null) {
      debugPrint('Cannot add weight: Pregnancy or Repository null');
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final entry = WeightEntry(
        id: _uuid.v4(),
        pregnancyId: _pregnancy!.id,
        userId: _pregnancy!.userId,
        date: date,
        weightValue: weight,
        bmi: _calculateBMI(weight, _pregnancy!.height),
        note: note,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _weightRepository.saveWeightEntry(entry);
      await _fetchWeights();
      _groupWeeklyData();
      unawaited(AnalyticsService.instance.logPregnancyWeight());
      _lastUpdate = DateTime.now();
    } catch (e) {
      debugPrint('Error adding weight: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteWeight(String id) async {
    if (_weightRepository == null) return;
    try {
      await _weightRepository.deleteWeightEntry(id);
      await _fetchWeights();
      _groupWeeklyData();
      _lastUpdate = DateTime.now();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting weight: $e');
    }
  }

  double? _calculateBMI(double weight, double? heightCm) {
    if (heightCm == null || heightCm <= 0) return null;
    final heightM = heightCm / 100;
    return weight / (heightM * heightM);
  }

  Future<void> addAppointment(Appointment appointment) async {
    if (_pregnancy == null || _appointmentRepository == null) {
      debugPrint('Cannot add appointment: Pregnancy or Repository null');
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      await _appointmentRepository.saveAppointment(appointment);
      await _fetchAppointments();
      _groupAppointmentsByWeek();
      onDataChanged?.call();
      unawaited(AnalyticsService.instance.logAddPregnancyAppointment());
      _lastUpdate = DateTime.now();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding appointment: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAppointment(String id) async {
    if (_appointmentRepository == null) return;
    try {
      await _appointmentRepository.deleteAppointment(id);
      await _fetchAppointments();
      _groupAppointmentsByWeek();
      onDataChanged?.call();
      _lastUpdate = DateTime.now();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting appointment: $e');
    }
  }

  Future<void> completePregnancy({
    required DateTime birthDate,
    required String babyName,
    required String babyGender,
    double? birthWeight,
    double? birthLength,
    String? deliveryNotes,
  }) async {
    if (_pregnancy == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final updated = _pregnancy!.copyWith(
        isActive: false,
        birthDate: birthDate,
        updatedAt: DateTime.now(),
        babyName: babyName,
        babyGender: babyGender,
        birthWeight: birthWeight,
        birthLength: birthLength,
        deliveryNotes: deliveryNotes,
      );
      await _pregnancyRepository.savePregnancy(updated);
      _pregnancy = null; // Clear active pregnancy state
      _weights = [];
      _appointments = [];
      _weeklyWeights = {};
      _weeklyAppointments = {};

      // Refresh history
      await fetchHistory(updated.userId);
      _lastUpdate = DateTime.now();
    } catch (e) {
      debugPrint('Error completing pregnancy: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePregnancyHistory(String id, String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _pregnancyRepository.deletePregnancyById(id);
      
      // Delete associated data
      if (_weightRepository != null) {
        await _weightRepository.deleteWeightEntriesByPregnancy(id);
      }
      if (_appointmentRepository != null) {
        await _appointmentRepository.deleteAppointmentsByPregnancy(id);
      }
      if (_kickRepository != null) {
        await _kickRepository.deleteKickSessionsByPregnancy(id);
      }
      if (_symptomRepository != null) {
        await _symptomRepository.deleteDailyEntriesByPregnancy(id);
      }
      if (_checklistRepository != null) {
        await _checklistRepository.deleteChecklistItemsByPregnancy(id);
      }

      await fetchHistory(userId);
      _lastUpdate = DateTime.now();
    } catch (e) {
      debugPrint('Error deleting pregnancy history: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteActivePregnancy() async {
    if (_pregnancy == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final pregId = _pregnancy!.id;
      await _pregnancyRepository.deletePregnancyById(pregId);

      // Delete associated data
      if (_weightRepository != null) {
        await _weightRepository.deleteWeightEntriesByPregnancy(pregId);
      }
      if (_appointmentRepository != null) {
        await _appointmentRepository.deleteAppointmentsByPregnancy(pregId);
      }
      if (_kickRepository != null) {
        await _kickRepository.deleteKickSessionsByPregnancy(pregId);
      }
      if (_symptomRepository != null) {
        await _symptomRepository.deleteDailyEntriesByPregnancy(pregId);
      }
      if (_checklistRepository != null) {
        await _checklistRepository.deleteChecklistItemsByPregnancy(pregId);
      }

      // Clear active pregnancy state and related data
      _pregnancy = null;
      _weights = [];
      _appointments = [];
      _kickSessions = [];
      _checklistItems = [];
      _weeklyWeights = {};
      _weeklyAppointments = {};
      _activeKickSession = null;

      _lastUpdate = DateTime.now();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting active pregnancy: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateInitialMeasures(double height, double weight) async {
    if (_pregnancy == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final updated = _pregnancy!.copyWith(
        height: height,
        initialWeight: weight,
        updatedAt: DateTime.now(),
      );
      await _pregnancyRepository.savePregnancy(updated);
      _pregnancy = updated;
      _lastUpdate = DateTime.now();
    } catch (e) {
      debugPrint('Error updating measures: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Start Pregnancy (Calculate EDD)
  Future<void> startPregnancy(
    String userId,
    DateTime lmp, {
    double? initialWeight,
    double? height,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Naegele's Rule: LMP + 1 year - 3 months + 7 days
      final edd = DateTime(lmp.year + 1, lmp.month - 3, lmp.day + 7);

      final newPregnancy = Pregnancy(
        id: _uuid.v4(),
        userId: userId,
        lastPeriodDate: lmp,
        estimatedDueDate: edd,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        initialWeight: initialWeight,
        height: height,
        isActive: true,
      );

      await _pregnancyRepository.savePregnancy(newPregnancy);

      // --- Retroactive Logging Sync ---
      // Background task to relink daily entries logged since conception
      if (_symptomRepository != null) {
        Future.microtask(() async {
          try {
            final recentEntries = await _symptomRepository
                .getDailyEntriesForDateRange(
                  userId,
                  lmp, // From conception date onwards
                  DateTime.now(),
                );

            for (final entry in recentEntries) {
              final updatedEntry = entry.copyWith(
                clearPeriodLogId: true,
                pregnancyLogId: newPregnancy.id,
                updatedAt: DateTime.now(),
              );
              await _symptomRepository.updateDailyEntry(updatedEntry);
            }
          } catch (e) {
            debugPrint('Error syncing retroactive pregnancy logs: $e');
          }
        });
      }

      // Set state immediately to trigger UI transitions
      _pregnancy = newPregnancy;
      notifyListeners();

      // Then do a full refresh to ensure everything is in sync
      await initialize(userId);
      _lastUpdate = DateTime.now();
    } catch (e) {
      debugPrint('Error starting pregnancy: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
