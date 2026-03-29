import 'package:flutter/material.dart';
import 'nav_bar.dart';

class PillReminderPage extends StatefulWidget {
  const PillReminderPage({super.key});

  @override
  State<PillReminderPage> createState() => _PillReminderPageState();
}

class _PillReminderPageState extends State<PillReminderPage> {
  final TextEditingController medicineNameController = TextEditingController();

  String selectedType = 'Pill';
  String selectedPeriod = 'Morning';
  String selectedDuration = '7 Days';
  String selectedFrequency = 'Once Daily';

  TimeOfDay selectedTime = TimeOfDay.now();

  final List<Map<String, dynamic>> medicineTypes = [
    {'label': 'Pill', 'icon': Icons.medication},
    {'label': 'Injection', 'icon': Icons.vaccines},
    {'label': 'Cream', 'icon': Icons.spa},
    {'label': 'Drop', 'icon': Icons.opacity},
    {'label': 'Inhaler', 'icon': Icons.air},
    {'label': 'Bandage', 'icon': Icons.healing},
    {'label': 'Syrup', 'icon': Icons.local_drink},
    {'label': 'Other', 'icon': Icons.medical_information},
  ];

  void _onBottomTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/reminder');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/finder');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/sos');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 1,
        onTap: (i) => _onBottomTap(context, i),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: width * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              const Center(
                child: Text(
                  'New Reminder',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                ),
              ),

              const SizedBox(height: 20),

              /// TYPE WITH LABEL
              const Text('Medicine Type',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),

              const SizedBox(height: 10),

              Wrap(
                spacing: 18,
                runSpacing: 12,
                children: medicineTypes.map((item) {
                  final isSelected = selectedType == item['label'];

                  return GestureDetector(
                    onTap: () => setState(() => selectedType = item['label']),
                    child: Container(
                      width: 70,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? const Color(0xFF3D84A8) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            item['icon'],
                            color: isSelected ? Colors.white : Colors.grey,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['label'],
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? Colors.white : Colors.black54,
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              /// NAME
              const Text('Medicine Name',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),

              const SizedBox(height: 8),

              _input(
                child: TextField(
                  controller: medicineNameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter medicine name',
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// PERIOD
              const Text('Time of Day',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),

              const SizedBox(height: 10),

              Row(
                children: ['Morning', 'Afternoon', 'Night']
                    .map((e) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _chip(
                              text: e,
                              selected: selectedPeriod == e,
                              onTap: () => setState(() => selectedPeriod = e),
                            ),
                          ),
                        ))
                    .toList(),
              ),

              const SizedBox(height: 20),

              /// TIME
              const Text('Select Time',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),

              const SizedBox(height: 10),

              GestureDetector(
                onTap: _pickTime,
                child: _input(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(selectedTime.format(context)),
                      const Icon(Icons.access_time),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// DURATION
              const Text('Duration',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),

              const SizedBox(height: 10),

              _dropdown(['7 Days', '14 Days', '1 Month'], selectedDuration,
                  (v) {
                setState(() => selectedDuration = v);
              }),

              const SizedBox(height: 20),

              /// FREQUENCY
              const Text('Frequency',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),

              const SizedBox(height: 10),

              _dropdown(['Once Daily', 'Twice Daily', 'Every 8 Hours'],
                  selectedFrequency, (v) {
                setState(() => selectedFrequency = v);
              }),

              const SizedBox(height: 30),

              /// BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D84A8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Add Reminder',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: child,
    );
  }

  Widget _chip({
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3D84A8) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color.fromARGB(255, 255, 255, 255)),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _dropdown(
      List<String> items, String value, Function(String) onChanged) {
    return _input(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => onChanged(v!),
        ),
      ),
    );
  }
}
