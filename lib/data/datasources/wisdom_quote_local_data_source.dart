import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:miqotul_khoir_tv/data/models/wisdom_quote_model.dart';
import 'package:miqotul_khoir_tv/domain/entities/wisdom_quote.dart';

/// Data source untuk memuat katalog Kata Mutiara dari JSON asset bundled.
///
/// Tidak bergantung pada database — data bersumber dari
/// `assets/data/wisdom_quotes.json` via [rootBundle].
class WisdomQuoteLocalDataSource {
  const WisdomQuoteLocalDataSource();

  static const _assetPath = 'assets/data/wisdom_quotes.json';

  /// Memuat seluruh 11 item katalog dari asset JSON.
  Future<List<WisdomQuote>> getAll() async {
    final jsonString = await rootBundle.loadString(_assetPath);
    final jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList
        .map(
          (e) =>
              WisdomQuoteModel.fromJson(e as Map<String, dynamic>).toEntity(),
        )
        .toList();
  }

  /// Mengembalikan subset item berdasarkan [ids].
  ///
  /// - ID yang tidak ditemukan di katalog diabaikan secara diam-diam.
  /// - [ids] kosong mengembalikan list kosong tanpa memuat asset.
  Future<List<WisdomQuote>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final all = await getAll();
    final idSet = ids.toSet();
    return all.where((q) => idSet.contains(q.id)).toList();
  }
}
