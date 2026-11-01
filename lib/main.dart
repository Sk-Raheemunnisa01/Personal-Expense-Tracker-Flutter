import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// Main application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Personal Expenses Tracker',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const ExpensePage(),
    );
  }
}

// Expense page
class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  String selectedCategory = 'Food';
  DateTime selectedDate = DateTime.now();

  // Available expense categories
  final List<String> categories = [
    'Food',
    'Transport',
    'Shopping',
    'Education',
    'Other',
  ];

  // Store expense details
  final List<Map<String, dynamic>> expenses = [];

  double get totalExpense {
    double total = 0;

    for (var expense in expenses) {
      total += expense['amount'];
    }

    return total;
  }

  // Select expense date
  Future<void> selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  // Add expense to the list
  void addExpense() {
    String name = nameController.text;
    double? amount = double.tryParse(amountController.text);

    if (name.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid name and amount'),
        ),
      );
      return;
    }

    setState(() {
      expenses.add({
        'name': name,
        'amount': amount,
        'category': selectedCategory,
        'date': selectedDate,
      });

      nameController.clear();
      amountController.clear();
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade50,

      // App bar
      appBar: AppBar(
        title: const Text('Personal Expenses Tracker'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            // Expense name field
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Expense Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
              ),
            ),

            const SizedBox(height: 12),

            // Expense amount field
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
            ),

            const SizedBox(height: 12),

            // Category selection
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Select Category',
                border: OutlineInputBorder(),
              ),
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
            ),

            const SizedBox(height: 12),

            // Date selection button
            OutlinedButton.icon(
              onPressed: selectDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(
                'Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
              ),
            ),

            const SizedBox(height: 12),

            // Add expense button
            ElevatedButton.icon(
              onPressed: addExpense,
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // Display total expense
            Text(
              'Total Expense: ₹${totalExpense.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),

            const Divider(height: 24),

            // Display expense list
            Expanded(
              child: expenses.isEmpty
                  ? const Center(
                      child: Text('No expenses added yet!'),
                    )
                  : ListView.builder(
                      itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        final expense = expenses[index];

                        return Card(
                          color: Colors.white,
                          elevation: 3,
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.deepPurple,
                              child: Icon(
                                Icons.currency_rupee,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(expense['name']),
                            subtitle: Text(
                              '${expense['category']} • '
                              '${expense['date'].day}/'
                              '${expense['date'].month}/'
                              '${expense['date'].year}',
                            ),
                            trailing: Text(
                              '₹${expense['amount'].toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}