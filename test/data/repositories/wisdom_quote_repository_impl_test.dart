import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:miqotul_khoir_tv/data/datasources/wisdom_quote_local_data_source.dart';
import 'package:miqotul_khoir_tv/data/repositories/wisdom_quote_repository_impl.dart';
import 'package:miqotul_khoir_tv/domain/entities/wisdom_quote.dart';

class MockWisdomQuoteLocalDataSource extends Mock
    implements WisdomQuoteLocalDataSource {}

/// Unit tests untuk [WisdomQuoteRepositoryImpl].
///
/// Menggunakan mock [WisdomQuoteLocalDataSource] sehingga tidak
/// membutuhkan rootBundle / asset loading saat test berjalan.
///
/// Ref: Plan feature-wisdom-quote-1.md TASK-064
void main() {
  late MockWisdomQuoteLocalDataSource mockDataSource;
  late WisdomQuoteRepositoryImpl repository;

  // 11 item lengkap sesuai spec
  final tAllQuotes = [
    const WisdomQuote(
      id: 'quran_001',
      type: 'quran',
      label: 'Ayat Al-Quran',
      translationText: 'Karena sesungguhnya bersama kesulitan ada kemudahan.',
      reference: 'QS. Al-Insyirah [94]: 6',
    ),
    const WisdomQuote(
      id: 'quran_002',
      type: 'quran',
      label: 'Ayat Al-Quran',
      translationText:
          'Allah tidak membebani seseorang melainkan sesuai dengan kesanggupannya.',
      reference: 'QS. Al-Baqarah [2]: 286',
    ),
    const WisdomQuote(
      id: 'quran_003',
      type: 'quran',
      label: 'Ayat Al-Quran',
      translationText: 'Janganlah kamu berputus asa dari rahmat Allah.',
      reference: 'QS. Az-Zumar [39]: 53',
    ),
    const WisdomQuote(
      id: 'quran_004',
      type: 'quran',
      label: 'Ayat Al-Quran',
      translationText:
          'Mintalah pertolongan kepada Allah dengan sabar dan sholat.',
      reference: 'QS. Al-Baqarah [2]: 153',
    ),
    const WisdomQuote(
      id: 'quran_005',
      type: 'quran',
      label: 'Ayat Al-Quran',
      translationText: 'Ingatlah kepada-Ku, maka Aku pun akan ingat kepadamu.',
      reference: 'QS. Al-Baqarah [2]: 152',
    ),
    const WisdomQuote(
      id: 'hadith_001',
      type: 'hadith',
      label: 'Hadits',
      translationText: 'Sesungguhnya setiap amal itu tergantung pada niatnya.',
      reference: 'HR. Bukhari No. 1',
    ),
    const WisdomQuote(
      id: 'hadith_002',
      type: 'hadith',
      label: 'Hadits',
      translationText:
          'Sebaik-baik manusia adalah yang paling bermanfaat bagi manusia lainnya.',
      reference: 'HR. Ahmad (Hasan)',
    ),
    const WisdomQuote(
      id: 'hadith_003',
      type: 'hadith',
      label: 'Hadits',
      translationText: 'Menuntut ilmu adalah kewajiban bagi setiap Muslim.',
      reference: 'HR. Ibnu Majah No. 224 (Hasan)',
    ),
    const WisdomQuote(
      id: 'hadith_004',
      type: 'hadith',
      label: 'Hadits',
      translationText: 'Berbuat baiklah kepada kedua orang tuamu.',
      reference: 'HR. Tirmidzi No. 1956 (Shahih)',
    ),
    const WisdomQuote(
      id: 'hadith_005',
      type: 'hadith',
      label: 'Hadits',
      translationText:
          'Tidak termasuk golongan kami orang yang tidak menyayangi yang lebih muda.',
      reference: 'HR. Bukhari No. 6018',
    ),
    const WisdomQuote(
      id: 'hadith_006',
      type: 'hadith',
      label: 'Hadits',
      translationText:
          'Orang-orang yang penyayang akan disayangi oleh Allah Yang Maha Penyayang.',
      reference: 'HR. Tirmidzi No. 1924 & Abu Dawud No. 4941 (Hasan Shahih)',
    ),
  ];

  setUp(() {
    mockDataSource = MockWisdomQuoteLocalDataSource();
    repository = WisdomQuoteRepositoryImpl(mockDataSource);
  });

  // ---------------------------------------------------------------------------
  // getAll()
  // ---------------------------------------------------------------------------

  group('getAll()', () {
    test('mengembalikan tepat 11 item dari data source', () async {
      when(() => mockDataSource.getAll()).thenAnswer((_) async => tAllQuotes);

      final result = await repository.getAll();

      expect(result, hasLength(11));
      expect(result, equals(tAllQuotes));
      verify(() => mockDataSource.getAll()).called(1);
    });

    test('mendelegasikan panggilan ke data source', () async {
      when(() => mockDataSource.getAll()).thenAnswer((_) async => tAllQuotes);

      await repository.getAll();

      verify(() => mockDataSource.getAll()).called(1);
      verifyNever(() => mockDataSource.getByIds(any()));
    });
  });

  // ---------------------------------------------------------------------------
  // getByIds()
  // ---------------------------------------------------------------------------

  group('getByIds()', () {
    test('memfilter item dengan benar berdasarkan ids', () async {
      final filteredQuotes = [
        tAllQuotes[0],
        tAllQuotes[5],
      ]; // quran_001, hadith_001
      when(
        () => mockDataSource.getByIds(['quran_001', 'hadith_001']),
      ).thenAnswer((_) async => filteredQuotes);

      final result = await repository.getByIds(['quran_001', 'hadith_001']);

      expect(result, hasLength(2));
      expect(result[0].id, equals('quran_001'));
      expect(result[1].id, equals('hadith_001'));
    });

    test(
      'getByIds([]) mengembalikan list kosong tanpa memanggil getAll',
      () async {
        when(() => mockDataSource.getByIds([])).thenAnswer((_) async => []);

        final result = await repository.getByIds([]);

        expect(result, isEmpty);
        verify(() => mockDataSource.getByIds([])).called(1);
      },
    );

    test(
      'id yang tidak ditemukan diabaikan (tidak menyebabkan error)',
      () async {
        when(
          () => mockDataSource.getByIds(['quran_999']),
        ).thenAnswer((_) async => []);

        final result = await repository.getByIds(['quran_999']);

        expect(result, isEmpty);
      },
    );

    test(
      'mendelegasikan panggilan ke data source dengan ids yang tepat',
      () async {
        const ids = ['quran_001', 'hadith_003', 'hadith_006'];
        when(() => mockDataSource.getByIds(ids)).thenAnswer(
          (_) async => [tAllQuotes[0], tAllQuotes[7], tAllQuotes[10]],
        );

        final result = await repository.getByIds(ids);

        expect(result, hasLength(3));
        verify(() => mockDataSource.getByIds(ids)).called(1);
      },
    );
  });
}
