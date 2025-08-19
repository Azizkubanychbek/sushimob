import 'package:flutter/material.dart';

class ProductImageCarouselWidget extends StatelessWidget {
  const ProductImageCarouselWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.grey,
      ),
      child: const Stack(
        children: [
          Center(
            child: Icon(
              Icons.image,
              size: 80,
              color: Colors.white,
            ),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(radius: 4, backgroundColor: Colors.white),
                SizedBox(width: 8),
                CircleAvatar(radius: 4, backgroundColor: Colors.white54),
                SizedBox(width: 8),
                CircleAvatar(radius: 4, backgroundColor: Colors.white54),
              ],
            ),
          ),
        ],
      ),
    );
  }
}