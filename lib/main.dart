
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
  DateTime? selectedDate;

  double monthlyBudget = 5000;

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

  String get currentMonth {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String monthOf(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  DateTime dateOf(Map<String, dynamic> expense) {
    return DateTime.tryParse(
          expense['date']?.toString() ?? '',
        ) ??
        DateTime.now();
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // Load expenses and budget
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('expenses');

    List<Map<String, dynamic>> loaded = [];

    if (savedData != null) {
      loaded = List<Map<String, dynamic>>.from(
        jsonDecode(savedData).map(
          (item) => Map<String, dynamic>.from(item),
        ),
      );

      // Add dates to older expense records
      for (var expense in loaded) {
        if (expense['date'] == null) {
          expense['date'] = DateTime.now().toIso8601String();
        }
        expense['month'] ??= monthOf(dateOf(expense));
      }
    }

    setState(() {
      expenses = loaded;
      monthlyBudget = prefs.getDouble('monthlyBudget') ?? 5000;
    });

    await saveExpenses();
  }

  // Save expenses
  Future<void> saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('expenses', jsonEncode(expenses));
  }

  // Save budget
  Future<void> saveBudget() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthlyBudget', monthlyBudget);
  }

  double get total {
    return expenses.fold(
      0.0,
      (sum, item) =>
          sum + (item['amount'] as num).toDouble(),
    );
  }

  double get monthlySpending {
    return expenses
        .where((item) => item['month'] == currentMonth)
        .fold(
          0.0,
          (sum, item) =>
              sum + (item['amount'] as num).toDouble(),
        );
  }

  double get remainingBudget => monthlyBudget - monthlySpending;

  double get budgetProgress {
    if (monthlyBudget <= 0) return 0;
    return (monthlySpending / monthlyBudget).clamp(0.0, 1.0);
  }

  double categoryTotal(String category) {
    return expenses
        .where((item) => item['category'] == category)
        .fold(
          0.0,
          (sum, item) =>
              sum + (item['amount'] as num).toDouble(),
        );
  }

  // Search, category and date filtering
  List<Map<String, dynamic>> get filteredExpenses {
    return expenses.where((expense) {
      final matchesCategory = selectedFilter == 'All' ||
          expense['category'] == selectedFilter;

      final matchesSearch = expense['name']
          .toString()
          .toLowerCase()
          .contains(searchText.toLowerCase());

      final expenseDate = dateOf(expense);

      final matchesDate = selectedDate == null ||
          (expenseDate.year == selectedDate!.year &&
              expenseDate.month == selectedDate!.month &&
              expenseDate.day == selectedDate!.day);

      return matchesCategory && matchesSearch && matchesDate;
    }).toList()
      ..sort((a, b) => dateOf(b).compareTo(dateOf(a)));
  }

  // Select expense date
  Future<DateTime?> pickExpenseDate(DateTime initialDate) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
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

    DateTime expenseDate = index == null
        ? DateTime.now()
        : dateOf(expenses[index]);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                index == null ? 'Add Expense' : 'Edit Expense',
              ),
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
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_month),
                      label: Text(formatDate(expenseDate)),
                      onPressed: () async {
                        final picked =
                            await pickExpenseDate(expenseDate);

                        if (picked != null) {
                          setDialogState(() {
                            expenseDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
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
                        'date': expenseDate.toIso8601String(),
                        'month': monthOf(expenseDate),
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

  // Change monthly budget
  void showBudgetDialog() {
    final controller = TextEditingController(
      text: monthlyBudget.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Set Monthly Budget'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Budget Amount',
              prefixText: '₹ ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final value = double.tryParse(controller.text);
                if (value == null || value <= 0) return;

                setState(() {
                  monthlyBudget = value;
                });

                await saveBudget();

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
  }

  // Monthly budget card
  Widget buildBudgetCard() {
    final exceeded = monthlySpending > monthlyBudget;
    final warning = budgetProgress >= 0.8 && !exceeded;

    final statusColor = exceeded
        ? Colors.red
        : warning
            ? Colors.orange
            : Colors.green;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Monthly Budget',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: showBudgetDialog,
                  icon: const Icon(Icons.edit),
                ),
              ],
            ),
            Text(
              '₹${monthlySpending.toStringAsFixed(2)} spent this month',
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: budgetProgress,
                minHeight: 13,
                backgroundColor: Colors.deepPurple.shade100,
                valueColor:
                    AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Budget: ₹${monthlyBudget.toStringAsFixed(0)}'),
                Text(
                  exceeded
                      ? 'Over by ₹${(-remainingBudget).toStringAsFixed(0)}'
                      : 'Left: ₹${remainingBudget.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              exceeded
                  ? 'Budget exceeded! Reduce your spending.'
                  : warning
                      ? 'Warning! You have used 80% or more.'
                      : 'You are within your monthly budget.',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Pie chart
  Widget buildPieChart() {
    final data = categories.asMap().entries
        .where((entry) => categoryTotal(entry.value) > 0)
        .toList();

    if (data.isEmpty) {
      return const SizedBox(
        height: 170,
        child: Center(child: Text('Add expenses to view chart')),
      );
    }

    return SizedBox(
      height: 180,
      child: PieChart(
        PieChartData(
          sectionsSpace: 3,
          centerSpaceRadius: 35,
          sections: data.map((entry) {
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

  // Chart legend
  Widget buildLegend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: categories.asMap().entries.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: chartColors[entry.key],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(entry.value, style: const TextStyle(fontSize: 12)),
          ],
        );
      }).toList(),
    );
  }

  // Bar chart
  Widget buildBarChart() {
    double highest = 0;

    for (String category in categories) {
      if (categoryTotal(category) > highest) {
        highest = categoryTotal(category);
      }
    }

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: highest == 0 ? 100 : highest * 1.25,
          minY: 0,
          alignment: BarChartAlignment.spaceAround,
          barGroups: categories.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: categoryTotal(entry.value),
                  color: chartColors[entry.key],
                  width: 23,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            );
          }).toList(),
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
                      style: const TextStyle(fontSize: 10),
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

  // Daily total
  double dailyTotal(DateTime date) {
    return expenses.where((item) {
      final d = dateOf(item);
      return d.year == date.year &&
          d.month == date.month &&
          d.day == date.day;
    }).fold(
      0.0,
      (sum, item) => sum + (item['amount'] as num).toDouble(),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredExpenses;

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
            // Overall total
            Card(
              color: Colors.deepPurple,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Expenses',
                      style: TextStyle(color: Colors.white70),
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

            buildBudgetCard(),

            // Pie chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
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
                    buildPieChart(),
                    buildLegend(),
                  ],
                ),
              ),
            ),

            // Bar chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
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
                    buildBarChart(),
                  ],
                ),
              ),
            ),

            // Search field
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search expenses by name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    setState(() => searchText = '');
                  },
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => searchText = value);
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
                      onSelected: (selected) {
                        setState(() => selectedFilter = category);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 10),

            // Date filter
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Expense History',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    selectedDate == null
                        ? 'Choose date'
                        : formatDate(selectedDate!),
                  ),
                  onPressed: () async {
                    final picked = await pickExpenseDate(
                      selectedDate ?? DateTime.now(),
                    );

                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                ),
                if (selectedDate != null)
                  IconButton(
                    tooltip: 'Clear date filter',
                    onPressed: () {
                      setState(() => selectedDate = null);
                    },
                    icon: const Icon(Icons.clear),
                  ),
              ],
            ),

            // Daily grouped expenses
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(25),
                child: Center(
                  child: Text('No matching expenses found'),
                ),
              )
            else
              ...filtered.map((expense) {
                final date = dateOf(expense);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (filtered.indexOf(expense) == 0 ||
                        dateOf(filtered[filtered.indexOf(expense) - 1])
                                .day !=
                            date.day ||
                        dateOf(filtered[filtered.indexOf(expense) - 1])
                                .month !=
                            date.month ||
                        dateOf(filtered[filtered.indexOf(expense) - 1])
                                .year !=
                            date.year)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 12,
                          bottom: 4,
                          left: 5,
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formatDate(date),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            Text(
                              'Daily total: ₹${dailyTotal(date).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Card(
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
                          crossAxisAlignment:
                              WrapCrossAlignment.center,
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
                    ),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }
}
