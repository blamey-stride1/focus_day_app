import 'package:percent_indicator/percent_indicator.dart';
import 'score_chart.dart';
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
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
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
  Duration remainingTime = Duration(minutes: 25);
  Duration totalTime = Duration(minutes: 25);
  Timer? timer;
  String dailyReflection = '';
  Map<String, int> scoreHistory = {};
  int currentStreak = 0;
  int personalBest = 0;
  String lastOpenDate = '';
  int sessionMinutes = 0;

  String formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  void initState() {
    super.initState();
    checkForNewDay();
    loadData();
  }

  void checkForNewDay() {
    String today = DateTime.now().toIso8601String().substring(0, 10);

    if (lastOpenDate != today && lastOpenDate != '') {
      scoreHistory[lastOpenDate] = productivityScore;

      if (productivityScore > personalBest) {
        personalBest = productivityScore;
      }

      if (productivityScore >= 70) {
        currentStreak += 1;
      } else {
        currentStreak = 0;
      }

      sessionMinutes = 0;
      tasks = [];
    }

    lastOpenDate = today;
    saveData();
  }

  void loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final taskData = prefs.getString('tasks');
    if (taskData != null) {
      final taskList = json.decode(taskData) as List;
      tasks = taskList.map((t) => Task(t['title'], isDone: t['done'])).toList();
    }
    scoreHistory = Map<String, int>.from(json.decode(prefs.getString('scoreHistory') ?? '{}'));
    currentStreak = prefs.getInt('streak') ?? 0;
    personalBest = prefs.getInt('personalBest') ?? 0;
    lastOpenDate = prefs.getString('lastOpenDate') ?? '';

    sessionMinutes = prefs.getInt('sessionMinutes') ?? 0;
    focusMinutes = prefs.getInt('focusMinutes') ?? 0;
    dailyReflection = prefs.getString('reflection') ?? '';

    setState(() {});
  }

  void saveData() async {
    final prefs = await SharedPreferences.getInstance();

    final taskList = tasks.map((t) => {'title': t.title, 'done': t.isDone}).toList();

    prefs.setString('tasks', json.encode(taskList));
    prefs.setInt('sessionMinutes', sessionMinutes);
    prefs.setInt('focusMinutes', focusMinutes);
    prefs.setString('reflection', dailyReflection);
    prefs.setString('scoreHistory', json.encode(scoreHistory));
    prefs.setInt('streak', currentStreak);
    prefs.setInt('personalBest', personalBest);
    prefs.setString('lastOpenDate', lastOpenDate);
  }

  int get productivityScore {
    double taskScore = tasks.isEmpty
        ? 0
        : tasks.where((task) => task.isDone).length / tasks.length;
    double focusScore = sessionMinutes / 90.0;
    double total = (taskScore * 0.5 + focusScore * 0.5) * 100;
    return total.clamp(0, 100).toInt();
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      if (remainingTime.inSeconds <= 0) {
        t.cancel();
        setState(() {
          focusMinutes += 25;
          sessionMinutes += 25;
        });
        saveData();
      } else {
        setState(() {
          remainingTime -= Duration(seconds: 1);
        });
      }
    });
  }

  void pauseTimer() {
    timer?.cancel();
  }

  void resetTimer() {
    timer?.cancel();
    setState(() {
      remainingTime = Duration(minutes: 25);
    });
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
            Center(
              child: CircularPercentIndicator(
                radius: 120.0,
                lineWidth: 12.0,
                percent: remainingTime.inSeconds / totalTime.inSeconds,
                center: Text(
                  formatTime(remainingTime),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                  ),
                ),
                progressColor: Colors.blue,
                backgroundColor: Colors.grey.shade300,
                circularStrokeCap: CircularStrokeCap.round,
              ),
            ),
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
            Text("Score History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ScoreChart(scoreHistory: scoreHistory),
            for (var date in scoreHistory.keys.toList().reversed.take(7))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text(
                  "$date: ${scoreHistory[date]}/100",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            SizedBox(height: 10),
            Text("🔥 Streak: $currentStreak days"),
            Text("🏅 Personal Best: $personalBest/100"),
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
