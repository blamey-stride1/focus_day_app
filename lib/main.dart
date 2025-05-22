import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(FocusDayApp());
}

class FocusDayApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Focus Day',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}

class Task {
  String title;
  bool isDone;
  Task(this.title, {this.isDone = false});
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> tasks = [];
  String newTask = "";
  int focusMinutes = 0;
  int sessionMinutes = 0;
  Timer? timer;
  bool isRunning = false;
  String dailyReflection = '';

  @override
void initState() {
  super.initState();
  loadData();
}

void loadData() async {
  final prefs = await SharedPreferences.getInstance();

  final taskData = prefs.getString('tasks');
  if (taskData != null) {
    final taskList = json.decode(taskData) as List;
    tasks = taskList.map((t) => Task(t['title'], isDone: t['done'])).toList();
  }

  sessionMinutes = prefs.getInt('sessionMinutes') ?? 0;
  focusMinutes = prefs.getInt('focusMinutes') ?? 0;
  dailyReflection = prefs.getString('reflection') ?? '';

  setState(() {});
}

void saveData() async {
  final prefs = await SharedPreferences.getInstance();

  final taskList = tasks
      .map((t) => {'title': t.title, 'done': t.isDone})
      .toList();

  prefs.setString('tasks', json.encode(taskList));
  prefs.setInt('sessionMinutes', sessionMinutes);
  prefs.setInt('focusMinutes', focusMinutes);
  prefs.setString('reflection', dailyReflection);
}


  int get productivityScore {
    double taskScore = tasks.isEmpty
        ? 0
        : tasks.where((task) => task.isDone).length / tasks.length;
    double focusScore = sessionMinutes / 90.0; // assume goal is 90 mins
    double total = (taskScore * 0.5 + focusScore * 0.5) * 100;
    return total.clamp(0, 100).toInt();
  }

  void startTimer() {
    if (isRunning) return;
    isRunning = true;
    timer = Timer.periodic(Duration(minutes: 1), (Timer t) {
      setState(() {
        sessionMinutes += 1;
      });
    });
  }

  void pauseTimer() {
    timer?.cancel();
    isRunning = false;
  }

  void resetTimer() {
    timer?.cancel();
    focusMinutes += sessionMinutes;
    sessionMinutes = 0;
    isRunning = false;
    saveData();
  }

  void addTask() {
    if (newTask.trim().isNotEmpty) {
      setState(() {
        tasks.add(Task(newTask.trim()));
        newTask = "";
      });
      saveData();
    }
  }

  void openReflection() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => ReflectionScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Focus Day")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text("Today's Score: $productivityScore/100",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Text("Focus Timer: $sessionMinutes min"),
            Row(
              children: [
                ElevatedButton(onPressed: startTimer, child: Text("Start")),
                SizedBox(width: 10),
                ElevatedButton(onPressed: pauseTimer, child: Text("Pause")),
                SizedBox(width: 10),
                ElevatedButton(onPressed: resetTimer, child: Text("Reset")),
              ],
            ),
            Divider(height: 30),
            Text("Tasks", style: TextStyle(fontSize: 18)),
            for (int i = 0; i < tasks.length; i++)
              ListTile(
                title: Text(tasks[i].title),
                leading: Checkbox(
                  value: tasks[i].isDone,
                  onChanged: (val) {
                    setState(() {
                      tasks[i].isDone = val!;
                    });
                    saveData();
                  },
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      tasks.removeAt(i);
                    });
                  },
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(hintText: "New task"),
                    onChanged: (val) => newTask = val,
                  ),
                ),
                ElevatedButton(onPressed: addTask, child: Text("Add"))
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
                onPressed: openReflection, child: Text("Daily Reflection"))
          ],
        ),
      ),
    );
  }
}

class ReflectionScreen extends StatefulWidget {
  @override
  _ReflectionScreenState createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> {
  String entry = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reflection")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Write your reflection:"),
            SizedBox(height: 10),
            TextField(
              maxLines: 8,
              onChanged: (val) => entry = val,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "How was your day?",
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // In future: save to local or Firebase
                Navigator.pop(context);
              },
              child: Text("Save Reflection"),
            )
          ],
        ),
      ),
    );
  }
}
