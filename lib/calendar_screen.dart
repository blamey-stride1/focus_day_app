import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'models/task.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  final List<Task> tasks;
  CalendarScreen({required this.tasks});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Task> _getTasksForDay(DateTime day) {
    return widget.tasks.where((task) {
      final bool isSameDayTask =
          isSameDay(task.dueDate, day);

      final bool isRecurringToday =
          task.isRecurring &&
          task.dueDate.weekday == day.weekday;

      return isSameDayTask || isRecurringToday;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tasksForDay = _selectedDay == null
        ? []
        : _getTasksForDay(_selectedDay!);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Calendar View", style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.deepPurpleAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.orangeAccent,
                shape: BoxShape.circle,
              ),
              defaultTextStyle: TextStyle(color: Colors.white),
              weekendTextStyle: TextStyle(color: Colors.redAccent),
              todayTextStyle: TextStyle(color: Colors.white),
              selectedTextStyle: TextStyle(color: Colors.black),
              outsideTextStyle: TextStyle(color: Colors.grey.shade700),
            ),
            headerStyle: HeaderStyle(
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
              formatButtonTextStyle: TextStyle(color: Colors.black),
              formatButtonDecoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
              ),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
            ),
          ),
          SizedBox(height: 20),
          Text(
            _selectedDay == null
                ? "Select a day to see tasks"
                : "Tasks for ${DateFormat.yMMMd().format(_selectedDay!)}:",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Expanded(
            child: tasksForDay.isEmpty
                ? Center(
                    child: Text(
                      "No tasks for this day.",
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView(
                    children: tasksForDay.map((task) {
                      return ListTile(
                        title: Text(task.title, style: TextStyle(color: Colors.white)),
                        subtitle: task.isRecurring
                            ? Text("Recurring", style: TextStyle(color: Colors.orangeAccent))
                            : null,
                        leading: Checkbox(
                          value: task.isDone,
                          onChanged: (_) {},
                          activeColor: Colors.orangeAccent,
                          checkColor: Colors.black,
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
