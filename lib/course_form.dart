import 'package:flutter/material.dart';

import 'course.dart';
import 'schedule_logic.dart';

class CourseForm extends StatefulWidget {
  const CourseForm({super.key, this.course, this.initialDay = 0});

  final Course? course; // null = adding a new course
  final int initialDay;

  @override
  State<CourseForm> createState() => _CourseFormState();
}

class _CourseFormState extends State<CourseForm> {
  final _name = TextEditingController();
  final _start = TextEditingController();
  final _end = TextEditingController();
  late int _day;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final c = widget.course;
    _day = c?.day ?? widget.initialDay;
    if (c != null) {
      _name.text = c.name;
      _start.text = formatTime(c.start);
      _end.text = formatTime(c.end);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  void _refuse(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final start = parseTime(_start.text);
    final end = parseTime(_end.text);

    // Every check first; if one fails, nothing is saved.
    if (name.isEmpty) return _refuse('Enter the course name.');
    if (start == null) return _refuse('Start time must look like 08:00 (hours 00-23, minutes 00-59).');
    if (end == null) return _refuse('End time must look like 10:00 (hours 00-23, minutes 00-59).');
    if (end <= start) return _refuse('The end time must be after the start time.');

    final course = Course(name: name, day: _day, start: start, end: end);
    setState(() => _busy = true);
    try {
      if (widget.course == null) {
        await myCourses().add(course.toMap());
      } else {
        await myCourses().doc(widget.course!.id).update(course.toMap());
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _refuse('Could not save. Check your internet connection.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.course == null ? 'Add course' : 'Edit course')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
                labelText: 'Course name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < dayCodes.length; i++)
                ChoiceChip(
                  label: Text(dayCodes[i]),
                  selected: _day == i,
                  onSelected: (_) => setState(() => _day = i),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _start,
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(
                      labelText: 'Start (08:00)', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _end,
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(
                      labelText: 'End (10:00)', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
