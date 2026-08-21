import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'nav_bar.dart';

class Managereminderspage extends StatefulWidget {
  const Managereminderspage({super.key});

  @override
  State<Managereminderspage> createState() => _ManagereminderspageState();
}

class _ManagereminderspageState extends State<Managereminderspage> {
  final Color primaryBlue = const Color(0xFF3D84A8);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _loading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> reminders = [];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  // ============================================================
  // LOAD REMINDERS
  // ============================================================

  Future<void> _loadReminders() async {
    final user = _auth.currentUser;

    if (user == null) {
      setState(() {
        _loading = false;
        _errorMessage = 'Please sign in again.';
      });
      return;
    }

    try {
      final medicineSnapshot = await _firestore
          .collection('medicines')
          .where('userId', isEqualTo: user.uid)
          .get();

      final appointmentSnapshot = await _firestore
          .collection('appointments')
          .where('userId', isEqualTo: user.uid)
          .get();

      final List<Map<String, dynamic>> loaded = [];

      // ----------------------------------------------------------
      // MEDICINES
      // ----------------------------------------------------------

      for (final doc in medicineSnapshot.docs) {
        final data = doc.data();

        final List<dynamic> times = data['times'] is List ? data['times'] : [];

        String timeText = 'No time';

        if (times.isNotEmpty) {
          timeText = times.map((e) => e.toString()).join(' • ');
        }

        final String instructions =
            (data['instructions'] ?? '').toString().trim();

        final String frequency = (data['frequency'] ?? '').toString().trim();

        String subtitle = '';

        if (instructions.isNotEmpty && frequency.isNotEmpty) {
          subtitle = '$instructions • $frequency';
        } else if (frequency.isNotEmpty) {
          subtitle = frequency;
        } else if (instructions.isNotEmpty) {
          subtitle = instructions;
        } else {
          subtitle = 'Medicine reminder';
        }

        loaded.add({
          'id': doc.id,
          'collection': 'medicines',
          'title': data['medicineName'] ?? 'Medicine',
          'subtitle': subtitle,
          'time': timeText,
          'type': 'pill',
          'active': data['active'] ?? true,
          'data': data,
        });
      }

      // ----------------------------------------------------------
      // APPOINTMENTS
      // ----------------------------------------------------------

      for (final doc in appointmentSnapshot.docs) {
        final data = doc.data();

        final Timestamp? dateTime = data['dateTime'] is Timestamp
            ? data['dateTime'] as Timestamp
            : null;

        String timeText = 'No date';

        if (dateTime != null) {
          final date = dateTime.toDate();

          timeText =
              '${date.day}/${date.month}/${date.year} • ${_formatTime(date)}';
        }

        final String hospital = (data['hospital'] ?? '').toString().trim();

        final String appointmentType =
            (data['appointmentType'] ?? 'Appointment').toString();

        loaded.add({
          'id': doc.id,
          'collection': 'appointments',
          'title': appointmentType,
          'subtitle': hospital.isEmpty ? 'Appointment' : hospital,
          'time': timeText,
          'type': 'appointment',
          'active': data['active'] ?? true,
          'data': data,
        });
      }

      // Medicines first, appointments second.
      loaded.sort((a, b) {
        if (a['type'] == b['type']) return 0;
        return a['type'] == 'pill' ? -1 : 1;
      });

      if (!mounted) return;

      setState(() {
        reminders = loaded;
        _loading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = 'Could not load reminders.';
      });

      debugPrint('Load reminders error: $e');
    }
  }

  // ============================================================
  // FORMAT TIME
  // ============================================================

  String _formatTime(DateTime date) {
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  // ============================================================
  // TOGGLE ACTIVE
  // ============================================================

  Future<void> _toggleReminder(
    Map<String, dynamic> item,
    bool value,
  ) async {
    final String collection = item['collection'];
    final String id = item['id'];

    try {
      await _firestore.collection(collection).doc(id).update({
        'active': value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        item['active'] = value;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update reminder.'),
        ),
      );

      debugPrint('Toggle reminder error: $e');
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _delete(Map<String, dynamic> item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Reminder'),
          content: Text(
            'Are you sure you want to delete "${item['title']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _firestore.collection(item['collection']).doc(item['id']).delete();

      if (!mounted) return;

      setState(() {
        reminders.remove(item);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder deleted.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete reminder.'),
        ),
      );

      debugPrint('Delete reminder error: $e');
    }
  }

  // ============================================================
  // EDIT
  // ============================================================

  Future<void> _editReminder(Map<String, dynamic> item) async {
    if (item['collection'] == 'medicines') {
      await _editMedicine(item);
    } else {
      await _editAppointment(item);
    }
  }

  // ============================================================
  // EDIT MEDICINE
  // ============================================================

  Future<void> _editMedicine(Map<String, dynamic> item) async {
    final data = Map<String, dynamic>.from(item['data']);

    final nameController = TextEditingController(
      text: (data['medicineName'] ?? '').toString(),
    );

    final doseController = TextEditingController(
      text: (data['dose'] ?? '').toString(),
    );

    final instructionsController = TextEditingController(
      text: (data['instructions'] ?? '').toString(),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Medicine'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(
                  controller: nameController,
                  label: 'Medicine Name',
                ),
                const SizedBox(height: 12),
                _dialogField(
                  controller: doseController,
                  label: 'Dose',
                ),
                const SizedBox(height: 12),
                _dialogField(
                  controller: instructionsController,
                  label: 'Instructions',
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  return;
                }

                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != true) {
      nameController.dispose();
      doseController.dispose();
      instructionsController.dispose();
      return;
    }

    try {
      await _firestore.collection('medicines').doc(item['id']).update({
        'medicineName': nameController.text.trim(),
        'dose': doseController.text.trim(),
        'instructions': instructionsController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      nameController.dispose();
      doseController.dispose();
      instructionsController.dispose();

      await _loadReminders();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medicine updated.'),
        ),
      );
    } catch (e) {
      nameController.dispose();
      doseController.dispose();
      instructionsController.dispose();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update medicine.'),
        ),
      );

      debugPrint('Edit medicine error: $e');
    }
  }

