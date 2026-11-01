
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const ExpenseApp());
}

class ExpenseApp extends StatelessWidget {
  const ExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Personal Expenses Tracker',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xfff3edff),
      ),
      home: const ExpenseHome(),
    );
  }
}

class ExpenseHome extends StatefulWidget {
  const ExpenseHome({super.key});

  @override
  State<ExpenseHome> createState() => _ExpenseHomeState();
}

class _ExpenseHomeState extends State<ExpenseHome> {
  List<Map<String, dynamic>> expenses = [];

  String selectedFilter = 'All';
  String searchText = '';

  final TextEditingController searchController =
      TextEditingController();

  final List<String> categories = [
    'Food',
    'Transport',
    'Shopping',
    'Education',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  // Load saved expenses
  Future<void> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('expenses');

    if (savedData != null) {
      setState(() {
        expenses = List<Map<String, dynamic>>.from(
          jsonDecode(savedData).map(
            (item) => Map<String, dynamic>.from(item),
          ),
        );
      });
    }
  }

  // Save expenses
  Future<void> saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('expenses', jsonEncode(expenses));
  }

  double get total {
    return expenses.fold(
      0,
      (sum, item) => sum + (item['amount'] as num).toDouble(),
    );
  }

  // Filter expenses by category and search text
  List<Map<String, dynamic>> get filteredExpenses {
    return expenses.where((expense) {
      final matchesCategory = selectedFilter == 'All' ||
          expense['category'] == selectedFilter;

      final matchesSearch = expense['name']
          .toString()
          .toLowerCase()
          .contains(searchText.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();
  }

  void showExpenseDialog({int? index}) {
    final nameController = TextEditingController(
      text: index == null ? '' : expenses[index]['name'],
    );

    final amountController = TextEditingController(
      text: index == null
          ? ''
          : expenses[index]['amount'].toString(),
    );

    String category = index == null
        ? 'Food'
        : expenses[index]['category'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(index == null ? 'Add Expense' : 'Edit Expense'),
              content: Column(
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
                  DropdownButton<String>(
                    value: category,
                    isExpanded: true,
                    items: categories.map((item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        category = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final amount =
                        double.tryParse(amountController.text);

                    if (name.isEmpty || amount == null || amount <= 0) {
                      return;
                    }

                    setState(() {
                      final item = {
                        'name': name,
                        'amount': amount,
                        'category': category,
                      };

                      if (index == null) {
                        expenses.add(item);
                      } else {
                        expenses[index] = item;
                      }
                    });

                    await saveExpenses();

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
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

  void deleteExpense(int index) async {
    final item = filteredExpenses[index];

    setState(() {
      expenses.remove(item);
    });

    await saveExpenses();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Expenses Tracker'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        onPressed: () => showExpenseDialog(),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Total expense card
            Card(
              color: Colors.deepPurple,
              child: ListTile(
                title: const Text(
                  'Total Expenses',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '₹${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Search bar
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search expenses by name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    setState(() {
                      searchText = '';
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
            ),

            const SizedBox(height: 10),

            // Category filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', ...categories].map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: selectedFilter == category,
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

            const SizedBox(height: 10),

            const Text(
              'Expense History',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Search and category filtered results
            Expanded(
              child: filteredExpenses.isEmpty
                  ? const Center(
                      child: Text('No matching expenses found'),
                    )
                  : ListView.builder(
                      itemCount: filteredExpenses.length,
                      itemBuilder: (context, index) {
                        final expense = filteredExpenses[index];

                        return Card(
                          child: ListTile(
                            title: Text(expense['name']),
                            subtitle: Text(
                              expense['category'],
                            ),
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xffe5d8ff),
                              child: Icon(
                                Icons.currency_rupee,
                                color: Colors.deepPurple,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '₹${expense['amount']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () =>
                                      showExpenseDialog(index: expenses.indexOf(expense)),
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
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
