import 'package:flutter/material.dart';

class GallerySection extends StatelessWidget {
  const GallerySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.church_outlined, size: 80, color: Colors.brown),
          SizedBox(height: 20),
          Text(
            '📸 Dokumentasi Kegiatan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Fitur ini sedang dalam pengembangan.\nMohon doanya agar segera dapat digunakan 🙏🏻',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54, height: 1.5),
          ),
          SizedBox(height: 24),
          Text(
            '“Segala sesuatu yang kamu lakukan,\nkerjakanlah dengan segenap hatimu\nseperti untuk Tuhan.”\n- Kolose 3:23',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}
