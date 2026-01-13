import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../dashboard.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final FirestoreService _firestoreService = FirestoreService();
  int _currentPage = 0;

  // Onboarding data
  String _incomeSource = 'Family Support';
  String _livingSituation = 'Hostel';
  String _monthlySpendRange = '5000-10000';
  final List<String> _stressTriggers = [];
  final List<String> _moneyEmotions = [];

  bool _saving = false;

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _saveProfile();
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    
    final profile = UserProfile(
      incomeSource: _incomeSource,
      livingSituation: _livingSituation,
      monthlySpendRange: _monthlySpendRange,
      stressTriggers: _stressTriggers,
      moneyEmotions: _moneyEmotions,
      createdAt: DateTime.now(),
    );

    try {
      await _firestoreService.saveProfile(profile);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Dashboard()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to MoneyMind AI'),
        elevation: 0,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_currentPage + 1) / 5),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _buildIncomePage(),
                _buildLivingPage(),
                _buildSpendRangePage(),
                _buildStressTriggersPage(),
                _buildMoneyEmotionsPage(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  TextButton(
                    onPressed: _previousPage,
                    child: const Text('Back'),
                  )
                else
                  const SizedBox(),
                ElevatedButton(
                  onPressed: _saving ? null : _nextPage,
                  child: _saving
                      ? const CircularProgressIndicator()
                      : Text(_currentPage == 4 ? 'Finish' : 'Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomePage() {
    return _buildPage(
      title: 'Where does your money come from?',
      subtitle: 'This helps us understand your financial situation',
      child: Column(
        children: [
          'Family Support',
          'Allowance',
          'Part-time Job',
          'Scholarship',
          'Loan',
        ].map((option) {
          return RadioListTile<String>(
            title: Text(option),
            value: option,
            groupValue: _incomeSource,
            onChanged: (value) => setState(() => _incomeSource = value!),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLivingPage() {
    return _buildPage(
      title: 'Where do you live?',
      subtitle: 'Your living situation affects your expenses',
      child: Column(
        children: [
          'Hostel',
          'Home',
          'PG',
          'Rented Apartment',
        ].map((option) {
          return RadioListTile<String>(
            title: Text(option),
            value: option,
            groupValue: _livingSituation,
            onChanged: (value) => setState(() => _livingSituation = value!),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSpendRangePage() {
    return _buildPage(
      title: 'How much do you spend monthly?',
      subtitle: 'Rough estimate is fine',
      child: Column(
        children: [
          'Less than ₹5,000',
          '₹5,000 - ₹10,000',
          '₹10,000 - ₹20,000',
          'More than ₹20,000',
        ].map((option) {
          return RadioListTile<String>(
            title: Text(option),
            value: option,
            groupValue: _monthlySpendRange,
            onChanged: (value) => setState(() => _monthlySpendRange = value!),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStressTriggersPage() {
    final triggers = [
      'Exams', 
      'Social Pressure', 
      'Bills', 
      'Impulse Shopping', 
      'Family Expectations',
      'Tuition Fees',
      'Peer Pressure'
    ];
    
    return _buildPage(
      title: 'What causes you financial stress?',
      subtitle: 'Select all that apply',
      child: Column(
        children: triggers.map((trigger) {
          return CheckboxListTile(
            title: Text(trigger),
            value: _stressTriggers.contains(trigger),
            onChanged: (checked) {
              setState(() {
                if (checked == true) {
                  _stressTriggers.add(trigger);
                } else {
                  _stressTriggers.remove(trigger);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMoneyEmotionsPage() {
    final emotions = [
      'Anxiety', 
      'Guilt', 
      'Avoidance', 
      'Shame', 
      'Confidence', 
      'Financial Insecurity',
      'Fear of Missing Out (FOMO)'
    ];
    
    return _buildPage(
      title: 'How do you feel about money?',
      subtitle: 'Select all that resonate with you',
      child: Column(
        children: emotions.map((emotion) {
          return CheckboxListTile(
            title: Text(emotion),
            value: _moneyEmotions.contains(emotion),
            onChanged: (checked) {
              setState(() {
                if (checked == true) {
                  _moneyEmotions.add(emotion);
                } else {
                  _moneyEmotions.remove(emotion);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
