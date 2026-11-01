import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Personal Expenses Tracker',
      home: const ExpensePage(),
    );
  }
}

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

  final List<String> categories = [
    'Food',
    'Transport',
    'Shopping',
    'Education',
    'Other',
  ];

  // Store expense details
  final List<Map<String, dynamic>> expenses = [];

  // Calculate total expense
  double get totalExpense {
    double total = 0;

    for (var expense in expenses) {
      total += expense['amount'];
    }

    return total;
  }

  // Add a new expense
  void addExpense() {
    String name = nameController.text;
    double? amount = double.tryParse(amountController.text);

    if (name.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid expense details'),
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

  // Delete an expense
  void deleteExpense(int index) {
    setState(() {
      expenses.removeAt(index);
    });
  }

  // Select date
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
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Expense Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
              ),
            ),

            const SizedBox(height: 12),

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

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: selectDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(
                'Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: addExpense,
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              'Total Expense: ₹${totalExpense.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),

            const Divider(height: 25),

            // Display expense list with delete option
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
                              '${expense['category']} - '
                              '${expense['date'].day}/'
                              '${expense['date'].month}/'
                              '${expense['date'].year}',
                            ),

                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '₹${expense['amount'].toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                // Delete button
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    deleteExpense(index);
                                  },
                                ),
                              ],
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