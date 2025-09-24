import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SansText extends StatelessWidget {
  final String text;
  final double size;
  // Make color and weight optional parameters for more flexibility
  final Color color;
  final FontWeight weight;

  const SansText(
    this.text,
    this.size, {
    super.key,
    this.color = Colors.white, // Default to white if not provided
    this.weight = FontWeight.w300, // Default to light weight
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign:
          TextAlign.center, // Consider making this an optional parameter too!
      style: GoogleFonts.openSans(
        fontSize: size,
        fontWeight: weight,

        color: color,
      ),
    );
  }
}
