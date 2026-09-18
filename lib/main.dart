import 'package:flutter/material.dart';

// Starting point of the Flutter application
void main() {
  runApp(const PersonalExpensesApp());
}

// Main application widget
class PersonalExpensesApp extends StatelessWidget {
  const PersonalExpensesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Personal Expenses Tracker',

      // Creates the main screen
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Personal Expenses Tracker'),
        ),

        // Column arranges the widgets vertically
        body: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Displays the page heading
              const Text(
                'Expense Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // Row places the expense cards side by side
              Row(
                children: [
                  // First expense card
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: const [
                            Text(
                              'Total Expense',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 10),
                            Text(
                              '₹2,450',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Second expense card
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: const [
                            Text(
                              'This Month',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 10),
                            Text(
                              '₹1,850',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Displays the recent expenses heading
              const Text(
                'Recent Expenses',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              // List of recent expenses
              const ListTile(
                leading: Icon(Icons.fastfood),
                title: Text('Food'),
                trailing: Text('₹250'),
              ),

              const ListTile(
                leading: Icon(Icons.directions_bus),
                title: Text('Transport'),
                trailing: Text('₹120'),
              ),

              const ListTile(
                leading: Icon(Icons.shopping_bag),
                title: Text('Shopping'),
                trailing: Text('₹500'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}