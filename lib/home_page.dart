import 'package:flutter/material.dart';
import 'nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedDayIndex = 2;

  final List<Map<String, String>> medicines = [
    {
      'title': 'Vitamin D',
      'subtitle': '2 Capsules - After meal',
      'time': '1:00 PM',
    },
    {
      'title': 'Vitamin A',
      'subtitle': '1 Capsule - After meal',
      'time': '6:00 PM',
    },
  ];

  final List<Map<String, String>> weekDays = [
    {'day': 'Mon', 'date': '10'},
    {'day': 'Tue', 'date': '11'},
    {'day': 'Wed', 'date': '12'},
    {'day': 'Thu', 'date': '13'},
    {'day': 'Fri', 'date': '14'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 0,
        onTap: (i) {},
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              /// 📅 MONTH
              const Text(
                'May 2024',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color.fromARGB(255, 50, 50, 50),
                ),
              ),

              const SizedBox(height: 12),

              /// 📆 DAYS
              SizedBox(
                height: 65,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: weekDays.length,
                  itemBuilder: (_, i) {
                    final item = weekDays[i];
                    final selected = i == selectedDayIndex;

                    return GestureDetector(
                      onTap: () => setState(() => selectedDayIndex = i),
                      child: Container(
                        width: 60,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color.fromARGB(255, 88, 145, 250)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item['day']!,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : const Color.fromARGB(202, 0, 0, 0),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['date']!,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              /// 📊 PROGRESS
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('5/10'),
                  Text('50% Completed'),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const LinearProgressIndicator(
                  value: 0.5,
                  minHeight: 8,
                  backgroundColor: Color(0xFFE4E7F2),
                  valueColor:
                      AlwaysStoppedAnimation(Color.fromARGB(219, 47, 97, 245)),
                ),
              ),

              const SizedBox(height: 18),

              /// 📦 CARDS
              ...medicines.map((e) => _card(e)),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// 💊 CARD (FINAL CLEAN VERSION)
  Widget _card(Map<String, String> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 ICON PLACEHOLDER (FOR FUTURE TYPES)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF2FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.medication_outlined,
              color: Color.fromARGB(255, 123, 139, 160),
            ),
          ),

          const SizedBox(width: 12),

          /// 📄 CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// TIME
                Text(
                  item['time']!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color.fromARGB(180, 253, 0, 0),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  item['title']!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D2D2D),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  item['subtitle']!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color.fromARGB(255, 134, 134, 134),
                  ),
                ),

                const SizedBox(height: 10),

                /// PRIMARY BUTTON
                SizedBox(
                  height: 36,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(237, 88, 145, 250),
                      foregroundColor: Colors.white,
                      side: const BorderSide(
                          color: Color.fromARGB(174, 64, 64, 64), width: 1),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text('Mark as Taken'),
                  ),
                ),

                const SizedBox(height: 6),

                /// SECONDARY ACTIONS
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Postpone',
                      style: TextStyle(
                        color: Color.fromARGB(178, 15, 0, 98), // soft orange
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Skip',
                      style: TextStyle(
                        color: Color(0xFFEF5350), // soft red
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
