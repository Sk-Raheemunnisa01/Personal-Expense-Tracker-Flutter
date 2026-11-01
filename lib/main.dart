
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const ExpenseHomePage(),
    );
  }
}

class ExpenseHomePage extends StatefulWidget {
  const ExpenseHomePage({super.key});

  @override
  State<ExpenseHomePage> createState() => _ExpenseHomePageState();
}

class _ExpenseHomePageState extends State<ExpenseHomePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  List<Map<String, dynamic>> expenses = [];

  String selectedCategory = 'Food';
  DateTime selectedDate = DateTime.now();

  bool isLoading = true;

  final List<String> categories = [
    'Food',
    'Transport',
    'Shopping',
    'Education',
    'Other',
  ];

  // Load saved expenses from local storage.
  Future<void> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString('expenses');

    if (savedData != null) {
      List<dynamic> decodedData = jsonDecode(savedData);

      setState(() {
        expenses = decodedData.map((item) {
          return Map<String, dynamic>.from(item);
        }).toList();
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  // Save expenses in local storage.
  Future<void> saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();

    String encodedData = jsonEncode(expenses);
    await prefs.setString('expenses', encodedData);
  }

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    super.dispose();
  }

  double get totalExpense {
    double total = 0;

    for (var expense in expenses) {
      total += (expense['amount'] as num).toDouble();
    }

    return total;
  }

  // Calculate category-wise expenses.
  double categoryTotal(String category) {
    double total = 0;

    for (var expense in expenses) {
      if (expense['category'] == category) {
        total += (expense['amount'] as num).toDouble();
      }
    }

    return total;
  }

  // Add a new expense.
  void addExpense() {
    String name = nameController.text.trim();
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
        'date': selectedDate.toIso8601String(),
      });

      nameController.clear();
      amountController.clear();
      selectedDate = DateTime.now();
    });

    saveExpenses();
  }

  // Select date.
  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // Delete an expense.
  void deleteExpense(int index) {
    setState(() {
      expenses.removeAt(index);
    });

    saveExpenses();
  }

  // Edit an expense.
  void editExpense(int index) {
    final expense = expenses[index];

    TextEditingController editNameController =
        TextEditingController(text: expense['name']);

    TextEditingController editAmountController =
        TextEditingController(text: expense['amount'].toString());

    String editCategory = expense['category'];
    DateTime editDate = DateTime.parse(expense['date']);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, updateDialog) {
            return AlertDialog(
              title: const Text('Edit Expense'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: editNameController,
                      decoration: const InputDecoration(
                        labelText: 'Expense Name',
                      ),
                    ),
                    TextField(
                      controller: editAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: editCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        updateDialog(() {
                          editCategory = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: editDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );

                        if (picked != null) {
                          updateDialog(() {
                            editDate = picked;
                          });
                        }
                      },
                      child: Text(
                        'Date: ${editDate.day}/${editDate.month}/${editDate.year}',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    editNameController.dispose();
                    editAmountController.dispose();
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    String name = editNameController.text.trim();
                    double? amount =
                        double.tryParse(editAmountController.text);

                    if (name.isEmpty || amount == null || amount <= 0) {
                      return;
                    }

                    setState(() {
                      expenses[index] = {
                        'name': name,
                        'amount': amount,
                        'category': editCategory,
                        'date': editDate.toIso8601String(),
                      };
                    });

                    saveExpenses();

                    editNameController.dispose();
                    editAmountController.dispose();
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Display category-wise summary.
  Widget buildCategorySummary(String category, IconData icon) {
    double amount = categoryTotal(category);

    double percentage =
        totalExpense == 0 ? 0 : amount / totalExpense;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.deepPurple),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '₹${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: Colors.deepPurple.shade100,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${(percentage * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(
        title: const Text('Personal Expenses Tracker'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total expense card.
                  Card(
                    color: Colors.deepPurple,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'Total Expenses',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${totalExpense.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Number of Expenses: ${expenses.length}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Add Expense',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Expense Name',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
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

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        ),
                      ),
                      TextButton(
                        onPressed: pickDate,
                        child: const Text('Select Date'),
                      ),
                    ],
                  ),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: addExpense,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Add Expense'),
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'Category-wise Summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  buildCategorySummary('Food', Icons.restaurant),
                  buildCategorySummary('Transport', Icons.directions_bus),
                  buildCategorySummary('Shopping', Icons.shopping_bag),
                  buildCategorySummary('Education', Icons.school),
                  buildCategorySummary('Other', Icons.category),

                  const SizedBox(height: 20),

                  const Text(
                    'Expense History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (expenses.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No expenses added yet'),
                      ),
                    ),

                  // Display all expenses.
                  ...List.generate(expenses.length, (index) {
                    final expense = expenses[index];
                    DateTime date = DateTime.parse(expense['date']);

                    return Card(
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
                          '${date.day}/${date.month}/${date.year}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹${(expense['amount'] as num).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.blue,
                              ),
                              onPressed: () => editExpense(index),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () => deleteExpense(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
