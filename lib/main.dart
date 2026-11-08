
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

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
        scaffoldBackgroundColor: const Color(0xfff5f0ff),
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

  final List<Color> chartColors = [
    Colors.deepPurple,
    Colors.orange,
    Colors.green,
    Colors.blue,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  // Load expenses from local storage
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

  // Calculate total expenses
  double get total {
    return expenses.fold(
      0.0,
      (sum, item) =>
          sum + (item['amount'] as num).toDouble(),
    );
  }

  // Calculate total for each category
  double categoryTotal(String category) {
    return expenses
        .where((item) => item['category'] == category)
        .fold(
          0.0,
          (sum, item) =>
              sum + (item['amount'] as num).toDouble(),
        );
  }

  // Search and category filtering
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

  // Add or edit expense
  void showExpenseDialog({int? index}) {
    final nameController = TextEditingController(
      text: index == null ? '' : expenses[index]['name'],
    );

    final amountController = TextEditingController(
      text: index == null
          ? ''
          : expenses[index]['amount'].toString(),
    );

    String category =
        index == null ? 'Food' : expenses[index]['category'];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                index == null ? 'Add Expense' : 'Edit Expense',
              ),
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
                      if (value != null) {
                        setDialogState(() {
                          category = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final amount =
                        double.tryParse(amountController.text);

                    if (name.isEmpty ||
                        amount == null ||
                        amount <= 0) {
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

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
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

  // Delete expense
  void deleteExpense(Map<String, dynamic> expense) async {
    setState(() {
      expenses.remove(expense);
    });

    await saveExpenses();
  }

  // Pie chart
  Widget buildPieChart() {
    final chartData = categories.asMap().entries
        .where((entry) => categoryTotal(entry.value) > 0)
        .toList();

    if (chartData.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text('Add expenses to view the chart'),
        ),
      );
    }

    return SizedBox(
      height: 190,
      child: PieChart(
        PieChartData(
          sectionsSpace: 3,
          centerSpaceRadius: 35,
          sections: chartData.map((entry) {
            return PieChartSectionData(
              value: categoryTotal(entry.value),
              title: '',
              color: chartColors[entry.key],
              radius: 65,
            );
          }).toList(),
        ),
      ),
    );
  }

  // Pie chart legend
  Widget buildLegend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 10,
      children: categories.asMap().entries.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: chartColors[entry.key],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              entry.value,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  // Bar chart
  Widget buildBarChart() {
    double highestAmount = 0;

    for (String category in categories) {
      if (categoryTotal(category) > highestAmount) {
        highestAmount = categoryTotal(category);
      }
    }

    final maxValue =
        highestAmount == 0 ? 100.0 : highestAmount * 1.25;

    return SizedBox(
      height: 230,
      child: BarChart(
        BarChartData(
          maxY: maxValue,
          minY: 0,
          alignment: BarChartAlignment.spaceAround,
          barGroups: categories.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: categoryTotal(entry.value),
                  color: chartColors[entry.key],
                  width: 24,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            );
          }).toList(),

          // Hide crowded number labels on the left
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();

                  if (index < 0 || index >= categories.length) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      categories[index],
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
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
        centerTitle: true,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        onPressed: () => showExpenseDialog(),
        child: const Icon(Icons.add),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Total expenses
            Card(
              color: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Expenses',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Pie chart section
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Expense Distribution',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 12),
                    buildPieChart(),
                    const SizedBox(height: 12),
                    buildLegend(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Bar chart section
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Category-wise Spending',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 12),
                    buildBarChart(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Search bar
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search expenses by name...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.deepPurple,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    setState(() {
                      searchText = '';
                    });
                  },
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
            ),

            const SizedBox(height: 12),

            // Category filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', ...categories].map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: selectedFilter == category,
                      selectedColor: Colors.deepPurple.shade100,
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

            const SizedBox(height: 12),

            const Text(
              'Expense History',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),

            const SizedBox(height: 5),

            // Expense list
            if (filteredExpenses.isEmpty)
              const Padding(
                padding: EdgeInsets.all(25),
                child: Center(
                  child: Text('No matching expenses found'),
                ),
              )
            else
              ...filteredExpenses.map((expense) {
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      expense['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(expense['category']),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xffe5d8ff),
                      child: Icon(
                        Icons.currency_rupee,
                        color: Colors.deepPurple,
                      ),
                    ),
                    trailing: Wrap(
                      spacing: 0,
                      crossAxisAlignment: WrapCrossAlignment.center,
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
                          onPressed: () {
                            showExpenseDialog(
                              index: expenses.indexOf(expense),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () => deleteExpense(expense),
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
