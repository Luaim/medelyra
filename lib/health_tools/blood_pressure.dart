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

    // Clear previous error.
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
        color: Colors.white,
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
                      color: const Color(0xFFD5D9DF),
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
                      const Expanded(
                        child: Text(
                          'Blood Pressure',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w600,
                            color: _textColor,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        splashRadius: 22,
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 23,
                          color: Color(0xFF6B7280),
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

                      const Text(
                        'Understand your blood pressure',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: _secondaryTextColor,
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

                      const Text(
                        'Systolic',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _textColor,
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

                      const Text(
                        'Diastolic',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _textColor,
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
                          color: _backgroundColor,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: const Color(0xFFE3EAF5),
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: _secondaryTextColor,
                            ),
                            SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'Blood pressure can vary throughout '
                                'the day. This tool is for general '
                                'information and does not diagnose '
                                'medical conditions.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.4,
                                  color: _secondaryTextColor,
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
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFE3EAF5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              onChanged: onChanged,
              style: const TextStyle(
                fontSize: 15,
                color: _textColor,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF9CA3AF),
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F7),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFF0C9CE),
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
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: _secondaryTextColor,
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE3EAF5),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Your blood pressure',
            style: TextStyle(
              fontSize: 14,
              color: _secondaryTextColor,
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
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: _secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
