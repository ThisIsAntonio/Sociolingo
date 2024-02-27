import 'dart:math';

class MathChallenge {
  late int number1;
  late int number2;
  late int correctAnswer;

  MathChallenge() {
    _generateNewChallenge();
  }

  void _generateNewChallenge() {
    number1 = _randomNumber();
    number2 = _randomNumber();
    correctAnswer = number1 +
        number2; // You can change this to another operation if you wish
  }

  bool checkAnswer(int userAnswer) {
    return userAnswer == correctAnswer;
  }

  int _randomNumber() {
    return Random().nextInt(10); // Generates a number between 0 and 9
  }

  String getQuestion() {
    return "$number1 + $number2"; // You can change this to reflect the operation used
  }
}
