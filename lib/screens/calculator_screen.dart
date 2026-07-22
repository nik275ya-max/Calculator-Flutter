import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/calculator_logic.dart';
import '../widgets/calculator_button.dart';
import '../widgets/calculator_display.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final CalculatorLogic _logic = CalculatorLogic();
  bool _showSettings = false;
  final TextEditingController _customNumberController = TextEditingController();
  final TextEditingController _customTextController = TextEditingController();
  Timer? _percentLongPressTimer;

  @override
  void initState() {
    super.initState();
    _logic.setCustomNumber(false, '');
    _logic.onStateChanged = () {
      if (mounted) setState(() {});
    };
  }

  @override
  void dispose() {
    _logic.dispose();
    _customNumberController.dispose();
    _customTextController.dispose();
    _percentLongPressTimer?.cancel();
    super.dispose();
  }

  void _updateState() {
    setState(() {});
  }

  void _onButtonPressed(String text) {
    switch (text) {
      case 'AC':
        _logic.clear();
        break;
      case '+':
        _logic.performOperation('+');
        break;
      case '-':
        _logic.performOperation('-');
        break;
      case '×':
        _logic.performOperation('×');
        break;
      case '÷':
        _logic.performDivisionOperation();
        break;
      case '=':
        _logic.executeCalculation();
        break;
      case '.':
        _logic.inputDecimal();
        break;
      default:
        _logic.inputDigit(text);
    }
    _updateState();
  }

  void _onPlusLongPressStart() {
    _logic.startPlusLongPress();
  }

  void _onPlusLongPressEnd() {
    _logic.cancelPlusLongPress();
  }

  void _onPercentLongPressStart() {
    _percentLongPressTimer = Timer(const Duration(seconds: 2), () {
      setState(() {
        _showSettings = true;
      });
    });
  }

  void _onPercentLongPressEnd() {
    _percentLongPressTimer?.cancel();
    _percentLongPressTimer = null;
  }

  void _closeSettings() {
    setState(() {
      _showSettings = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSettings) {
      return _buildSettingsScreen();
    }
    return _buildCalculatorScreen();
  }

  Widget _buildSettingsScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom:
                      BorderSide(color: Color(0xFF374151), width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Настройки',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: _closeSettings,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2937),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Готово',
                        style: TextStyle(
                          color: Color(0xFFF97316),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // --- Text mode toggle ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Текстовый режим',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Switch(
                          value: _logic.isTextMode,
                          onChanged: (value) {
                            _logic.setTextMode(value);
                            _updateState();
                          },
                          activeThumbColor: const Color(0xFFF97316),
                          activeTrackColor: const Color(0xFFF97316),
                        ),
                      ],
                    ),
                    const Text(
                      'При нажатии +/- в поле появится текст',
                      style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 14,
                      ),
                    ),

                    if (_logic.isTextMode) ...[
                      const SizedBox(height: 20),

                      // --- Custom text input ---
                      const Text(
                        'Свой текст',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _customTextController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Введите текст',
                          hintStyle:
                              const TextStyle(color: Color(0xFF6B7280)),
                          filled: true,
                          fillColor: const Color(0xFF1F2937),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xFF4B5563)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xFF4B5563)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xFFF97316)),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        onChanged: (value) {
                          _logic.setCustomText(value);
                        },
                      ),

                      const SizedBox(height: 20),

                      // --- Card suit picker ---
                      const Text(
                        'Или выберите масть',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: CardSuit.values.map((suit) {
                          final isSelected =
                              _logic.selectedSuit == suit;
                          return GestureDetector(
                            onTap: () {
                              _logic.setCardSuit(suit);
                              // Append suit symbol to text field
                              _customTextController.text += suit.symbol;
                              _logic.setCustomText(_customTextController.text);
                              _updateState();
                            },
                            child: Container(
                              width: 70,
                              height: 90,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF374151)
                                    : const Color(0xFF1F2937),
                                borderRadius:
                                    BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFF97316)
                                      : const Color(0xFF4B5563),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    suit.symbol,
                                    style: TextStyle(
                                      fontSize: 32,
                                      color: suit == CardSuit.hearts ||
                                              suit == CardSuit.diamonds
                                          ? const Color(0xFFEF4444)
                                          : Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    suit.name,
                                    style: const TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 12),
                      Text(
                        'Текущий выбор: ${_logic.customText.isNotEmpty ? _logic.customText : _logic.selectedSuit.symbol}',
                        style: const TextStyle(
                          color: Color(0xFFF97316),
                          fontSize: 14,
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // --- Custom number (existing) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Использовать свое число',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Switch(
                          value: _logic.useCustomNumber,
                          onChanged: (value) {
                            _logic.setCustomNumber(
                                value, _customNumberController.text);
                            _updateState();
                          },
                          activeThumbColor: const Color(0xFFF97316),
                          activeTrackColor: const Color(0xFFF97316),
                        ),
                      ],
                    ),
                    const Text(
                      'Заменить автоматическое число (дата+время) на свое',
                      style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 14,
                      ),
                    ),
                    if (_logic.useCustomNumber) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _customNumberController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Введите число',
                          hintStyle:
                              const TextStyle(color: Color(0xFF6B7280)),
                          filled: true,
                          fillColor: const Color(0xFF1F2937),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xFF4B5563)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xFF4B5563)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xFFF97316)),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        onChanged: (value) {
                          _logic.setCustomNumber(true, value);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorScreen() {
    final isBlocked = _logic.isBlocked;
    final isDivisionBlocked = _logic.isDivisionBlocked;
    final isPartiallyBlocked = _logic.isPartiallyBlocked;
    final anyBlocked =
        isBlocked || isDivisionBlocked || isPartiallyBlocked;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Display
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding:
                          const EdgeInsets.only(bottom: 16, right: 24),
                      child: CalculatorDisplay(
                        value: _logic.display,
                        isBlocked: isBlocked,
                        isTextMode: _logic.showingText,
                      ),
                    ),
                  ),
                ),

                // Buttons
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Row 1: AC, +/-, %, ÷
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly,
                          children: [
                            CalculatorButton(
                              text: 'AC',
                              variant: ButtonVariant.secondary,
                              disabled: isBlocked || isDivisionBlocked,
                              onPressed: () {
                                _onButtonPressed('AC');
                              },
                            ),
                            CalculatorButton(
                              text: '+/-',
                              variant: ButtonVariant.secondary,
                              disabled: anyBlocked,
                              onPressed: () {
                                _logic.toggleSign();
                                _updateState();
                              },
                            ),
                            CalculatorButton(
                              text: '%',
                              variant: ButtonVariant.secondary,
                              disabled: anyBlocked,
                              onPressed: () {},
                              onLongPressStart:
                                  _onPercentLongPressStart,
                              onLongPressEnd: _onPercentLongPressEnd,
                            ),
                            CalculatorButton(
                              text: '÷',
                              variant: ButtonVariant.operator,
                              disabled: anyBlocked,
                              onPressed: () {
                                _onButtonPressed('÷');
                              },
                            ),
                          ],
                        ),

                        // Row 2: 7, 8, 9, ×
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly,
                          children: [
                            CalculatorButton(
                              text: '7',
                              disabled: anyBlocked,
                              onPressed: () =>
                                  _onButtonPressed('7'),
                            ),
                            CalculatorButton(
                              text: '8',
                              disabled: anyBlocked,
                              onPressed: () =>
                                  _onButtonPressed('8'),
                            ),
                            CalculatorButton(
                              text: '9',
                              disabled: anyBlocked,
                              onPressed: () =>
                                  _onButtonPressed('9'),
                            ),
                            CalculatorButton(
                              text: '×',
                              variant: ButtonVariant.operator,
                              disabled: anyBlocked,
                              onPressed: () =>
                                  _onButtonPressed('×'),
                            ),
                          ],
                        ),

                        // Row 3: 4, 5, 6, -
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly,
                          children: [
                            CalculatorButton(
                              text: '4',
                              disabled: anyBlocked,
                              onPressed: () =>
                                  _onButtonPressed('4'),
                            ),
                            CalculatorButton(
                              text: '5',
                              disabled: anyBlocked,
                              onPressed: () =>
                                  _onButtonPressed('5'),
                            ),
                            CalculatorButton(
                              text: '6',
                              disabled: anyBlocked,
                              onPressed: () =>
                                  _onButtonPressed('6'),
                            ),
                            CalculatorButton(
                              text: '-',
                              variant: ButtonVariant.operator,
                              disabled: anyBlocked,
                              onPressed: () =>
                                  _onButtonPressed('-'),
                            ),
                          ],
                        ),

                        // Row 4: 1, 2, 3, +
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly,
                          children: [
                            CalculatorButton(
                              text: '1',
                              disabled: anyBlocked,
                              onPressed: () =>
                                  _onButtonPressed('1'),
                            ),
                            CalculatorButton(
                              text: '2',
                              disabled: anyBlocked,
                              onPressed: () =>
                                  _onButtonPressed('2'),
                            ),
                            CalculatorButton(
                              text: '3',
                              disabled: anyBlocked,
                              onPressed: () =>
                                  _onButtonPressed('3'),
                            ),
                            CalculatorButton(
                              text: '+',
                              variant: ButtonVariant.operator,
                              disabled: anyBlocked,
                              onPressed: () =>
                                  _onButtonPressed('+'),
                              onLongPressStart:
                                  _onPlusLongPressStart,
                              onLongPressEnd:
                                  _onPlusLongPressEnd,
                            ),
                          ],
                        ),

                        // Row 5: 0, ., =
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly,
                          children: [
                            CalculatorButton(
                              text: '0',
                              variant: ButtonVariant.zero,
                              disabled: anyBlocked,
                              onPressed: () =>
                                  _onButtonPressed('0'),
                            ),
                            CalculatorButton(
                              text: '.',
                              disabled: anyBlocked,
                              onPressed: () =>
                                  _onButtonPressed('.'),
                            ),
                            CalculatorButton(
                              text: '=',
                              variant: ButtonVariant.operator,
                              disabled:
                                  isBlocked || isDivisionBlocked,
                              onPressed: () =>
                                  _onButtonPressed('='),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Block overlay
            if (isBlocked)
              Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Калькулятор заблокирован...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
