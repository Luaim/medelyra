import 'package:flutter/material.dart';

const Color _backgroundColor = Color(0xFFFAF9FC);
const Color _primaryColor = Color(0xFF7A63B8);
const Color _textColor = Color(0xFF333333);
const Color _secondaryTextColor = Color(0xFF666666);

class MedicalUnitConverterPage extends StatefulWidget {
  const MedicalUnitConverterPage({super.key});

  @override
  State<MedicalUnitConverterPage> createState() =>
      _MedicalUnitConverterPageState();
}

class _MedicalUnitConverterPageState extends State<MedicalUnitConverterPage> {
  final TextEditingController _valueController = TextEditingController();

  String _conversionType = 'Weight';
  String _fromUnit = 'kg';
  String _toUnit = 'lb';

  double? _result;
  String? _resultText;

  final Map<String, List<String>> _units = {
    'Weight': ['kg', 'lb'],
    'Temperature': ['°C', '°F'],
    'Length': ['cm', 'in'],
    'Glucose': ['mg/dL', 'mmol/L'],
  };

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
      _isDark ? const Color(0xFF8E8E8E) : const Color(0xFF6B7280);

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // CHANGE CONVERSION TYPE
  // --------------------------------------------------------------------------

  void _changeConversionType(String? value) {
    if (value == null) return;

    setState(() {
      _conversionType = value;

      final availableUnits = _units[value]!;

      _fromUnit = availableUnits[0];
      _toUnit = availableUnits[1];

      _clearResult();
    });
  }

  // --------------------------------------------------------------------------
  // CONVERT
  // --------------------------------------------------------------------------

  void _convert() {
    FocusScope.of(context).unfocus();

    final input = double.tryParse(
      _valueController.text.trim().replaceAll(',', '.'),
    );

    if (input == null) {
      _showError('Please enter a valid value.');
      return;
    }

    if (!input.isFinite) {
      _showError('Please enter a valid value.');
      return;
    }

    final result = _convertValue(
      input,
      _conversionType,
      _fromUnit,
      _toUnit,
    );

    if (result == null || !result.isFinite) {
      _showError('Unable to convert this value.');
      return;
    }

    setState(() {
      _result = result;
      _resultText = '${_formatNumber(input)} $_fromUnit = '
          '${_formatNumber(result)} $_toUnit';
    });
  }

  // --------------------------------------------------------------------------
  // CONVERSION LOGIC
  // --------------------------------------------------------------------------

  double? _convertValue(
    double value,
    String type,
    String from,
    String to,
  ) {
    if (from == to) {
      return value;
    }

    switch (type) {
      case 'Weight':
        if (from == 'kg' && to == 'lb') {
          return value * 2.2046226218;
        }

        if (from == 'lb' && to == 'kg') {
          return value / 2.2046226218;
        }
        break;

      case 'Temperature':
        if (from == '°C' && to == '°F') {
          return (value * 9 / 5) + 32;
        }

        if (from == '°F' && to == '°C') {
          return (value - 32) * 5 / 9;
        }
        break;

      case 'Length':
        if (from == 'cm' && to == 'in') {
          return value / 2.54;
        }

        if (from == 'in' && to == 'cm') {
          return value * 2.54;
        }
        break;

      case 'Glucose':
        if (from == 'mg/dL' && to == 'mmol/L') {
          return value / 18.0182;
        }

        if (from == 'mmol/L' && to == 'mg/dL') {
          return value * 18.0182;
        }
        break;
    }

    return null;
  }

  // --------------------------------------------------------------------------
  // FORMAT NUMBER
  // --------------------------------------------------------------------------

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  // --------------------------------------------------------------------------
  // CLEAR RESULT
  // --------------------------------------------------------------------------

