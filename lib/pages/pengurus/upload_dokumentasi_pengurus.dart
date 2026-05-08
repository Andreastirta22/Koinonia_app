import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadDokumentasiPengurusPage extends StatefulWidget {
  const UploadDokumentasiPengurusPage({super.key});

  @override
  State<UploadDokumentasiPengurusPage> createState() =>
      _UploadDokumentasiPengurusPageState();
}

class _UploadDokumentasiPengurusPageState
    extends State<UploadDokumentasiPengurusPage> {
  File? _imageFile;
  bool _isUploading = false;

  Future<void> _pickAndProcessImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final rawFile = File(picked.path);
    setState(() {
      _imageFile = rawFile;
    });
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    setState(() => _isUploading = true);

    final fileName = 'dokumentasi/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storageRef = FirebaseStorage.instance.ref().child(fileName);

    await storageRef.putFile(
      _imageFile!,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final downloadUrl = await storageRef.getDownloadURL();

    await FirebaseFirestore.instance.collection('dokumentasi').add({
      'url': downloadUrl,
      'created_at': Timestamp.now(),
    });

    setState(() {
      _isUploading = false;
      _imageFile = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Upload berhasil dan disimpan di Firebase!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Dokumentasi')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _pickAndProcessImage,
              icon: const Icon(Icons.photo),
              label: const Text('Pilih Gambar dari Galeri'),
            ),
            const SizedBox(height: 16),
            if (_imageFile != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _imageFile!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      color: Colors.black54,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      child: const Text(
                        'Theresia Jesus Jornet',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadImage,
              icon: const Icon(Icons.cloud_upload),
              label:
                  _isUploading
                      ? const Text('Mengupload...')
                      : const Text('Upload ke Firebase'),
            ),
          ],
        ),
      ),
    );
  }
}
