import 'package:flutter/material.dart';

const Color _backgroundColor = Color(0xFFFAF9FC);
const Color _primaryColor = Color(0xFFD95C68);
const Color _textColor = Color(0xFF333333);
const Color _secondaryTextColor = Color(0xFF666666);

class BloodPressurePage extends StatefulWidget {
  const BloodPressurePage({super.key});

  @override
  State<BloodPressurePage> createState() => _BloodPressurePageState();
}

class _BloodPressurePageState extends State<BloodPressurePage> {
  final TextEditingController _systolicController = TextEditingController();
  final TextEditingController _diastolicController = TextEditingController();

  String? _category;
  String? _message;
  String? _errorMessage;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _sheetBackground =>
      _isDark ? const Color(0xFF1E1E1E) : Colors.white;

  Color get _fieldBackground =>
      _isDark ? const Color(0xFF252525) : const Color(0xFFFAFAFC);

  Color get _resultBackground =>
      _isDark ? const Color(0xFF252525) : _backgroundColor;

  Color get _borderColor =>
      _isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE3EAF5);

  Color get _primaryTextColor => _isDark ? Colors.white : _textColor;

  Color get _secondaryTextColorForTheme =>
      _isDark ? const Color(0xFFBDBDBD) : _secondaryTextColor;

  Color get _mutedTextColor =>
      _isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280);

  Color get _placeholderColor =>
      _isDark ? const Color(0xFF8E8E8E) : const Color(0xFF9CA3AF);

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // CHECK BLOOD PRESSURE
  // --------------------------------------------------------------------------

  void _checkBloodPressure() {
    FocusScope.of(context).unfocus();

    final systolic = int.tryParse(
      _systolicController.text.trim(),
    );

    final diastolic = int.tryParse(
      _diastolicController.text.trim(),
    );

    setState(() {
      _errorMessage = null;
    });

    // ------------------------------------------------------------------------
    // EMPTY / INVALID INPUT
    // ------------------------------------------------------------------------

    if (systolic == null || systolic <= 0) {
      _showError('Please enter a valid systolic pressure.');
      return;
    }

    if (diastolic == null || diastolic <= 0) {
      _showError('Please enter a valid diastolic pressure.');
      return;
    }

    // ------------------------------------------------------------------------
    // REALISTIC RANGE
    // ------------------------------------------------------------------------

    if (systolic < 50 || systolic > 300) {
      _showError(
        'Please enter a realistic systolic pressure between 50 and 300 mmHg.',
      );
      return;
    }

    if (diastolic < 30 || diastolic > 200) {
      _showError(
        'Please enter a realistic diastolic pressure between 30 and 200 mmHg.',
      );
      return;
    }

    // ------------------------------------------------------------------------
    // SYSTOLIC MUST BE HIGHER
    // ------------------------------------------------------------------------

    if (diastolic >= systolic) {
      _showError(
        'Diastolic pressure should be lower than systolic pressure.',
      );
      return;
    }

    // ------------------------------------------------------------------------
    // CALCULATE RESULT
    // ------------------------------------------------------------------------

    final result = _getBloodPressureCategory(
      systolic,
      diastolic,
    );

    setState(() {
      _category = result.$1;
      _message = result.$2;
      _errorMessage = null;
    });
  }

  // --------------------------------------------------------------------------
  // BLOOD PRESSURE CATEGORY
  // --------------------------------------------------------------------------

  (String, String) _getBloodPressureCategory(
    int systolic,
    int diastolic,
  ) {
    // Very high / crisis range.
    if (systolic > 180 || diastolic > 120) {
      return (
        'Very high',
        'This reading is very high. If you have symptoms such as '
            'chest pain, difficulty breathing, weakness, vision changes, '
            'or severe headache, seek emergency medical help.'
      );
    }

    // Stage 2.
    if (systolic >= 140 || diastolic >= 90) {
      return (
        'High blood pressure',
        'This reading is above the usual range. Consider discussing '
            'your readings with a healthcare professional.'
      );
    }

    // Stage 1.
    if (systolic >= 130 || diastolic >= 80) {
      return (
        'Elevated',
        'This reading is above the usual range. Consider monitoring '
            'your blood pressure and discussing repeated readings '
            'with a healthcare professional.'
      );
    }

    // Elevated systolic.
    if (systolic >= 120 && diastolic < 80) {
      return (
        'Elevated',
        'Your systolic pressure is above the usual range. Consider '
            'monitoring your blood pressure over time.'
      );
    }

    // Normal.
    return (
      'Normal range',
      'This reading is within the usual range for blood pressure.'
    );
  }

  // --------------------------------------------------------------------------
  // CLEAR RESULT
  // --------------------------------------------------------------------------

  void _clearResult() {
    if (_category == null && _message == null && _errorMessage == null) {
      return;
    }

    setState(() {
      _category = null;
      _message = null;
      _errorMessage = null;
    });
  }

  // --------------------------------------------------------------------------
  // SHOW ERROR
  // --------------------------------------------------------------------------

  void _showError(String message) {
    setState(() {
      _category = null;
      _message = null;
      _errorMessage = message;
    });
  }

  // --------------------------------------------------------------------------
  // BUILD
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final hasResult = _category != null && _message != null;

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
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ----------------------------------------------------------------
                // HANDLE
                // ----------------------------------------------------------------

                Padding(
                  padding: const EdgeInsets.only(top: 10),
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

                // ----------------------------------------------------------------
                // HEADER
                // ----------------------------------------------------------------

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    8,
                    10,
                    0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Blood Pressure',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w600,
                            color: _primaryTextColor,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        splashRadius: 22,
                        icon: Icon(
                          Icons.close_rounded,
                          size: 23,
                          color: _mutedTextColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // ----------------------------------------------------------------
                // CONTENT
                // ----------------------------------------------------------------

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    4,
                    20,
                    24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ----------------------------------------------------------
                      // DESCRIPTION
                      // ----------------------------------------------------------

                      Text(
                        'Understand your blood pressure',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: _secondaryTextColorForTheme,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ----------------------------------------------------------
                      // ICON
                      // ----------------------------------------------------------

                      const Icon(
                        Icons.favorite_outline_rounded,
                        size: 50,
                        color: _primaryColor,
                      ),

                      const SizedBox(height: 20),

                      // ----------------------------------------------------------
                      // SYSTOLIC
                      // ----------------------------------------------------------

                      Text(
                        'Systolic',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _primaryTextColor,
                        ),
                      ),

                      const SizedBox(height: 7),

                      _PressureInputField(
                        controller: _systolicController,
                        hintText: 'Enter systolic pressure',
                        unit: 'mmHg',
                        onChanged: (_) => _clearResult(),
                      ),

                      const SizedBox(height: 16),

                      // ----------------------------------------------------------
                      // DIASTOLIC
                      // ----------------------------------------------------------

                      Text(
                        'Diastolic',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _primaryTextColor,
                        ),
                      ),

                      const SizedBox(height: 7),

                      _PressureInputField(
                        controller: _diastolicController,
                        hintText: 'Enter diastolic pressure',
                        unit: 'mmHg',
                        onChanged: (_) => _clearResult(),
                      ),

                      const SizedBox(height: 20),

                      // ----------------------------------------------------------
                      // BUTTON
                      // ----------------------------------------------------------

                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _checkBloodPressure,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Check Blood Pressure',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      // ----------------------------------------------------------
                      // ERROR
                      // ----------------------------------------------------------

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        _ErrorCard(
                          message: _errorMessage!,
                        ),
                      ],

                      // ----------------------------------------------------------
                      // RESULT
                      // ----------------------------------------------------------

                      if (hasResult) ...[
                        const SizedBox(height: 18),
                        _BloodPressureResultCard(
                          systolic: int.parse(
                            _systolicController.text,
                          ),
                          diastolic: int.parse(
                            _diastolicController.text,
                          ),
                          category: _category!,
                          message: _message!,
                        ),
                      ],

                      const SizedBox(height: 18),

                      // ----------------------------------------------------------
                      // DISCLAIMER
                      // ----------------------------------------------------------

                      Container(
                        padding: const EdgeInsets.all(13),
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
                                'Blood pressure can vary throughout '
                                'the day. This tool is for general '
                                'information and does not diagnose '
                                'medical conditions.',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================================================
// PRESSURE INPUT FIELD
// ==========================================================================

class _PressureInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String unit;
  final ValueChanged<String>? onChanged;

  const _PressureInputField({
    required this.controller,
    required this.hintText,
    required this.unit,
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
              keyboardType: TextInputType.number,
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
          const Padding(
            padding: EdgeInsets.only(right: 15),
            child: Text(
              'mmHg',
              style: TextStyle(
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

// ==========================================================================
// ERROR CARD
// ==========================================================================

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final errorBackground =
        isDark ? const Color(0xFF2A1F20) : const Color(0xFFFFF7F7);

    final errorBorder =
        isDark ? const Color(0xFF5A3438) : const Color(0xFFF0C9CE);

    final textColor = isDark ? const Color(0xFFBDBDBD) : _secondaryTextColor;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: errorBackground,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: errorBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: _primaryColor,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// RESULT CARD
// ==========================================================================

class _BloodPressureResultCard extends StatelessWidget {
  final int systolic;
  final int diastolic;
  final String category;
  final String message;

  const _BloodPressureResultCard({
    required this.systolic,
    required this.diastolic,
    required this.category,
    required this.message,
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
        vertical: 18,
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
            'Your blood pressure',
            style: TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$systolic / $diastolic',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            category,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
