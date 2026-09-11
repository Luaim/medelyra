import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EmergencyGuideDetailsPage extends StatefulWidget {
  final String guideId;

  const EmergencyGuideDetailsPage({
    super.key,
    required this.guideId,
  });

  @override
  State<EmergencyGuideDetailsPage> createState() =>
      _EmergencyGuideDetailsPageState();
}

class _EmergencyGuideDetailsPageState extends State<EmergencyGuideDetailsPage> {
  Map<String, dynamic>? guide;

  bool isLoading = true;
  String? errorMessage;

  // ---------------------------------------------------------------------------
  // THEME COLORS
  // ---------------------------------------------------------------------------

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _pageBackground =>
      _isDark ? const Color(0xFF121212) : const Color(0xFFF6F6F6);

  Color get _primaryTextColor =>
      _isDark ? Colors.white : const Color(0xFF29262D);

  Color get _secondaryTextColor =>
      _isDark ? const Color(0xFFBDBDBD) : const Color(0xFF77737A);

  // ---------------------------------------------------------------------------
  // LANGUAGE
  // ---------------------------------------------------------------------------

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  // Reads either:
  //
  // {
  //   "en": "Choking",
  //   "ar": "الاختناق"
  // }
  //
  // or a normal String for backwards compatibility.
  String _localizedText(dynamic value) {
    if (value is Map) {
      if (_isArabic) {
        return value['ar']?.toString() ?? value['en']?.toString() ?? '';
      }

      return value['en']?.toString() ?? value['ar']?.toString() ?? '';
    }

    return value?.toString() ?? '';
  }

  // ---------------------------------------------------------------------------
  // LOAD GUIDE
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadGuide();
  }

  Future<void> _loadGuide() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final jsonString = await rootBundle.loadString(
        'assets/emergency_guides/emergency_guides.json',
      );

      final decoded = jsonDecode(jsonString);

      if (decoded is! List) {
        throw const FormatException(
          'Emergency guides JSON must contain a list.',
        );
      }

      Map<String, dynamic>? foundGuide;

      for (final item in decoded) {
        if (item is! Map) continue;

        final data = Map<String, dynamic>.from(item);

        if (data['id']?.toString() == widget.guideId) {
          foundGuide = data;
          break;
        }
      }

      if (!mounted) return;

      if (foundGuide == null) {
        setState(() {
          isLoading = false;
          errorMessage = _isArabic
              ? 'تعذر العثور على دليل الطوارئ هذا.'
              : 'This emergency guide could not be found.';
        });
        return;
      }

      setState(() {
        guide = foundGuide;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = _isArabic
            ? 'تعذر تحميل دليل الطوارئ هذا.'
            : 'Could not load this emergency guide.';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: _pageBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: _primaryTextColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isArabic ? 'دليل الطوارئ' : 'Emergency guide',
          style: TextStyle(
            color: _primaryTextColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  // ---------------------------------------------------------------------------
  // BODY
  // ---------------------------------------------------------------------------

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF3D84A8),
        ),
      );
    }

    if (errorMessage != null) {
      return _ErrorState(
        message: errorMessage!,
        onRetry: _loadGuide,
      );
    }

    if (guide == null) {
      return _ErrorState(
        message: _isArabic
            ? 'تعذر العثور على دليل الطوارئ هذا.'
            : 'This emergency guide could not be found.',
      );
    }

    // -------------------------------------------------------------------------
    // GUIDE TITLE
    // -------------------------------------------------------------------------

    final String title = _localizedText(
      guide!['title'],
    );

    // -------------------------------------------------------------------------
    // SHORT DESCRIPTION
    // -------------------------------------------------------------------------

    final String shortDescription = _localizedText(
      guide!['shortDescription'],
    );

    // -------------------------------------------------------------------------
    // STEPS
    // -------------------------------------------------------------------------

    final List<dynamic> steps =
        guide!['steps'] is List ? guide!['steps'] as List<dynamic> : [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------------------------------------------------------------------
          // TITLE
          // -------------------------------------------------------------------

          Text(
            title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: _primaryTextColor,
            ),
          ),

          // -------------------------------------------------------------------
          // SHORT DESCRIPTION
          // -------------------------------------------------------------------

          if (shortDescription.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              shortDescription,
              style: TextStyle(
                fontSize: 16,
                height: 1.45,
                color: _secondaryTextColor,
              ),
            ),
          ],

          const SizedBox(height: 22),

          // -------------------------------------------------------------------
          // STEPS
          // -------------------------------------------------------------------

          if (steps.isEmpty)
            const _NoStepsState()
          else
            ...List.generate(
              steps.length,
              (index) {
                final step = steps[index];

                if (step is! Map) {
                  return const SizedBox.shrink();
                }

                // -------------------------------------------------------------
                // IMPORTANT:
                //
                // title is now a language object in the JSON.
                // _localizedText() selects "en" or "ar".
                // -------------------------------------------------------------

                final String stepTitle = _localizedText(
                  step['title'],
                );

                final String description = _localizedText(
                  step['description'],
                );

                final String image = step['image']?.toString() ?? '';

                return _GuideStepCard(
                  stepNumber: index + 1,
                  title: stepTitle,
                  description: description,
                  image: image,
                );
              },
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// GUIDE STEP
// =============================================================================

class _GuideStepCard extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String description;
  final String image;

  const _GuideStepCard({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBackground = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final primaryTextColor = isDark ? Colors.white : const Color(0xFF29262D);

    final descriptionColor =
        isDark ? const Color(0xFFB8B8B8) : const Color(0xFF65616A);

    final stepCircleBackground =
        isDark ? const Color(0xFF26343A) : const Color(0xFFE9F2F6);

    final stepNumberColor =
        isDark ? const Color(0xFF6FA9C5) : const Color(0xFF3D84A8);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: isDark
            ? Border.all(
                color: const Color(0xFF333333),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------------------------------------------------------------------
          // STEP TITLE
          // -------------------------------------------------------------------

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: stepCircleBackground,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$stepNumber',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: stepNumberColor,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),

          // -------------------------------------------------------------------
          // DESCRIPTION
          // -------------------------------------------------------------------

          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: descriptionColor,
              ),
            ),
          ],

          // -------------------------------------------------------------------
          // IMAGE
          // -------------------------------------------------------------------

          if (image.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 190,
              child: Image.asset(
                image,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) {
                  return Icon(
                    Icons.image_not_supported_outlined,
                    size: 38,
                    color: isDark
                        ? const Color(0xFF9E9E9E)
                        : const Color(0xFF9A979F),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// NO STEPS
// =============================================================================

class _NoStepsState extends StatelessWidget {
  const _NoStepsState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final message = Localizations.localeOf(context).languageCode == 'ar'
        ? 'لا توجد تعليمات متاحة لهذا الدليل.'
        : 'No instructions are available for this guide.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isDark
            ? Border.all(
                color: const Color(0xFF333333),
              )
            : null,
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15,
          color: isDark ? const Color(0xFFBDBDBD) : const Color(0xFF77737A),
        ),
      ),
    );
  }
}

// =============================================================================
// ERROR STATE
// =============================================================================

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorState({
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tryAgain = Localizations.localeOf(context).languageCode == 'ar'
        ? 'حاول مرة أخرى'
        : 'Try Again';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: isDark
                ? Border.all(
                    color: const Color(0xFF333333),
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 44,
                color: Color(0xFFE96B6B),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark
                      ? const Color(0xFFBDBDBD)
                      : const Color(0xFF55525A),
                  height: 1.4,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  child: Text(tryAgain),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
