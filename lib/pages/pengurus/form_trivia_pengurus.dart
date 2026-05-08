import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TriviaPengurusPage extends StatefulWidget {
  const TriviaPengurusPage({super.key});

  @override
  State<TriviaPengurusPage> createState() => _TriviaPengurusPageState();
}

class _TriviaPengurusPageState extends State<TriviaPengurusPage> {
  final TextEditingController _triviaController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitTrivia({String? docId}) async {
    final isi = _triviaController.text.trim();
    if (isi.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final collection = FirebaseFirestore.instance.collection('trivia');
      if (docId == null) {
        await collection.add({
          'isi': isi,
          'dibuat_pada': Timestamp.now(),
          'dibuat_oleh': 'pengurus',
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trivia berhasil ditambahkan!')),
        );
      } else {
        await collection.doc(docId).update({'isi': isi});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trivia berhasil diperbarui!')),
        );
      }
      _triviaController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    }

    setState(() => _isSubmitting = false);
  }

  Future<void> _deleteTrivia(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus Trivia'),
            content: const Text(
              'Apakah anda yakin ingin menghapus trivia ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('trivia').doc(docId).delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Trivia berhasil dihapus!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    }
  }

  void _editTrivia(String docId, String isi) {
    _triviaController.text = isi;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _triviaController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed:
                      _isSubmitting ? null : () => _submitTrivia(docId: docId),
                  icon: const Icon(Icons.save),
                  label: Text(_isSubmitting ? 'Menyimpan...' : 'Simpan'),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final triviaCollection = FirebaseFirestore.instance
        .collection('trivia')
        .orderBy('dibuat_pada', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Trivia'),
        backgroundColor: Colors.deepPurple, // tema utama
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _triviaController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Masukkan trivia baru...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : () => _submitTrivia(),
                        icon:
                            _isSubmitting
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.send),
                        label: Text(_isSubmitting ? 'Mengirim...' : 'Kirim'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors
                                  .amber[700], // warna sekunder yang lebih hangat
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: triviaCollection.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty)
                    return const Center(child: Text('Belum ada trivia.'));
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final isi = doc['isi'] ?? '';
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(isi),
                          subtitle: Text(
                            (doc['dibuat_pada'] as Timestamp)
                                .toDate()
                                .toString(),
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _editTrivia(doc.id, isi),
                                icon: Icon(
                                  Icons.edit,
                                  color: Colors.orange[600],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _deleteTrivia(doc.id),
                                icon: Icon(
                                  Icons.delete,
                                  color: Colors.red[400],
                                ),
                              ),
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
      ),
    );
  }
}
