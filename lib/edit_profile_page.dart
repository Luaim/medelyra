import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final nameController = TextEditingController(text: 'Luaim Ahmed');
  final emailController = TextEditingController(text: 'luaim@example.com');
  final phoneController = TextEditingController(text: '+60 12-345 6789');

  String gender = 'Male';
  String bloodGroup = 'O+';

  DateTime selectedDate = DateTime(2002, 5, 12);

  List<String> allergies = ['Dust']; // example
  final allergyController = TextEditingController();

  /// PICK DATE
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  /// ADD ALLERGY
  void _addAllergy() {
    if (allergyController.text.trim().isEmpty) return;

    setState(() {
      allergies.add(allergyController.text.trim());
      allergyController.clear();
    });
  }

  /// REMOVE ALLERGY
  void _removeAllergy(String item) {
    setState(() => allergies.remove(item));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text('Edit Profile'),
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

            /// PERSONAL
            const Text(
              'Personal Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 12),

            _input(nameController, 'Full Name'),
            _input(emailController, 'Email'),
            _input(phoneController, 'Phone Number'),

            /// DATE
            GestureDetector(
              onTap: _pickDate,
              child: _box(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// GENDER
            const Text('Gender'),
            const SizedBox(height: 6),
            _dropdown(['Male', 'Female'], gender, (v) {
              setState(() => gender = v);
            }),

            const SizedBox(height: 22),

            /// MEDICAL
            const Text(
              'Medical Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 12),

            const Text('Blood Group'),
            const SizedBox(height: 6),
            _dropdown(['A+', 'B+', 'AB+', 'O+'], bloodGroup, (v) {
              setState(() => bloodGroup = v);
            }),

            const SizedBox(height: 16),

            /// ALLERGIES
            const Text('Allergies'),
            const SizedBox(height: 6),

            Wrap(
              spacing: 8,
              children: allergies.map((item) {
                return Chip(
                  label: Text(item),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () => _removeAllergy(item),
                );
              }).toList(),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _box(
                    child: TextField(
                      controller: allergyController,
                      decoration: const InputDecoration(
                        hintText: 'Add allergy',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addAllergy,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D84A8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),

            const SizedBox(height: 30),

            /// SAVE
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D84A8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// INPUT
  Widget _input(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _box(
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  /// BOX STYLE
  Widget _box({required Widget child}) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  /// DROPDOWN
  Widget _dropdown(
      List<String> items, String value, Function(String) onChanged) {
    return _box(
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
