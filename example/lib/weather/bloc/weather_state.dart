part of 'weather_bloc.dart';

enum WeatherStatus { initial, loading, loaded, error }

class DayForecast extends Equatable implements JsonEncodable {
  const DayForecast({
    required this.day,
    required this.high,
    required this.low,
    required this.condition,
  });

  final String day;
  final double high;
  final double low;
  final String condition;

  @override
  List<Object> get props => [day, high, low, condition];

  @override
  Map<String, dynamic> toJson() => {
        'day': day,
        'high': high,
        'low': low,
        'condition': condition,
      };
}

class Weather extends Equatable implements JsonEncodable {
  const Weather({
    required this.city,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.condition,
    required this.latitude,
    required this.longitude,
    required this.forecast,
  });

  final String city;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String condition;
  final double latitude;
  final double longitude;
  final List<DayForecast> forecast;

  @override
  List<Object> get props => [
        city, temperature, feelsLike, humidity,
        windSpeed, condition, latitude, longitude, forecast,
      ];

  @override
  Map<String, dynamic> toJson() => {
        'city': city,
        'temperature': temperature,
        'feelsLike': feelsLike,
        'humidity': humidity,
        'windSpeed': windSpeed,
        'condition': condition,
        'location': {
          'latitude': latitude,
          'longitude': longitude,
        },
        'forecast': forecast.map((f) => f.toJson()).toList(),
      };
}

class WeatherState extends Equatable implements JsonEncodable {
  const WeatherState({
    this.status = WeatherStatus.initial,
    this.weather,
    this.errorMessage,
  });

  final WeatherStatus status;
  final Weather? weather;
  final String? errorMessage;

  WeatherState copyWith({
    WeatherStatus? status,
    Weather? weather,
    String? errorMessage,
  }) {
    return WeatherState(
      status: status ?? this.status,
      weather: weather ?? this.weather,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, weather, errorMessage];

  @override
  Map<String, dynamic> toJson() => {
        'status': status.name,
        'weather': weather?.toJson(),
        'errorMessage': errorMessage,
      };
}
