import 'package:flutter/material.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  int? expandedIndex;

  final List<Map<String, String>> faqs = [
    {
      'q': 'How do I add a medicine reminder?',
      'a':
          'Go to Reminder page, tap "Add Reminder", fill the details and save.',
    },
    {
      'q': 'Will I receive notifications?',
      'a': 'Yes, MedMinder will notify you based on your schedule.',
    },
    {
      'q': 'Can I edit my profile?',
      'a': 'Yes, go to Settings → Edit Profile to update your information.',
    },
    {
      'q': 'How do I delete a reminder?',
      'a': 'Open the reminder and choose delete or manage it from the list.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            /// TITLE
            const Text(
              'How can we help you?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Find answers or contact support',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            /// FAQ
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 10),

            ...List.generate(faqs.length, (index) {
              final item = faqs[index];

              final isOpen = expandedIndex == index;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    expandedIndex = isOpen ? null : index;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item['q']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            isOpen
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                          )
                        ],
                      ),
                      if (isOpen) ...[
                        const SizedBox(height: 8),
                        Text(
                          item['a']!,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ]
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            /// CONTACT
            const Text(
              'Contact Support',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.email_outlined, color: Color(0xFF3D84A8)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('support@medminder.app'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // later: open email / support form
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D84A8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Contact Support'),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
