import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FinancialFeatures {
  final double financialStressIndex; // 0-100
  final String riskLevel; // Low, Medium, High
  final String moneyPersonality; // Avoider, Worrier, Stress-Spender, Balanced
  final List<String> triggerTypes;
  final String? predictedRiskWindow; // e.g., "Next week (Exam period)"
  final DateTime lastUpdated;

  FinancialFeatures({
    required this.financialStressIndex,
    required this.riskLevel,
    required this.moneyPersonality,
    required this.triggerTypes,
    this.predictedRiskWindow,
    required this.lastUpdated,
  });

  factory FinancialFeatures.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return FinancialFeatures.empty();
    }
    
    return FinancialFeatures(
      financialStressIndex: (data['financialStressIndex'] as num?)?.toDouble() ?? 0.0,
      riskLevel: data['riskLevel'] ?? 'Low',
      moneyPersonality: data['moneyPersonality'] ?? 'Balanced',
      triggerTypes: List<String>.from(data['triggerTypes'] ?? []),
      predictedRiskWindow: data['predictedRiskWindow'],
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory FinancialFeatures.empty() {
    return FinancialFeatures(
      financialStressIndex: 0.0,
      riskLevel: 'Low',
      moneyPersonality: 'New User',
      triggerTypes: [],
      predictedRiskWindow: null,
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'financialStressIndex': financialStressIndex,
      'riskLevel': riskLevel,
      'moneyPersonality': moneyPersonality,
      'triggerTypes': triggerTypes,
      'predictedRiskWindow': predictedRiskWindow,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  Color getRiskColor() {
    switch (riskLevel) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
      default:
        return Colors.green;
    }
  }
}
