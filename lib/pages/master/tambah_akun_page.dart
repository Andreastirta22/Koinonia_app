import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Halaman untuk menambahkan akun pengguna baru.
class TambahAkunPage extends StatefulWidget {
  const TambahAkunPage({super.key});

  @override
  State<TambahAkunPage> createState() => _TambahAkunPageState();
}

class _TambahAkunPageState extends State<TambahAkunPage> {
  // Controller untuk input teks
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController namaController = TextEditingController();

  // Variabel state untuk pilihan pengguna
  String selectedRole = 'pengurus'; // Pindahkan role ke atas sesuai permintaan
  String selectedGender = 'laki-laki';
  DateTime? tanggalLahir;
  bool isKepalaKeluarga = false;
  bool isGaptek = false;

  // Form key untuk validasi
  final _formKey = GlobalKey<FormState>();

  // Format tanggal untuk tampilan
  final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

  // Fungsi untuk menampilkan SnackBar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.brown,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _simpanAkun() async {
    // Validasi form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Pastikan password memiliki minimal 6 karakter
    if (passwordController.text.trim().length < 6) {
      _showSnackBar('Password harus memiliki minimal 6 karakter');
      return;
    }

    try {
      final username = usernameController.text.trim();

      // 🔎 Cek apakah username/email sudah dipakai
      final existingUser =
          await FirebaseFirestore.instance
              .collection('users')
              .where('username', isEqualTo: username)
              .limit(1)
              .get();

      if (existingUser.docs.isNotEmpty) {
        _showSnackBar('Username/email sudah digunakan!');
        return;
      }

      // Data user baru
      final Map<String, dynamic> userData = {
        'username': username,
        'password': passwordController.text.trim(),
        'nama': namaController.text.trim(),
        'jenis_kelamin': selectedGender,
        'role': selectedRole,
        'created_at': Timestamp.now(),
      };

      // Tambahan data untuk role 'warga'
      if (selectedRole == 'warga') {
        userData['is_kepala_keluarga'] = isKepalaKeluarga;
        userData['gaptek'] = isGaptek;
        userData['tanggal_lahir'] =
            tanggalLahir != null ? Timestamp.fromDate(tanggalLahir!) : null;
      }

      // Simpan data baru
      await FirebaseFirestore.instance.collection('users').add(userData);

      _showSnackBar('Akun berhasil ditambahkan!');

      // Reset form
      usernameController.clear();
      passwordController.clear();
      namaController.clear();
      setState(() {
        selectedRole = 'pengurus';
        selectedGender = 'laki-laki';
        tanggalLahir = null;
        isKepalaKeluarga = false;
        isGaptek = false;
      });
    } catch (e) {
      _showSnackBar('Gagal menyimpan: $e');
    }
  }

  // Widget untuk menampilkan date picker
  Widget _buildDatePickerField() {
    // Sembunyikan tanggal lahir untuk pengurus dan master
    if (selectedRole == 'pengurus' || selectedRole == 'master') {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: tanggalLahir ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() => tanggalLahir = picked);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Tanggal Lahir',
              prefixIcon: const Icon(Icons.cake_outlined, color: Colors.brown),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              tanggalLahir != null
                  ? dateFormat.format(tanggalLahir!)
                  : 'Pilih Tanggal Lahir (Opsional)',
              style: TextStyle(
                fontSize: 16,
                color: tanggalLahir != null ? Colors.black87 : Colors.black54,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tambah Akun',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.brown.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Form Tambah Akun',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.brown.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.grey.shade300, height: 1.5),
                      const SizedBox(height: 24),

                      // Dropdown untuk Role, ditempatkan di paling atas
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: InputDecoration(
                          labelText: 'Role',
                          prefixIcon: const Icon(
                            Icons.shield_outlined,
                            color: Colors.brown,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'master',
                            child: Text('Master'),
                          ),
                          DropdownMenuItem(
                            value: 'pengurus',
                            child: Text('Pengurus'),
                          ),
                          DropdownMenuItem(
                            value: 'warga',
                            child: Text('Warga'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedRole = value!;
                            // Reset tanggalLahir jika role berubah ke pengurus/master
                            if (selectedRole == 'pengurus' ||
                                selectedRole == 'master') {
                              tanggalLahir = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Input teks lainnya
                      TextFormField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: Colors.brown,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Username tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Colors.brown,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: namaController,
                        decoration: InputDecoration(
                          labelText: 'Nama Lengkap',
                          prefixIcon: const Icon(
                            Icons.badge_outlined,
                            color: Colors.brown,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Jenis Kelamin',
                          prefixIcon: const Icon(
                            Icons.wc_outlined,
                            color: Colors.brown,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'laki-laki',
                            child: Text('Laki-laki'),
                          ),
                          DropdownMenuItem(
                            value: 'perempuan',
                            child: Text('Perempuan'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => selectedGender = value!);
                        },
                      ),

                      // Bidang Tanggal Lahir (hanya untuk role 'warga')
                      _buildDatePickerField(),

                      // Opsi tambahan untuk role 'warga'
                      if (selectedRole == 'warga') ...[
                        const SizedBox(height: 16),
                        _buildSwitchTile(
                          'Kepala Keluarga',
                          Icons.home_outlined,
                          isKepalaKeluarga,
                          (value) {
                            setState(() => isKepalaKeluarga = value);
                          },
                        ),
                        _buildSwitchTile(
                          'Warga Gaptek (Auto Hadir)',
                          Icons.elderly_outlined,
                          isGaptek,
                          (value) {
                            setState(() => isGaptek = value);
                          },
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Tombol Simpan
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save_alt),
                        label: const Text('Simpan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _simpanAkun,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget pembantu untuk switch
  Widget _buildSwitchTile(
    String title,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.brown),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
          Switch(value: value, activeColor: Colors.brown, onChanged: onChanged),
        ],
      ),
    );
  }
}
