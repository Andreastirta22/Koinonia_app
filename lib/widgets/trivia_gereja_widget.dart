import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TriviaGerejaWidget extends StatefulWidget {
  const TriviaGerejaWidget({super.key});

  @override
  State<TriviaGerejaWidget> createState() => _TriviaGerejaWidgetState();
}

class _TriviaGerejaWidgetState extends State<TriviaGerejaWidget> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoSlide(int itemCount) {
    _timer?.cancel(); // reset timer
    if (itemCount > 1) {
      // Timer Schedule
      _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (_pageController.hasClients) {
          _currentPage = (_currentPage + 1) % itemCount;
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('trivia')
              .orderBy('dibuat_pada', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text(
            'Belum ada trivia.',
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }

        final triviaList =
            snapshot.data!.docs
                .map((doc) => doc['isi'] as String? ?? '—')
                .toList();

        // mulai auto slide
        _startAutoSlide(triviaList.length);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trivia Gereja Katolik',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Fakta-fakta unik dan menarik seputar Gereja Katolik.',
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 100,
              child: PageView.builder(
                controller: _pageController,
                itemCount: triviaList.length,
                itemBuilder: (context, index) {
                  final isi = triviaList[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.brown.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.brown.shade100),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: Colors.brown,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isi,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
