import 'package:cloud_firestore/cloud_firestore.dart';

class MoodEntry {
  final String mood; // Calm, Stressed, Anxious
  final String moneyFeeling; // Safe, Worried, Guilty
  final bool moneyCausedStress;
  final String? notes;
  final DateTime timestamp;

  MoodEntry({
    required this.mood,
    required this.moneyFeeling,
    required this.moneyCausedStress,
    this.notes,
    required this.timestamp,
  });

  factory MoodEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MoodEntry(
      mood: data['mood'] ?? 'Calm',
      moneyFeeling: data['money'] ?? 'Safe',
      moneyCausedStress: data['moneyCausedStress'] ?? false,
      notes: data['notes'],
      timestamp: (data['time'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'mood': mood,
      'money': moneyFeeling,
      'moneyCausedStress': moneyCausedStress,
      'notes': notes,
      'time': Timestamp.fromDate(timestamp),
    };
  }
}
