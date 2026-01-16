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
      print('🔄 Triggering stress index recalculation...');
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('recalculateStressIndex').call();
      print('✅ Stress index recalculated: ${result.data}');
    } on FirebaseFunctionsException catch (e) {
      print('❌ Firebase Functions Error: ${e.code} - ${e.message}');
      print('❌ Details: ${e.details}');
      
      // If the function doesn't exist or there's a permission issue, 
      // we'll calculate it locally as a fallback
      if (e.code == 'not-found' || e.code == 'unavailable') {
        print('⚠️ Cloud Function not available, calculating locally...');
        await _calculateStressIndexLocally();
      }
    } catch (e, stackTrace) {
      print('❌ Error recalculating stress index: $e');
      print('❌ Stack trace: $stackTrace');
      // Try local calculation as fallback
      await _calculateStressIndexLocally();
    }
  }
  
  // Fallback: Calculate stress index locally if Cloud Function fails
  Future<void> _calculateStressIndexLocally() async {
    try {
      print('🔄 Calculating stress index locally...');
      
      // Get user data to check role
      final userDoc = await _db.collection('users').doc(_uid).get();
      final userData = userDoc.data();
      
      if (userData == null || userData['role'] != 'student') {
        print('⚠️ User is not a student, setting role...');
        // Set role if missing
        await _db.collection('users').doc(_uid).set({
          'role': 'student',
        }, SetOptions(merge: true));
      }
      
      // Get recent data (last 7 days)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      
      // Get moods
      final moodsSnapshot = await _db
          .collection('users')
          .doc(_uid)
          .collection('private')
          .doc('moods')
          .collection('entries')
          .where('time', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .get();
      
      // Get spending
      final spendingSnapshot = await _db
          .collection('users')
          .doc(_uid)
          .collection('private')
          .doc('spending')
          .collection('entries')
          .where('time', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .get();
      
      // Calculate stress score
      double stressScore = 30.0; // Base
      
      int moodCount = 0;
      for (var doc in moodsSnapshot.docs) {
        final data = doc.data();
        final timestamp = (data['time'] as Timestamp).toDate();
        final daysAgo = DateTime.now().difference(timestamp).inDays.toDouble();
        final recencyWeight = (1.0 - (daysAgo / 7.0)).clamp(0.5, 1.0);
        
        if (data['mood'] == 'Stressed' || data['mood'] == 'Anxious') {
          stressScore += 10 * recencyWeight;
        }
        if (data['money'] == 'Worried' || data['money'] == 'Guilty') {
          stressScore += 15 * recencyWeight;
        }
        if (data['moneyCausedStress'] == true) {
          stressScore += 20 * recencyWeight;
        }
        moodCount++;
      }
      
      int unplannedCount = 0;
      double unplannedSpend = 0;
      for (var doc in spendingSnapshot.docs) {
        final data = doc.data();
        final isUnplanned = data['isPlanned'] == false;
        if (isUnplanned) {
          final timestamp = (data['time'] as Timestamp).toDate();
          final daysAgo = DateTime.now().difference(timestamp).inDays.toDouble();
          final recencyWeight = (1.0 - (daysAgo / 7.0)).clamp(0.5, 1.0);
          stressScore += 5 * recencyWeight;
          unplannedSpend += (data['amount'] as num?)?.toDouble() ?? 0.0;
          unplannedCount++;
        }
      }
      
      // Cap the score
      stressScore = stressScore.clamp(0.0, 100.0);
      
      // Determine risk level
      String riskLevel = 'Low';
      if (stressScore > 75) riskLevel = 'High';
      else if (stressScore > 40) riskLevel = 'Medium';
      
      // Determine personality
      String personality = 'Balanced';
      if (moodCount == 0 && spendingSnapshot.docs.isEmpty) {
        personality = 'New User';
      } else if (unplannedSpend > 1000 && stressScore > 60) {
        personality = 'Stress Spender';
      } else if (stressScore > 80 && unplannedSpend < 500) {
        personality = 'Anxious Saver';
      } else if (unplannedSpend > 2000) {
        personality = 'Impulsive';
      }
      
      // Save to Firestore
      await _db.collection('users').doc(_uid).collection('features').doc('summary').set({
        'financialStressIndex': stressScore,
        'riskLevel': riskLevel,
        'moneyPersonality': personality,
        'triggerTypes': userData?['stressTriggers'] ?? [],
        'predictedRiskWindow': (riskLevel == 'High' || riskLevel == 'Medium') ? 'Next 3 Days' : null,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('✅ Local stress index calculated: $stressScore ($riskLevel)');
    } catch (e) {
      print('❌ Error in local calculation: $e');
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
