import 'package:flutter/material.dart';
import 'models/mood_entry.dart';
import 'services/firestore_service.dart';

class CheckIn extends StatefulWidget {
  const CheckIn({Key? key}) : super(key: key);

  @override
  _CheckInState createState() => _CheckInState();
}

class _CheckInState extends State<CheckIn> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _notesController = TextEditingController();
  
  String mood = "Calm";
  String moneyFeeling = "Safe";
  bool moneyCausedStress = false;
  bool saving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void save() async {
    setState(() => saving = true);
    try {
      final entry = MoodEntry(
        mood: mood,
        moneyFeeling: moneyFeeling,
        moneyCausedStress: moneyCausedStress,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        timestamp: DateTime.now(),
      );
      
      await _firestoreService.saveMoodEntry(entry);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily check-in saved!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Daily Check-in")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            Hero(
              tag: 'checkin',
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.check_circle)),
                  title: const Text('How are you feeling today?'),
                  subtitle: Text('Mood: $mood | Money: $moneyFeeling'),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Mood Selection
            const Text('Overall Mood', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: mood,
              decoration: const InputDecoration(labelText: 'How do you feel?'),
              items: ["Calm", "Stressed", "Anxious", "Happy", "Overwhelmed"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => mood = v!),
            ),
            const SizedBox(height: 16),
            
            // Money Feeling
            const Text('Money Feeling', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: moneyFeeling,
              decoration: const InputDecoration(labelText: 'How do you feel about money?'),
              items: ["Safe", "Worried", "Guilty", "Confident", "Anxious"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => moneyFeeling = v!),
            ),
            const SizedBox(height: 16),
            
            // Money Stress Toggle
            SwitchListTile(
              title: const Text('Did money cause you stress today?'),
              subtitle: const Text('This helps us understand your triggers'),
              value: moneyCausedStress,
              onChanged: (v) => setState(() => moneyCausedStress = v),
            ),
            const SizedBox(height: 16),
            
            // Optional Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Anything specific on your mind?',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: saving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: save,
                      child: const Text("Save Check-in"),
                    ),
            )
          ]),
        ));
  }
}
