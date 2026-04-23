const Map<int, String> _spokenDenominations = <int, String>{
  1000: 'seribu',
  2000: 'dua ribu',
  5000: 'lima ribu',
  10000: 'sepuluh ribu',
  20000: 'dua puluh ribu',
  50000: 'lima puluh ribu',
  100000: 'seratus ribu',
};

class CurrencyRecognition {
  CurrencyRecognition({required this.amount, DateTime? recognizedAt})
    : recognizedAt = recognizedAt ?? DateTime.now();

  final int amount;
  final DateTime recognizedAt;

  String get spokenAmount => _spokenDenominations[amount] ?? '$amount';

  String get spokenText => 'Ini uang $spokenAmount rupiah';

  String get formattedAmount => _formatRupiah(amount);
}

String _formatRupiah(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    final positionFromEnd = digits.length - index;
    buffer.write(digits[index]);

    if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
      buffer.write('.');
    }
  }

  return 'Rp$buffer';
}
