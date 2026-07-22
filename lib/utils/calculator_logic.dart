import 'dart:async';

enum CardSuit {
  hearts('♥', 'Черви'),
  diamonds('♦', 'Бубны'),
  clubs('♣', 'Трефы'),
  spades('♠', 'Пики');

  final String symbol;
  final String name;
  const CardSuit(this.symbol, this.name);
}

class CalculatorLogic {
  String _display = '0';
  String _textResult = '';
  double? _previousValue;
  String? _operation;
  bool _waitingForOperand = false;
  bool _isSpecialMode = false;
  bool _useCustomNumber = false;
  String _customNumber = '';

  // Text mode
  bool _isTextMode = false;
  String _customText = '';
  CardSuit _selectedSuit = CardSuit.hearts;

  // 3 independent booleans
  bool _isBlocked = false;
  bool _isDivisionBlocked = false;
  bool _isPartiallyBlocked = false;

  Timer? _longPressTimer;
  Timer? _blockTimer;
  Timer? _unblockTimer;
  Timer? _divisionBlockTimer;
  Timer? _divisionResultTimer;

  Function()? onStateChanged;

  String get display => _textResult.isNotEmpty ? _textResult : _display;
  bool get isSpecialMode => _isSpecialMode;
  bool get useCustomNumber => _useCustomNumber;
  String get customNumber => _customNumber;

  bool get isBlocked => _isBlocked;
  bool get isDivisionBlocked => _isDivisionBlocked;
  bool get isPartiallyBlocked => _isPartiallyBlocked;

  bool get isTextMode => _isTextMode;
  String get customText => _customText;
  CardSuit get selectedSuit => _selectedSuit;
  bool get showingText => _textResult.isNotEmpty;

  String get displayText => _textResult;

  void setCustomNumber(bool use, String number) {
    _useCustomNumber = use;
    _customNumber = number;
  }

  void setTextMode(bool enabled) {
    _isTextMode = enabled;
  }

  void setCustomText(String text) {
    _customText = text;
  }

  void setCardSuit(CardSuit suit) {
    _selectedSuit = suit;
  }

  void _notify() {
    onStateChanged?.call();
  }

  void inputDigit(String digit) {
    if (_isBlocked || _isDivisionBlocked || _isPartiallyBlocked) return;

    // Clear text result on new input
    if (_textResult.isNotEmpty) {
      _textResult = '';
    }

    if (_waitingForOperand) {
      _display = digit;
      _waitingForOperand = false;
    } else {
      _display = _display == '0' ? digit : _display + digit;
    }
  }

  void inputDecimal() {
    if (_isBlocked || _isDivisionBlocked || _isPartiallyBlocked) return;

    if (_textResult.isNotEmpty) {
      _textResult = '';
    }

    if (_waitingForOperand) {
      _display = '0.';
      _waitingForOperand = false;
    } else if (!_display.contains('.')) {
      _display = '$_display.';
    }
  }

  void clear() {
    if (_isBlocked || _isDivisionBlocked) return;

    _display = '0';
    _textResult = '';
    _previousValue = null;
    _operation = null;
    _waitingForOperand = false;
    _isSpecialMode = false;
    _isPartiallyBlocked = false;
  }

  void toggleSign() {
    if (_isBlocked || _isDivisionBlocked || _isPartiallyBlocked) return;

    if (_isTextMode) {
      // Show text: custom text or suit symbol
      final text = _customText.isNotEmpty ? _customText : _selectedSuit.symbol;
      _textResult = text;
      _waitingForOperand = true;
      _notify();
      return;
    }

    if (_display != '0') {
      if (_display.startsWith('-')) {
        _display = _display.substring(1);
      } else {
        _display = '-$_display';
      }
    }
  }

  double _calculate(double first, double second, String op) {
    switch (op) {
      case '+':
        return first + second;
      case '-':
        return first - second;
      case '×':
        return first * second;
      case '÷':
        return first / second;
      case '=':
        return second;
      default:
        return second;
    }
  }

