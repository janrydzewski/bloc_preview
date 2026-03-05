import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/weather_bloc.dart';

class WeatherPage extends StatelessWidget {
  const WeatherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WeatherBloc(),
      child: const WeatherView(),
    );
  }
}

class WeatherView extends StatelessWidget {
  const WeatherView({super.key});

  static const _cities = ['Warsaw', 'London', 'New York', 'Tokyo', 'Sydney'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weather')),
      body: BlocBuilder<WeatherBloc, WeatherState>(
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  children: _cities.map((city) {
                    return ActionChip(
                      label: Text(city),
                      onPressed: () => context
                          .read<WeatherBloc>()
                          .add(FetchWeather(city: city)),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1),
              Expanded(child: _buildContent(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, WeatherState state) {
    switch (state.status) {
      case WeatherStatus.initial:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Select a city to check the weather'),
            ],
          ),
        );
      case WeatherStatus.loading:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Fetching weather data...'),
            ],
          ),
        );
      case WeatherStatus.error:
        return Center(
          child: Text(
            state.errorMessage ?? 'An error occurred',
            style: const TextStyle(color: Colors.red),
          ),
        );
      case WeatherStatus.loaded:
        final w = state.weather!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(w.city,
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text('${w.temperature.toStringAsFixed(1)}°C',
                          style: Theme.of(context).textTheme.displaySmall),
                      Text(w.condition,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _WeatherInfo(
                              icon: Icons.thermostat,
                              label: 'Feels like',
                              value: '${w.feelsLike.toStringAsFixed(1)}°C'),
                          _WeatherInfo(
                              icon: Icons.water_drop,
                              label: 'Humidity',
                              value: '${w.humidity}%'),
                          _WeatherInfo(
                              icon: Icons.air,
                              label: 'Wind',
                              value: '${w.windSpeed.toStringAsFixed(1)} km/h'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('5-Day Forecast',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...w.forecast.map((f) => Card(
                    child: ListTile(
                      title: Text(f.day),
                      subtitle: Text(f.condition),
                      trailing: Text(
                        '${f.high.toStringAsFixed(0)}° / ${f.low.toStringAsFixed(0)}°',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  )),
              const SizedBox(height: 16),
              Center(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.read<WeatherBloc>().add(RefreshWeather()),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _WeatherInfo extends StatelessWidget {
  const _WeatherInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}
