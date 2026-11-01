
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
      home: const ExpenseDashboard(),
    );
  }
}

class ExpenseDashboard extends StatefulWidget {
  const ExpenseDashboard({super.key});

  @override
  State<ExpenseDashboard> createState() => _ExpenseDashboardState();
}

class _ExpenseDashboardState extends State<ExpenseDashboard> {
  List<Map<String, dynamic>> expenses = [];
  bool isLoading = true;

  String selectedFilter = 'All';

  final List<String> categories = [
    'All',
    'Food',
    'Transport',
    'Shopping',
    'Education',
    'Other',
  ];

  final Map<String, IconData> categoryIcons = {
    'Food': Icons.restaurant,
    'Transport': Icons.directions_bus,
    'Shopping': Icons.shopping_bag,
    'Education': Icons.school,
    'Other': Icons.category,
  };

  final Map<String, Color> categoryColors = {
    'Food': Colors.orange,
    'Transport': Colors.blue,
    'Shopping': Colors.deepPurple,
    'Education': Colors.green,
    'Other': Colors.pink,
  };

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  // Load saved expenses.
  Future<void> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString('expenses');

    if (savedData != null) {
      List<dynamic> decoded = jsonDecode(savedData);

      expenses = decoded.map((item) {
        return Map<String, dynamic>.from(item);
      }).toList();
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  // Save expenses locally.
  Future<void> saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('expenses', jsonEncode(expenses));
  }

  // Calculate total expense.
  double get totalExpense {
    double total = 0;

    for (var expense in expenses) {
      total += (expense['amount'] as num).toDouble();
    }

    return total;
  }

  // Calculate category-wise amount.
  double categoryTotal(String category) {
    double total = 0;

    for (var expense in expenses) {
      if (expense['category'] == category) {
        total += (expense['amount'] as num).toDouble();
      }
    }

    return total;
  }

  // Filter expenses based on selected category.
  List<Map<String, dynamic>> get filteredExpenses {
    if (selectedFilter == 'All') {
      return expenses;
    }

    return expenses.where((expense) {
      return expense['category'] == selectedFilter;
    }).toList();
  }

  // Add a new expense.
  void addExpense() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();

    String selectedCategory = 'Food';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, updateDialog) {
            return AlertDialog(
              title: const Text('Add New Expense'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Expense Name',
                      ),
                    ),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                      ),
                      items: categories.where((c) => c != 'All').map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        );
                      }).toList(),
                      onChanged: (value) {
                        updateDialog(() {
                          selectedCategory = value!;
                        });
                      },
                    ),
                    TextButton(
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );

                        if (picked != null) {
                          updateDialog(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Text(
                        'Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    nameController.dispose();
                    amountController.dispose();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    String name = nameController.text.trim();
                    double? amount =
                        double.tryParse(amountController.text);

                    if (name.isEmpty || amount == null || amount <= 0) {
                      return;
                    }

                    setState(() {
                      expenses.add({
                        'name': name,
                        'amount': amount,
                        'category': selectedCategory,
                        'date': selectedDate.toIso8601String(),
                      });
                    });

                    saveExpenses();

                    Navigator.pop(dialogContext);
                    nameController.dispose();
                    amountController.dispose();
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Edit an expense.
  void editExpense(int index) {
    final expense = expenses[index];

    final nameController =
        TextEditingController(text: expense['name']);
    final amountController =
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
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Expense Name',
                      ),
                    ),
                    TextField(
                      controller: amountController,
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
                      items: categories.where((c) => c != 'All').map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        );
                      }).toList(),
                      onChanged: (value) {
                        updateDialog(() {
                          editCategory = value!;
                        });
                      },
                    ),
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
                    Navigator.pop(dialogContext);
                    nameController.dispose();
                    amountController.dispose();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    String name = nameController.text.trim();
                    double? amount =
                        double.tryParse(amountController.text);

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

                    Navigator.pop(dialogContext);
                    nameController.dispose();
                    amountController.dispose();
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

  // Delete an expense.
  void deleteExpense(int index) {
    setState(() {
      expenses.removeAt(index);
    });

    saveExpenses();
  }

  // Display category summary.
  Widget categoryCard(String category) {
    double amount = categoryTotal(category);
    double percentage =
        totalExpense == 0 ? 0 : amount / totalExpense;

    Color color = categoryColors[category]!;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: color.withAlpha(35),
              child: Icon(
                categoryIcons[category],
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('₹${amount.toStringAsFixed(0)}'),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: percentage,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Display an expense item.
  Widget expenseItem(Map<String, dynamic> expense) {
    int actualIndex = expenses.indexOf(expense);
    DateTime date = DateTime.parse(expense['date']);
    String category = expense['category'];

    return Card(
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 17,
          backgroundColor:
              categoryColors[category]!.withAlpha(35),
          child: Icon(
            categoryIcons[category],
            color: categoryColors[category],
            size: 18,
          ),
        ),
        title: Text(expense['name']),
        subtitle: Text(
          '$category • ${date.day}/${date.month}/${date.year}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹${(expense['amount'] as num).toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 19),
              onPressed: () => editExpense(actualIndex),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 19),
              onPressed: () => deleteExpense(actualIndex),
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
        title: const Text('Personal Expenses'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: addExpense,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total expense card.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Total Expenses',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '₹${totalExpense.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${expenses.length} expenses recorded',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Category-wise Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    ...categories
                        .where((category) => category != 'All')
                        .map(categoryCard),

                    const SizedBox(height: 8),

                    const Text(
                      'Expense History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Category filter buttons.
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.map((category) {
                          bool isSelected =
                              selectedFilter == category;

                          return Padding(
                            padding: const EdgeInsets.only(right: 7),
                            child: ChoiceChip(
                              label: Text(category),
                              selected: isSelected,
                              selectedColor: Colors.deepPurple,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.deepPurple,
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  selectedFilter = category;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Filtered expense list.
                    Expanded(
                      child: filteredExpenses.isEmpty
                          ? const Center(
                              child: Text('No expenses in this category'),
                            )
                          : ListView.builder(
                              itemCount: filteredExpenses.length,
                              itemBuilder: (context, index) {
                                return expenseItem(
                                  filteredExpenses[
                                      filteredExpenses.length - 1 - index],
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: addExpense,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
