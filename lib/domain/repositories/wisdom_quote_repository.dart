import 'package:miqotul_khoir_tv/domain/entities/wisdom_quote.dart';

/// Port: Abstract interface untuk akses data Kata Mutiara.
///
/// Didefinisikan di domain layer agar tidak bergantung pada
/// implementation details (JSON asset, network, dll).
///
/// Implementasi konkret: `WisdomQuoteRepositoryImpl` di
/// `data/repositories/wisdom_quote_repository_impl.dart`.
///
/// Ref: plan/feature-wisdom-quote-1.md — TASK-004
abstract class WisdomQuoteRepository {
  /// Mengambil seluruh katalog Kata Mutiara (11 item).
  ///
  /// Urutan sesuai urutan file JSON asset.
  Future<List<WisdomQuote>> getAll();

  /// Mengambil subset katalog berdasarkan daftar [ids].
  ///
  /// Item dikembalikan dengan urutan sesuai [ids].
  /// ID yang tidak ditemukan di katalog diabaikan secara diam-diam.
  /// Mengembalikan list kosong jika [ids] kosong.
  Future<List<WisdomQuote>> getByIds(List<String> ids);
}
