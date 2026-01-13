import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/financial_features.dart';
import '../models/mood_entry.dart';
import '../models/spending_entry.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({Key? key}) : super(key: key);

  @override
  _InsightsScreenState createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Insights')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Financial Features Summary
            StreamBuilder<FinancialFeatures>(
              stream: _firestoreService.watchFinancialFeatures(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final features = snapshot.data!;
                return _buildFeaturesSummary(features);
              },
            ),
            
            const SizedBox(height: 24),
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Recent Moods
            _buildRecentMoods(),
            
            const SizedBox(height: 16),
            
            // Recent Spending
            _buildRecentSpending(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSummary(FinancialFeatures features) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E1E2E),
              const Color(0xFF2D2D3A),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Financial Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey[800], height: 1),
            _buildInfoRow('Stress Index', '${features.financialStressIndex.toStringAsFixed(1)}/100'),
            _buildInfoRow('Risk Level', features.riskLevel),
            _buildInfoRow('Money Personality', features.moneyPersonality),
            if (features.triggerTypes.isNotEmpty)
              _buildInfoRow('Triggers', features.triggerTypes.join(', ')),
            if (features.predictedRiskWindow != null)
              _buildInfoRow('Risk Window', features.predictedRiskWindow!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMoods() {
    return StreamBuilder<List<MoodEntry>>(
      stream: _firestoreService.getMoodEntries(limit: 5),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        
        final moods = snapshot.data!;
        if (moods.isEmpty) {
          return const Text('No mood entries yet. Start with a daily check-in!');
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Moods', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...moods.map((mood) => ListTile(
              leading: Icon(
                Icons.mood,
                color: mood.moneyCausedStress ? Colors.orange : Colors.green,
              ),
              title: Text('${mood.mood} - ${mood.moneyFeeling}'),
              subtitle: Text(mood.notes ?? 'No notes'),
              trailing: Text(_formatDate(mood.timestamp)),
            )),
          ],
        );
      },
    );
  }

  Widget _buildRecentSpending() {
    return StreamBuilder<List<SpendingEntry>>(
      stream: _firestoreService.getSpendingEntries(limit: 5),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        
        final spending = snapshot.data!;
        if (spending.isEmpty) {
          return const Text('No expenses recorded yet.');
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Expenses', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...spending.map((entry) => ListTile(
              leading: CircleAvatar(
                child: Text('₹'),
                backgroundColor: entry.isPlanned ? Colors.green[100] : Colors.red[100],
              ),
              title: Text('₹${entry.amount.toStringAsFixed(0)} - ${entry.category}'),
              subtitle: Text('${entry.emotion} • ${entry.isPlanned ? "Planned" : "Unplanned"}'),
              trailing: Text(_formatDate(entry.timestamp)),
            )),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${date.day}/${date.month}';
  }
}
