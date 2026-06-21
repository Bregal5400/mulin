import 'package:flutter/material.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _playerCount = 4;
  final List<TextEditingController> _nameControllers = List.generate(
    4, (i) => TextEditingController(text: i == 0 ? 'Du' : 'KI ${i}'),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            color: const Color(0xFF2E7D32),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 12,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'MULATSCHAK',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Österreichisches Kartenspiel',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 32),
                  _buildPlayerCountSelector(),
                  const SizedBox(height: 24),
                  ..._buildNameFields(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _startGame,
                      child: const Text('SPIELEN'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCountSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Anzahl Spieler', style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          children: [2, 3, 4].map((n) {
            final selected = _playerCount == n;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _playerCount = n),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFFFD700) : const Color(0xFF1B5E20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selected ? const Color(0xFFFFD700) : Colors.white30),
                  ),
                  child: Text('$n',
                    style: TextStyle(
                      color: selected ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 16,
                    )),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<Widget> _buildNameFields() {
    return List.generate(_playerCount, (i) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: _nameControllers[i],
          enabled: i == 0, // Nur Spieler 1 ist menschlich
          decoration: InputDecoration(
            labelText: i == 0 ? 'Dein Name' : 'KI Spieler ${i + 1}',
            labelStyle: const TextStyle(color: Colors.white70),
            prefixIcon: Icon(i == 0 ? Icons.person : Icons.smart_toy,
              color: i == 0 ? const Color(0xFFFFD700) : Colors.white38),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white30)),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFFFD700))),
            disabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white12)),
          ),
          style: const TextStyle(color: Colors.white),
        ),
      );
    });
  }

  void _startGame() {
    final names = List.generate(_playerCount, (i) => _nameControllers[i].text.trim().isEmpty
        ? (i == 0 ? 'Du' : 'KI $i')
        : _nameControllers[i].text.trim());

    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => GameScreen(playerNames: names, humanCount: 1),
    ));
  }
}
