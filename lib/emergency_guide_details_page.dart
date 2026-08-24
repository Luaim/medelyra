import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EmergencyGuideDetailsPage extends StatelessWidget {
  final String guideId;

  const EmergencyGuideDetailsPage({
    super.key,
    required this.guideId,
  });

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
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('emergency_guides')
            .doc(guideId)
            .snapshots(),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF3D84A8),
              ),
            );
          }

          // Error
          if (snapshot.hasError) {
            return _ErrorState(
              message: 'Could not load this emergency guide.',
              onRetry: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EmergencyGuideDetailsPage(
                      guideId: guideId,
                    ),
                  ),
                );
              },
            );
          }

          // Document doesn't exist
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const _ErrorState(
              message: 'This emergency guide could not be found.',
            );
          }

          final data = snapshot.data!.data();

          if (data == null) {
            return const _ErrorState(
              message: 'This emergency guide has no data.',
            );
          }

          final String title = data['title']?.toString() ?? 'Emergency guide';

          final String shortDescription =
              data['shortDescription']?.toString() ?? '';

          final List<dynamic> steps =
              data['steps'] is List ? data['steps'] as List<dynamic> : [];

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TITLE
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF29262D),
                  ),
                ),

                // SHORT DESCRIPTION
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

                // STEPS
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
        },
      ),
    );
  }
}

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
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // STEP NUMBER + TITLE
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF2FF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$stepNumber',
                  style: const TextStyle(
                    color: Color(0xFF3D84A8),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF29262D),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // DESCRIPTION
          if (description.isNotEmpty)
            Text(
              description,
              style: const TextStyle(
                fontSize: 15,
                height: 1.45,
                color: Color(0xFF68646B),
              ),
            ),

          // IMAGE
          if (image.isNotEmpty) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                image,
                width: double.infinity,
                height: 190,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) {
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoStepsState extends StatelessWidget {
  const _NoStepsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.info_outline,
            size: 42,
            color: Color(0xFF3D84A8),
          ),
          SizedBox(height: 12),
          Text(
            'No instructions are available yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF68646B),
            ),
          ),
        ],
      ),
    );
  }
}

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
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Color(0xFFE96B6B),
              ),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF4A464D),
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D84A8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
