import 'package:equatable/equatable.dart';

/// Domain entity yang merepresentasikan satu imam sholat berjamaah.
///
/// Immutable class dengan value equality via [Equatable].
/// Data bersumber dari tabel `imams` di SQLite.
///
/// [props] hanya menggunakan [id] sehingga dua Imam dengan id
/// yang sama dianggap equal meskipun name berbeda (mendukung
/// update-in-place di UI tanpa memicu unnecessary rebuilds).
class Imam extends Equatable {
  final int id;
  final String name;
  final bool isActive;

  const Imam({required this.id, required this.name, required this.isActive});

  @override
  List<Object?> get props => [id];
}
