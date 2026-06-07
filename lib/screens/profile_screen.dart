import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user?.nombre ?? '', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(user?.email ?? ''),
            const SizedBox(height: 8),
            Text('Rol: ${user?.role ?? ""}'),
            const SizedBox(height: 8),
            Text('Edad: ${user?.edad ?? ""}'),
          ],
        ),
      ),
    );
  }
}
