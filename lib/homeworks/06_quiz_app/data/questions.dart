import '../models/quiz_question.dart';

// Prvá odpoveď pri každej otázke je vždy správna.
// Pred zobrazením sa poradie odpovedí zamieša cez shuffle().
const List<QuizQuestion> questions = [
  QuizQuestion(
    'Ktorý widget je určený na prácu s meniacim sa stavom?',
    ['StatefulWidget', 'StatelessWidget', 'Text', 'Icon'],
  ),
  QuizQuestion(
    'Ktorá metóda oznámi Flutteru, že sa stav widgetu zmenil?',
    ['setState()', 'build()', 'dispose()', 'runApp()'],
  ),
  QuizQuestion(
    'Ktorý operátor rozbalí prvky zoznamu do children?',
    ['...', '??', '==', '=>'],
  ),
  QuizQuestion(
    'Na čo slúži metóda map() pri práci so zoznamom?',
    [
      'Na transformáciu jednotlivých prvkov',
      'Na vymazanie všetkých prvkov',
      'Na zoradenie prvkov podľa abecedy',
      'Na ukončenie aplikácie',
    ],
  ),
  QuizQuestion(
    'Aké hodnoty môže vrátiť Random().nextInt(6)?',
    ['0 až 5', '1 až 6', '0 až 6', '1 až 5'],
  ),
  QuizQuestion(
    'Ktorý widget umožní posúvať obsah, ktorý sa nezmestí na obrazovku?',
    ['SingleChildScrollView', 'SizedBox', 'Center', 'Opacity'],
  ),
];
