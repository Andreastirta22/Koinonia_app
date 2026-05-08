import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:koinonia/dashboard/warga_dashboard.dart';

class EditProfilePage extends StatefulWidget {
  final UserData userData;

  const EditProfilePage({super.key, required this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _tanggalLahirController;
  DateTime? _selectedDate;

  bool _isSaving = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _tanggalLahirController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _tanggalLahirController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
        _errorMessage = '';
      });

      try {
        final newEmail = _emailController.text.trim();

        // 🔎 Cek apakah email sudah dipakai user lain
        final querySnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: newEmail)
                .get();

        if (querySnapshot.docs.isNotEmpty &&
            querySnapshot.docs.first.id != widget.userData.uid) {
          setState(() {
            _errorMessage = 'Email sudah digunakan oleh akun lain';
            _isSaving = false;
          });
          return;
        }

        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userData.uid);

        await docRef.update({
          'email': newEmail,
          'no_telp': _phoneController.text.trim(),
          'tanggal_lahir': _selectedDate,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui.'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      } catch (e) {
        setState(() {
          _errorMessage = 'Gagal menyimpan profil: $e';
        });
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userData.uid)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        // isi controller hanya kalau kosong (pertama kali)
        if (_nameController.text.isEmpty) {
          _nameController.text = data['nama'] ?? '';
        }
        if (_emailController.text.isEmpty) {
          _emailController.text = data['email'] ?? '';
        }
        if (_phoneController.text.isEmpty) {
          _phoneController.text = data['no_telp'] ?? '';
        }
        if (_tanggalLahirController.text.isEmpty &&
            data['tanggal_lahir'] != null) {
          final tgl = (data['tanggal_lahir'] as Timestamp).toDate();
          _selectedDate = tgl;
          _tanggalLahirController.text = '${tgl.day}/${tgl.month}/${tgl.year}';
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Profil'),
            backgroundColor: Colors.brown,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Perbarui informasi pribadi Anda.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  TextFormField(
                    controller: _nameController,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email tidak boleh kosong';
                      }

                      // Regex sederhana untuk validasi email
                      final emailRegex = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      );
                      if (!emailRegex.hasMatch(value)) {
                        return 'Format email tidak valid';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Telepon',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _tanggalLahirController,
                    readOnly: true,
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null && pickedDate != _selectedDate) {
                        setState(() {
                          _selectedDate = pickedDate;
                          _tanggalLahirController.text =
                              '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Lahir',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_errorMessage.isNotEmpty)
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),

                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    child:
                        _isSaving
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text('Simpan Perubahan'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
