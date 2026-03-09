import 'package:equatable/equatable.dart';

/// Domain entity yang merepresentasikan satu item Kata Mutiara Islam.
///
/// Immutable class dengan value equality via [Equatable].
/// Equality hanya berdasarkan [id] — dua item dengan ID yang sama
/// dianggap item yang sama meski field lainnya berbeda.
///
/// Data bersumber dari `assets/data/wisdom_quotes.json` (hardcoded catalog).
///
/// Ref: plan/feature-wisdom-quote-1.md — TASK-003
class WisdomQuote extends Equatable {
  /// Identifier unik item, e.g. `"quran_001"`, `"hadith_006"`.
  final String id;

  /// Tipe konten: `"quran"` atau `"hadith"`.
  final String type;

  /// Label tampilan yang ditampilkan sebagai badge di UI,
  /// e.g. `"Ayat Al-Quran"` atau `"Hadits"`.
  final String label;

  /// Teks terjemahan Bahasa Indonesia (tanpa teks Arab).
  final String translationText;

  /// Referensi sumber, e.g. `"QS. Al-Insyirah [94]: 6"` atau
  /// `"HR. Bukhari No. 1"`.
  final String reference;

  const WisdomQuote({
    required this.id,
    required this.type,
    required this.label,
    required this.translationText,
    required this.reference,
  });

  /// Equality hanya berdasarkan [id].
  /// Memastikan perbandingan di checklist dan dropdown selalu akurat.
  @override
  List<Object?> get props => [id];
}
