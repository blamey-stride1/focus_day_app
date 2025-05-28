import 'calendar_screen.dart';
import 'profile_screen.dart';
import 'models/task.dart';
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
      theme: ThemeData.dark(),
      home: HomeScreen(),
    );
  }
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
      tasks = taskList.map((t) => Task(
        t['title'],
        isDone: t['done'],
        dueDate: DateTime.parse(t['dueDate']),
      )).toList();
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

    final taskList = tasks.map((t) => {
      'title': t.title,
      'done': t.isDone,
      'dueDate': t.dueDate.toIso8601String(),
    }).toList();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Focus Day", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Image.asset('assets/icon.png'),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ProfileScreen(personalBest: personalBest),
              ));
            },
          )
        ],
      ),
      body: Container(
        color: Colors.black,
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
            Center(
              child: CircularPercentIndicator(
                radius: 120.0,
                lineWidth: 12.0,
                percent: remainingTime.inSeconds / totalTime.inSeconds,
                center: Text(
                  formatTime(remainingTime),
                  style: TextStyle(fontSize: 36, color: Colors.white),
                ),
                progressColor: Colors.orangeAccent,
                backgroundColor: Colors.grey.shade800,
                circularStrokeCap: CircularStrokeCap.round,
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: startTimer,
                  child: Text("Start"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: pauseTimer,
                  child: Text("Pause"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: resetTimer,
                  child: Text("Reset"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text("Daily Overview", style: TextStyle(fontSize: 18, color: Colors.white)),
            Card(
              color: Colors.grey.shade900,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("🔥 Current Streak: $currentStreak days", style: TextStyle(color: Colors.white)),
                    SizedBox(height: 8),
                    Text("📅 What's On Today:", style: TextStyle(color: Colors.white)),
                    ...tasks
                      .where((task) => task.dueDate.day == DateTime.now().day &&
                                       task.dueDate.month == DateTime.now().month &&
                                       task.dueDate.year == DateTime.now().year)
                      .map((task) => Text("- ${task.title}", style: TextStyle(color: Colors.white)))
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => CalendarScreen(tasks: tasks),
                ));
              },
              child: Text("📅 Open Calendar"),
            )
          ],
        ),
      ),
    );
  }
}
