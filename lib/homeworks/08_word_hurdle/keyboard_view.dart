import 'package:flutter/material.dart';

const keyList = [
  ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
  ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
  ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
];

class KeyboardView extends StatelessWidget {
  final List<String> excludedLetters;
  final ValueChanged<String> onPressed;
  final bool enabled;

  const KeyboardView({
    super.key,
    required this.excludedLetters,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < keyList.length; i++)
              Row(
                children: keyList[i]
                    .map(
                      (letter) => VirtualKey(
                        letter: letter,
                        excluded: excludedLetters.contains(letter),
                        enabled: enabled,
                        onPress: (value) => onPressed(value),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class VirtualKey extends StatelessWidget {
  final String letter;
  final bool excluded;
  final ValueChanged<String> onPress;
  final bool enabled;

  const VirtualKey({
    super.key,
    required this.letter,
    required this.excluded,
    required this.onPress,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: excluded ? Colors.red : Colors.black,
            foregroundColor: Colors.white,
            disabledBackgroundColor: excluded
                ? Colors.red.shade900
                : Colors.black54,
            disabledForegroundColor: Colors.white54,
            minimumSize: const Size(0, 44),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: enabled ? () => onPress(letter) : null,
          child: Text(letter),
        ),
      ),
    );
  }
}
