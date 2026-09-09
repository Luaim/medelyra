import 'package:flutter/material.dart';

const Color _backgroundColor = Color(0xFFFAF9FC);
const Color _primaryColor = Color(0xFF3D84A8);
const Color _textColor = Color(0xFF333333);
const Color _secondaryTextColor = Color(0xFF666666);

class BmiPage extends StatefulWidget {
  const BmiPage({super.key});

  @override
  State<BmiPage> createState() => _BmiPageState();
}

class _BmiPageState extends State<BmiPage> {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  double? _bmi;
  String? _category;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _sheetBackground =>
      _isDark ? const Color(0xFF1E1E1E) : Colors.white;

  Color get _resultBackground =>
      _isDark ? const Color(0xFF252525) : _backgroundColor;

  Color get _borderColor =>
      _isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE3EAF5);

  Color get _primaryTextColor => _isDark ? Colors.white : _textColor;

  Color get _secondaryTextColorForTheme =>
      _isDark ? const Color(0xFFBDBDBD) : _secondaryTextColor;

  Color get _mutedTextColor =>
      _isDark ? const Color(0xFF9E9E9E) : const Color(0xFF737985);

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // CALCULATE BMI
  // --------------------------------------------------------------------------

  void _calculateBmi() {
    FocusScope.of(context).unfocus();

    final height = double.tryParse(
      _heightController.text.trim().replaceAll(',', '.'),
    );

    final weight = double.tryParse(
      _weightController.text.trim().replaceAll(',', '.'),
    );

    if (height == null || height <= 0) {
      _showError('Please enter a valid height.');
      return;
    }

    if (weight == null || weight <= 0) {
      _showError('Please enter a valid weight.');
      return;
    }

    if (height < 50 || height > 300) {
      _showError('Please enter a realistic height.');
      return;
    }

    if (weight < 1 || weight > 500) {
      _showError('Please enter a realistic weight.');
      return;
    }

    final heightInMeters = height / 100;
    final bmi = weight / (heightInMeters * heightInMeters);

    setState(() {
      _bmi = bmi;
      _category = _getCategory(bmi);
    });
  }

  String _getCategory(double bmi) {
    if (bmi < 18.5) {
      return 'Underweight';
    } else if (bmi < 25) {
      return 'Healthy weight';
    } else if (bmi < 30) {
      return 'Overweight';
    } else {
      return 'Obesity';
    }
  }

  // --------------------------------------------------------------------------
  // CLEAR RESULT
  // --------------------------------------------------------------------------

  void _clearResult() {
    if (_bmi == null) return;

    setState(() {
      _bmi = null;
      _category = null;
    });
  }

  // --------------------------------------------------------------------------
  // ERROR
  // --------------------------------------------------------------------------

  void _showError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // PAGE
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Material(
        color: _sheetBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(26),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ----------------------------------------------------------------
                // HANDLE
                // ----------------------------------------------------------------

                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _isDark
                          ? const Color(0xFF4A4A4A)
                          : const Color(0xFFD5D9DF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ----------------------------------------------------------------
                // HEADER
                // ----------------------------------------------------------------

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'BMI Calculator',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w600,
                          color: _primaryTextColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 23,
                        color: _mutedTextColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                // ----------------------------------------------------------------
                // DESCRIPTION
                // ----------------------------------------------------------------

                Text(
                  'Check your body mass index',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: _secondaryTextColorForTheme,
                  ),
                ),

                const SizedBox(height: 16),

                // ----------------------------------------------------------------
                // ICON
                // ----------------------------------------------------------------

                const Center(
                  child: Icon(
                    Icons.monitor_weight_outlined,
                    size: 50,
                    color: _primaryColor,
                  ),
                ),

                const SizedBox(height: 18),

                // ----------------------------------------------------------------
                // HEIGHT
                // ----------------------------------------------------------------

                Text(
                  'Height',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _primaryTextColor,
                  ),
                ),

                const SizedBox(height: 7),

                _InputField(
                  controller: _heightController,
                  hintText: 'Enter your height',
                  unit: 'cm',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => _clearResult(),
                ),

                const SizedBox(height: 16),

                // ----------------------------------------------------------------
                // WEIGHT
                // ----------------------------------------------------------------

                Text(
                  'Weight',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _primaryTextColor,
                  ),
                ),

                const SizedBox(height: 7),

                _InputField(
                  controller: _weightController,
                  hintText: 'Enter your weight',
                  unit: 'kg',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => _clearResult(),
                ),

                const SizedBox(height: 20),

                // ----------------------------------------------------------------
                // CALCULATE BUTTON
                // ----------------------------------------------------------------

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _calculateBmi,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Calculate BMI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // ----------------------------------------------------------------
                // RESULT
                // ----------------------------------------------------------------

                if (_bmi != null && _category != null) ...[
                  const SizedBox(height: 18),
                  _BmiResultCard(
                    bmi: _bmi!,
                    category: _category!,
                  ),
                ],

                const SizedBox(height: 18),

                // ----------------------------------------------------------------
                // DISCLAIMER
                // ----------------------------------------------------------------

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _resultBackground,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: _borderColor,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: _secondaryTextColorForTheme,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'BMI is a screening measure and does not '
                          'diagnose health conditions. It may not be '
                          'suitable for everyone.',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: _secondaryTextColorForTheme,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// INPUT FIELD
// ============================================================================

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String unit;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  const _InputField({
    required this.controller,
    required this.hintText,
    required this.unit,
    required this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fieldBackground =
        isDark ? const Color(0xFF252525) : const Color(0xFFFAFAFC);

    final borderColor =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE3EAF5);

    final textColor = isDark ? Colors.white : _textColor;

    final hintColor =
        isDark ? const Color(0xFF8E8E8E) : const Color(0xFF9CA3AF);

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: fieldBackground,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              onChanged: onChanged,
              style: TextStyle(
                fontSize: 15,
                color: textColor,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: hintColor,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 14,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Text(
              unit,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BMI RESULT CARD
// ============================================================================

class _BmiResultCard extends StatelessWidget {
  final double bmi;
  final String category;

  const _BmiResultCard({
    required this.bmi,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final resultBackground =
        isDark ? const Color(0xFF252525) : _backgroundColor;

    final borderColor =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE3EAF5);

    final primaryTextColor = isDark ? Colors.white : _textColor;

    final secondaryTextColor =
        isDark ? const Color(0xFFBDBDBD) : _secondaryTextColor;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 17,
      ),
      decoration: BoxDecoration(
        color: resultBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Your BMI',
            style: TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            bmi.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            category,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Adult BMI categories are used as a general '
            'screening reference.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
