import 'package:flutter/material.dart';

class AbsensiPage extends StatefulWidget {
  const AbsensiPage({super.key});

  @override
  State<AbsensiPage> createState() => _AbsensiPageState();
}

class _AbsensiPageState extends State<AbsensiPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && args['jadwalId'] != null) {
      Future.microtask(() {
        if (!mounted) return; // ✅ Tambahan penting
        Navigator.pushReplacementNamed(
          context,
          '/qr-scan',
          arguments: {'jadwalId': args['jadwalId']},
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
