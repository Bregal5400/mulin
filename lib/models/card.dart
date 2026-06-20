enum CardSuit {
  herz,
  laub,
  schelle,
  eichel;

  String get displayName {
    switch (this) {
      case CardSuit.herz: return 'Herz';
      case CardSuit.laub: return 'Laub';
      case CardSuit.schelle: return 'Schelle';
      case CardSuit.eichel: return 'Eichel';
    }
  }

  String get symbol {
    switch (this) {
      case CardSuit.herz: return '♥';
      case CardSuit.laub: return '♠';
      case CardSuit.schelle: return '♦';
      case CardSuit.eichel: return '♣';
    }
  }
}

enum CardValue {
  sechs,
  sieben,
  acht,
  neun,
  zehn,
  unter,
  ober,
  koenig,
  ass;

  String get displayName {
    switch (this) {
      case CardValue.sechs: return '6';
      case CardValue.sieben: return '7';
      case CardValue.acht: return '8';
      case CardValue.neun: return '9';
      case CardValue.zehn: return '10';
      case CardValue.unter: return 'U';
      case CardValue.ober: return 'O';
      case CardValue.koenig: return 'K';
      case CardValue.ass: return 'A';
    }
  }

  int get pointValue {
    switch (this) {
      case CardValue.ass: return 11;
      case CardValue.zehn: return 10;
      case CardValue.koenig: return 4;
      case CardValue.ober: return 3;
      case CardValue.unter: return 2;
      default: return 0;
    }
  }

  int get sortOrder {
    switch (this) {
      case CardValue.ass: return 9;
      case CardValue.koenig: return 8;
      case CardValue.ober: return 7;
      case CardValue.unter: return 6;
      case CardValue.zehn: return 5;
      case CardValue.neun: return 4;
      case CardValue.acht: return 3;
      case CardValue.sieben: return 2;
      case CardValue.sechs: return 1;
    }
  }
}

class GameCard {
  final CardSuit suit;
  final CardValue value;
  final bool isWeli;

  const GameCard({required this.suit, required this.value, this.isWeli = false});

  String get id => isWeli ? 'WELI' : '${suit.name}_${value.name}';

  int get pointValue => value.pointValue;

  bool isTrump(CardSuit? trumpSuit) {
    if (isWeli) return true;
    return suit == trumpSuit;
  }

  int trumpStrength(CardSuit? trumpSuit) {
    if (isWeli) return 100; // Weli ist immer höchster Trumpf
    if (suit == trumpSuit) return value.sortOrder;
    return 0;
  }

  @override
  String toString() => isWeli ? 'Weli' : '${value.displayName} ${suit.displayName}';

  @override
  bool operator ==(Object other) => other is GameCard && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
