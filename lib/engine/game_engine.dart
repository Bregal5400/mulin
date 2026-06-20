import '../models/card.dart';
import '../models/game_state.dart';
import 'card_deck.dart';
import 'trick_evaluator.dart';
import 'ai_player.dart';

class GameEngine {
  GameState state;

  GameEngine(this.state);

  static GameEngine newGame(List<String> playerNames, int humanCount) {
    final players = playerNames.asMap().entries.map((e) =>
      Player(id: 'p${e.key}', name: e.value, isHuman: e.key < humanCount)
    ).toList();

    final engine = GameEngine(GameState(players: players));
    engine._dealCards();
    return engine;
  }

  void _dealCards() {
    final deck = CardDeck.shuffle(CardDeck.createDeck());
    final hands = CardDeck.deal(deck, state.playerCount, 5);

    for (int i = 0; i < state.playerCount; i++) {
      state.players[i] = state.players[i].copyWith(
        hand: hands[i],
        tricksThisRound: 0,
      );
    }

    state.currentTrickPlays = [];
    state.completedTricks = [];
    state.currentBid = null;
    state.trumpSuit = null;
    state.biddingPassCount = 0;
    state.phase = GamePhase.bidding;
    state.currentPlayerIndex = (state.dealerIndex + 1) % state.playerCount;
    state.message = _biddingMessage();
  }

  String _biddingMessage() {
    final mult = state.pendingMultiplier > 1 ? ' (${state.pendingMultiplier}×)' : '';
    return '${state.currentPlayer.name} ist am Ansagen$mult';
  }

  /// Spieler sagt an oder passt. Gibt true zurück wenn Ansage akzeptiert.
  bool placeBid(String playerId, Bid? bid) {
    if (state.phase != GamePhase.bidding) return false;
    if (state.currentPlayer.id != playerId) return false;

    if (bid != null) {
      // Validierung
      if (bid.tricks == 1 && bid.suit != CardSuit.herz) return false;
      if (bid.tricks < 1 || bid.tricks > 5) return false;

      state.currentBid = bid;
      state.trumpSuit = bid.suit;
      state.phase = GamePhase.playing;
      state.currentPlayerIndex = (state.dealerIndex + 1) % state.playerCount;
      state.message = '${state.players.firstWhere((p) => p.id == bid.playerId).name} sagt ${bid.tricks} Stich(e) auf ${bid.suit.displayName} an! (${state.effectiveMultiplier}×)';
      return true;
    } else {
      // Passen
      state.biddingPassCount++;
      if (state.biddingPassCount >= state.playerCount) {
        // Alle haben gepasst → Schönern
        _triggerSchoener();
        return true;
      }
      state.currentPlayerIndex = (state.currentPlayerIndex + 1) % state.playerCount;
      state.message = _biddingMessage();
      return true;
    }
  }

  void _triggerSchoener() {
    state.pendingMultiplier++;
    state.message = 'Schönern! Nächste Runde gilt ${state.pendingMultiplier}×';
    state.phase = GamePhase.bidding;
    // Geber wechselt
    state.dealerIndex = (state.dealerIndex + 1) % state.playerCount;
    Future.delayed(const Duration(seconds: 2), () {
      _dealCards();
    });
  }

  /// Spieler spielt eine Karte. Gibt true zurück wenn legal.
  bool playCard(String playerId, GameCard card) {
    if (state.phase != GamePhase.playing) return false;
    if (state.currentPlayer.id != playerId) return false;

    final player = state.currentPlayer;
    if (!player.hand.contains(card)) return false;

    if (!TrickEvaluator.isLegalPlay(card, player.hand, state.currentTrickPlays, state.trumpSuit)) {
      return false;
    }

    // Karte spielen
    final newHand = List<GameCard>.from(player.hand)..remove(card);
    state.players[state.currentPlayerIndex] = player.copyWith(hand: newHand);
    state.currentTrickPlays.add(CardPlay(playerId: playerId, card: card));

    if (state.currentTrickPlays.length >= state.playerCount) {
      _evaluateTrick();
    } else {
      state.currentPlayerIndex = (state.currentPlayerIndex + 1) % state.playerCount;
      state.message = '${state.currentPlayer.name} ist am Zug';
    }

    return true;
  }