  void performOperation(String nextOperation) {
    if (_isBlocked || _isDivisionBlocked || _isPartiallyBlocked) return;

    final inputValue = double.tryParse(_display) ?? 0;

    if (_previousValue == null) {
      _previousValue = inputValue;
    } else if (_operation != null) {
      final newValue = _calculate(_previousValue!, inputValue, _operation!);
      _display = _formatResult(newValue);
      _previousValue = newValue;
    }

    _waitingForOperand = true;
    _operation = nextOperation;
  }

  void executeCalculation() {
    if (_isBlocked || _isDivisionBlocked) return;

    final inputValue = double.tryParse(_display) ?? 0;

    if (_previousValue != null && _operation != null) {
      double newValue;

      if (_isSpecialMode) {
        final now = DateTime.now();
        final timeString =
            '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
        _display = timeString;
        _isSpecialMode = false;
        newValue = double.tryParse(timeString) ?? 0;
      } else {
        newValue = _calculate(_previousValue!, inputValue, _operation!);
        _display = _formatResult(newValue);
      }

      _previousValue = newValue;
      _operation = null;
      _waitingForOperand = true;
    }
  }

  int _generateAutoNumber() {
    final now = DateTime.now();
    final day = now.day;
    final month = now.month.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return int.parse('$day$month$hour$minute');
  }

  void performDivisionOperation() {
    if (_isBlocked || _isDivisionBlocked || _isPartiallyBlocked) return;

    _isDivisionBlocked = true;
    _isPartiallyBlocked = true;

    _divisionResultTimer?.cancel();
    _divisionResultTimer = Timer(const Duration(seconds: 1), () {
      final currentValue = double.tryParse(_display) ?? 0;
      double result;

      if (_useCustomNumber && _customNumber.isNotEmpty) {
        final viewerNumber = int.tryParse(_customNumber) ?? 0;
        result = viewerNumber - currentValue;
      } else {
        final autoNumber = _generateAutoNumber();
        result = autoNumber - currentValue + 1;
      }

      _display = _formatResult(result);
      _textResult = '';
      _waitingForOperand = true;
      _notify();
    });

    _divisionBlockTimer?.cancel();
    _divisionBlockTimer = Timer(const Duration(seconds: 7), () {
      _isDivisionBlocked = false;
      _isPartiallyBlocked = false;
      _notify();
    });
  }

  void startPlusLongPress() {
    _longPressTimer = Timer(const Duration(seconds: 2), () {
      _blockTimer = Timer(const Duration(seconds: 3), () {
        _isBlocked = true;
        _performSpecialOperation();
        _notify();

        _unblockTimer = Timer(const Duration(seconds: 5), () {
          _isBlocked = false;
          _notify();
        });
      });
    });
  }

  void cancelPlusLongPress() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
    _blockTimer?.cancel();
    _blockTimer = null;
  }

  void _performSpecialOperation() {
    final currentValue = double.tryParse(_display) ?? 0;
    double result;

    if (_useCustomNumber && _customNumber.isNotEmpty) {
      final viewerNumber = int.tryParse(_customNumber) ?? 0;
      result = viewerNumber - currentValue;
    } else {
      final autoNumber = _generateAutoNumber();
      result = autoNumber - currentValue + 1;
    }

    _display = _formatResult(result);
    _isSpecialMode = true;
    _waitingForOperand = true;
  }

  String _formatResult(double value) {
    if (value == value.toInt().toDouble()) {
      return value.toInt().toString();
    }
    final formatted = value.toStringAsFixed(10);
    return formatted
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  void dispose() {
    _longPressTimer?.cancel();
    _blockTimer?.cancel();
    _unblockTimer?.cancel();
    _divisionBlockTimer?.cancel();
    _divisionResultTimer?.cancel();
  }
}
