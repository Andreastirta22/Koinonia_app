import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AuditLogPage extends StatefulWidget {
  const AuditLogPage({Key? key}) : super(key: key);

  @override
  _AuditLogPageState createState() => _AuditLogPageState();
}

class _AuditLogPageState extends State<AuditLogPage> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Log Pengguna'),
        backgroundColor: Colors.brown,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cari username atau aksi...',
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
                  FirebaseFirestore.instance
                      .collection('audit_logs')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Belum ada aktivitas.'));
                }

                final logs =
                    snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final username = (data['username'] ?? '').toLowerCase();
                      final action = (data['action'] ?? '').toLowerCase();
                      return username.contains(searchQuery) ||
                          action.contains(searchQuery);
                    }).toList();

                if (logs.isEmpty) {
                  return const Center(child: Text('Tidak ada hasil.'));
                }

                return ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index].data() as Map<String, dynamic>;
                    final username = log['username'] ?? 'Unknown';
                    final action = log['action'] ?? 'Tidak diketahui';
                    final details = log['details'] ?? '';
                    final timestamp = log['timestamp'] as Timestamp?;
                    final formattedDate =
                        timestamp != null
                            ? DateFormat(
                              'dd MMM yyyy HH:mm',
                            ).format(timestamp.toDate())
                            : '-';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.history, color: Colors.brown),
                        title: Text('$username - $action'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Waktu: $formattedDate'),
                            if (details.isNotEmpty) Text('Detail: $details'),
                          ],
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
}
