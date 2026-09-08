import 'package:flutter/material.dart';

const Color _backgroundColor = Color(0xFFFAF9FC);
const Color _primaryColor = Color(0xFFD18B3C);
const Color _textColor = Color(0xFF333333);
const Color _secondaryTextColor = Color(0xFF666666);

class AgePage extends StatefulWidget {
  const AgePage({super.key});

  @override
  State<AgePage> createState() => _AgePageState();
}

class _AgePageState extends State<AgePage> {
  DateTime? _dateOfBirth;

  int? _years;
  int? _months;
  int? _days;

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

  Future<void> _selectDateOfBirth() async {
    FocusScope.of(context).unfocus();

    final today = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(
        today.year - 20,
        today.month,
        today.day,
      ),
      firstDate: DateTime(1900),
      lastDate: today,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: _isDark
                ? ColorScheme.dark(
                    primary: _primaryColor,
                    onPrimary: Colors.white,
                    surface: const Color(0xFF1E1E1E),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: _primaryColor,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: _textColor,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null) return;

    setState(() {
      _dateOfBirth = selectedDate;

      // Clear the previous result when the date changes.
      _years = null;
      _months = null;
      _days = null;
    });
  }

  void _calculateAge() {
    FocusScope.of(context).unfocus();

    if (_dateOfBirth == null) {
      _showError('Please select your date of birth.');
      return;
    }

    final today = DateTime.now();

    if (_dateOfBirth!.isAfter(today)) {
      _showError('Date of birth cannot be in the future.');
      return;
    }

    int years = today.year - _dateOfBirth!.year;
    int months = today.month - _dateOfBirth!.month;
    int days = today.day - _dateOfBirth!.day;

    if (days < 0) {
      months--;

      final previousMonth = DateTime(
        today.year,
        today.month,
        0,
      );

      days += previousMonth.day;
    }

    if (months < 0) {
      years--;
      months += 12;
    }

    setState(() {
      _years = years;
      _months = months;
      _days = days;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16,
        ),
      ),
    );
  }

  String _formattedDate() {
    if (_dateOfBirth == null) {
      return 'Select your date of birth';
    }

    final day = _dateOfBirth!.day.toString().padLeft(2, '0');
    final month = _dateOfBirth!.month.toString().padLeft(2, '0');
    final year = _dateOfBirth!.year.toString();

    return '$day/$month/$year';
  }

  bool get _hasResult => _years != null && _months != null && _days != null;

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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ------------------------------------------------------------
              // TOP HANDLE
              // ------------------------------------------------------------

              Center(
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

              const SizedBox(height: 8),

              // ------------------------------------------------------------
              // HEADER
              // ------------------------------------------------------------

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Age Calculator',
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
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 23,
                      color: _mutedTextColor,
                    ),
                  ),
                ],
              ),

              // ------------------------------------------------------------
              // DESCRIPTION
              // ------------------------------------------------------------

              const SizedBox(height: 1),

              Text(
                'Find your exact age',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: _secondaryTextColorForTheme,
                ),
              ),

              const SizedBox(height: 18),

              // ------------------------------------------------------------
              // ICON
              // ------------------------------------------------------------

              const Icon(
                Icons.cake_outlined,
                size: 50,
                color: _primaryColor,
              ),

              const SizedBox(height: 18),

              // ------------------------------------------------------------
              // DATE OF BIRTH
              // ------------------------------------------------------------

              Text(
                'Date of birth',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _primaryTextColor,
                ),
              ),

              const SizedBox(height: 7),

              GestureDetector(
                onTap: _selectDateOfBirth,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: _fieldBackground,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: _borderColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                          ),
                          child: Text(
                            _formattedDate(),
                            style: TextStyle(
                              fontSize: 15,
                              color: _dateOfBirth == null
                                  ? _placeholderColor
                                  : _primaryTextColor,
                            ),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(right: 15),
                        child: Icon(
                          Icons.calendar_today_outlined,
                          size: 20,
                          color: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ------------------------------------------------------------
              // CALCULATE BUTTON
              // ------------------------------------------------------------

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _calculateAge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Calculate Age',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // ------------------------------------------------------------
              // RESULT
              // ------------------------------------------------------------

              if (_hasResult) ...[
                const SizedBox(height: 18),
                _AgeResultCard(
                  years: _years!,
                  months: _months!,
                  days: _days!,
                ),
              ],

              const SizedBox(height: 18),

              // ------------------------------------------------------------
              // DISCLAIMER
              // ------------------------------------------------------------

              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: _isDark ? const Color(0xFF252525) : _backgroundColor,
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
                        'Age is calculated from your date of birth '
                        'using today\'s date.',
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
    );
  }
}

// ==========================================================================
// AGE RESULT CARD
// ==========================================================================

class _AgeResultCard extends StatelessWidget {
  final int years;
  final int months;
  final int days;

  const _AgeResultCard({
    required this.years,
    required this.months,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color resultBackground =
        isDark ? const Color(0xFF252525) : _backgroundColor;

    final Color borderColor =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE3EAF5);

    final Color primaryTextColor = isDark ? Colors.white : _textColor;

    final Color secondaryTextColor =
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
            'Your Age',
            style: TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$years',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            'years old',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$months months • $days days',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
