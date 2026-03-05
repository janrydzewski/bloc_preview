import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth/view/auth_page.dart';
import '../counter/view/counter_page.dart';
import '../theme/cubit/theme_cubit.dart';
import '../todo/view/todo_page.dart';
import '../weather/view/weather_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('bloc_preview demo'),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () => context.read<ThemeCubit>().toggleTheme(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Open the dashboard at http://localhost:4680\nto see all BLoC state changes in real time.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _DemoCard(
            icon: Icons.pin_outlined,
            title: 'Counter (Bloc)',
            subtitle: 'Simple increment/decrement with Bloc pattern',
            color: Colors.blue,
            onTap: () => _navigate(context, const CounterPage()),
          ),
          _DemoCard(
            icon: Icons.checklist,
            title: 'Todo List (Bloc)',
            subtitle: 'CRUD operations with loading states and nested data',
            color: Colors.green,
            onTap: () => _navigate(context, const TodoPage()),
          ),
          _DemoCard(
            icon: Icons.person,
            title: 'Authentication (Cubit)',
            subtitle: 'Login flow with loading, error, and success states',
            color: Colors.orange,
            onTap: () => _navigate(context, const AuthPage()),
          ),
          _DemoCard(
            icon: Icons.cloud,
            title: 'Weather (Bloc)',
            subtitle: 'Deeply nested state with forecast data and refresh',
            color: Colors.purple,
            onTap: () => _navigate(context, const WeatherPage()),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

class _DemoCard extends StatelessWidget {
  const _DemoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
