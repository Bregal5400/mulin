import 'dart:async';
import 'package:flutter/material.dart';
import '../engine/game_engine.dart';
import '../models/card.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../widgets/card_widget.dart';
import 'home_screen.dart';

class GameScreen extends StatefulWidget {
  final List<String> playerNames;
  final int humanCount;

  const GameScreen({super.key, required this.playerNames, required this.humanCount});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameEngine _engine;
  GameCard? _selectedCard;
  Timer? _aiTimer;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    _engine = GameEngine.newGame(widget.playerNames, widget.humanCount);
    _scheduleAiIfNeeded();
  }

  @override
  void dispose() {
    _aiTimer?.cancel();
    _messageTimer?.cancel();
    super.dispose();
  }

  GameState get _state => _engine.state;
  Player get _humanPlayer => _state.players.firstWhere((p) => p.isHuman);

  void _scheduleAiIfNeeded() {
    if (_state.phase == GamePhase.roundEnd || _state.phase == GamePhase.gameOver) return;

    final action = _engine.getAiAction();
    if (action == null) return;

    _aiTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        if (action.type == AiActionType.bid) {
          _engine.placeBid(_state.currentPlayer.id, action.bid);
        } else if (action.type == AiActionType.playCard && action.card != null) {
          _engine.playCard(_state.currentPlayer.id, action.card!);
        }
        _scheduleAiIfNeeded();
      });
    });
  }

  void _onCardTap(GameCard card) {
    if (_state.phase != GamePhase.playing) return;
    if (!_state.currentPlayer.isHuman) return;

    setState(() {
      if (_selectedCard == card) {
        // Zweiter Tap → Karte spielen
        final played = _engine.playCard(_state.currentPlayer.id, card);
        if (played) {
          _selectedCard = null;
          _scheduleAiIfNeeded();
        }
      } else {
        _selectedCard = card;
      }
    });
  }

  void _onBid(Bid? bid) {
    setState(() {
      _engine.placeBid(_state.currentPlayer.id, bid);
      _scheduleAiIfNeeded();
    });
  }

  void _nextRound() {
    setState(() {
      _engine.nextRound();
      _selectedCard = null;
      _scheduleAiIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildGameArea()),
            _buildBottomArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.black26,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('MULATSCHAK',
            style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          _buildMultiplierBadge(),
          const SizedBox(width: 12),
          if (_state.trumpSuit != null) _buildTrumpBadge(),
          const SizedBox(width: 12),
          Text('Runde ${_state.roundNumber}',
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white54),
            onPressed: () => Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const HomeScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiplierBadge() {
    final mult = _state.effectiveMultiplier;
    if (mult <= 1) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: mult >= 4 ? Colors.red : const Color(0xFFFFD700),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('${mult}×',
        style: TextStyle(
          color: mult >= 4 ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold, fontSize: 14,
        )),
    );
  }

  Widget _buildTrumpBadge() {
    final suit = _state.trumpSuit!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: suitColor(suit).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: suitColor(suit)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(suit.symbol, style: TextStyle(color: suitColor(suit), fontSize: 14)),
          const SizedBox(width: 4),
          Text(suit.displayName,
            style: TextStyle(color: suitColor(suit), fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildGameArea() {
    return Column(
      children: [
        // Andere Spieler
        _buildOpponentArea(),
        // Spieltisch / Stich
        Expanded(child: _buildTrickArea()),
        // Status-Nachricht
        _buildStatusMessage(),
      ],
    );
  }

  Widget _buildOpponentArea() {
    final opponents = _state.players.where((p) => !p.isHuman).toList();
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: opponents.map((p) => _buildPlayerInfo(p)).toList(),
      ),
    );
  }

  Widget _buildPlayerInfo(Player player) {
    final isActive = _state.currentPlayer.id == player.id;
    final tricksWon = _state.tricksWonBy(player.id);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.white12 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? Border.all(color: const Color(0xFFFFD700), width: 2)
            : Border.all(color: Colors.transparent),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.smart_toy, color: isActive ? const Color(0xFFFFD700) : Colors.white54, size: 16),
              const SizedBox(width: 4),
              Text(player.name,
                style: TextStyle(
                  color: isActive ? const Color(0xFFFFD700) : Colors.white70,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                )),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${player.totalScore} Pkt',
                style: const TextStyle(color: Colors.white, fontSize: 12)),
              const SizedBox(width: 8),
              Text('✓ $tricksWon',
                style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          // Kartenrücken anzeigen
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              player.hand.length,
              (i) => Padding(
                padding: const EdgeInsets.only(right: 2),
                child: CardWidget(card: player.hand[i], faceDown: true, width: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrickArea() {
    final plays = _state.currentTrickPlays;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF145214),
        borderRadius: BorderRadius.circular(60),
        border: Border.all(color: Colors.white12),
      ),
      child: plays.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.style, color: Colors.white12, size: 48),
                  const SizedBox(height: 8),
                  Text(_state.phase == GamePhase.bidding ? 'Ansage-Phase' : 'Karte spielen...',
                    style: const TextStyle(color: Colors.white24, fontSize: 14)),
                ],
              ),
            )
          : Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: plays.map((play) {
                  final playerName = _state.players
                      .firstWhere((p) => p.id == play.playerId).name;
                  return Column(
                    children: [
                      CardWidget(card: play.card, width: 60),
                      const SizedBox(height: 4),
                      Text(playerName,
                        style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  );
                }).toList(),
              ),
            ),
    );
  }

  Widget _buildStatusMessage() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(_state.message),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          _state.message ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildBottomArea() {
    switch (_state.phase) {
      case GamePhase.bidding:
        return _state.currentPlayer.isHuman
            ? _buildBiddingPanel()
            : _buildWaitingPanel('${_state.currentPlayer.name} überlegt...');
      case GamePhase.playing:
        return _state.currentPlayer.isHuman
            ? _buildHandPanel()
            : _buildWaitingPanel('${_state.currentPlayer.name} spielt...');
      case GamePhase.roundEnd:
        return _buildRoundEndPanel();
      case GamePhase.gameOver:
        return _buildGameOverPanel();
      default:
        return const SizedBox(height: 80);
    }
  }

  Widget _buildBiddingPanel() {

    return Container(
      color: Colors.black26,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Ansage wählen:',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              // 1 Stich → nur Herz
              _bidButton(1, CardSuit.herz),
              // 2-4 Stiche → alle Farben
              for (int t = 2; t <= 5; t++)
                for (final suit in CardSuit.values)
                  _bidButton(t, suit),
              // Passen
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white30),
                ),
                onPressed: () => _onBid(null),
                child: const Text('Passen'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bidButton(int tricks, CardSuit suit) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: suitColor(suit),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: const Size(0, 36),
      ),
      onPressed: () => _onBid(Bid(
        playerId: _humanPlayer.id,
        suit: suit,
        tricks: tricks,
      )),
      child: Text('$tricks ${suit.symbol}', style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _buildHandPanel() {
    final hand = _humanPlayer.hand;
    final isMyTurn = _state.currentPlayer.id == _humanPlayer.id;
    final tricksWon = _state.tricksWonBy(_humanPlayer.id);
    final bid = _state.currentBid;

    return Container(
      color: Colors.black26,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person, color: isMyTurn ? const Color(0xFFFFD700) : Colors.white54, size: 16),
              const SizedBox(width: 4),
              Text(_humanPlayer.name,
                style: TextStyle(
                  color: isMyTurn ? const Color(0xFFFFD700) : Colors.white70,
                  fontWeight: FontWeight.bold, fontSize: 14,
                )),
              const SizedBox(width: 16),
              Text('${_humanPlayer.totalScore} Pkt',
                style: const TextStyle(color: Colors.white, fontSize: 13)),
              const SizedBox(width: 16),
              Text('✓ $tricksWon${bid != null && bid.playerId == _humanPlayer.id ? '/${bid.tricks}' : ''}',
                style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          if (isMyTurn && _selectedCard == null)
            const Text('Tippe auf eine Karte um sie auszuwählen',
              style: TextStyle(color: Colors.white54, fontSize: 11)),
          if (isMyTurn && _selectedCard != null)
            const Text('Nochmal tippen um die Karte zu spielen',
              style: TextStyle(color: Colors.lightGreenAccent, fontSize: 11)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: hand.map((card) {
                final isPlayable = isMyTurn && _engine.state.phase == GamePhase.playing;
                final isSelected = _selectedCard == card;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: CardWidget(
                    card: card,
                    selected: isSelected,
                    playable: isPlayable && !isSelected,
                    onTap: isPlayable ? () => _onCardTap(card) : null,
                    width: 62,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingPanel(String text) {
    return Container(
      color: Colors.black26,
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
          ),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white54, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildRoundEndPanel() {
    final bid = _state.currentBid;
    return Container(
      color: Colors.black26,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Runde beendet',
            style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ..._state.players.map((p) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(p.name,
                  style: TextStyle(
                    color: bid?.playerId == p.id ? const Color(0xFFFFD700) : Colors.white,
                    fontWeight: bid?.playerId == p.id ? FontWeight.bold : FontWeight.normal,
                  )),
                const SizedBox(width: 12),
                Text('${p.totalScore} Punkte (✓ ${p.tricksThisRound})',
                  style: const TextStyle(color: Colors.white70)),
              ],
            ),
          )),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
            onPressed: _nextRound,
            child: const Text('Nächste Runde'),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverPanel() {
    final sorted = List<Player>.from(_state.players)
      ..sort((a, b) => b.totalScore.compareTo(a.totalScore));
    final winner = sorted.first;

    return Container(
      color: Colors.black45,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🏆 ${winner.name} gewinnt!',
            style: const TextStyle(color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...sorted.map((p) => Text(
            '${sorted.indexOf(p) + 1}. ${p.name}: ${p.totalScore} Punkte',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          )),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700)),
            onPressed: () => Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const HomeScreen())),
            child: const Text('Hauptmenü', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
