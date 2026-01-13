import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../models/spending_entry.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;
  List<SpendingEntry> _allEntries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final entries = await _firestoreService.getAllSpendingEntries();
      if (mounted) {
        setState(() {
          _allEntries = entries;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  // Group spending by day
  Map<String, double> _getDailySpending() {
    final Map<String, double> dailySpending = {};
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    for (var entry in _allEntries) {
      // Only include entries from last 30 days
      if (entry.timestamp.isAfter(thirtyDaysAgo) || entry.timestamp.isAtSameMomentAs(thirtyDaysAgo)) {
        final dateKey = DateFormat('MMM dd').format(entry.timestamp);
        dailySpending[dateKey] = (dailySpending[dateKey] ?? 0) + entry.amount;
      }
    }
    
    // Sort by date
    final sorted = dailySpending.entries.toList()
      ..sort((a, b) {
        try {
          final dateA = DateFormat('MMM dd').parse(a.key);
          final dateB = DateFormat('MMM dd').parse(b.key);
          return dateA.compareTo(dateB);
        } catch (e) {
          return a.key.compareTo(b.key);
        }
      });
    
    return Map.fromEntries(sorted);
  }

  // Group spending by month
  Map<String, double> _getMonthlySpending() {
    final Map<String, double> monthlySpending = {};
    
    for (var entry in _allEntries) {
      final monthKey = DateFormat('MMM yyyy').format(entry.timestamp);
      monthlySpending[monthKey] = (monthlySpending[monthKey] ?? 0) + entry.amount;
    }
    
    // Sort by date
    final sorted = monthlySpending.entries.toList()
      ..sort((a, b) {
        try {
          final dateA = DateFormat('MMM yyyy').parse(a.key);
          final dateB = DateFormat('MMM yyyy').parse(b.key);
          return dateA.compareTo(dateB);
        } catch (e) {
          return a.key.compareTo(b.key);
        }
      });
    
    return Map.fromEntries(sorted);
  }

  // Group spending by year
  Map<String, double> _getYearlySpending() {
    final Map<String, double> yearlySpending = {};
    
    for (var entry in _allEntries) {
      final yearKey = entry.timestamp.year.toString();
      yearlySpending[yearKey] = (yearlySpending[yearKey] ?? 0) + entry.amount;
    }
    
    // Sort by year
    final sorted = yearlySpending.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    return Map.fromEntries(sorted);
  }

  Widget _buildBarChart(Map<String, double> data, String title) {
    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, size: 64, color: Colors.grey[700]),
              const SizedBox(height: 16),
              Text(
                'No spending data available',
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Start adding expenses to see your analytics',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final entries = data.entries.toList();
    final maxAmount = data.values.reduce((a, b) => a > b ? a : b);
    final maxY = (maxAmount * 1.2).ceilToDouble(); // Add 20% padding

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
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total: ₹${data.values.fold(0.0, (a, b) => a + b).toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      tooltipBgColor: Colors.grey[800],
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${entries[group.x.toInt()].key}\n₹${rod.toY.toStringAsFixed(0)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < entries.length) {
                            // Show abbreviated labels for better readability
                            final label = entries[index].key;
                            if (label.length > 6) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  label.substring(0, 6),
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 40,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '₹${value.toInt()}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: entries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final dataEntry = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: dataEntry.value,
                          color: _getColorForIndex(index),
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300]!,
                        strokeWidth: 1,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF10B981), // Green
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFEC4899), // Pink
      const Color(0xFF3B82F6), // Blue
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Daily', icon: Icon(Icons.calendar_today)),
            Tab(text: 'Monthly', icon: Icon(Icons.calendar_month)),
            Tab(text: 'Yearly', icon: Icon(Icons.event_note)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Daily View
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildBarChart(
                      _getDailySpending(),
                      'Daily Spending (Last 30 Days)',
                    ),
                  ),
                  // Monthly View
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildBarChart(
                      _getMonthlySpending(),
                      'Monthly Spending',
                    ),
                  ),
                  // Yearly View
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildBarChart(
                      _getYearlySpending(),
                      'Yearly Spending',
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