  void _evaluateTrick() {
    final winnerId = TrickEvaluator.evaluateTrick(state.currentTrickPlays, state.trumpSuit);
    final trick = Trick(plays: List.from(state.currentTrickPlays), winnerId: winnerId);
    state.completedTricks.add(trick);

    final winnerIndex = state.players.indexWhere((p) => p.id == winnerId);
    state.players[winnerIndex] = state.players[winnerIndex].copyWith(
      tricksThisRound: state.players[winnerIndex].tricksThisRound + 1,
    );

    state.lastTrickWinnerId = winnerId;
    state.currentTrickPlays = [];
    state.currentPlayerIndex = winnerIndex;

    // Prüfe ob Runde vorbei (alle Karten gespielt)
    final handsEmpty = state.players.every((p) => p.hand.isEmpty);
    if (handsEmpty) {
      _endRound();
    } else {
      state.message = '${state.players[winnerIndex].name} gewinnt den Stich!';
    }
  }

  void _endRound() {
    final bid = state.currentBid;
    final multiplier = state.effectiveMultiplier;

    if (bid == null) {
      // Sollte nicht passieren (Schönern wurde schon behandelt)
      state.phase = GamePhase.roundEnd;
      return;
    }

    final bidder = state.players.firstWhere((p) => p.id == bid.playerId);
    final tricksWon = bidder.tricksThisRound;
    final bidSuccess = tricksWon >= bid.tricks;

    // Punkte vergeben
    for (int i = 0; i < state.players.length; i++) {
      final p = state.players[i];
      int roundScore = 0;

      if (p.id == bid.playerId) {
        roundScore = bidSuccess
            ? bid.tricks * multiplier      // Ansager: Stiche × Multiplikator
            : -(bid.tricks * multiplier);  // Ansager verfehlt: Minus
      } else {
        // Anderen Spieler bekommen Punkte für ihre Stiche
        roundScore = p.tricksThisRound * multiplier;
      }

      state.players[i] = p.copyWith(totalScore: p.totalScore + roundScore);
    }

    // Multiplikator zurücksetzen nach gespielter Runde
    state.pendingMultiplier = 1;
    state.roundNumber++;
    state.phase = GamePhase.roundEnd;

    final result = bidSuccess
        ? '${bidder.name} hat ${bid.tricks} Stich(e) gemacht! +${bid.tricks * multiplier} Punkte'
        : '${bidder.name} hat die Ansage verfehlt! ${bid.tricks * multiplier} Punkte Abzug';
    state.message = result;
  }

  /// Startet nächste Runde
  void nextRound() {
    state.dealerIndex = (state.dealerIndex + 1) % state.playerCount;
    _dealCards();
  }

  /// Prüft ob ein KI-Spieler am Zug ist und gibt seinen Zug zurück
  AiAction? getAiAction() {
    final current = state.currentPlayer;
    if (current.isHuman) return null;

    if (state.phase == GamePhase.bidding) {
      final bid = AiPlayer.chooseBid(current, state.trumpSuit, state.biddingPassCount == state.playerCount - 1);
      return AiAction(type: AiActionType.bid, bid: bid);
    }

    if (state.phase == GamePhase.playing) {
      final card = AiPlayer.chooseCard(current, state.currentTrickPlays, state.trumpSuit);
      return AiAction(type: AiActionType.playCard, card: card);
    }

    return null;
  }
}

enum AiActionType { bid, playCard }

class AiAction {
  final AiActionType type;
  final Bid? bid;
  final GameCard? card;

  const AiAction({required this.type, this.bid, this.card});
}
