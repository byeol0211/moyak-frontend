/// 화면 공통 날짜·금액 표기 (HTML 화면의 fmtDate / toLocaleTimeString 과 같은 모양).
library;

String formatDate(DateTime date) =>
    '${date.year}.${_two(date.month)}.${_two(date.day)}';

/// 예: 오후 2:18
String formatTime(DateTime date) {
  final period = date.hour < 12 ? '오전' : '오후';
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  return '$period $hour:${_two(date.minute)}';
}

/// 예: 3,000원
String formatPrice(int price) {
  final digits = price.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return '$buffer원';
}

String _two(int value) => value.toString().padLeft(2, '0');
