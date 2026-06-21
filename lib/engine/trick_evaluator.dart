import '../models/card.dart';
import '../models/game_state.dart';

class TrickEvaluator {
  static String evaluateTrick(List<CardPlay> plays, CardSuit? trumpSuit) {
    if (plays.isEmpty) throw StateError('Keine Karten im Stich');

    final leadSuit = plays.first.card.suit;
    CardPlay? winner = plays.first;
    int winnerStrength = _cardStrength(plays.first.card, leadSuit, trumpSuit);

    for (int i = 1; i < plays.length; i++) {
      final strength = _cardStrength(plays[i].card, leadSuit, trumpSuit);
      if (strength > winnerStrength) {
        winner = plays[i];
        winnerStrength = strength;
      }
    }

    return winner!.playerId;
  }

  static int _cardStrength(GameCard card, CardSuit leadSuit, CardSuit? trumpSuit) {
    if (card.isWeli) return 1000; // Weli schlägt alles

    if (trumpSuit != null && card.suit == trumpSuit) {
      return 100 + card.value.sortOrder; // Trumpf schlägt Beifarbe
    }

    if (card.suit == leadSuit) {
      return card.value.sortOrder; // Angespielt zählt
    }

    return 0; // Andere Farbe, kein Trumpf → kein Stich
  }

  static bool canFollowSuit(List<GameCard> hand, CardSuit leadSuit) {
    return hand.any((c) => c.suit == leadSuit && !c.isWeli);
  }

  static bool canPlayTrump(List<GameCard> hand, CardSuit? trumpSuit) {
    return hand.any((c) => c.isTrump(trumpSuit));
  }

  static bool isLegalPlay(GameCard card, List<GameCard> hand, List<CardPlay> currentTrick, CardSuit? trumpSuit) {
    if (currentTrick.isEmpty) return true; // Erste Karte → alles erlaubt

    final leadSuit = currentTrick.first.card.suit;

    // Weli darf immer gespielt werden
    if (card.isWeli) return true;

    // Wenn Spieler die Anspielfarbe hat → muss bekennen
    if (canFollowSuit(hand, leadSuit)) {
      return card.suit == leadSuit;
    }

    // Keine Anspielfarbe → Trumpf wenn vorhanden
    if (trumpSuit != null && canPlayTrump(hand, trumpSuit)) {
      return card.isTrump(trumpSuit);
    }

    // Kein Trumpf, keine Farbe → alles erlaubt
    return true;
  }
}
