import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/models/fee.dart';

class StudentFeesScreen extends StatefulWidget {
  const StudentFeesScreen({super.key});

  @override
  State<StudentFeesScreen> createState() => _StudentFeesScreenState();
}

class _StudentFeesScreenState extends State<StudentFeesScreen> {
  // Mock data for fees and payments
  final List<Fee> _upcomingFees = [
    Fee(title: 'Tution Fee - Sem 1', amount: 50000.0, dueDate: '2025-10-30'),
    Fee(title: 'Exam Fee', amount: 2500.0, dueDate: '2025-11-15'),
  ];

  final List<Payment> _paymentHistory = [
    Payment(title: 'Admission Fee', amount: 10000.0, date: '2025-08-25'),
    Payment(title: 'Security Deposit', amount: 5000.0, date: '2025-08-25'),
  ];

  double get _totalOutstanding =>
      _upcomingFees.fold(0.0, (sum, item) => sum + item.amount);

  void _downloadReceipt(BuildContext context, Payment payment) {
    // TODO: Implement the logic to download the payment receipt
    // This would likely involve an API call to get the PDF URL and then a download service.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading receipt for ${payment.title}...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fees & Payments'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section with Total Outstanding Balance
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Total Outstanding Balance',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${_totalOutstanding.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Upcoming Fees Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildSectionTitle('Upcoming Fees'),
            ),
            _buildUpcomingFeesList(_upcomingFees),
            const SizedBox(height: 24),

            // Payment History Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildSectionTitle('Payment History'),
            ),
            _buildPaymentHistoryList(_paymentHistory),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildUpcomingFeesList(List<Fee> fees) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: fees.length,
      itemBuilder: (context, index) {
        final fee = fees[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fee.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Due: ${fee.dueDate}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${fee.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implement payment logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Payment for ${fee.title} clicked!'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Pay Now',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // The corrected method
  Widget _buildPaymentHistoryList(List<Payment> payments) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Paid on: ${payment.date}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${payment.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.download,
                    color: AppColors.textPrimary,
                    size: 30,
                  ),
                  onPressed: () => _downloadReceipt(context, payment),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
