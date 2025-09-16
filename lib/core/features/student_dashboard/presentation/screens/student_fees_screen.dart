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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fees & Payments'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Outstanding Balance
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Outstanding',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '₹${_totalOutstanding.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Upcoming Fees Section
            _buildSectionTitle('Upcoming Fees'),
            const SizedBox(height: 8),
            _buildFeeList(_upcomingFees),
            const SizedBox(height: 24),

            // Payment History Section
            _buildSectionTitle('Payment History'),
            const SizedBox(height: 8),
            _buildPaymentList(_paymentHistory),
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

  Widget _buildFeeList(List<Fee> fees) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: fees.length,
      itemBuilder: (context, index) {
        final fee = fees[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.payment, color: AppColors.primary),
            title: Text(
              fee.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Due Date: ${fee.dueDate}'),
            trailing: Text(
              '₹${fee.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.error,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentList(List<Payment> payments) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.check_circle, color: AppColors.success),
            title: Text(
              payment.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Paid on: ${payment.date}'),
            trailing: Text(
              '₹${payment.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.success,
              ),
            ),
          ),
        );
      },
    );
  }
}
