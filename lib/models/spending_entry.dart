import 'package:cloud_firestore/cloud_firestore.dart';

class SpendingEntry {
  final double amount;
  final String category; // Food, Travel, Shopping, Entertainment, Bills, Education, Social
  final String emotion; // Neutral, Happy, Stress, Guilt, Anxiety, FOMO, Regret
  final bool isPlanned;
  final String? notes;
  final DateTime timestamp;

  SpendingEntry({
    required this.amount,
    required this.category,
    required this.emotion,
    required this.isPlanned,
    this.notes,
    required this.timestamp,
  });

  factory SpendingEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SpendingEntry(
      amount: (data['amount'] is String) 
          ? double.tryParse(data['amount']) ?? 0.0
          : (data['amount'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] ?? 'Other',
      emotion: data['emotion'] ?? 'Neutral',
      isPlanned: data['isPlanned'] ?? false,
      notes: data['notes'],
      timestamp: (data['time'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'amount': amount,
      'category': category,
      'emotion': emotion,
      'isPlanned': isPlanned,
      'notes': notes,
      'time': Timestamp.fromDate(timestamp),
    };
  }
}
