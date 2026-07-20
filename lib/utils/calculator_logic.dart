import 'dart:async';

class CalculatorLogic {
  String _display = '0';
  double? _previousValue;
  String? _operation;
  bool _waitingForOperand = false;
  bool _isSpecialMode = false;
  bool _useCustomNumber = false;
  String _customNumber = '';

  // 3 independent booleans — exact match of the original web app
  bool _isBlocked = false;
  bool _isDivisionBlocked = false;
  bool _isPartiallyBlocked = false;

  Timer? _longPressTimer;
  Timer? _blockTimer;
  Timer? _unblockTimer;
  Timer? _divisionBlockTimer;
  Timer? _divisionResultTimer;

  Function()? onStateChanged;

  String get display => _display;
  bool get isSpecialMode => _isSpecialMode;
  bool get useCustomNumber => _useCustomNumber;
  String get customNumber => _customNumber;

  bool get isBlocked => _isBlocked;
  bool get isDivisionBlocked => _isDivisionBlocked;
  bool get isPartiallyBlocked => _isPartiallyBlocked;

  void setCustomNumber(bool use, String number) {
    _useCustomNumber = use;
    _customNumber = number;
  }

  void _notify() {
    onStateChanged?.call();
  }

  void inputDigit(String digit) {
    if (_isBlocked || _isDivisionBlocked || _isPartiallyBlocked) return;

    if (_waitingForOperand) {
      _display = digit;
      _waitingForOperand = false;
    } else {
      _display = _display == '0' ? digit : _display + digit;
    }
  }

  void inputDecimal() {
    if (_isBlocked || _isDivisionBlocked || _isPartiallyBlocked) return;

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
    _previousValue = null;
    _operation = null;
    _waitingForOperand = false;
    _isSpecialMode = false;
    _isPartiallyBlocked = false;
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

    // Original: setIsDivisionBlocked(true) + setIsPartiallyBlocked(true)
    _isDivisionBlocked = true;
    _isPartiallyBlocked = true;

    // 1 second delay before showing result
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
      _waitingForOperand = true;
      _notify();
    });

    // 7 seconds: full unblock
    _divisionBlockTimer?.cancel();
    _divisionBlockTimer = Timer(const Duration(seconds: 7), () {
      _isDivisionBlocked = false;
      _isPartiallyBlocked = false;
      _notify();
    });
  }

  void startPlusLongPress() {
    // 2 seconds → then 3 more seconds → total 5 seconds to trigger
    _longPressTimer = Timer(const Duration(seconds: 2), () {
      _blockTimer = Timer(const Duration(seconds: 3), () {
        _isBlocked = true;
        _performSpecialOperation();
        _notify();

        // 5 seconds of full block
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
