import 'package:flutter_homeworks/homeworks/08_word_hurdle/hurdle_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void enterWord(HurdleProvider provider, String word) {
  for (final letter in word.split('')) {
    provider.inputLetter(letter);
  }
}

void main() {
  late HurdleProvider provider;

  setUp(() {
    provider = HurdleProvider()..init();
    provider.totalWords = ['apple', 'grape', 'pearl', 'stone'];
    provider.targetWord = 'APPLE';
  });

  tearDown(() => provider.dispose());

  test('initialization creates 30 empty cells and does not restart a game', () {
    expect(provider.hurdleBoard, hasLength(30));
    expect(provider.hurdleBoard.every((cell) => cell.letter.isEmpty), isTrue);

    provider.inputLetter('A');
    provider.init();
    expect(provider.targetWord, 'APPLE');
    expect(provider.rowInputs, ['A']);
    expect(provider.index, 1);
  });

  test('input and delete stay inside the current row', () {
    provider.deleteLetter();
    enterWord(provider, 'grapex');
    expect(provider.rowInputs.join(), 'GRAPE');
    expect(provider.index, 5);
    expect(provider.count, 5);

    provider.deleteLetter();
    expect(provider.hurdleBoard[4].letter, isEmpty);
    provider.inputLetter('e');
    provider.checkAnswer();

    provider.deleteLetter();
    expect(provider.index, 5);
    expect(provider.hurdleBoard[4].letter, 'E');
    provider.inputLetter('S');
    provider.deleteLetter();
    expect(provider.index, 5);
    expect(provider.count, 0);
    expect(provider.hurdleBoard[5].letter, isEmpty);
  });

  test('incomplete and unknown words do not use an attempt', () {
    enterWord(provider, 'APP');
    provider.checkAnswer();
    expect(provider.shouldCheckForAnswer, isFalse);
    expect(provider.attempts, 0);

    enterWord(provider, 'XX');
    provider.checkAnswer();
    expect(provider.isValidWord, isFalse);
    expect(provider.isAValidWord, isFalse);
    expect(provider.attempts, 0);
    expect(provider.rowInputs.join(), 'APPXX');
    expect(provider.hurdleBoard.every((cell) => !cell.existsInTarget), isTrue);
  });

  test('submitted letters are marked and excluded letters are unique', () {
    enterWord(provider, 'GRAPE');
    provider.checkAnswer();

    expect(provider.hurdleBoard[0].doesNotExistInTarget, isTrue);
    expect(provider.hurdleBoard[1].doesNotExistInTarget, isTrue);
    expect(provider.hurdleBoard[2].existsInTarget, isTrue);
    expect(provider.hurdleBoard[3].existsInTarget, isTrue);
    expect(provider.hurdleBoard[4].existsInTarget, isTrue);
    expect(provider.excludedLetters, ['G', 'R']);
    expect(provider.rowInputs, isEmpty);
    expect(provider.attempts, 1);

    enterWord(provider, 'GRAPE');
    provider.checkAnswer();
    expect(provider.excludedLetters, ['G', 'R']);
  });

  test('the sixth wrong word loses and further editing is ignored', () {
    for (var attempt = 0; attempt < 6; attempt++) {
      enterWord(provider, 'GRAPE');
      provider.checkAnswer();
    }

    expect(provider.attempts, 6);
    expect(provider.index, 30);
    expect(provider.noAttemptsLeft, isTrue);
    expect(provider.isGameOver, isTrue);
    expect(provider.wins, isFalse);
    provider.inputLetter('A');
    provider.deleteLetter();
    provider.checkAnswer();
    expect(provider.index, 30);
    expect(provider.attempts, 6);
    expect(provider.hurdleBoard.last.letter, 'E');
  });

  test('the correct word wins even on the sixth attempt', () {
    for (var attempt = 0; attempt < 5; attempt++) {
      enterWord(provider, 'GRAPE');
      provider.checkAnswer();
    }
    enterWord(provider, 'APPLE');
    provider.checkAnswer();

    expect(provider.wins, isTrue);
    expect(provider.attempts, 6);
    expect(provider.noAttemptsLeft, isFalse);
    expect(provider.isGameOver, isTrue);
    expect(
      provider.hurdleBoard.skip(25).every((cell) => cell.existsInTarget),
      isTrue,
    );
    provider.deleteLetter();
    provider.inputLetter('X');
    expect(provider.index, 30);
  });

  test('reset clears a finished game and allows another round', () {
    enterWord(provider, 'GRAPE');
    provider.checkAnswer();
    enterWord(provider, 'APPLE');
    provider.checkAnswer();
    provider.reset();

    expect(provider.wins, isFalse);
    expect(provider.isGameOver, isFalse);
    expect(provider.attempts, 0);
    expect(provider.count, 0);
    expect(provider.index, 0);
    expect(provider.rowInputs, isEmpty);
    expect(provider.excludedLetters, isEmpty);
    expect(provider.hurdleBoard, hasLength(30));
    expect(provider.hurdleBoard.every((cell) => cell.letter.isEmpty), isTrue);
    expect(provider.totalWords, contains(provider.targetWord.toLowerCase()));
    provider.inputLetter('A');
    expect(provider.hurdleBoard.first.letter, 'A');
  });

  test('editing, submitting and resetting notify listeners', () {
    var changes = 0;
    provider.addListener(() => changes++);
    enterWord(provider, 'GRAPE');
    expect(changes, 5);
    provider.checkAnswer();
    expect(changes, 6);
    provider.reset();
    expect(changes, 7);
  });
}
