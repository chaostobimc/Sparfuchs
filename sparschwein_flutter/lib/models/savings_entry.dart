import 'package:intl/intl.dart';

const savingsTypes = <String>[
  'Cashback',
  'Rabatt',
  'Gratisartikel',
  'Fundstück',
  'Sonstiges',
];

const savingsStores = <String>[
  'REWE',
  'Lidl',
  'ALDI SÜD',
  'dm',
  'Rossmann',
  'Kaufland',
  'EDEKA',
  'Sonstiges',
];

class SavingsEntry {
  const SavingsEntry({
    required this.id,
    required this.amount,
    required this.title,
    required this.store,
    required this.type,
    required this.date,
    this.note = '',
  });

  final String id;
  final double amount;
  final String title;
  final String store;
  final String type;
  final DateTime date;
  final String note;

  Map<String, Object?> toJson() => {
        'id': id,
        'amount': amount,
        'title': title,
        'store': store,
        'type': type,
        'date': DateFormat('yyyy-MM-dd').format(date),
        'note': note,
      };

  factory SavingsEntry.fromJson(Map<String, dynamic> json) {
    final parsedDate = DateTime.tryParse('${json['date'] ?? ''}');
    return SavingsEntry(
      id: '${json['id'] ?? DateTime.now().microsecondsSinceEpoch}',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      title: '${json['title'] ?? ''}',
      store: '${json['store'] ?? 'Sonstiges'}',
      type: savingsTypes.contains(json['type']) ? '${json['type']}' : 'Sonstiges',
      date: parsedDate ?? DateTime.now(),
      note: '${json['note'] ?? ''}',
    );
  }
}

String formatMoney(num amount) =>
    NumberFormat.currency(locale: 'de_DE', symbol: '€').format(amount);

String formatShortMoney(num amount) =>
    '${NumberFormat('#,##0', 'de_DE').format(amount)} €';

String formatEntryDate(DateTime date) =>
    DateFormat('d. MMM yyyy', 'de_DE').format(date);

String formatMonthName(DateTime date) =>
    DateFormat('MMMM yyyy', 'de_DE').format(date);

String formatMonthShort(DateTime date) =>
    DateFormat('MMM', 'de_DE').format(date).replaceAll('.', '');
