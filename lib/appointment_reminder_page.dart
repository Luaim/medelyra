import 'package:flutter/material.dart';
import 'nav_bar.dart';

class AppointmentReminderPage extends StatefulWidget {
  const AppointmentReminderPage({super.key});

  @override
  State<AppointmentReminderPage> createState() =>
      _AppointmentReminderPageState();
}

class _AppointmentReminderPageState extends State<AppointmentReminderPage> {
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

  final TextEditingController reasonController = TextEditingController();

  String selectedType = 'General';
  String selectedHospital = 'Select Hospital';

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  final List<Map<String, dynamic>> appointmentTypes = [
    {'label': 'General', 'icon': Icons.local_hospital},
    {'label': 'Eye', 'icon': Icons.remove_red_eye},
    {'label': 'Dental', 'icon': Icons.medical_services},
    {'label': 'Heart', 'icon': Icons.favorite},
  ];

  final TextEditingController hospitalController = TextEditingController();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
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
                  'New Appointment',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                ),
              ),

              const SizedBox(height: 20),

              /// TYPE WITH LABEL
              const Text('Appointment Type',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),

              const SizedBox(height: 10),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: appointmentTypes.map((item) {
                  final isSelected = selectedType == item['label'];

                  return GestureDetector(
                    onTap: () => setState(() => selectedType = item['label']),
                    child: Container(
                      width: 80,
                      padding: const EdgeInsets.symmetric(vertical: 10),
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
                              fontSize: 12,
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

              /// HOSPITAL
              const Text('Hospital',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),

              const SizedBox(height: 8),

              _input(
                child: TextField(
                  controller: hospitalController,
                  decoration: const InputDecoration(
                    hintText: 'Enter hospital name...',
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// DATE
              const Text('Select Date',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),

              const SizedBox(height: 10),

              GestureDetector(
                onTap: _pickDate,
                child: _input(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
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

              /// REASON
              const Text('Reason / Notes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),

              const SizedBox(height: 8),

              _input(
                child: TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Describe your appointment...',
                    border: InputBorder.none,
                  ),
                ),
              ),

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
                    'Confirm Appointment',
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
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
}
