// ignore_for_file: depend_on_referenced_packages

import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:bloc_preview/bloc_preview.dart';
import 'package:equatable/equatable.dart';

part 'weather_event.dart';
part 'weather_state.dart';

class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  WeatherBloc() : super(const WeatherState()) {
    on<FetchWeather>(_onFetchWeather);
    on<RefreshWeather>(_onRefreshWeather);
  }

  final _random = Random();

  static const _cities = {
    'Warsaw': _CityData(52.23, 21.01),
    'London': _CityData(51.51, -0.13),
    'New York': _CityData(40.71, -74.01),
    'Tokyo': _CityData(35.68, 139.69),
    'Sydney': _CityData(-33.87, 151.21),
  };

  Future<void> _onFetchWeather(
    FetchWeather event,
    Emitter<WeatherState> emit,
  ) async {
    emit(state.copyWith(status: WeatherStatus.loading));

    await Future.delayed(const Duration(seconds: 2));

    final cityData = _cities[event.city];
    if (cityData == null) {
      emit(state.copyWith(
        status: WeatherStatus.error,
        errorMessage: 'City "${event.city}" not found',
      ));
      return;
    }

    final weather = _generateWeather(event.city, cityData);
    emit(state.copyWith(status: WeatherStatus.loaded, weather: weather));
  }

  Future<void> _onRefreshWeather(
    RefreshWeather event,
    Emitter<WeatherState> emit,
  ) async {
    if (state.weather == null) return;

    emit(state.copyWith(status: WeatherStatus.loading));
    await Future.delayed(const Duration(seconds: 1));

    final city = state.weather!.city;
    final cityData = _cities[city]!;
    final weather = _generateWeather(city, cityData);
    emit(state.copyWith(status: WeatherStatus.loaded, weather: weather));
  }

  Weather _generateWeather(String city, _CityData data) {
    final conditions = ['Sunny', 'Cloudy', 'Rainy', 'Partly Cloudy', 'Stormy'];
    return Weather(
      city: city,
      temperature: 15 + _random.nextInt(20).toDouble(),
      feelsLike: 13 + _random.nextInt(22).toDouble(),
      humidity: 40 + _random.nextInt(50),
      windSpeed: 5 + _random.nextInt(30).toDouble(),
      condition: conditions[_random.nextInt(conditions.length)],
      latitude: data.lat,
      longitude: data.lon,
      forecast: List.generate(5, (i) {
        return DayForecast(
          day: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][(DateTime.now().weekday - 1 + i) % 7],
          high: 18 + _random.nextInt(15).toDouble(),
          low: 5 + _random.nextInt(12).toDouble(),
          condition: conditions[_random.nextInt(conditions.length)],
        );
      }),
    );
  }
}

class _CityData {
  const _CityData(this.lat, this.lon);
  final double lat;
  final double lon;
}
