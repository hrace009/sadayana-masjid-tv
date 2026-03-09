import 'package:miqotul_khoir_tv/data/datasources/wisdom_quote_local_data_source.dart';
import 'package:miqotul_khoir_tv/domain/entities/wisdom_quote.dart';
import 'package:miqotul_khoir_tv/domain/repositories/wisdom_quote_repository.dart';

/// Implementasi konkret [WisdomQuoteRepository].
///
/// Mendelegasikan seluruh operasi ke [WisdomQuoteLocalDataSource]
/// yang membaca data dari JSON asset bundled.
class WisdomQuoteRepositoryImpl implements WisdomQuoteRepository {
  final WisdomQuoteLocalDataSource _dataSource;

  const WisdomQuoteRepositoryImpl(this._dataSource);

  @override
  Future<List<WisdomQuote>> getAll() => _dataSource.getAll();

  @override
  Future<List<WisdomQuote>> getByIds(List<String> ids) =>
      _dataSource.getByIds(ids);
}
