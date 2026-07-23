import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/calculator_logic.dart';
import '../widgets/calculator_button.dart';
import '../widgets/calculator_display.dart';
import '../services/sensor_service.dart';

enum GravityAnimState { normal, falling, fallen, restoring }

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});
  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final CalculatorLogic _logic = CalculatorLogic();
  final SensorService _sensorService = SensorService();
  bool _showSettings = false;
  final TextEditingController _customNumberController = TextEditingController();
  final TextEditingController _customTextController = TextEditingController();
  Timer? _percentLongPressTimer;
  GravityAnimState _gravityState = GravityAnimState.normal;
  final Random _random = Random();
  List<Offset> _fallenPositions = [];
  Size _containerSize = Size.zero;
  bool _pendingFall = false;

  final List<Map<String, dynamic>> _buttonDefs = [
    {'text': 'AC', 'variant': ButtonVariant.secondary},
    {'text': '+/-', 'variant': ButtonVariant.secondary},
    {'text': '%', 'variant': ButtonVariant.secondary},
    {'text': '\u00F7', 'variant': ButtonVariant.operator},
    {'text': '7', 'variant': ButtonVariant.primary},
    {'text': '8', 'variant': ButtonVariant.primary},
    {'text': '9', 'variant': ButtonVariant.primary},
    {'text': '\u00D7', 'variant': ButtonVariant.operator},
    {'text': '4', 'variant': ButtonVariant.primary},
    {'text': '5', 'variant': ButtonVariant.primary},
    {'text': '6', 'variant': ButtonVariant.primary},
    {'text': '-', 'variant': ButtonVariant.operator},
    {'text': '1', 'variant': ButtonVariant.primary},
    {'text': '2', 'variant': ButtonVariant.primary},
    {'text': '3', 'variant': ButtonVariant.primary},
    {'text': '+', 'variant': ButtonVariant.operator},
    {'text': '0', 'variant': ButtonVariant.zero},
    {'text': '.', 'variant': ButtonVariant.primary},
    {'text': '=', 'variant': ButtonVariant.operator},
  ];

  @override
  void initState() {
    super.initState();
    _logic.setCustomNumber(false, '');
    _logic.onStateChanged = () { if (mounted) setState(() {}); };
    _sensorService.onShakeDetected = _onShakeDetected;
  }

  @override
  void dispose() {
    _logic.dispose();
    _sensorService.dispose();
    _customNumberController.dispose();
    _customTextController.dispose();
    _percentLongPressTimer?.cancel();
    super.dispose();
  }

  void _updateState() { setState(() {}); }

  void _onButtonPressed(String text) {
    if (_gravityState != GravityAnimState.normal) return;
    switch (text) {
      case 'AC': _logic.clear(); break;
      case '+/-': _logic.toggleSign(); break;
      case '%': break;
      case '+': _logic.performOperation('+'); break;
      case '-': _logic.performOperation('-'); break;
      case '\u00D7': _logic.performOperation('\u00D7'); break;
      case '\u00F7': _logic.performDivisionOperation(); break;
      case '=': _logic.executeCalculation(); break;
      case '.': _logic.inputDecimal(); break;
      default: _logic.inputDigit(text);
    }
    _updateState();
  }

  void _onPlusLongPressStart() { _logic.startPlusLongPress(); }
  void _onPlusLongPressEnd() { _logic.cancelPlusLongPress(); }

  void _onPercentLongPressStart() {
    _percentLongPressTimer = Timer(const Duration(seconds: 2), () {
      setState(() { _showSettings = true; });
    });
  }
  void _onPercentLongPressEnd() {
    _percentLongPressTimer?.cancel();
    _percentLongPressTimer = null;
  }
  void _closeSettings() { setState(() { _showSettings = false; }); }

  void _onShakeDetected() {
    if (!_logic.isAnimationEnabled) return;
    if (_gravityState != GravityAnimState.normal) return;
    setState(() { _gravityState = GravityAnimState.falling; });
    if (_containerSize == Size.zero) { _pendingFall = true; return; }
    _startFall();
  }

  void _startFall() {
    _generateFallenPositions();
    final maxDelay = _buttonDefs.length * 80 + 800;
    Timer(Duration(milliseconds: maxDelay), () {
      if (mounted && _gravityState == GravityAnimState.falling) {
        setState(() { _gravityState = GravityAnimState.fallen; });
      }
    });
  }

  void _onRestoreDetected() {
    if (_gravityState != GravityAnimState.falling && _gravityState != GravityAnimState.fallen) return;
    setState(() { _gravityState = GravityAnimState.restoring; });
    Timer(const Duration(seconds: 3), () {
      if (mounted) { setState(() { _gravityState = GravityAnimState.normal; }); }
    });
  }

  void _onTapToRestore() { _onRestoreDetected(); }

  void _generateFallenPositions() {
    if (_containerSize == Size.zero) return;
    _fallenPositions = List.generate(_buttonDefs.length, (i) {
      return Offset(
        _random.nextDouble() * (_containerSize.width - 80),
        _containerSize.height * 0.5 + _random.nextDouble() * (_containerSize.height * 0.45),
      );
    });
  }

  Offset _calcPos(int index, BoxConstraints constraints) {
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;
    const btn = 80.0;
    const vGap = 12.0;
    final rowH = (h - vGap * 4) / 5.0;

    if (index < 16) {
      final row = index ~/ 4;
      final col = index % 4;
      final hGap = (w - 4 * btn) / 5.0;
      final x = hGap + col * (btn + hGap);
      final y = row * (rowH + vGap) + (rowH - btn) / 2;
      return Offset(x, y);
    } else {
      final localIndex = index - 16;
      final y = 4 * (rowH + vGap) + (rowH - btn) / 2;
      final wideBtn = 170.0;
      final hGap = (w - wideBtn - 2 * btn) / 4.0;
      if (localIndex == 0) {
        return Offset(0, y);
      } else if (localIndex == 1) {
        return Offset(wideBtn + hGap, y);
      } else {
        return Offset(wideBtn + hGap + btn + hGap, y);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSettings) return _buildSettingsScreen();
    return _buildCalculatorScreen();
  }

  Widget _buildSettingsScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF374151), width: 0.5))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('\u041D\u0430\u0441\u0442\u0440\u043E\u0439\u043A\u0438', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500)),
              GestureDetector(onTap: _closeSettings, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(8)), child: const Text('\u0413\u043E\u0442\u043E\u0432\u043E', style: TextStyle(color: Color(0xFFF97316), fontSize: 16, fontWeight: FontWeight.w600)))),
            ]),
          ),
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Expanded(child: Text('\u0422\u0435\u043A\u0441\u0442\u043E\u0432\u044B\u0439 \u0440\u0435\u0436\u0438\u043C', style: TextStyle(color: Colors.white, fontSize: 18))),
              Switch(value: _logic.isTextMode, onChanged: (v) { _logic.setTextMode(v); _updateState(); }, activeThumbColor: const Color(0xFFF97316), activeTrackColor: const Color(0xFFF97316)),
            ]),
            const Text('\u041F\u043E\u0441\u043B\u0435 \u043D\u0430\u0436\u0430\u0442\u0438\u044F +/- \u043D\u0430\u0436\u043C\u0438\u0442\u0435 = \u0438 \u043F\u043E\u044F\u0432\u0438\u0442\u0441\u044F \u044D\u0442\u043E\u0442 \u0442\u0435\u043A\u0441\u0442', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
            if (_logic.isTextMode) ...[
              const SizedBox(height: 20),
              const Text('\u0421\u0432\u043E\u0439 \u0442\u0435\u043A\u0441\u0442', style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 8),
              TextField(controller: _customTextController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: '\u0412\u0432\u0435\u0434\u0438\u0442\u0435 \u0442\u0435\u043A\u0441\u0442', hintStyle: const TextStyle(color: Color(0xFF6B7280)), filled: true, fillColor: const Color(0xFF1F2937), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4B5563))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4B5563))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFF97316))), contentPadding: const EdgeInsets.all(16)), onChanged: (v) => _logic.setCustomText(v)),
              const SizedBox(height: 20),
              const Text('\u0418\u043B\u0438 \u0432\u044B\u0431\u0435\u0440\u0438\u0442\u0435 \u043C\u0430\u0441\u0442\u044C', style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: CardSuit.values.map((suit) {
                final sel = _logic.selectedSuit == suit;
                return GestureDetector(onTap: () { _logic.setCardSuit(suit); _customTextController.text += suit.symbol; _logic.setCustomText(_customTextController.text); _updateState(); }, child: Container(width: 70, height: 90, decoration: BoxDecoration(color: sel ? const Color(0xFF374151) : const Color(0xFF1F2937), borderRadius: BorderRadius.circular(10), border: Border.all(color: sel ? const Color(0xFFF97316) : const Color(0xFF4B5563), width: 2)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(suit.symbol, style: TextStyle(fontSize: 32, color: suit == CardSuit.hearts || suit == CardSuit.diamonds ? const Color(0xFFEF4444) : Colors.white)), const SizedBox(height: 4), Text(suit.name, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12))])));
              }).toList()),
              const SizedBox(height: 12),
              Text('\u0422\u0435\u043A\u0443\u0449\u0438\u0439 \u0432\u044B\u0431\u043E\u0440: ', style: const TextStyle(color: Color(0xFFF97316), fontSize: 14)),
            ],
            const SizedBox(height: 32),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Expanded(child: Text('\u0418\u0441\u043F\u043E\u043B\u044C\u0437\u043E\u0432\u0430\u0442\u044C \u0441\u0432\u043E\u0435 \u0447\u0438\u0441\u043B\u043E', style: TextStyle(color: Colors.white, fontSize: 18))),
              Switch(value: _logic.useCustomNumber, onChanged: (v) { _logic.setCustomNumber(v, _customNumberController.text); _updateState(); }, activeThumbColor: const Color(0xFFF97316), activeTrackColor: const Color(0xFFF97316)),
            ]),
            const Text('\u0417\u0430\u043C\u0435\u043D\u0438\u0442\u044C \u0430\u0432\u0442\u043E\u043C\u0430\u0442\u0438\u0447\u0435\u0441\u043A\u043E\u0435 \u0447\u0438\u0441\u043B\u043E (\u0434\u0430\u0442\u0430+\u0432\u0440\u0435\u043C\u044F) \u043D\u0430 \u0441\u0432\u043E\u0435', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
            if (_logic.useCustomNumber) ...[
              const SizedBox(height: 16),
              TextField(controller: _customNumberController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: '\u0412\u0432\u0435\u0434\u0438\u0442\u0435 \u0447\u0438\u0441\u043B\u043E', hintStyle: const TextStyle(color: Color(0xFF6B7280)), filled: true, fillColor: const Color(0xFF1F2937), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4B5563))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4B5563))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFF97316))), contentPadding: const EdgeInsets.all(16)), onChanged: (v) => _logic.setCustomNumber(true, v)),
            ],
            const SizedBox(height: 32),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Expanded(child: Text('\u0410\u043D\u0438\u043C\u0430\u0446\u0438\u044F', style: TextStyle(color: Colors.white, fontSize: 18))),
              Switch(value: _logic.isAnimationEnabled, onChanged: (v) { _logic.setAnimationEnabled(v); if (v) { _sensorService.startListening(); } else { _sensorService.stopListening(); } _updateState(); }, activeThumbColor: const Color(0xFFF97316), activeTrackColor: const Color(0xFFF97316)),
            ]),
            const Text('\u041F\u043E\u0442\u0440\u044F\u0441\u0438\u0442\u0435 \u0442\u0435\u043B\u0435\u0444\u043E\u043D \u2014 \u043A\u043D\u043E\u043F\u043A\u0438 \u0443\u043F\u0430\u0434\u0443\u0442. \u041D\u0430\u0436\u043C\u0438\u0442\u0435 \u043D\u0430 \u044D\u043A\u0440\u0430\u043D \u2014 \u0432\u0435\u0440\u043D\u0443\u0442\u0441\u044F', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
          ]))),
        ]),
      ),
    );
  }

  Widget _buildCalculatorScreen() {
    final isBlocked = _logic.isBlocked;
    final isDivisionBlocked = _logic.isDivisionBlocked;
    final anyBlocked = isBlocked || isDivisionBlocked;
    final isActive = _gravityState != GravityAnimState.normal;

    final calculatorBody = Stack(children: [
      Column(children: [
        Expanded(flex: 2, child: Align(alignment: Alignment.bottomRight, child: Padding(padding: const EdgeInsets.only(bottom: 16, right: 24), child: AnimatedOpacity(duration: const Duration(milliseconds: 500), opacity: isActive ? 0.3 : 1.0, child: CalculatorDisplay(value: _logic.display, isBlocked: isBlocked, isTextMode: _logic.showingText))))),
          Expanded(flex: 5, child: Padding(padding: const EdgeInsets.all(12), child: LayoutBuilder(builder: (context, constraints) {
            _containerSize = Size(constraints.maxWidth, constraints.maxHeight);
            if (_pendingFall) { _pendingFall = false; WidgetsBinding.instance.addPostFrameCallback((_) { _startFall(); }); }
            return Stack(clipBehavior: Clip.none, children: List.generate(_buttonDefs.length, (index) {
              final def = _buttonDefs[index];
              final normal = _calcPos(index, constraints);
              final fallen = index < _fallenPositions.length ? _fallenPositions[index] : Offset(normal.dx, _containerSize.height + 100);
              Offset target;
              Duration dur;
              switch (_gravityState) {
                case GravityAnimState.normal: target = normal; dur = const Duration(milliseconds: 200); break;
                case GravityAnimState.falling: target = fallen; dur = Duration(milliseconds: 800 + index * 80); break;
                case GravityAnimState.fallen: target = fallen; dur = Duration.zero; break;
                case GravityAnimState.restoring: target = normal; dur = Duration(milliseconds: 1200 + index * 100); break;
              }
              return AnimatedPositioned(
                duration: dur,
                curve: _gravityState == GravityAnimState.falling ? Curves.bounceOut : Curves.easeInOut,
                width: def['text'] == '0' ? 170.0 : 80.0,
                height: 80.0,
                left: target.dx,
                top: target.dy,
                child: CalculatorButton(
                  text: def['text'],
                  variant: def['variant'],
                  disabled: isActive,
                  onPressed: () => _onButtonPressed(def['text']),
                  onLongPressStart: def['text'] == '%' ? _onPercentLongPressStart : (def['text'] == '+' ? _onPlusLongPressStart : null),
                  onLongPressEnd: def['text'] == '%' ? _onPercentLongPressEnd : (def['text'] == '+' ? _onPlusLongPressEnd : null),
                ),
              );
            }));
          }))),
        ]),
      if (isBlocked) Container(color: Colors.black.withValues(alpha: 0.7), child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20), decoration: BoxDecoration(color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(12)), child: const Text('\u041A\u0430\u043B\u044C\u043A\u0443\u043B\u044F\u0442\u043E\u0440 \u0437\u0430\u0431\u043B\u043E\u043A\u0438\u0440\u043E\u0432\u0430\u043D...', style: TextStyle(color: Colors.white, fontSize: 16))))),
    ]);

    return Scaffold(backgroundColor: Colors.black, body: SafeArea(
      child: isActive
        ? GestureDetector(onTap: _onTapToRestore, behavior: HitTestBehavior.translucent, child: calculatorBody)
        : calculatorBody,
    ));
  }
}
