import 'package:flutter/material.dart';
import 'package:xdama/utils/constants.dart';

class AppBarLogo extends StatelessWidget {
  final double height;
  
  const AppBarLogo({
    Key? key,
    this.height = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: height,
        ),
        const SizedBox(width: 8),
        Text(
          'xDama',
          style: TextStyle(
            fontSize: height * 0.6,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
