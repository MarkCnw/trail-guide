import 'package:flutter/material.dart';

class LobbyPage extends StatelessWidget {
  const LobbyPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lobby (Waiting Room)')),
      body: const Center(child: Text('QR Code & Member List Here')),
    );
  }
}