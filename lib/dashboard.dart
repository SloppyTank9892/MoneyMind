import 'package:flutter/material.dart';
import 'checkin.dart';
import 'spend.dart';
import 'ai.dart';
import 'screens/insights_screen.dart';
import 'screens/analytics_screen.dart';
import 'services/firestore_service.dart';
import 'models/financial_features.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildStressIndexCard(FinancialFeatures features) {
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Financial Stress Index',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: features.getRiskColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: features.getRiskColor().withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    features.riskLevel,
                    style: TextStyle(
                      color: features.getRiskColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              features.financialStressIndex.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: features.getRiskColor(),
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: features.financialStressIndex / 100,
                backgroundColor: Colors.grey[900]!,
                valueColor: AlwaysStoppedAnimation<Color>(features.getRiskColor()),
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Money Personality: ${features.moneyPersonality}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                letterSpacing: 0.3,
              ),
            ),
            if (features.triggerTypes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: features.triggerTypes
                      .map((trigger) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF8B5CF6).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              trigger,
                              style: TextStyle(
                                fontSize: 11,
                                color: const Color(0xFF8B5CF6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskBanner(String riskWindow) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF4444).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: const Color(0xFFEF4444), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'High Risk Period: $riskWindow',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: const Color(0xFFEF4444),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, IconData icon, VoidCallback onTap, String heroTag) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
      child: Hero(
        tag: heroTag,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey[800]!,
                  width: 1,
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 72,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: const Color(0xFF6366F1),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("MoneyMind AI")),
      body: StreamBuilder<FinancialFeatures>(
        stream: _firestoreService.watchFinancialFeatures(),
        builder: (context, snapshot) {
          final features = snapshot.data ?? FinancialFeatures.empty();
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Financial Stress Index Card
                _buildStressIndexCard(features),
                const SizedBox(height: 16),
                
                // Risk Warning Banner
                if (features.predictedRiskWindow != null)
                  _buildRiskBanner(features.predictedRiskWindow!),
                
                const SizedBox(height: 8),
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Colors.grey[300],
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildCard("Daily Check-in", Icons.check_circle, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckIn())), 'checkin'),
                const SizedBox(height: 12),
                _buildCard("Add Expense", Icons.attach_money, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Spend())), 'spend'),
                const SizedBox(height: 12),
                _buildCard("View Insights", Icons.analytics, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InsightsScreen())), 'insights'),
                const SizedBox(height: 12),
                _buildCard("Spending Analytics", Icons.bar_chart, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen())), 'analytics'),
                const SizedBox(height: 12),
                _buildCard("Ask AI", Icons.chat_bubble, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIChat())), 'ai'),
              ],
            ),
          );
        },
      ),
      floatingActionButton: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut)),
        child: FloatingActionButton(
          onPressed: () {
            // Show a bottom sheet with quick actions
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.attach_money),
                      title: const Text('Add Expense'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const Spend()));
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.check_circle),
                      title: const Text('Daily Check-in'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckIn()));
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.chat_bubble),
                      title: const Text('Ask AI'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AIChat()));
                      },
                    ),
                  ],
                ),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
