import 'package:flutter/material.dart';

import 'data/questions.dart';
import 'questions_summary.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({
    super.key,
    required this.chosenAnswers,
    required this.onRestartQuiz,
  });

  final List<String> chosenAnswers;
  final VoidCallback onRestartQuiz;

  List<Map<String, Object>> getSummaryData() {
    return chosenAnswers.asMap().entries.map((entry) {
      final questionIndex = entry.key;
      final question = questions[questionIndex];

      return {
        'question_index': questionIndex,
        'question': question.text,
        'correct_answer': question.answers[0],
        'user_answer': entry.value,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final summaryData = getSummaryData();
    final correctAnswers = summaryData.where((answer) {
      return answer['user_answer'] == answer['correct_answer'];
    }).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        children: [
          const Text(
            'Výsledky kvízu',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Správne odpovede: $correctAnswers z ${questions.length}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 19),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: QuestionsSummary(summaryData: summaryData),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRestartQuiz,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Restart Quiz'),
            style: ElevatedButton.styleFrom(
              foregroundColor: const Color(0xFF4C1D95),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 16,
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}