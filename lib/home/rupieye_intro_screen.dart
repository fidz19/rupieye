import 'package:flutter/material.dart';

class RupieyeIntroScreen extends StatelessWidget {
  const RupieyeIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF343889),
      body: Center(
        child: Container(
          width: 168,
          height: 168,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3B111441),
                blurRadius: 28,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/logo_rupi_eye.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) {
              return const FittedBox(
                fit: BoxFit.contain,
                child: Text(
                  'RUPI-EYE',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF122C69),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
