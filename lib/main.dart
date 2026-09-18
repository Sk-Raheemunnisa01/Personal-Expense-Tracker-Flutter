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

// Stateful widget is used because the expense amount changes
class ExpenseHomePage extends StatefulWidget {
  const ExpenseHomePage({super.key});

  @override
  State<ExpenseHomePage> createState() => _ExpenseHomePageState();
}

// State of the expense home page
class _ExpenseHomePageState extends State<ExpenseHomePage> {

  // Initial total expense
  double totalExpense = 2450;

  // Function to add a new expense
  void addExpense() {
    setState(() {
      // Increase the total expense by ₹250
      totalExpense += 250;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // Application title bar
      appBar: AppBar(
        title: const Text('Personal Expenses Tracker'),
        centerTitle: true,
      ),

      // Main content of the application
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Expense summary heading
            const Text(
              'Expense Summary',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            // Container displaying total expenses
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

                  // Display current total expense
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

            // Recent expenses heading
            const Text(
              'Recent Expenses',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // Food expense
            const Card(
              child: ListTile(
                leading: Icon(Icons.fastfood),
                title: Text('Food'),
                subtitle: Text('Lunch'),
                trailing: Text('₹250'),
              ),
            ),

            // Transport expense
            const Card(
              child: ListTile(
                leading: Icon(Icons.directions_bus),
                title: Text('Transport'),
                subtitle: Text('Bus'),
                trailing: Text('₹120'),
              ),
            ),

            // Shopping expense
            const Card(
              child: ListTile(
                leading: Icon(Icons.shopping_bag),
                title: Text('Shopping'),
                subtitle: Text('Clothes'),
                trailing: Text('₹500'),
              ),
            ),

            // Takes the remaining available space
            const Spacer(),

            // Add Expense button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: addExpense,
                icon: const Icon(Icons.add),
                label: const Text('Add Expense'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}