import 'package:flutter/material.dart';

const Color _backgroundColor = Color(0xFFFAF9FC);
const Color _primaryColor = Color(0xFFD95C68);
const Color _textColor = Color(0xFF333333);
const Color _secondaryTextColor = Color(0xFF666666);

class HeartRatePage extends StatefulWidget {
  const HeartRatePage({super.key});

  @override
  State<HeartRatePage> createState() => _HeartRatePageState();
}

class _HeartRatePageState extends State<HeartRatePage> {
  final TextEditingController _heartRateController = TextEditingController();

  String? _category;
  String? _message;
  String? _errorMessage;

  int? _resultHeartRate;

  @override
  void dispose() {
    _heartRateController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // CHECK HEART RATE
  // --------------------------------------------------------------------------

  void _checkHeartRate() {
    FocusScope.of(context).unfocus();

    setState(() {
      _errorMessage = null;
      _category = null;
      _message = null;
      _resultHeartRate = null;
    });

    final heartRate = int.tryParse(
      _heartRateController.text.trim(),
    );

    // Empty / invalid input
    if (heartRate == null || heartRate <= 0) {
      _showError('Please enter a valid heart rate.');
      return;
    }

    // Unrealistic input
    if (heartRate < 30 || heartRate > 220) {
      _showError(
        'Please enter a realistic heart rate between 30 and 220 bpm.',
      );
      return;
    }

    final result = _getHeartRateCategory(heartRate);

    setState(() {
      _resultHeartRate = heartRate;
      _category = result.$1;
      _message = result.$2;
      _errorMessage = null;
    });
  }

  // --------------------------------------------------------------------------
  // HEART RATE CATEGORY
  // --------------------------------------------------------------------------

  (String, String) _getHeartRateCategory(int heartRate) {
    if (heartRate < 60) {
      return (
        'Below typical resting range',
        'A resting heart rate below 60 bpm can be normal for some '
            'people, especially trained athletes. Consider your usual '
            'resting heart rate and how you feel.',
      );
    }

    if (heartRate <= 100) {
      return (
        'Typical resting range',
        'This reading is within the commonly used resting heart rate '
            'range for adults.',
      );
    }

    return (
      'Above typical resting range',
      'A resting heart rate above 100 bpm can have many causes. '
          'Consider resting and checking again, especially if this '
          'is unusual for you.',
    );
  }

  // --------------------------------------------------------------------------
  // CLEAR RESULT / ERROR
  // --------------------------------------------------------------------------

  void _clearResult() {
    if (_category == null &&
        _message == null &&
        _errorMessage == null &&
        _resultHeartRate == null) {
      return;
    }

    setState(() {
      _category = null;
      _message = null;
      _errorMessage = null;
      _resultHeartRate = null;
    });
  }

  // --------------------------------------------------------------------------
  // ERROR
  // --------------------------------------------------------------------------

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _category = null;
      _message = null;
      _resultHeartRate = null;
    });
  }

  // --------------------------------------------------------------------------
  // BUILD
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final hasResult =
        _category != null && _message != null && _resultHeartRate != null;

    final hasError = _errorMessage != null;

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
                          'Heart Rate',
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
                        'Check your heart rate',
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
                        Icons.monitor_heart_outlined,
                        size: 50,
                        color: _primaryColor,
                      ),

                      const SizedBox(height: 20),

                      // ----------------------------------------------------------
                      // HEART RATE
                      // ----------------------------------------------------------

                      const Text(
                        'Heart rate',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _textColor,
                        ),
                      ),

                      const SizedBox(height: 7),

                      _HeartRateInputField(
                        controller: _heartRateController,
                        onChanged: (_) => _clearResult(),
                      ),

                      const SizedBox(height: 20),

                      // ----------------------------------------------------------
                      // BUTTON
                      // ----------------------------------------------------------

                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _checkHeartRate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Check Heart Rate',
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

                      if (hasError) ...[
                        const SizedBox(height: 18),
                        _HeartRateErrorCard(
                          message: _errorMessage!,
                        ),
                      ],

                      // ----------------------------------------------------------
                      // RESULT
                      // ----------------------------------------------------------

                      if (hasResult) ...[
                        const SizedBox(height: 18),
                        _HeartRateResultCard(
                          heartRate: _resultHeartRate!,
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
                                'Heart rate can change with activity, stress, '
                                'medications, and other factors. This tool is '
                                'for general information and does not diagnose '
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
// HEART RATE INPUT FIELD
// ==========================================================================

class _HeartRateInputField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const _HeartRateInputField({
    required this.controller,
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
              decoration: const InputDecoration(
                hintText: 'Enter your heart rate',
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF9CA3AF),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 15),
            child: Text(
              'bpm',
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

class _HeartRateErrorCard extends StatelessWidget {
  final String message;

  const _HeartRateErrorCard({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFE3EAF5),
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

class _HeartRateResultCard extends StatelessWidget {
  final int heartRate;
  final String category;
  final String message;

  const _HeartRateResultCard({
    required this.heartRate,
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
            'Your heart rate',
            style: TextStyle(
              fontSize: 14,
              color: _secondaryTextColor,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$heartRate bpm',
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
