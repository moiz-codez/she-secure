String formatMmSs(int totalSeconds) {
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// '13 Oct, 5:34 pm' — history/event timestamps.
String formatWhen(DateTime? dt) {
  if (dt == null) return '';
  return '${dt.day} ${_months[dt.month - 1]}, ${formatMinuteOfDay(dt.hour * 60 + dt.minute)}';
}

/// 1034 -> '5:14 pm'.
String formatMinuteOfDay(int minuteOfDay) {
  final hour = minuteOfDay ~/ 60;
  final hour12 = hour % 12 == 0 ? 12 : hour % 12;
  final minute = (minuteOfDay % 60).toString().padLeft(2, '0');
  return '$hour12:$minute ${hour >= 12 ? 'pm' : 'am'}';
}
