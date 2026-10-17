import 'package:flutter/material.dart';

import 'answer_button.dart';
import 'data/questions.dart';

class QuestionsScreen extends StatelessWidget {
  const QuestionsScreen({
    super.key,
    required this.questionIndex,
    required this.onSelectAnswer,
  });

  final int questionIndex;
  final ValueChanged<String> onSelectAnswer;

  @override
  Widget build(BuildContext context) {
    final currentQuestion = questions[questionIndex];
    final shuffledAnswers = currentQuestion.getShuffledAnswers();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Otázka ${questionIndex + 1} z ${questions.length}',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Text(
              currentQuestion.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            ...shuffledAnswers.map(
                  (answer) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AnswerButton(
                  answerText: answer,
                  onTap: () => onSelectAnswer(answer),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}