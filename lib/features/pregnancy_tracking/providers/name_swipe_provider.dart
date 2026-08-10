import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/data/repositories/name_swipe_repository.dart';
import '../../../../core/data/local/database/app_database.dart';
import '../../../../core/services/analytics_service.dart';

class NameSwipeProvider extends ChangeNotifier {
  final NameSwipeRepository _nameSwipeRepository;
  final FirebaseFirestore? _firestore;

  NameSwipeProvider({
    required NameSwipeRepository nameSwipeRepository,
    FirebaseFirestore? firestore,
  }) : _nameSwipeRepository = nameSwipeRepository,
       _firestore = firestore;

  FirebaseFirestore? get firestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  // Cache for the parsed database
  Map<String, dynamic>? _cachedDb;

  // Deck State
  List<Map<String, String>> _currentDeck = [];
  bool _isLoading = false;
  String? _pregnancyId;
  String? _userId;

  // Filter State
  String _genderFilter = 'both'; // 'boy' | 'girl' | 'both'
  String _localeFilter = 'en';

  // History stack for undo actions (local memory backup)
  final List<Map<String, String>> _swipedNamesHistory = [];
  final List<String> _swipedActionsHistory = [];

  // Real-time Matches Listening
  StreamSubscription<QuerySnapshot>? _matchesSubscription;
  final _matchController = StreamController<String>.broadcast();

  // Getters
  List<Map<String, String>> get currentDeck => _currentDeck;
  bool get isLoading => _isLoading;
  String get genderFilter => _genderFilter;
  String get localeFilter => _localeFilter;
  bool get canUndo => _swipedNamesHistory.isNotEmpty;
  String? get lastSwipedAction => _swipedActionsHistory.isNotEmpty ? _swipedActionsHistory.last : null;
  Stream<String> get onMatchFound => _matchController.stream;

  @override
  void dispose() {
    _matchesSubscription?.cancel();
    _matchController.close();
    super.dispose();
  }

  /// Initialize the deck by loading and filtering names
  Future<void> initializeDeck({
    required String pregnancyId,
    required String userId,
    required String appLocale,
    String? defaultBabyGender,
  }) async {
    _pregnancyId = pregnancyId;
    _userId = userId;
    _localeFilter = appLocale;
    _swipedNamesHistory.clear();
    _swipedActionsHistory.clear();

    // Set default gender filter based on pregnancy profile if not already customized
    if (defaultBabyGender != null && _genderFilter == 'both') {
      if (defaultBabyGender.toLowerCase() == 'male' || defaultBabyGender.toLowerCase() == 'boy') {
        _genderFilter = 'boy';
      } else if (defaultBabyGender.toLowerCase() == 'female' || defaultBabyGender.toLowerCase() == 'girl') {
        _genderFilter = 'girl';
      }
    }

    await loadAndFilterDeck();
    // startListeningToMatches(pregnancyId, userId); // Disabled until partner sync is implemented
  }

  /// Change gender filter and reload deck
  Future<void> setGenderFilter(String filter) async {
    if (_genderFilter == filter) return;
    _genderFilter = filter;
    _swipedNamesHistory.clear();
    _swipedActionsHistory.clear();
    notifyListeners();
    await loadAndFilterDeck();
  }

