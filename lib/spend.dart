import 'package:flutter/material.dart';
import 'models/spending_entry.dart';
import 'services/firestore_service.dart';

class Spend extends StatefulWidget {
  const Spend({Key? key}) : super(key: key);

  @override
  _SpendState createState() => _SpendState();
}

class _SpendState extends State<Spend> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  String category = "Food";
  String emotion = "Neutral";
  bool isPlanned = true;
  bool saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void save() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => saving = true);
    try {
      final entry = SpendingEntry(
        amount: amount,
        category: category,
        emotion: emotion,
        isPlanned: isPlanned,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        timestamp: DateTime.now(),
      );
      
      await _firestoreService.saveSpendingEntry(entry);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense saved!')),
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
        appBar: AppBar(title: const Text("Add Expense")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            Hero(
              tag: 'spend',
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.attach_money)),
                  title: const Text('Record an expense'),
                  subtitle: Text('$category - ${isPlanned ? "Planned" : "Unplanned"}'),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Amount Field
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Amount",
                prefixText: "₹ ",
                hintText: "Enter amount",
              ),
            ),
            const SizedBox(height: 16),
            
            // Category Dropdown
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                "Food",
                "Travel",
                "Shopping",
                "Entertainment",
                "Bills",
                "Education",
                "Social",
                "Other"
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => category = v!),
            ),
            const SizedBox(height: 16),
            
            // Planned/Unplanned Toggle
            SwitchListTile(
              title: const Text('Was this expense planned?'),
              subtitle: Text(isPlanned ? 'Budgeted expense' : 'Impulse/Unplanned'),
              value: isPlanned,
              onChanged: (v) => setState(() => isPlanned = v),
            ),
            const SizedBox(height: 16),
            
            // Emotion Dropdown
            DropdownButtonFormField<String>(
              value: emotion,
              decoration: const InputDecoration(
                labelText: 'How did you feel while spending?',
                helperText: 'Understanding emotions helps identify patterns',
              ),
              items: [
                "Neutral",
                "Happy",
                "Stress",
                "Guilt",
                "Anxiety",
                "FOMO",
                "Regret",
                "Confident"
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => emotion = v!),
            ),
            const SizedBox(height: 16),
            
            // Optional Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'What did you buy?',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: saving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: save,
                      child: const Text("Save Expense"),
                    ),
            )
          ]),
        ));
  }
}
