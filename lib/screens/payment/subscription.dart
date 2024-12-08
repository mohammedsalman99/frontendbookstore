import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'lahza.dart';

class SubscriptionPage extends StatefulWidget {
  @override
  _SubscriptionPageState createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  List<dynamic> plans = []; // List of subscription plans
  String? selectedPlan; // Currently selected plan ID
  bool isLoading = true; // To show loading state when fetching plans
  bool isProcessing = false; // To show processing state during subscription

  @override
  void initState() {
    super.initState();
    fetchPlans(); // Fetch subscription plans when the widget initializes
  }

  Future<void> fetchPlans() async {
    try {
      final fetchedPlans = await LahzaService.fetchPlans(); // Fetch plans from API
      setState(() {
        plans = fetchedPlans; // Update plans list
        isLoading = false; // Stop loading
      });
    } catch (e) {
      setState(() {
        isLoading = false; // Stop loading on error
      });
      _showSnackBar("Error fetching plans: $e", isError: true);
    }
  }

  Future<void> initiateSubscription(String planId) async {
    setState(() {
      isProcessing = true;
    });

    try {
      // Step 1: Subscribe to the plan and get payment URL
      final subscriptionDetails = await LahzaService.subscribeToPlan(planId);
      final transactionId = subscriptionDetails['transaction']['id'];
      final authorizationUrl = subscriptionDetails['payment']['authorization_url'];

      // Step 2: Redirect to payment gateway
      if (await canLaunch(authorizationUrl)) {
        await launch(authorizationUrl);
        _showSnackBar("Redirected to payment gateway.", isError: false);

        // Step 3: Poll the transaction status
        pollTransactionStatus(transactionId, planId);
      } else {
        _showSnackBar("Failed to launch payment gateway.", isError: true);
      }
    } catch (e) {
      _showSnackBar("Error initiating subscription: $e", isError: true);
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }
  Future<void> pollTransactionStatus(String transactionId, String planId) async {
    const int pollingInterval = 5000; // 5 seconds
    const int maxRetries = 12; // 1 minute (12 x 5 seconds)
    int retries = 0;

    while (retries < maxRetries) {
      try {
        // Fetch transaction status
        final transaction = await LahzaService.checkTransactionStatus(transactionId);
        final status = transaction['transaction']['status'];

        if (status == 'COMPLETED') {
          // Transaction completed
          _showSnackBar("Payment successful! Subscription activated.", isError: false);
          return;
        } else if (status == 'FAILED') {
          // Transaction failed
          _showSnackBar("Payment failed. Please try again.", isError: true);
          return;
        }
      } catch (e) {
        // Handle errors (e.g., network issues)
        _showSnackBar("Error checking transaction status: $e", isError: true);
      }

      // Wait before the next retry
      await Future.delayed(Duration(milliseconds: pollingInterval));
      retries++;
    }

    // Timeout case
    _showSnackBar("Payment status check timed out. Please verify manually.", isError: true);
  }


  Future<void> finalizeTransaction(String planId, String transactionId) async {
    try {
      // Finalize transaction after payment
      final transaction = await LahzaService.createTransaction(planId, "CREDIT_CARD");
      final status = transaction['transaction']['status'];

      if (status == 'COMPLETED') {
        _showSnackBar("Payment successful! Subscription activated.", isError: false);
      } else {
        _showSnackBar("Payment failed. Please try again.", isError: true);
      }
    } catch (e) {
      _showSnackBar("Error finalizing transaction: $e", isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final backgroundColor = isError ? Colors.red.shade100 : Colors.green.shade100;
    final textColor = isError ? Colors.red : Colors.green;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: backgroundColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Subscription Plan"),
        backgroundColor: Color(0xFF5AA5B1),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading spinner
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Subscription Plans",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: plans.length,
                itemBuilder: (context, index) {
                  final plan = plans[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedPlan = plan['_id']; // Update selected plan
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: selectedPlan == plan['_id']
                            ? Color(0xFF5AA5B1).withOpacity(0.1)
                            : Colors.white,
                        border: Border.all(
                          color: selectedPlan == plan['_id']
                              ? Color(0xFF5AA5B1)
                              : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan['planName'],
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "${plan['durationInDays']} Day(s)",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700]),
                              ),
                            ],
                          ),
                          Text(
                            "${plan['price']} USD",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: !isProcessing && selectedPlan != null
                  ? () {
                initiateSubscription(selectedPlan!); // Initiate subscription
              }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                isProcessing ? Colors.grey : Color(0xFF5AA5B1),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isProcessing
                  ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white),
              )
                  : Center(
                child: Text(
                  "SUBSCRIBE",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
