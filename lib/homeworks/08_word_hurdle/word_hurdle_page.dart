import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'helper_functions.dart';
import 'hurdle_provider.dart';
import 'keyboard_view.dart';
import 'wordle_view.dart';

class WordHurdlePage extends StatefulWidget {
  const WordHurdlePage({super.key});

  @override
  State<WordHurdlePage> createState() => _WordHurdlePageState();
}

class _WordHurdlePageState extends State<WordHurdlePage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Provider.of<HurdleProvider>(context, listen: false).init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Hurdle'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'New game',
            onPressed: () => context.read<HurdleProvider>().reset(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final game = Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Consumer<HurdleProvider>(
                        builder: (context, provider, child) => Column(
                          children: [
                            Text(
                              provider.wins
                                  ? 'You won!'
                                  : provider.noAttemptsLeft
                                  ? 'No attempts left'
                                  : 'Attempt ${provider.attempts + 1} of ${provider.totalAttempts}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            const Text('Guess the five-letter English word.'),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Šesť riadkov sa zmestí aj na nižšiu obrazovku.
                          final boardWidth = min(
                            constraints.maxWidth * 0.70,
                            max(0.0, (constraints.maxHeight - 4) * 5 / 6),
                          );
                          return Center(
                            child: SizedBox(
                              width: boardWidth,
                              child: Consumer<HurdleProvider>(
                                builder: (context, provider, child) =>
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 5,
                                            mainAxisSpacing: 4,
                                            crossAxisSpacing: 4,
                                          ),
                                      itemCount: provider.hurdleBoard.length,
                                      itemBuilder: (context, index) =>
                                          WordleView(
                                            wordle: provider.hurdleBoard[index],
                                          ),
                                    ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 20,
                        runSpacing: 8,
                        children: [
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 12,
                                color: Colors.white60,
                              ),
                              SizedBox(width: 6),
                              Text('In the word'),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 12,
                                color: Colors.blueGrey.shade700,
                              ),
                              const SizedBox(width: 6),
                              const Text('Not in the word'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Consumer<HurdleProvider>(
                      builder: (context, provider, child) => KeyboardView(
                        excludedLetters: provider.excludedLetters,
                        enabled: !provider.isGameOver,
                        onPressed: (value) => provider.inputLetter(value),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Consumer<HurdleProvider>(
                        builder: (context, provider, child) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed:
                                  !provider.isGameOver &&
                                      provider.rowInputs.isNotEmpty
                                  ? provider.deleteLetter
                                  : null,
                              child: const Text('DELETE'),
                            ),
                            ElevatedButton(
                              onPressed: provider.isGameOver
                                  ? null
                                  : () => _handleInput(provider),
                              child: const Text('SUBMIT'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
            // Na nízkej obrazovke ostane celá hra dostupná posúvaním.
            if (constraints.maxHeight < 500) {
              return SingleChildScrollView(
                child: SizedBox(height: 600, child: game),
              );
            }
            return game;
          },
        ),
      ),
    );
  }

  void _handleInput(HurdleProvider provider) {
    if (provider.isGameOver) return;

    // Dĺžku kontrolujeme pred slovníkom, aby bola správa zrozumiteľná.
    if (!provider.shouldCheckForAnswer) {
      showMsg(context, 'Enter all five letters first');
      return;
    }
    if (!provider.isAValidWord) {
      showMsg(context, 'Not a word in my dictionary');
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    provider.checkAnswer();

    if (provider.wins || provider.noAttemptsLeft) {
      showResult(
        context: context,
        title: provider.wins ? 'You Win!!!' : 'You lost!!',
        body: 'The word was ${provider.targetWord}',
        onPlayAgain: () {
          Navigator.pop(context);
          provider.reset();
        },
        onCancel: () => Navigator.pop(context),
      );
    }
  }
}
