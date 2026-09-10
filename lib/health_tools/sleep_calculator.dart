import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

const Color _backgroundColor = Color(0xFFFAF9FC);
const Color _primaryColor = Color(0xFF7167B7);
const Color _textColor = Color(0xFF333333);
const Color _secondaryTextColor = Color(0xFF666666);

class SleepCalculatorPage extends StatefulWidget {
  const SleepCalculatorPage({super.key});

  @override
  State<SleepCalculatorPage> createState() => _SleepCalculatorPageState();
}

class _SleepCalculatorPageState extends State<SleepCalculatorPage> {
  TimeOfDay? _selectedTime;

  String? _resultTitle;
  String? _resultMessage;

  List<_SleepSuggestion>? _sleepSuggestions;

  String? _errorMessage;

  // --------------------------------------------------------------------------
  // THEME COLORS
  // --------------------------------------------------------------------------

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

  Color get _placeholderColor =>
      _isDark ? const Color(0xFF8E8E8E) : const Color(0xFF9CA3AF);

  // --------------------------------------------------------------------------
  // SELECT WAKE-UP TIME
  // --------------------------------------------------------------------------

  Future<void> _selectWakeUpTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ??
          const TimeOfDay(
            hour: 7,
            minute: 0,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: _isDark
                ? const ColorScheme.dark(
                    primary: _primaryColor,
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E1E1E),
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

    if (picked == null) return;

    setState(() {
      _selectedTime = picked;
      _clearResult();
      _errorMessage = null;
    });
  }

  // --------------------------------------------------------------------------
  // CALCULATE SLEEP TIMES
  // --------------------------------------------------------------------------

  void _calculateSleepTimes() {
    FocusScope.of(context).unfocus();

    final l10n = AppLocalizations.of(context)!;

    if (_selectedTime == null) {
      setState(() {
        _errorMessage = l10n.selectWakeUpTime;
        _sleepSuggestions = null;
        _resultTitle = null;
        _resultMessage = null;
      });
      return;
    }

    final wakeMinutes = _selectedTime!.hour * 60 + _selectedTime!.minute;

    // Approximate sleep durations.
    //
    // These are suggestions only and are not medical recommendations.
    const sleepDurations = [
      Duration(hours: 9),
      Duration(hours: 7, minutes: 30),
      Duration(hours: 6),
    ];

    final suggestions = <_SleepSuggestion>[];

    for (final duration in sleepDurations) {
      var bedtimeMinutes = wakeMinutes - duration.inMinutes;

      // Move to the previous day if the calculation goes before midnight.
      if (bedtimeMinutes < 0) {
        bedtimeMinutes += 24 * 60;
      }

      final bedtime = TimeOfDay(
        hour: bedtimeMinutes ~/ 60,
        minute: bedtimeMinutes % 60,
      );

      suggestions.add(
        _SleepSuggestion(
          bedtime: bedtime,
          duration: duration,
        ),
      );
    }

    setState(() {
      _sleepSuggestions = suggestions;
      _resultTitle = l10n.suggestedBedtimes;
      _resultMessage = l10n.sleepSuggestionMessage;
      _errorMessage = null;
    });
  }

  // --------------------------------------------------------------------------
  // CLEAR RESULT
  // --------------------------------------------------------------------------

  void _clearResult() {
    setState(() {
      _sleepSuggestions = null;
      _resultTitle = null;
      _resultMessage = null;
    });
  }

  // --------------------------------------------------------------------------
  // FORMAT TIME
  // --------------------------------------------------------------------------

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  // --------------------------------------------------------------------------
  // FORMAT DURATION
  // --------------------------------------------------------------------------

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (minutes == 0) {
      return '$hours ${hours == 1 ? 'hour' : 'hours'}';
    }

    final decimalHours = duration.inMinutes / 60;

