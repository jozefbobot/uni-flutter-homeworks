import 'package:flutter/material.dart';

import 'data/questions.dart';
import 'questions_screen.dart';
import 'results_screen.dart';
import 'start_screen.dart';

class Quiz extends StatefulWidget {
  const Quiz({super.key});

  @override
  State<Quiz> createState() {
    return _QuizState();
  }
}

class _QuizState extends State<Quiz> {
  String _activeScreen = 'start-screen';
  final List<String> _selectedAnswers = [];

  void _startQuiz() {
    setState(() {
      _selectedAnswers.clear();
      _activeScreen = 'questions-screen';
    });
  }

  void _selectAnswer(String answer) {
    setState(() {
      _selectedAnswers.add(answer);

      if (_selectedAnswers.length == questions.length) {
        _activeScreen = 'results-screen';
      }
    });
  }

  void _restartQuiz() {
    setState(() {
      _selectedAnswers.clear();
      _activeScreen = 'start-screen';
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget screenWidget = StartScreen(onStartQuiz: _startQuiz);

    if (_activeScreen == 'questions-screen') {
      screenWidget = QuestionsScreen(
        questionIndex: _selectedAnswers.length,
        onSelectAnswer: _selectAnswer,
      );
    } else if (_activeScreen == 'results-screen') {
      screenWidget = ResultsScreen(
        chosenAnswers: _selectedAnswers,
        onRestartQuiz: _restartQuiz,
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E1065), Color(0xFF7E22CE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(child: screenWidget),
      ),
    );
  }
}