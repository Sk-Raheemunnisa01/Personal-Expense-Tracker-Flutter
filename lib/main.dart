import 'package:flutter/material.dart';

// Starting point of the Flutter application
void main() {
  runApp(const PersonalExpensesTracker());
}

// Main application widget
class PersonalExpensesTracker extends StatelessWidget {
  const PersonalExpensesTracker({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Personal Expenses Tracker',

      // Home screen of the application
      home: const ExpenseHomePage(),
    );
  }
}

// Stateful widget is used because the expense list changes
class ExpenseHomePage extends StatefulWidget {
  const ExpenseHomePage({super.key});

  @override
  State<ExpenseHomePage> createState() => _ExpenseHomePageState();
}

// State of the expense home page
class _ExpenseHomePageState extends State<ExpenseHomePage> {

  // Controller to get the expense name entered by the user
  final TextEditingController expenseNameController =
      TextEditingController();

  // Controller to get the expense amount entered by the user
  final TextEditingController amountController =
      TextEditingController();

  // List to store expenses
  final List<Map<String, dynamic>> expenses = [
    {
      'name': 'Food',
      'amount': 250.0,
    },
    {
      'name': 'Transport',
      'amount': 120.0,
    },
    {
      'name': 'Shopping',
      'amount': 500.0,
    },
  ];

  // Function to add a new expense
  void addExpense() {
    // Get the values entered by the user
    String name = expenseNameController.text;
    double? amount = double.tryParse(amountController.text);

    // Check whether the input is valid
    if (name.isNotEmpty && amount != null) {
      setState(() {
        // Add the new expense to the list
        expenses.add({
          'name': name,
          'amount': amount,
        });
      });

      // Clear the text fields after adding the expense
      expenseNameController.clear();
      amountController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the total of all expenses
    double totalExpense = 0;

    for (var expense in expenses) {
      totalExpense += expense['amount'];
    }

    return Scaffold(

      // Application title bar
      appBar: AppBar(
        title: const Text('Personal Expenses Tracker'),
        centerTitle: true,
      ),

      // Main content
      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Page heading
            const Text(
              'Expense Summary',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            // Display total expenses
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [

                  // Total expense label
                  const Text(
                    'Total Expenses',
                    style: TextStyle(fontSize: 18),
                  ),

                  const SizedBox(height: 8),

                  // Display total amount
                  Text(
                    '₹${totalExpense.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Expense name input field
            TextField(
              controller: expenseNameController,
              decoration: const InputDecoration(
                labelText: 'Expense Name',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            // Expense amount input field
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixText: '₹ ',
              ),
            ),

            const SizedBox(height: 12),

            // Button to add the entered expense
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: addExpense,
                icon: const Icon(Icons.add),
                label: const Text('Add Expense'),
              ),
            ),

            const SizedBox(height: 20),

            // Recent expenses heading
            const Text(
              'Recent Expenses',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // Display the expense list
            Expanded(
              child: ListView.builder(
                itemCount: expenses.length,

                itemBuilder: (context, index) {
                  // Get the current expense
                  final expense = expenses[index];

                  return Card(
                    child: ListTile(

                      // Expense icon
                      leading: const Icon(Icons.account_balance_wallet),

                      // Expense name
                      title: Text(expense['name']),

                      // Expense amount
                      trailing: Text(
                        '₹${expense['amount'].toStringAsFixed(0)}',
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

  @override
  void dispose() {
    // Dispose controllers when the screen is removed
    expenseNameController.dispose();
    amountController.dispose();

    super.dispose();
  }
}