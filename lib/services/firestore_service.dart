import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/user_profile.dart';
import '../models/mood_entry.dart';
import '../models/spending_entry.dart';
import '../models/financial_features.dart';
import '../models/chat_message.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // User Profile
  Future<void> saveProfile(UserProfile profile) async {
    await _db.collection('users').doc(_uid).collection('private').doc('profile').set(profile.toFirestore());
  }

  Future<UserProfile?> getProfile() async {
    final doc = await _db.collection('users').doc(_uid).collection('private').doc('profile').get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc);
  }

  Future<bool> hasCompletedOnboarding() async {
    final profile = await getProfile();
    return profile != null;
  }

  // Mood Entries
  Future<void> saveMoodEntry(MoodEntry entry) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('private')
        .doc('moods')
        .collection('entries')
        .add(entry.toFirestore());
    // Trigger real-time recalculation
    await recalculateStressIndex();
  }

  Stream<List<MoodEntry>> getMoodEntries({int limit = 30}) {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('private')
        .doc('moods')
        .collection('entries')
        .orderBy('time', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MoodEntry.fromFirestore(doc)).toList());
  }

  // Spending Entries
  Future<void> saveSpendingEntry(SpendingEntry entry) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('private')
        .doc('spending')
        .collection('entries')
        .add(entry.toFirestore());
    // Trigger real-time recalculation
    await recalculateStressIndex();
  }

  Stream<List<SpendingEntry>> getSpendingEntries({int limit = 30}) {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('private')
        .doc('spending')
        .collection('entries')
        .orderBy('time', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => SpendingEntry.fromFirestore(doc)).toList());
  }

  // Get all spending entries for analytics (no limit)
  Future<List<SpendingEntry>> getAllSpendingEntries() async {
    final snapshot = await _db
        .collection('users')
        .doc(_uid)
        .collection('private')
        .doc('spending')
        .collection('entries')
        .orderBy('time', descending: true)
        .get();
    
    return snapshot.docs.map((doc) => SpendingEntry.fromFirestore(doc)).toList();
  }

  // Financial Features
  Future<FinancialFeatures> getFinancialFeatures() async {
    final doc = await _db.collection('users').doc(_uid).collection('features').doc('summary').get();
    return FinancialFeatures.fromFirestore(doc);
  }

  Stream<FinancialFeatures> watchFinancialFeatures() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('features')
        .doc('summary')
        .snapshots()
        .map((doc) => FinancialFeatures.fromFirestore(doc));
  }

  // AI Chat
  Future<void> saveChatMessage(ChatMessage message) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('private')
        .doc('aiChats')
        .collection('messages')
        .add(message.toFirestore());
  }

  Stream<List<ChatMessage>> getChatHistory({int limit = 50}) {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('private')
        .doc('aiChats')
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc.data())).toList());
  }

  // Recalculate Financial Stress Index in real-time
  Future<void> recalculateStressIndex() async {
    try {
      final functions = FirebaseFunctions.instance;
      await functions.httpsCallable('recalculateStressIndex').call();
    } catch (e) {
      // Silently fail - the daily scheduled function will update it eventually
      print('Error recalculating stress index: $e');
    }
  }

  // Admin: Get university students (anonymized features only)
  Stream<List<Map<String, dynamic>>> getUniversityStudents(String universityId) {
    return _db
        .collection('universities')
        .doc(universityId)
        .collection('students')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          data['uid'] = doc.id;
          return data;
        }).toList());
  }
}
