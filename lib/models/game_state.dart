import 'card.dart';

class Player {
  final String id;
  final String name;
  final bool isHuman;
  List<GameCard> hand;
  int totalScore;
  int tricksThisRound;

  Player({
    required this.id,
    required this.name,
    required this.isHuman,
    this.hand = const [],
    this.totalScore = 0,
    this.tricksThisRound = 0,
  });

  Player copyWith({List<GameCard>? hand, int? totalScore, int? tricksThisRound}) {
    return Player(
      id: id,
      name: name,
      isHuman: isHuman,
      hand: hand ?? this.hand,
      totalScore: totalScore ?? this.totalScore,
      tricksThisRound: tricksThisRound ?? this.tricksThisRound,
    );
  }
}

class CardPlay {
  final String playerId;
  final GameCard card;

  const CardPlay({required this.playerId, required this.card});
}

class Trick {
  final List<CardPlay> plays;
  String? winnerId;

  Trick({List<CardPlay>? plays, this.winnerId}) : plays = plays ?? [];

  CardSuit? get leadSuit => plays.isEmpty ? null : plays.first.card.suit;

  bool get isComplete => plays.length >= 2; // wird dynamisch geprüft
}

class Bid {
  final String playerId;
  final CardSuit suit;
  final int tricks;

  const Bid({required this.playerId, required this.suit, required this.tricks});
}

enum GamePhase {
  setup,
  bidding,
  playing,
  roundEnd,
  gameOver,
}

class GameState {
  List<Player> players;
  int currentPlayerIndex;
  int dealerIndex;
  GamePhase phase;
  Bid? currentBid;
  CardSuit? trumpSuit;
  List<CardPlay> currentTrickPlays;
  List<Trick> completedTricks;
  int pendingMultiplier; // Schönern-Akkumulator
  int roundNumber;
  String? lastTrickWinnerId;
  String? message;
  int biddingPassCount; // wie viele haben gepasst

  GameState({
    required this.players,
    this.currentPlayerIndex = 0,
    this.dealerIndex = 0,
    this.phase = GamePhase.setup,
    this.currentBid,
    this.trumpSuit,
    List<CardPlay>? currentTrickPlays,
    List<Trick>? completedTricks,
    this.pendingMultiplier = 1,
    this.roundNumber = 1,
    this.lastTrickWinnerId,
    this.message,
    this.biddingPassCount = 0,
  })  : currentTrickPlays = currentTrickPlays ?? [],
        completedTricks = completedTricks ?? [];

  Player get currentPlayer => players[currentPlayerIndex];

  int get effectiveMultiplier {
    final herzBonus = (trumpSuit == CardSuit.herz) ? 1 : 0;
    return pendingMultiplier + herzBonus;
  }

  int get playerCount => players.length;

  int tricksWonBy(String playerId) {
    return completedTricks.where((t) => t.winnerId == playerId).length;
  }
}