    return '${decimalHours.toStringAsFixed(1)} hours';
  }

  // --------------------------------------------------------------------------
  // BUILD
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final hasResult = _sleepSuggestions != null &&
        _resultTitle != null &&
        _resultMessage != null;

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
                          l10n.sleepCalculator,
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
                          color: _isDark
                              ? const Color(0xFFBDBDBD)
                              : const Color(0xFF6B7280),
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
                        l10n.findSuggestedBedtimes,
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
                        Icons.bedtime_outlined,
                        size: 50,
                        color: _primaryColor,
                      ),

                      const SizedBox(height: 20),

                      // ----------------------------------------------------------
                      // WAKE-UP TIME LABEL
                      // ----------------------------------------------------------

                      Text(
                        l10n.wakeUpTime,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _primaryTextColor,
                        ),
                      ),

                      const SizedBox(height: 7),

                      // ----------------------------------------------------------
                      // WAKE-UP TIME PICKER
                      // ----------------------------------------------------------

                      InkWell(
                        onTap: _selectWakeUpTime,
                        borderRadius: BorderRadius.circular(13),
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                          ),
                          decoration: BoxDecoration(
                            color: _fieldBackground,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: _borderColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 21,
                                color: _primaryColor,
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Text(
                                  _selectedTime == null
                                      ? l10n.selectYourWakeUpTime
                                      : _formatTime(
                                          _selectedTime!,
                                        ),
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: _selectedTime == null
                                        ? _placeholderColor
                                        : _primaryTextColor,
                                    fontWeight: _selectedTime == null
                                        ? FontWeight.normal
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: _isDark
                                    ? const Color(0xFFBDBDBD)
                                    : const Color(0xFF7B8491),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ----------------------------------------------------------
                      // ERROR
                      // ----------------------------------------------------------

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _isDark
                                ? const Color(0xFF2A1F20)
                                : const Color(0xFFFFF5F5),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: _isDark
                                  ? const Color(0xFF57383B)
                                  : const Color(0xFFF0D0D0),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 18,
                                color: _isDark
                                    ? const Color(0xFFE58A94)
                                    : const Color(0xFFC95C68),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    height: 1.35,
                                    color: _isDark
                                        ? const Color(0xFFE58A94)
                                        : const Color(0xFFC95C68),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // ----------------------------------------------------------
                      // BUTTON
                      // ----------------------------------------------------------

                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _calculateSleepTimes,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            l10n.calculateBedtimes,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      // ----------------------------------------------------------
                      // RESULT
                      // ----------------------------------------------------------

                      if (hasResult) ...[
                        const SizedBox(height: 18),
                        _SleepResultCard(
                          title: _resultTitle!,
                          message: _resultMessage!,
                          suggestions: _sleepSuggestions!,
                          formatTime: _formatTime,
                          formatDuration: _formatDuration,
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
                                l10n.sleepCalculatorDisclaimer,
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
// SLEEP SUGGESTION MODEL
// ==========================================================================

class _SleepSuggestion {
  final TimeOfDay bedtime;
  final Duration duration;

  const _SleepSuggestion({
    required this.bedtime,
    required this.duration,
  });
}

// ==========================================================================
// RESULT CARD
// ==========================================================================

class _SleepResultCard extends StatelessWidget {
  final String title;
  final String message;
  final List<_SleepSuggestion> suggestions;
  final String Function(TimeOfDay) formatTime;
  final String Function(Duration) formatDuration;

  const _SleepResultCard({
    required this.title,
    required this.message,
    required this.suggestions,
    required this.formatTime,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final resultBackground =
        isDark ? const Color(0xFF252525) : _backgroundColor;

    final suggestionBackground =
        isDark ? const Color(0xFF2D2D2D) : Colors.white;

    final borderColor =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE3EAF5);

    final primaryTextColor = isDark ? Colors.white : _textColor;

    final secondaryTextColor =
        isDark ? const Color(0xFFBDBDBD) : _secondaryTextColor;

    final l10n = AppLocalizations.of(context)!;

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
            title,
            style: TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 10),
          ...suggestions.asMap().entries.map(
            (entry) {
              final suggestion = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: suggestionBackground,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: borderColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bedtime_outlined,
                        size: 19,
                        color: _primaryColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          formatTime(
                            suggestion.bedtime,
                          ),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                          ),
                        ),
                      ),
                      Text(
                        _localizedDuration(
                          suggestion.duration,
                          l10n,
                          formatDuration,
                        ),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
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

  String _localizedDuration(
    Duration duration,
    AppLocalizations l10n,
    String Function(Duration) fallbackFormatter,
  ) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (minutes == 0) {
      if (hours == 1) {
        return l10n.oneHour;
      }

      return l10n.hoursCount(hours);
    }

    final decimalHours = duration.inMinutes / 60;

    return l10n.decimalHours(
      decimalHours.toStringAsFixed(1),
    );
  }
}
