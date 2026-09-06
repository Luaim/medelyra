import 'package:flutter/material.dart';

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

    if (_selectedTime == null) {
      setState(() {
        _errorMessage = 'Please select your wake-up time.';
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
      _resultTitle = 'Suggested bedtimes';
      _resultMessage =
          'These times are based on approximate sleep-cycle lengths. '
          'Your actual sleep needs can vary.';
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
    final hasResult = _sleepSuggestions != null &&
        _resultTitle != null &&
        _resultMessage != null;

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
                          'Sleep Calculator',
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
                      const Text(
                        'Find suggested bedtimes',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: _secondaryTextColor,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ----------------------------------------------------------------
                      // ICON
                      // ----------------------------------------------------------------

                      const Icon(
                        Icons.bedtime_outlined,
                        size: 50,
                        color: _primaryColor,
                      ),

                      const SizedBox(height: 20),

                      // ----------------------------------------------------------------
                      // WAKE-UP TIME LABEL
                      // ----------------------------------------------------------------

                      const Text(
                        'Wake-up time',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _textColor,
                        ),
                      ),

                      const SizedBox(height: 7),

                      // ----------------------------------------------------------------
                      // WAKE-UP TIME PICKER
                      // ----------------------------------------------------------------

                      InkWell(
                        onTap: _selectWakeUpTime,
                        borderRadius: BorderRadius.circular(13),
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFAFC),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: const Color(0xFFE3EAF5),
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
                                      ? 'Select your wake-up time'
                                      : _formatTime(_selectedTime!),
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: _selectedTime == null
                                        ? const Color(0xFF9CA3AF)
                                        : _textColor,
                                    fontWeight: _selectedTime == null
                                        ? FontWeight.normal
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFF7B8491),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ----------------------------------------------------------------
                      // ERROR
                      // ----------------------------------------------------------------

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF5F5),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: const Color(0xFFF0D0D0),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 18,
                                color: Color(0xFFC95C68),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    height: 1.35,
                                    color: Color(0xFFC95C68),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // ----------------------------------------------------------------
                      // BUTTON
                      // ----------------------------------------------------------------

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
                          child: const Text(
                            'Calculate Bedtimes',
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
                        _SleepResultCard(
                          title: _resultTitle!,
                          message: _resultMessage!,
                          suggestions: _sleepSuggestions!,
                          formatTime: _formatTime,
                          formatDuration: _formatDuration,
                        ),
                      ],

                      const SizedBox(height: 18),

                      // ----------------------------------------------------------------
                      // DISCLAIMER
                      // ----------------------------------------------------------------

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
                                'Sleep needs vary from person to person. '
                                'These suggestions are based on approximate '
                                'sleep-cycle lengths and are not medical advice.',
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: _secondaryTextColor,
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: const Color(0xFFE3EAF5),
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
                          formatTime(suggestion.bedtime),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _textColor,
                          ),
                        ),
                      ),
                      Text(
                        formatDuration(suggestion.duration),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: _secondaryTextColor,
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
