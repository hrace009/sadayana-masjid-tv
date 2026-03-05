import 'package:equatable/equatable.dart';

/// Domain entity yang merepresentasikan satu kota/kabupaten.
///
/// Immutable class dengan value equality via [Equatable].
/// Data diambil dari table `cities` (lookup untuk Setup Wizard).
///
/// Ref: SPEC-01 §4.2
class City extends Equatable {
  final int id;
  final String provinceName;
  final String cityName;
  final double latitude;
  final double longitude;

  /// Ketinggian tempat di atas permukaan laut (meter).
  /// Digunakan untuk koreksi waktu Maghrib/Syuruq.
  final int elevation;

  const City({
    required this.id,
    required this.provinceName,
    required this.cityName,
    required this.latitude,
    required this.longitude,
    this.elevation = 0,
  });

  @override
  List<Object?> get props => [
    id,
    provinceName,
    cityName,
    latitude,
    longitude,
    elevation,
  ];
}
