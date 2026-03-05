part of 'theme_cubit.dart';

class ThemeState extends Equatable implements JsonEncodable {
  const ThemeState({
    this.themeMode = ThemeMode.light,
    this.seedColor = Colors.deepPurple,
  });

  final ThemeMode themeMode;
  final Color seedColor;

  @override
  List<Object> get props => [themeMode, seedColor];

  @override
  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'seedColor': '#${seedColor.toARGB32().toRadixString(16).padLeft(8, '0')}',
      };
}
