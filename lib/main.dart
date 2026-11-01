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

  bool isLoading = true;

  final List<String> categories = [
    'Food',
    'Transport',
    'Shopping',
    'Education',
    'Other',
  ];

  List<Map<String, dynamic>> expenses = [];

  // Calculate total expense
  double get totalExpense {
    double total = 0;

    for (var expense in expenses) {
      total += (expense['amount'] as num).toDouble();
    }

    return total;
  }

  // Save expenses in local storage
  Future<void> saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();

    String data = jsonEncode(expenses);

    await prefs.setString('expenses', data);
  }

  // Load saved expenses
  Future<void> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();

    String? data = prefs.getString('expenses');

    if (data != null) {
      List decodedData = jsonDecode(data);

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

  // Add expense
  Future<void> addExpense() async {
    String name = nameController.text.trim();
    double? amount = double.tryParse(amountController.text);

    if (name.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid expense details')),
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
    });

    await saveExpenses();
  }

  // Delete expense
  Future<void> deleteExpense(int index) async {
    setState(() {
      expenses.removeAt(index);
    });

    await saveExpenses();
  }

  // Edit expense
  void editExpense(int index) {
    final expense = expenses[index];

    final editNameController =
        TextEditingController(text: expense['name']);

    final editAmountController =
        TextEditingController(text: expense['amount'].toString());

    String editCategory = expense['category'];
    DateTime editDate = DateTime.parse(expense['date']);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                        if (value != null) {
                          setDialogState(() {
                            editCategory = value;
                          });
                        }
                      },
                    ),

                    TextButton.icon(
                      onPressed: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: editDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );

                        if (pickedDate != null) {
                          setDialogState(() {
                            editDate = pickedDate;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        '${editDate.day}/${editDate.month}/${editDate.year}',
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
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () async {
                    String name = editNameController.text.trim();
                    double? amount =
                        double.tryParse(editAmountController.text);

                    if (name.isEmpty || amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enter valid details'),
                        ),
                      );
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

                    await saveExpenses();

                    editNameController.dispose();
                    editAmountController.dispose();

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
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

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                      if (value != null) {
                        setState(() {
                          selectedCategory = value;
                        });
                      }
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

                  Expanded(
                    child: expenses.isEmpty
                        ? const Center(
                            child: Text('No expenses added yet!'),
                          )
                        : ListView.builder(
                            itemCount: expenses.length,
                            itemBuilder: (context, index) {
                              final expense = expenses[index];

                              final date =
                                  DateTime.parse(expense['date']);

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
                                        onPressed: () {
                                          editExpense(index);
                                        },
                                      ),

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