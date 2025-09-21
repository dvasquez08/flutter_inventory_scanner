import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SansText extends StatelessWidget {
  final text;
  final size;
  const SansText(this.text, this.size, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.openSans(
        fontSize: size,
        fontWeight: FontWeight.w300,
        color: Colors.white,
      ),
    );
  }
}