  // ============================================================
  // EDIT APPOINTMENT
  // ============================================================

  Future<void> _editAppointment(Map<String, dynamic> item) async {
    final data = Map<String, dynamic>.from(item['data']);

    final hospitalController = TextEditingController(
      text: (data['hospital'] ?? '').toString(),
    );

    final reasonController = TextEditingController(
      text: (data['reason'] ?? '').toString(),
    );

    String appointmentType = (data['appointmentType'] ?? 'General').toString();

    DateTime appointmentDate = DateTime.now();

    if (data['dateTime'] is Timestamp) {
      appointmentDate = (data['dateTime'] as Timestamp).toDate();
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Appointment'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: appointmentType,
                      decoration: const InputDecoration(
                        labelText: 'Appointment Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        'General',
                        'Eye',
                        'Dental',
                        'Heart',
                      ]
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            appointmentType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _dialogField(
                      controller: hospitalController,
                      label: 'Hospital',
                    ),
                    const SizedBox(height: 12),
                    _dialogField(
                      controller: reasonController,
                      label: 'Reason / Notes',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.calendar_today_outlined,
                        color: primaryBlue,
                      ),
                      title: const Text('Date & Time'),
                      subtitle: Text(
                        '${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year} • ${_formatTime(appointmentDate)}',
                      ),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: appointmentDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2035),
                        );

                        if (pickedDate == null) return;

                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                            appointmentDate,
                          ),
                        );

                        if (pickedTime == null) return;

                        setDialogState(() {
                          appointmentDate = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) {
      hospitalController.dispose();
      reasonController.dispose();
      return;
    }

    try {
      await _firestore.collection('appointments').doc(item['id']).update({
        'appointmentType': appointmentType,
        'hospital': hospitalController.text.trim(),
        'reason': reasonController.text.trim(),
        'dateTime': Timestamp.fromDate(appointmentDate),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      hospitalController.dispose();
      reasonController.dispose();

      await _loadReminders();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment updated.'),
        ),
      );
    } catch (e) {
      hospitalController.dispose();
      reasonController.dispose();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update appointment.'),
        ),
      );

      debugPrint('Edit appointment error: $e');
    }
  }

  // ============================================================
  // DIALOG FIELD
  // ============================================================

  Widget _dialogField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  // ============================================================
  // BOTTOM NAV
  // ============================================================

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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 1,
        onTap: (i) => _onBottomTap(context, i),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadReminders,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.06,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Reminders',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Manage your reminders',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_errorMessage != null)
                  _errorState()
                else if (reminders.isEmpty)
                  _emptyState()
                else
                  ...reminders.map(_card),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _errorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 42,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 10),
          Text(
            _errorMessage ?? 'Something went wrong.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadReminders,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 35,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 50,
            color: primaryBlue,
          ),
          const SizedBox(height: 12),
          const Text(
            'No reminders yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your medicine and appointment reminders will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _card(Map<String, dynamic> item) {
    final bool isMedicine = item['type'] == 'pill';
    final bool active = item['active'] == true;

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
          // ICON
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF2FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isMedicine
                  ? Icons.medication_outlined
                  : Icons.calendar_today_outlined,
              color: primaryBlue,
            ),
          ),

          const SizedBox(width: 12),

          // CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TIME
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(87, 207, 207, 207),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item['time'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // TITLE
                Text(
                  item['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 2),

                // SUBTITLE
                Text(
                  item['subtitle'],
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 10),

                // ACTIONS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _action(
                          'Edit',
                          () => _editReminder(item),
                        ),
                        const SizedBox(width: 16),
                        _action(
                          'Delete',
                          () => _delete(item),
                          isDelete: true,
                        ),
                      ],
                    ),
                    Switch(
                      value: active,
                      onChanged: (value) {
                        _toggleReminder(item, value);
                      },
                      activeColor: Colors.white,
                      activeTrackColor: primaryBlue,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey.shade300,
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

  // ============================================================
  // ACTION
  // ============================================================

  Widget _action(
    String text,
    VoidCallback onTap, {
    bool isDelete = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 2,
          vertical: 4,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isDelete ? Colors.red : primaryBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
