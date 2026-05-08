import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KelolaRolePage extends StatefulWidget {
  const KelolaRolePage({Key? key}) : super(key: key);

  @override
  _KelolaRolePageState createState() => _KelolaRolePageState();
}

class _KelolaRolePageState extends State<KelolaRolePage> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Role & Permission'),
        backgroundColor: Colors.brown,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cari nama atau username...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users =
                    snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final nama =
                          (data['nama'] ?? '').toString().toLowerCase();
                      final username =
                          (data['username'] ?? '').toString().toLowerCase();
                      return nama.contains(searchQuery) ||
                          username.contains(searchQuery);
                    }).toList();

                if (users.isEmpty) {
                  return const Center(child: Text('Tidak ada user ditemukan.'));
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userDoc = users[index];
                    final user =
                        userDoc.data() as Map<String, dynamic>; // ambil data
                    final currentRole = user['role'] ?? 'warga';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.person, color: Colors.brown),
                        title: Text(user['nama'] ?? 'Tanpa Nama'),
                        subtitle: Text(user['username'] ?? '-'),
                        trailing: StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('roles')
                                  .snapshots(),
                          builder: (context, roleSnapshot) {
                            if (!roleSnapshot.hasData) {
                              return const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(),
                              );
                            }

                            final roleDocs = roleSnapshot.data!.docs;
                            if (roleDocs.isEmpty) {
                              return const Text("No roles");
                            }

                            // Pastikan value cocok dengan daftar roles
                            String selectedValue =
                                roleDocs.any(
                                      (doc) =>
                                          (doc.data()
                                              as Map<String, dynamic>)['key'] ==
                                          currentRole,
                                    )
                                    ? currentRole
                                    : (roleDocs.first.data()
                                        as Map<String, dynamic>)['key'];

                            return DropdownButton<String>(
                              value: selectedValue,
                              items:
                                  roleDocs.map((doc) {
                                    final roleData =
                                        doc.data() as Map<String, dynamic>;
                                    return DropdownMenuItem<String>(
                                      value: roleData['key'],
                                      child: Text(roleData['name']),
                                    );
                                  }).toList(),
                              onChanged: (newRole) {
                                if (newRole != null) {
                                  _updateUserRole(userDoc.id, newRole);
                                }
                              },
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'role': newRole,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Role berhasil diubah menjadi $newRole')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengubah role: $e')));
    }
  }
}
