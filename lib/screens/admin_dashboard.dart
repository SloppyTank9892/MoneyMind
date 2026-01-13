import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../login.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? _universityId;
  bool _loading = true;

  // Stats
  int _totalStudents = 0;
  int _highRisk = 0;
  int _mediumRisk = 0;
  int _lowRisk = 0;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final uniId = userDoc.data()?['university_id'];

    if (uniId != null) {
      setState(() => _universityId = uniId);
      if (mounted) {
        await _fetchStudentStats(uniId);
      }
    }
  }

  Future<void> _fetchStudentStats(String uniId) async {
    // Admins can ONLY read /universities/{uniId}/students/*
    final studentsSnapshot = await _db
        .collection('universities')
        .doc(uniId)
        .collection('students')
        .get();

    int high = 0;
    int medium = 0;
    int low = 0;

    for (var doc in studentsSnapshot.docs) {
      // Accessing the feature summary subcollection or fields if flattened
      // The prompt schema says: /universities/{uni}/students/{uid}/features/summary
      // So we need to query subcollections or assume the function copies it to the student doc for easier querying.
      // However, querying subcollections for ALL students is expensive (N reads).
      // Ideally, the 'stress engine' would update a summary document at /universities/{uni}/stats/summary
      // But adhering to the prompt: /universities/{university_id}/students/{uid}/features/summary

      // We'll try to fetch the features/summary for each student.
      // Note: In a real app with thousands of students, this is bad.
      // But for this prototype, we will fetch the subcollection.

      final featureSnap = await doc.reference
          .collection('features')
          .doc('summary')
          .get();
      if (featureSnap.exists) {
        final data = featureSnap.data();
        final risk = data?['riskLevel'] ?? 'Low';
        if (risk == 'High') {
          high++;
        } else if (risk == 'Medium') {
          medium++;
        } else {
          low++;
        }
      } else {
        low++; // Default to low if no data
      }
    }

    if (mounted) {
      setState(() {
        _totalStudents = studentsSnapshot.docs.length;
        _highRisk = high;
        _mediumRisk = medium;
        _lowRisk = low;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text('University Admin: $_universityId'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Student Mental Health Overview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildStatCard(
                  'Total Students',
                  _totalStudents.toString(),
                  Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildStatCard('High Risk', _highRisk.toString(), Colors.red),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Medium Risk',
                  _mediumRisk.toString(),
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 40),
            const Text(
              'Risk Distribution',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      color: Colors.red,
                      value: _highRisk.toDouble(),
                      title: 'High',
                      radius: 60,
                    ),
                    PieChartSectionData(
                      color: Colors.orange,
                      value: _mediumRisk.toDouble(),
                      title: 'Med',
                      radius: 60,
                    ),
                    PieChartSectionData(
                      color: Colors.green,
                      value: _lowRisk.toDouble(),
                      title: 'Low',
                      radius: 60,
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(title, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
