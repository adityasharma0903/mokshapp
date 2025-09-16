// lib/core/models/fee.dart
class Fee {
  final String title;
  final double amount;
  final String dueDate;
  final bool isPaid;

  Fee({
    required this.title,
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
  });
}

class Payment {
  final String title;
  final double amount;
  final String date;

  Payment({required this.title, required this.amount, required this.date});
}
