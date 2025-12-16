import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TrailGuide Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => context.push('/lobby'), // ไปหน้า Host (เต็มจอ)
              child: const Text('Host Team'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.push('/scan'), // ไปหน้า Join (เต็มจอ)
              child: const Text('Join Team'),
            ),
          ],
        ),
      ),
    );
  }
}