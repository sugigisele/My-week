import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'course.dart';
import 'course_form.dart';
import 'schedule_logic.dart';

class WeekScreen extends StatefulWidget {
  const WeekScreen({super.key});

  @override
  State<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  int selectedDay = 0;

  Future<void> _delete(Course course) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this course?'),
        content: Text(course.name),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (sure != true) return;
    try {
      await myCourses().doc(course.id).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${course.name} deleted'),
          action: SnackBarAction(
            label: 'Undo',
            // Undo = write the same data back with the same id
            onPressed: () => myCourses().doc(course.id).set(course.toMap()),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete. Try again.')));
    }
  }

  void _open({Course? course}) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => CourseForm(course: course, initialDay: selectedDay)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Week'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _open(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: myCourses().orderBy('start').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load your courses.\n${snapshot.error}',
                    textAlign: TextAlign.center),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Everything below is calculated every time the data arrives.
          final all = snapshot.data!.docs.map(Course.fromDoc).toList();
          final today = all.where((c) => c.day == selectedDay).toList()
            ..sort((a, b) => a.start.compareTo(b.start));

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'This week: ${formatDuration(totalMinutes(all))}',
                  style: const TextStyle(color: Colors.white, fontSize: 22),
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (var i = 0; i < dayCodes.length; i++)
                    ChoiceChip(
                      label: Text(dayCodes[i]),
                      selected: selectedDay == i,
                      onSelected: (_) => setState(() => selectedDay = i),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '${dayNames[selectedDay]}: ${formatDuration(totalMinutes(today))}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              Expanded(
                child: today.isEmpty
                    ? Center(child: Text('No classes on ${dayNames[selectedDay]}'))
                    : ListView.builder(
                        itemCount: today.length,
                        itemBuilder: (context, index) {
                          final c = today[index];
                          final others = clashesWith(c, all);
                          final clash = others.isNotEmpty;
                          return Card(
                            color: clash ? Colors.red.shade100 : null,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: ListTile(
                              title: Text(c.name),
                              subtitle: Text(
                                '${formatTime(c.start)}–${formatTime(c.end)}'
                                '${clash ? '\nClashes with ${others.map((o) => o.name).join(', ')}' : ''}',
                                style: TextStyle(
                                    color: clash ? Colors.red.shade900 : null),
                              ),
                              isThreeLine: clash,
                              onTap: () => _open(course: c),
                              onLongPress: () => _delete(c),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
