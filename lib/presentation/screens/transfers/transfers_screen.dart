import 'package:flutter/material.dart';

class TransfersScreen extends StatelessWidget {
  const TransfersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transferencias')),
      body: const Center(
        child: Text('Pantalla de Transferencias (Próximamente)'),
      ),
    );
  }
}