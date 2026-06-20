import 'dart:math';
import '../models/card.dart';
import '../models/game_state.dart';
import 'trick_evaluator.dart';

class AiPlayer {
  static final _rng = Random();

  /// Wählt eine legale Karte. Versucht sinnvoll zu spielen.
  static GameCard chooseCard(Player player, List<CardPlay> currentTrick, CardSuit? trumpSuit) {
    final hand = player.hand;
    final legalCards = hand.where((c) => TrickEvaluator.isLegalPlay(c, hand, currentTrick, trumpSuit)).toList();

    if (legalCards.isEmpty) return hand.first; // Fallback

    if (currentTrick.isEmpty) {
      // Erste Karte: spiele niedrigste Nicht-Trumpf-Karte
      final nonTrump = legalCards.where((c) => !c.isTrump(trumpSuit)).toList();
      if (nonTrump.isNotEmpty) {
        nonTrump.sort((a, b) => a.value.sortOrder.compareTo(b.value.sortOrder));
        return nonTrump.first;
      }
      return legalCards[_rng.nextInt(legalCards.length)];
    }

    // Versuche Stich zu gewinnen wenn möglich
    final winningCards = legalCards.where((c) {
      final testPlays = [...currentTrick, CardPlay(playerId: player.id, card: c)];
      final winner = TrickEvaluator.evaluateTrick(testPlays, trumpSuit);
      return winner == player.id;
    }).toList();

    if (winningCards.isNotEmpty) {
      // Gewinne mit niedrigstem möglichen Wert
      winningCards.sort((a, b) => a.value.sortOrder.compareTo(b.value.sortOrder));
      return winningCards.first;
    }

    // Kein Gewinn möglich → spiele Karte mit wenigstem Wert
    legalCards.sort((a, b) => a.value.pointValue.compareTo(b.value.pointValue));
    return legalCards.first;
  }

  /// Entscheidet ob die KI ansagen soll und was
  static Bid? chooseBid(Player player, CardSuit? existingTrump, bool herzOnly) {
    final hand = player.hand;

    // Zähle Trumpfkarten (nehmen Herz als Referenz an)
    final herzCount = hand.where((c) => c.suit == CardSuit.herz || c.isWeli).length;
    final hasWeli = hand.any((c) => c.isWeli);

    // Starke Hand: ansagen
    if (herzCount >= 3 || hasWeli) {
      // Wie viele Stiche kann ich wahrscheinlich machen?
      final strongCards = hand.where((c) =>
        c.suit == CardSuit.herz && c.value.sortOrder >= CardValue.ober.sortOrder ||
        c.isWeli
      ).length;

      if (herzOnly || strongCards >= 2) {
        final tricks = strongCards.clamp(1, 4);
        if (tricks == 1) {
          return Bid(playerId: player.id, suit: CardSuit.herz, tricks: 1);
        }
        // 2-4 Stiche: nimm beste Farbe
        final bestSuit = _getBestSuit(hand);
        return Bid(playerId: player.id, suit: bestSuit, tricks: tricks);
      }
    }

    return null; // Passen
  }

  static CardSuit _getBestSuit(List<GameCard> hand) {
    final counts = <CardSuit, int>{};
    for (final suit in CardSuit.values) {
      counts[suit] = hand.where((c) => c.suit == suit).length;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}