  void _clearResult() {
    if (_result == null && _resultText == null) {
      return;
    }

    setState(() {
      _result = null;
      _resultText = null;
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
  // BUILD
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final hasResult = _result != null && _resultText != null;
    final availableUnits = _units[_conversionType]!;

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
                          ? const Color(0xFF555555)
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
                          'Medical Unit Converter',
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
                      // DESCRIPTION

                      Text(
                        'Convert common medical units',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: _secondaryTextColorForTheme,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ICON

                      const Icon(
                        Icons.swap_horiz_rounded,
                        size: 50,
                        color: _primaryColor,
                      ),

                      const SizedBox(height: 20),

                      // ----------------------------------------------------------------
                      // CONVERSION TYPE
                      // ----------------------------------------------------------------

                      Text(
                        'Convert',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _primaryTextColor,
                        ),
                      ),

                      const SizedBox(height: 7),

                      _DropdownField(
                        value: _conversionType,
                        items: _units.keys.toList(),
                        onChanged: _changeConversionType,
                      ),

                      const SizedBox(height: 16),

                      // ----------------------------------------------------------------
                      // VALUE
                      // ----------------------------------------------------------------

                      Text(
                        'Value',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _primaryTextColor,
                        ),
                      ),

                      const SizedBox(height: 7),

                      _ValueInputField(
                        controller: _valueController,
                        onChanged: (_) => _clearResult(),
                      ),

                      const SizedBox(height: 16),

                      // ----------------------------------------------------------------
                      // FROM / TO
                      // ----------------------------------------------------------------

                      Row(
                        children: [
                          Expanded(
                            child: _UnitDropdown(
                              label: 'From',
                              value: _fromUnit,
                              items: availableUnits,
                              onChanged: (value) {
                                if (value == null) return;

                                setState(() {
                                  _fromUnit = value;
                                  _clearResult();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _UnitDropdown(
                              label: 'To',
                              value: _toUnit,
                              items: availableUnits,
                              onChanged: (value) {
                                if (value == null) return;

                                setState(() {
                                  _toUnit = value;
                                  _clearResult();
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ----------------------------------------------------------------
                      // BUTTON
                      // ----------------------------------------------------------------

                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _convert,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Convert',
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

                      if (hasResult) ...[
                        const SizedBox(height: 18),
                        _ConverterResultCard(
                          resultText: _resultText!,
                        ),
                      ],

                      const SizedBox(height: 18),

                      // ----------------------------------------------------------------
                      // DISCLAIMER
                      // ----------------------------------------------------------------

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
                                'This tool provides unit conversions for '
                                'general reference. It does not provide '
                                'medical or medication dosing advice.',
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
// CONVERSION TYPE DROPDOWN
// ==========================================================================

class _DropdownField extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fieldBackground =
        isDark ? const Color(0xFF252525) : const Color(0xFFFAFAFC);

    final borderColor =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE3EAF5);

    final textColor = isDark ? Colors.white : _textColor;

    final secondaryColor =
        isDark ? const Color(0xFFBDBDBD) : _secondaryTextColor;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: fieldBackground,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: secondaryColor,
          ),
          style: TextStyle(
            fontSize: 15,
            color: textColor,
          ),
          dropdownColor: isDark ? const Color(0xFF252525) : Colors.white,
          borderRadius: BorderRadius.circular(13),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ==========================================================================
// VALUE INPUT
// ==========================================================================

class _ValueInputField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const _ValueInputField({
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : const Color(0xFFFAFAFC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE3EAF5),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
        ),
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 15,
          color: isDark ? Colors.white : _textColor,
        ),
        decoration: InputDecoration(
          hintText: 'Enter a value',
          hintStyle: TextStyle(
            fontSize: 15,
            color: isDark ? const Color(0xFF8E8E8E) : const Color(0xFF9CA3AF),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

// ==========================================================================
// UNIT DROPDOWN
// ==========================================================================

class _UnitDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _UnitDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fieldBackground =
        isDark ? const Color(0xFF252525) : const Color(0xFFFAFAFC);

    final borderColor =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE3EAF5);

    final textColor = isDark ? Colors.white : _textColor;

    final secondaryColor =
        isDark ? const Color(0xFFBDBDBD) : _secondaryTextColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: fieldBackground,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: borderColor,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: secondaryColor,
              ),
              style: TextStyle(
                fontSize: 14,
                color: textColor,
              ),
              dropdownColor: isDark ? const Color(0xFF252525) : Colors.white,
              borderRadius: BorderRadius.circular(13),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================================================
// RESULT CARD
// ==========================================================================

class _ConverterResultCard extends StatelessWidget {
  final String resultText;

  const _ConverterResultCard({
    required this.resultText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : _backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE3EAF5),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Converted value',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFFBDBDBD) : _secondaryTextColor,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            resultText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