  /// Load and parse the JSON names asset, then filter out already-swiped names
  Future<void> loadAndFilterDeck() async {
    if (_pregnancyId == null || _userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Load JSON file if not cached
      if (_cachedDb == null) {
        final jsonStr = await rootBundle.loadString('assets/names_db.json');
        _cachedDb = jsonDecode(jsonStr) as Map<String, dynamic>;
      }

      // 2. Resolve language locale (fallback to 'en' if unsupported)
      String targetLocale = _localeFilter;
      if (!_cachedDb!.containsKey(targetLocale)) {
        targetLocale = 'en';
      }

      final localeData = _cachedDb![targetLocale] as Map<String, dynamic>?;
      if (localeData == null) {
        _currentDeck = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 3. Collect names from selected categories (boy / girl)
      final List<Map<String, String>> rawNames = [];

      if (_genderFilter == 'boy' || _genderFilter == 'both') {
        final boyList = localeData['boy'] as List<dynamic>? ?? [];
        for (var item in boyList) {
          if (item is Map) {
            rawNames.add({
              'name': item['name'] as String? ?? '',
              'meaning': item['meaning'] as String? ?? '',
              'gender': 'boy',
            });
          }
        }
      }

      if (_genderFilter == 'girl' || _genderFilter == 'both') {
        final girlList = localeData['girl'] as List<dynamic>? ?? [];
        for (var item in girlList) {
          if (item is Map) {
            rawNames.add({
              'name': item['name'] as String? ?? '',
              'meaning': item['meaning'] as String? ?? '',
              'gender': 'girl',
            });
          }
        }
      }

      // 4. Query swiped names from Drift SQLite
      final swipedList = await _nameSwipeRepository.getSwipedNames(_pregnancyId!, _userId!);
      final Set<String> swipedNames = swipedList.map((e) => e.name.toLowerCase()).toSet();

      // 5. Filter deck to only show unseen names
      _currentDeck = rawNames.where((element) {
        final name = element['name'] ?? '';
        return name.isNotEmpty && !swipedNames.contains(name.toLowerCase());
      }).toList();

      // Shuffle the deck for serendipity
      _currentDeck.shuffle();

    } catch (e) {
      debugPrint('Error loading name swipe deck: $e');
      _currentDeck = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Handle a user swipe (Like / Pass)
  Future<void> handleSwipe(bool liked) async {
    if (_currentDeck.isEmpty || _pregnancyId == null || _userId == null) return;

    // Remove first card from deck
    final swipedCard = _currentDeck.removeAt(0);
    _swipedNamesHistory.add(swipedCard);
    _swipedActionsHistory.add(liked ? 'liked' : 'passed');
    notifyListeners();

    final name = swipedCard['name'] ?? '';
    final gender = swipedCard['gender'] ?? 'boy';
    final meaning = swipedCard['meaning'];
    final action = liked ? 'liked' : 'passed';

    // 1. Persist locally to Drift SQLite immediately
    await _nameSwipeRepository.recordSwipe(
      pregnancyId: _pregnancyId!,
      userId: _userId!,
      name: name,
      gender: gender,
      meaning: meaning,
      action: action,
    );

    unawaited(AnalyticsService.instance.logUseNameSwiper());

    // 2. Sync to Firestore if it's a LIKE (for partner match detection)
    // if (liked) {
    //   _syncLikeToFirestore(name, gender, meaning);
    // }
  }

  /// Undo the immediate last swipe
  Future<void> undoSwipe() async {
    if (_pregnancyId == null || _userId == null || _swipedNamesHistory.isEmpty) return;

    final nameToRestore = _swipedNamesHistory.removeLast();
    _swipedActionsHistory.removeLast();

    // 1. Remove from local Drift SQLite
    await _nameSwipeRepository.undoLastSwipe(_pregnancyId!, _userId!);

    // 2. Remove from Firestore if it was a liked name (Disabled until partner sync is implemented)
    // if (actionToRestore == 'liked') {
    //   _removeLikeFromFirestore(name);
    // }

    // 3. Put back on top of the deck
    _currentDeck.insert(0, nameToRestore);
    notifyListeners();
  }

  /// Reset all passed names so the user can see them again
  Future<void> resetPasses() async {
    if (_pregnancyId == null || _userId == null) return;

    _isLoading = true;
    notifyListeners();

    await _nameSwipeRepository.resetPasses(_pregnancyId!, _userId!);
    await loadAndFilterDeck();
  }

  /// Fetch all names liked by the user (Drift)
  Future<List<NameSwipe>> getLikedNames() async {
    if (_pregnancyId == null || _userId == null) return [];
    return _nameSwipeRepository.getLikedNames(_pregnancyId!, _userId!);
  }

  /// Manually remove a name from user's liked list
  Future<void> deleteLikedName(String name) async {
    if (_pregnancyId == null || _userId == null) return;
    await _nameSwipeRepository.removeLikedName(_pregnancyId!, _userId!, name);
    // _removeLikeFromFirestore(name);
    notifyListeners();
  }

  /*
  Future<void> _syncLikeToFirestore(String name, String gender, String? meaning) async {
    if (_pregnancyId == null || _userId == null) return;
    final fs = firestore;
    if (fs == null) return;

    try {
      final docRef = fs
          .collection('pregnancies')
          .doc(_pregnancyId)
          .collection('liked_names')
          .doc(name.toLowerCase());

      await docRef.set({
        'name': name,
        'gender': gender,
        'meaning': meaning ?? '',
        'likedBy': FieldValue.arrayUnion([_userId!]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore sync failed (offline or partner sync not set up): $e');
    }
  }

  Future<void> _removeLikeFromFirestore(String name) async {
    if (_pregnancyId == null || _userId == null) return;
    final fs = firestore;
    if (fs == null) return;

    try {
      final docRef = fs
          .collection('pregnancies')
          .doc(_pregnancyId)
          .collection('liked_names')
          .doc(name.toLowerCase());

      await docRef.update({
        'likedBy': FieldValue.arrayRemove([_userId!]),
        'isMatch': false, // Un-match if it was a match
      });
    } catch (e) {
      debugPrint('Firestore swipe removal failed: $e');
    }
  }
  */

  /// Listen to real-time matches under this pregnancy
  void startListeningToMatches(String pregnancyId, String userId) {
    _matchesSubscription?.cancel();
    final fs = firestore;
    if (fs == null) return;

    _matchesSubscription = fs
        .collection('pregnancies')
        .doc(pregnancyId)
        .collection('liked_names')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified || change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            final likedBy = List<String>.from((data['likedBy'] as Iterable?) ?? const []);
            final name = data['name'] as String? ?? '';
            final isMatch = data['isMatch'] as bool? ?? false;

            // Check if both partners have liked this name
            if (likedBy.length >= 2 && likedBy.contains(userId) && !isMatch) {
              // Mark as match in Firestore to avoid triggering multiple times
              change.doc.reference.update({
                'isMatch': true,
                'matchedAt': FieldValue.serverTimestamp(),
              });

              // Fire match event to subscribers (UI screens)
              _matchController.add(name);
            }
          }
        }
      }
    }, onError: (Object e) {
      debugPrint('Firestore matches subscription listener error: $e');
    });
  }
}
