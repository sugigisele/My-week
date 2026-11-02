import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const dayCodes = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

class Course {
  Course({
    this.id = '',
    required this.name,
    required this.day, // 0 = Monday ... 4 = Friday
    required this.start, // minutes since midnight
    required this.end,
  });

  final String id;
  final String name;
  final int day;
  final int start;
  final int end;

  Map<String, dynamic> toMap() => {
        'name': name,
        'day': day,
        'start': start,
        'end': end,
      };

  factory Course.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Course(
      id: doc.id,
      name: data['name'] as String,
      day: (data['day'] as num).toInt(),
      start: (data['start'] as num).toInt(),
      end: (data['end'] as num).toInt(),
    );
  }
}

// The signed-in user's courses: users/{uid}/courses
CollectionReference<Map<String, dynamic>> myCourses() {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('courses');
}

// Sample data, written once when a new account is created
// (3 days, and Monday has a clash: Maths and Physics overlap)
Future<void> addSampleCourses() async {
  final samples = [
    Course(name: 'Mathematics', day: 0, start: 8 * 60, end: 10 * 60),
    Course(name: 'Physics', day: 0, start: 9 * 60 + 30, end: 11 * 60),
    Course(name: 'Programming', day: 2, start: 10 * 60, end: 12 * 60),
    Course(name: 'English', day: 2, start: 12 * 60, end: 13 * 60 + 30),
    Course(name: 'Networks', day: 4, start: 14 * 60, end: 16 * 60),
  ];
  final batch = FirebaseFirestore.instance.batch();
  for (final c in samples) {
    batch.set(myCourses().doc(), c.toMap());
  }
  await batch.commit();
}
