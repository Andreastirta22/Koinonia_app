import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class KelolaAkunUserPage extends StatelessWidget {
  const KelolaAkunUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kelola Akun User"), centerTitle: true),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(20),
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        children: [
          _buildRoleCard(context, "warga", Colors.blue, Icons.people),
          _buildRoleCard(
            context,
            "pengurus",
            Colors.green,
            Icons.admin_panel_settings,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context,
    String role,
    Color color,
    IconData icon,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => UserListPage(role: role)),
        );
      },
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: color,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 12),
            Text(
              role.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserListPage extends StatefulWidget {
  final String role;
  const UserListPage({super.key, required this.role});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection('users');
  String searchQuery = "";

  Future<void> _updateRole(String docId, String newRole) async {
    await usersCollection.doc(docId).update({'role': newRole});
  }

  Future<void> _deleteUser(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Konfirmasi Hapus"),
            content: const Text("Apakah Anda yakin ingin menghapus akun ini?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Hapus"),
              ),
            ],
          ),
    );
    if (confirm == true) {
      await usersCollection.doc(docId).delete();
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return "-";
    return DateFormat("d MMMM yyyy, HH:mm", "id_ID").format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Daftar ${widget.role.replaceAll("_", " ")}")),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Cari nama atau email...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onChanged:
                  (val) => setState(() => searchQuery = val.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  usersCollection
                      .where("role", isEqualTo: widget.role)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Terjadi kesalahan"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs =
                    snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final nama =
                          (data['nama'] ?? '').toString().toLowerCase();
                      final email =
                          (data['email'] ?? '').toString().toLowerCase();
                      return nama.contains(searchQuery) ||
                          email.contains(searchQuery);
                    }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      "Belum ada data ${widget.role.replaceAll("_", " ")}",
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final nama = data['nama'] ?? '-';
                      final email = data['email'] ?? '-';
                      final noTelp = data['no_telp'] ?? '-';
                      final username = data['username'] ?? '-';
                      final jenisKelamin = data['jenis_kelamin'] ?? '-';
                      final isKepalaKeluarga =
                          data['is_kepala_keluarga'] ?? false;

                      final tanggalLahir =
                          (data['tanggal_lahir'] != null)
                              ? (data['tanggal_lahir'] as Timestamp).toDate()
                              : null;
                      final createdAt =
                          (data['created_at'] != null)
                              ? (data['created_at'] as Timestamp).toDate()
                              : null;
                      final lastLogin =
                          (data['last_login'] != null)
                              ? (data['last_login'] as Timestamp).toDate()
                              : null;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Icon(
                              Icons.person,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          title: Text(
                            nama,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Email: $email"),
                              Text("Username: $username"),
                              Text("No. Telp: $noTelp"),
                              Text("Jenis Kelamin: $jenisKelamin"),
                              Text(
                                "Kepala Keluarga: ${isKepalaKeluarga ? 'Ya' : 'Tidak'}",
                              ),
                              Text(
                                "Tanggal Lahir: ${tanggalLahir != null ? DateFormat('d MMMM yyyy', 'id_ID').format(tanggalLahir) : '-'}",
                              ),
                              Text("Created At: ${formatDate(createdAt)}"),
                              Text("Last Login: ${formatDate(lastLogin)}"),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == "delete") {
                                await _deleteUser(doc.id);
                              } else if (value == "edit") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => EditUserPage(
                                          docId: doc.id,
                                          data: data,
                                        ),
                                  ),
                                );
                              } else {
                                await _updateRole(doc.id, value);
                              }
                            },
                            itemBuilder:
                                (context) => [
                                  const PopupMenuItem(
                                    value: "warga",
                                    child: Text("Jadikan Warga"),
                                  ),
                                  const PopupMenuItem(
                                    value: "pengurus",
                                    child: Text("Jadikan Pengurus"),
                                  ),
                                  const PopupMenuItem(
                                    value: "edit",
                                    child: Text("Edit User"),
                                  ),
                                  const PopupMenuItem(
                                    value: "delete",
                                    child: Text(
                                      "Hapus Akun",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// ===================
/// Edit User Page
/// ===================
class EditUserPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const EditUserPage({super.key, required this.docId, required this.data});

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  late TextEditingController namaController;
  late TextEditingController emailController;
  late TextEditingController telpController;
  late TextEditingController usernameController;
  DateTime? tanggalLahir;

  final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection('users');

  @override
  void initState() {
    super.initState();
    namaController = TextEditingController(text: widget.data['nama'] ?? '');
    emailController = TextEditingController(text: widget.data['email'] ?? '');
    telpController = TextEditingController(text: widget.data['no_telp'] ?? '');
    usernameController = TextEditingController(
      text: widget.data['username'] ?? '',
    );

    if (widget.data['tanggal_lahir'] != null) {
      tanggalLahir = (widget.data['tanggal_lahir'] as Timestamp).toDate();
    }
  }

  Future<void> _saveChanges() async {
    await usersCollection.doc(widget.docId).update({
      'nama': namaController.text.trim(),
      'email': emailController.text.trim(),
      'no_telp': telpController.text.trim(),
      'username': usernameController.text.trim(),
      'tanggal_lahir': tanggalLahir,
      'updated_at': DateTime.now(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Perubahan berhasil disimpan")),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _pickTanggalLahir() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: tanggalLahir ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale("id", "ID"),
    );
    if (picked != null) {
      setState(() {
        tanggalLahir = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String tanggalText =
        tanggalLahir != null
            ? DateFormat("d MMMM yyyy", "id_ID").format(tanggalLahir!)
            : "Belum dipilih";

    return Scaffold(
      appBar: AppBar(title: const Text("Edit User")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: namaController,
              decoration: const InputDecoration(labelText: "Nama"),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: telpController,
              decoration: const InputDecoration(labelText: "No. Telepon"),
            ),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text("Tanggal Lahir"),
              subtitle: Text(tanggalText),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _pickTanggalLahir,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save),
              label: const Text("Simpan Perubahan"),
            ),
          ],
        ),
      ),
    );
  }
}
