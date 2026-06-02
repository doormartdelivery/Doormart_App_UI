import 'package:flutter/material.dart';

class CarouselCard extends StatelessWidget {
  const CarouselCard({super.key, required this.title, this.video = false});
  final String title;
  final bool video;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [if (video) const Icon(Icons.play_circle), Text(title)],
        ),
      ),
    );
  }
}
