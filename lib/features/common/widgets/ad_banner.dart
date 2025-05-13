import 'package:flutter/material.dart';

class AdBanner extends StatelessWidget {
  const AdBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: Colors.yellow[100],
      alignment: Alignment.center,
      child: const Text('구글광고', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
