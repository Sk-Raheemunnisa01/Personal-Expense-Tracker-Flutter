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
    // MaterialApp provides the basic Flutter app structure
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Personal Expenses Tracker',

      // Scaffold provides the basic screen layout
      home: Scaffold(
        // AppBar displays the title at the top
        appBar: AppBar(
          title: const Text('Personal Expenses Tracker'),
        ),

        // Center places the content in the middle of the screen
        body: Center(
          // Column arranges widgets vertically
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Displays the main heading
              const Text(
                'My Expenses',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Adds space between the widgets
              const SizedBox(height: 20),

              // Container is used to hold the expense information
              Container(
                padding: const EdgeInsets.all(20),

                // Displays the total expense
                child: const Text(
                  'Total Expense: ₹2,450',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}