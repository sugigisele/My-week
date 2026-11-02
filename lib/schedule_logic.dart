import 'course.dart';

// "08:30" -> 510. Returns null for 8h, 25:00, 10:75, ...
int? parseTime(String text) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(text.trim());
  if (m == null) return null;
  final h = int.parse(m.group(1)!);
  final min = int.parse(m.group(2)!);
  if (h > 23 || min > 59) return null;
  return h * 60 + min;
}

// 510 -> "08:30"
String formatTime(int minutes) {
  final h = (minutes ~/ 60).toString().padLeft(2, '0');
  final m = (minutes % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

// 210 -> "3h 30m"
String formatDuration(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (m == 0) return '${h}h';
  if (h == 0) return '${m}m';
  return '${h}h ${m}m';
}

// Same day, and each one starts before the other ends.
// "<" (not "<="): 09:00-11:00 and 11:00-12:00 only touch, they do not clash.
bool clashes(Course a, Course b) =>
    a.id != b.id && a.day == b.day && a.start < b.end && b.start < a.end;

List<Course> clashesWith(Course c, List<Course> all) =>
    all.where((other) => clashes(c, other)).toList();

int totalMinutes(Iterable<Course> courses) =>
    courses.fold<int>(0, (sum, c) => sum + (c.end - c.start));
