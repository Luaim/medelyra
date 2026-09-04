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

  @override
  void initState() {
    super.initState();
    _loadGuide();
  }

  // ---------------------------------------------------------------------------
  // LOAD GUIDE
  // ---------------------------------------------------------------------------

  Future<void> _loadGuide() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Load the same bundled JSON used by the Emergency Guide list.
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
          errorMessage = 'This emergency guide could not be found.';
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
        errorMessage = 'Could not load this emergency guide.';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F6F6),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF29262D),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Emergency guide',
          style: TextStyle(
            color: Color(0xFF29262D),
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
      return const _ErrorState(
        message: 'This emergency guide could not be found.',
      );
    }

    final String title = guide!['title']?.toString() ?? 'Emergency guide';

    final String shortDescription =
        guide!['shortDescription']?.toString() ?? '';

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
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Color(0xFF29262D),
            ),
          ),
          if (shortDescription.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              shortDescription,
              style: const TextStyle(
                fontSize: 16,
                height: 1.45,
                color: Color(0xFF77737A),
              ),
            ),
          ],
          const SizedBox(height: 22),
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

                final String stepTitle = step['title']?.toString() ?? '';

                final String description =
                    step['description']?.toString() ?? '';

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
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
                decoration: const BoxDecoration(
                  color: Color(0xFFE9F2F6),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$stepNumber',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3D84A8),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF29262D),
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
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Color(0xFF65616A),
              ),
            ),
          ],

          // -------------------------------------------------------------------
          // IMAGE
          // -------------------------------------------------------------------

          if (image.isNotEmpty) ...[
            const SizedBox(height: 16),

            // Keep the same image size as the old design.
            // BoxFit.contain shows the COMPLETE image without cropping
            // or zooming.
            SizedBox(
              width: double.infinity,
              height: 190,
              child: Image.asset(
                image,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) {
                  return const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 38,
                      color: Color(0xFF9A979F),
                    ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'No instructions are available for this guide.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15,
          color: Color(0xFF77737A),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
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
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF55525A),
                  height: 1.4,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Try Again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
