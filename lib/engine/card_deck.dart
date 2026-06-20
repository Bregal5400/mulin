import 'dart:math';
import '../models/card.dart';

class CardDeck {
  static List<GameCard> createDeck() {
    final cards = <GameCard>[];
    for (final suit in CardSuit.values) {
      for (final value in CardValue.values) {
        final isWeli = suit == CardSuit.schelle && value == CardValue.sechs;
        cards.add(GameCard(suit: suit, value: value, isWeli: isWeli));
      }
    }
    return cards; // 36 Karten (inkl. Weli als 6 der Schelle)
  }

  static List<GameCard> shuffle(List<GameCard> deck) {
    final rng = Random();
    final shuffled = List<GameCard>.from(deck);
    for (int i = shuffled.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final tmp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = tmp;
    }
    return shuffled;
  }

  static List<List<GameCard>> deal(List<GameCard> deck, int playerCount, int cardsPerPlayer) {
    final hands = List.generate(playerCount, (_) => <GameCard>[]);
    for (int i = 0; i < cardsPerPlayer * playerCount; i++) {
      hands[i % playerCount].add(deck[i]);
    }
    return hands;
  }
}
