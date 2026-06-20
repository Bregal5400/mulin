import 'package:flutter/material.dart';
import '../models/card.dart';
import '../theme/app_theme.dart';

class CardWidget extends StatefulWidget {
  final GameCard card;
  final bool faceDown;
  final bool selected;
  final bool playable;
  final VoidCallback? onTap;
  final double width;

  const CardWidget({
    super.key,
    required this.card,
    this.faceDown = false,
    this.selected = false,
    this.playable = false,
    this.onTap,
    this.width = 60,
  });

  @override
  State<CardWidget> createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget> with SingleTickerProviderStateMixin {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final height = widget.width * 1.5;
    final offset = widget.selected ? -12.0 : (_hovered && widget.playable ? -6.0 : 0.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.translationValues(0, offset, 0),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: widget.width,
            height: height,
            decoration: BoxDecoration(
              color: widget.faceDown ? const Color(0xFF1565C0) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.selected ? Colors.yellow : (widget.playable ? Colors.lightGreenAccent : Colors.grey.shade400),
                width: widget.selected || widget.playable ? 2.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: widget.selected ? 12 : 4,
                  offset: const Offset(2, 3),
                ),
              ],
            ),
            child: widget.faceDown ? _buildBack() : _buildFront(),
          ),
        ),
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text('🂠', style: TextStyle(fontSize: widget.width * 0.5)),
      ),
    );
  }

  Widget _buildFront() {
    final color = widget.card.isWeli ? const Color(0xFF7B1FA2) : suitColor(widget.card.suit);
    final symbol = widget.card.isWeli ? '★' : widget.card.suit.symbol;
    final valueText = widget.card.isWeli ? 'W' : widget.card.value.displayName;
    final small = widget.width * 0.22;
    final large = widget.width * 0.38;

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(valueText, style: TextStyle(color: color, fontSize: small, fontWeight: FontWeight.bold)),
                  Text(symbol, style: TextStyle(color: color, fontSize: small)),
                ],
              ),
            ],
          ),
          Text(symbol, style: TextStyle(color: color, fontSize: large)),
          RotatedBox(
            quarterTurns: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(valueText, style: TextStyle(color: color, fontSize: small, fontWeight: FontWeight.bold)),
                Text(symbol, style: TextStyle(color: color, fontSize: small)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
