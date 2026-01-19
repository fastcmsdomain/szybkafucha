/// Earnings summary model
class EarningsSummary {
  final double todayEarnings;
  final double weekEarnings;
  final double monthEarnings;
  final double totalEarnings;
  final double pendingPayout;
  final double availableBalance;
  final int tasksToday;
  final int tasksThisWeek;
  final int tasksThisMonth;
  final int completedTasks;

  const EarningsSummary({
    this.todayEarnings = 0,
    this.weekEarnings = 0,
    this.monthEarnings = 0,
    this.totalEarnings = 0,
    this.pendingPayout = 0,
    this.availableBalance = 0,
    this.tasksToday = 0,
    this.tasksThisWeek = 0,
    this.tasksThisMonth = 0,
    this.completedTasks = 0,
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    return EarningsSummary(
      todayEarnings: (json['today_earnings'] as num?)?.toDouble() ?? 0,
      weekEarnings: (json['week_earnings'] as num?)?.toDouble() ?? 0,
      monthEarnings: (json['month_earnings'] as num?)?.toDouble() ?? 0,
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0,
      pendingPayout: (json['pending_payout'] as num?)?.toDouble() ?? 0,
      availableBalance: (json['available_balance'] as num?)?.toDouble() ?? 0,
      tasksToday: json['tasks_today'] as int? ?? 0,
      tasksThisWeek: json['tasks_this_week'] as int? ?? 0,
      tasksThisMonth: json['tasks_this_month'] as int? ?? 0,
      completedTasks: json['completed_tasks'] as int? ?? 0,
    );
  }

  /// Mock data for development
  static EarningsSummary mock() {
    return const EarningsSummary(
      todayEarnings: 245.00,
      weekEarnings: 1280.50,
      monthEarnings: 4520.00,
      totalEarnings: 18750.00,
      pendingPayout: 850.00,
      availableBalance: 1850.50,
      tasksToday: 3,
      tasksThisWeek: 15,
      tasksThisMonth: 52,
      completedTasks: 127,
    );
  }
}

/// Transaction model for earnings history
class Transaction {
  final String id;
  final String taskId;
  final String taskTitle;
  final String description;
  final double amount;
  final double commission;
  final double netAmount;
  final TransactionType type;
  final TransactionStatus status;
  final DateTime date;
  final DateTime createdAt;
  final DateTime? completedAt;

  const Transaction({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.description,
    required this.amount,
    required this.commission,
    required this.netAmount,
    required this.type,
    required this.status,
    required this.date,
    required this.createdAt,
    this.completedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      taskTitle: json['task_title'] as String,
      description: json['description'] as String? ?? json['task_title'] as String,
      amount: (json['amount'] as num).toDouble(),
      commission: (json['commission'] as num).toDouble(),
      netAmount: (json['net_amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => TransactionType.earning,
      ),
      status: TransactionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TransactionStatus.pending,
      ),
      date: DateTime.parse(json['date'] as String? ?? json['created_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  /// Mock transactions for development
  static List<Transaction> mockList() {
    final now = DateTime.now();
    return [
      Transaction(
        id: 't1',
        taskId: 'task1',
        taskTitle: 'Sprzątanie mieszkania',
        description: 'Sprzątanie mieszkania',
        amount: 150.00,
        commission: 25.50,
        netAmount: 124.50,
        type: TransactionType.earning,
        status: TransactionStatus.completed,
        date: now.subtract(const Duration(hours: 2)),
        createdAt: now.subtract(const Duration(hours: 2)),
        completedAt: now.subtract(const Duration(hours: 1)),
      ),
      Transaction(
        id: 't2',
        taskId: 'task2',
        taskTitle: 'Zakupy spożywcze',
        description: 'Zakupy spożywcze',
        amount: 45.00,
        commission: 7.65,
        netAmount: 37.35,
        type: TransactionType.earning,
        status: TransactionStatus.completed,
        date: now.subtract(const Duration(hours: 5)),
        createdAt: now.subtract(const Duration(hours: 5)),
        completedAt: now.subtract(const Duration(hours: 4)),
      ),
      Transaction(
        id: 't3',
        taskId: 'task3',
        taskTitle: 'Montaż mebli IKEA',
        description: 'Montaż mebli IKEA',
        amount: 200.00,
        commission: 34.00,
        netAmount: 166.00,
        type: TransactionType.earning,
        status: TransactionStatus.pending,
        date: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Transaction(
        id: 't4',
        taskId: 'tip1',
        taskTitle: 'Napiwek - Sprzątanie',
        description: 'Napiwek - Sprzątanie',
        amount: 20.00,
        commission: 0.00,
        netAmount: 20.00,
        type: TransactionType.tip,
        status: TransactionStatus.completed,
        date: now.subtract(const Duration(hours: 1)),
        createdAt: now.subtract(const Duration(hours: 1)),
        completedAt: now.subtract(const Duration(hours: 1)),
      ),
      Transaction(
        id: 'w1',
        taskId: 'withdrawal1',
        taskTitle: 'Wypłata na konto',
        description: 'Wypłata na konto',
        amount: 500.00,
        commission: 0.00,
        netAmount: 500.00,
        type: TransactionType.withdrawal,
        status: TransactionStatus.completed,
        date: now.subtract(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 3)),
        completedAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }
}

enum TransactionType {
  earning,
  tip,
  withdrawal,
  refund,
}

extension TransactionTypeExtension on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.earning:
        return 'Płatność za zlecenie';
      case TransactionType.tip:
        return 'Napiwek';
      case TransactionType.withdrawal:
        return 'Wypłata';
      case TransactionType.refund:
        return 'Zwrot';
    }
  }

  bool get isIncoming =>
      this == TransactionType.earning || this == TransactionType.tip;
}

enum TransactionStatus {
  pending,
  processing,
  completed,
  failed,
}

extension TransactionStatusExtension on TransactionStatus {
  String get displayName {
    switch (this) {
      case TransactionStatus.pending:
        return 'Oczekuje';
      case TransactionStatus.processing:
        return 'Przetwarzanie';
      case TransactionStatus.completed:
        return 'Zakończono';
      case TransactionStatus.failed:
        return 'Nieudane';
    }
  }
}
