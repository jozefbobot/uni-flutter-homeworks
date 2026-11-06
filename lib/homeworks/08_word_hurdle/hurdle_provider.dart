import 'dart:math';

import 'package:english_words/english_words.dart' as words;
import 'package:flutter/foundation.dart';

import 'wordle.dart';

class HurdleProvider extends ChangeNotifier {
  final random = Random.secure();

  List<String> totalWords = [];
  final List<String> rowInputs = [];
  final List<String> excludedLetters = [];
  List<Wordle> hurdleBoard = [];
  String targetWord = '';

  final int lettersPerRow = 5;
  final int totalAttempts = 6;
  int count = 0;
  int index = 0;
  int attempts = 0;
  bool wins = false;
  bool _initialized = false;

  bool get isValidWord => totalWords.contains(rowInputs.join('').toLowerCase());

  // V materiáloch z hodiny sú použité oba názvy getteru.
  bool get isAValidWord => isValidWord;

  bool get shouldCheckForAnswer => rowInputs.length == lettersPerRow;
  bool get noAttemptsLeft => attempts >= totalAttempts && !wins;
  bool get isGameOver => wins || noAttemptsLeft;

  void init() {
    // didChangeDependencies sa môže zavolať opakovane bez reštartu hry.
    if (_initialized) return;
    totalWords = words.all
        .where((word) => word.length == lettersPerRow)
        .toList();
    generateBoard();
    generateRandomWord();
    _initialized = true;
  }

  void generateBoard() {
    hurdleBoard = List.generate(
      totalAttempts * lettersPerRow,
      (_) => Wordle(letter: ''),
    );
  }

  void generateRandomWord() {
    targetWord = totalWords[random.nextInt(totalWords.length)].toUpperCase();
    if (kDebugMode) debugPrint(targetWord);
  }

  void inputLetter(String letter) {
    if (!_initialized || isGameOver || count >= lettersPerRow) return;
    final input = letter.toUpperCase();
    if (!RegExp(r'^[A-Z]$').hasMatch(input)) return;

    rowInputs.add(input);
    hurdleBoard[index] = Wordle(letter: input);
    count++;
    index++;
    notifyListeners();
  }

  void deleteLetter() {
    if (isGameOver || rowInputs.isEmpty) return;
    rowInputs.removeLast();
    hurdleBoard[index - 1] = Wordle(letter: '');
    count--;
    index--;
    notifyListeners();
  }

  void checkAnswer() {
    // Ochrana je aj v provider-i, aby neplatný vstup nespotreboval pokus.
    if (isGameOver || !shouldCheckForAnswer || !isValidWord) return;

    final input = rowInputs.join('');
    _markLettersOnBoard();
    wins = targetWord == input;
    _goToNextRow();
    notifyListeners();
  }

  void _markLettersOnBoard() {
    for (final wordle in hurdleBoard) {
      if (wordle.letter.isEmpty) continue;
      if (targetWord.contains(wordle.letter)) {
        wordle.existsInTarget = true;
      } else {
        wordle.doesNotExistInTarget = true;
        if (!excludedLetters.contains(wordle.letter)) {
          excludedLetters.add(wordle.letter);
        }
      }
    }
  }

  void _goToNextRow() {
    // Každé vyhodnotené slovo spotrebuje práve jeden zo šiestich pokusov.
    attempts++;
    count = 0;
    rowInputs.clear();
  }

  void reset() {
    count = 0;
    index = 0;
    rowInputs.clear();
    hurdleBoard.clear();
    excludedLetters.clear();
    attempts = 0;
    wins = false;
    targetWord = '';
    if (!_initialized) {
      init();
    } else {
      generateBoard();
      generateRandomWord();
    }
    notifyListeners();
  }
}
