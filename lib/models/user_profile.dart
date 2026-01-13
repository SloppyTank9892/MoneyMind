import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String incomeSource; // Allowance, Part-time Job, Scholarship, Family Support
  final String livingSituation; // Hostel, Home, PG, Rent
  final String monthlySpendRange; // <5000, 5000-10000, 10000-20000, >20000
  final List<String> stressTriggers; // Exams, Social Events, Bills, Shopping, Travel
  final List<String> moneyEmotions; // Anxiety, Guilt, FOMO, Confidence, Shame
  final DateTime createdAt;

  UserProfile({
    required this.incomeSource,
    required this.livingSituation,
    required this.monthlySpendRange,
    required this.stressTriggers,
    required this.moneyEmotions,
    required this.createdAt,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      incomeSource: data['incomeSource'] ?? 'Not set',
      livingSituation: data['livingSituation'] ?? 'Not set',
      monthlySpendRange: data['monthlySpendRange'] ?? 'Not set',
      stressTriggers: List<String>.from(data['stressTriggers'] ?? []),
      moneyEmotions: List<String>.from(data['moneyEmotions'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'incomeSource': incomeSource,
      'livingSituation': livingSituation,
      'monthlySpendRange': monthlySpendRange,
      'stressTriggers': stressTriggers,
      'moneyEmotions': moneyEmotions,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
