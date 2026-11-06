import 'package:flutter/material.dart';
import 'package:flutter_homeworks/homeworks/08_word_hurdle/hurdle_provider.dart';
import 'package:flutter_homeworks/homeworks/08_word_hurdle/keyboard_view.dart';
import 'package:flutter_homeworks/homeworks/08_word_hurdle/main.dart';
import 'package:flutter_homeworks/homeworks/08_word_hurdle/wordle_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Future<void> pumpGame(
  WidgetTester tester,
  HurdleProvider provider, {
  Size size = const Size(360, 640),
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(value: provider, child: const MyApp()),
  );
  await tester.pumpAndSettle();
}

Future<void> typeWord(WidgetTester tester, String word) async {
  for (final letter in word.split('')) {
    await tester.tap(find.widgetWithText(ElevatedButton, letter));
    await tester.pump();
  }
}

Future<void> submitWord(WidgetTester tester, String word) async {
  await typeWord(tester, word);
  await tester.tap(find.widgetWithText(ElevatedButton, 'SUBMIT'));
  await tester.pumpAndSettle();
}

void main() {
  late HurdleProvider provider;

  setUp(() {
    provider = HurdleProvider()..init();
    provider.totalWords = ['apple', 'grape', 'stone'];
    provider.targetWord = 'APPLE';
  });

  tearDown(() => provider.dispose());

  testWidgets('keyboard entry and DELETE update the visible board', (
    tester,
  ) async {
    await pumpGame(tester, provider);
    expect(find.text('Attempt 1 of 6'), findsOneWidget);
    expect(find.byType(VirtualKey), findsNWidgets(26));

    await typeWord(tester, 'AP');
    expect(
      find.descendant(
        of: find.byType(WordleView).at(0),
        matching: find.text('A'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(WordleView).at(1),
        matching: find.text('P'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'DELETE'));
    await tester.pump();
    expect(provider.rowInputs, ['A']);
    expect(
      tester.widget<WordleView>(find.byType(WordleView).at(1)).wordle.letter,
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('SUBMIT explains incomplete and unknown words without a turn', (
    tester,
  ) async {
    await pumpGame(tester, provider);
    await tester.tap(find.widgetWithText(ElevatedButton, 'SUBMIT'));
    await tester.pumpAndSettle();
    expect(find.text('Enter all five letters first'), findsOneWidget);
    expect(provider.attempts, 0);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await submitWord(tester, 'XXXXX');
    expect(find.text('Not a word in my dictionary'), findsOneWidget);
    expect(find.text('Attempt 1 of 6'), findsOneWidget);
    expect(provider.attempts, 0);
    expect(provider.rowInputs.join(), 'XXXXX');
    expect(tester.takeException(), isNull);
  });

  testWidgets('winning dialog Play Again clears the board and attempts', (
    tester,
  ) async {
    await pumpGame(tester, provider);
    await submitWord(tester, 'GRAPE');
    expect(find.text('Attempt 2 of 6'), findsOneWidget);
    expect(provider.excludedLetters, isNotEmpty);

    await submitWord(tester, 'APPLE');
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('You Win!!!'), findsOneWidget);
    expect(find.text('The word was APPLE'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Play Again'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Attempt 1 of 6'), findsOneWidget);
    expect(provider.attempts, 0);
    expect(provider.excludedLetters, isEmpty);
    expect(provider.hurdleBoard.every((cell) => cell.letter.isEmpty), isTrue);
    await typeWord(tester, 'A');
    expect(provider.rowInputs, ['A']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sixth wrong word loses, Quit locks input, New game resets', (
    tester,
  ) async {
    await pumpGame(tester, provider);
    for (var attempt = 0; attempt < 6; attempt++) {
      await submitWord(tester, 'GRAPE');
    }
    expect(find.text('You lost!!'), findsOneWidget);
    expect(find.text('The word was APPLE'), findsOneWidget);
    expect(provider.attempts, 6);

    await tester.tap(find.widgetWithText(TextButton, 'Quit'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('No attempts left'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'SUBMIT'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widgetList<ElevatedButton>(
            find.descendant(
              of: find.byType(KeyboardView),
              matching: find.byType(ElevatedButton),
            ),
          )
          .every((button) => button.onPressed == null),
      isTrue,
    );

    await tester.tap(find.byTooltip('New game'));
    await tester.pumpAndSettle();
    expect(find.text('Attempt 1 of 6'), findsOneWidget);
    expect(provider.isGameOver, isFalse);
    expect(provider.hurdleBoard.every((cell) => cell.letter.isEmpty), isTrue);
    await typeWord(tester, 'A');
    expect(provider.rowInputs, ['A']);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(360, 640), const Size(412, 892)]) {
    testWidgets('board and controls fit ${size.width}x${size.height}', (
      tester,
    ) async {
      await pumpGame(tester, provider, size: size);
      expect(find.byType(WordleView), findsNWidgets(30));
      expect(find.widgetWithText(ElevatedButton, 'SUBMIT'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'DELETE'), findsOneWidget);
      expect(tester.takeException(), isNull);
      for (final label in ['A', 'Z', 'SUBMIT', 'DELETE']) {
        final bounds = tester.getRect(
          find.widgetWithText(ElevatedButton, label),
        );
        expect(bounds.top, greaterThanOrEqualTo(0));
        expect(bounds.bottom, lessThanOrEqualTo(size.height));
      }
    });
  }

  testWidgets('landscape scrolls to the keyboard and SUBMIT without overflow', (
    tester,
  ) async {
    await pumpGame(tester, provider, size: const Size(640, 360));
    expect(tester.takeException(), isNull);

    for (final letter in 'GRAPE'.split('')) {
      final key = find.widgetWithText(ElevatedButton, letter);
      await tester.ensureVisible(key);
      await tester.pumpAndSettle();
      await tester.tap(key);
      await tester.pump();
    }
    expect(provider.rowInputs.join(), 'GRAPE');

    final submit = find.widgetWithText(ElevatedButton, 'SUBMIT');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(provider.attempts, 1);
    expect(provider.rowInputs, isEmpty);
    expect(provider.hurdleBoard.first.letter, 'G');
    expect(tester.takeException(), isNull);
  });
}
