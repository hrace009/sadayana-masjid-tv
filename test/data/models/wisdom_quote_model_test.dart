import 'package:flutter_test/flutter_test.dart';
import 'package:miqotul_khoir_tv/data/models/wisdom_quote_model.dart';
import 'package:miqotul_khoir_tv/domain/entities/wisdom_quote.dart';

/// Unit tests untuk [WisdomQuoteModel] — konversi fromJson/toEntity.
///
/// Ref: Plan feature-wisdom-quote-1.md TASK-063
void main() {
  // ---------------------------------------------------------------------------
  // Test Data
  // ---------------------------------------------------------------------------

  final Map<String, dynamic> quranJson = {
    'id': 'quran_001',
    'type': 'quran',
    'label': 'Ayat Al-Quran',
    'translation_text': 'Karena sesungguhnya bersama kesulitan ada kemudahan.',
    'reference': 'QS. Al-Insyirah [94]: 6',
  };

  final Map<String, dynamic> hadithJson = {
    'id': 'hadith_006',
    'type': 'hadith',
    'label': 'Hadits',
    'translation_text':
        'Orang-orang yang penyayang akan disayangi oleh Allah Yang Maha Penyayang.',
    'reference': 'HR. Tirmidzi No. 1924 & Abu Dawud No. 4941 (Hasan Shahih)',
  };

  // ---------------------------------------------------------------------------
  // WisdomQuoteModel.fromJson
  // ---------------------------------------------------------------------------

  group('WisdomQuoteModel.fromJson()', () {
    test('maps all fields dari item quran dengan benar', () {
      final model = WisdomQuoteModel.fromJson(quranJson);

      expect(model.id, equals('quran_001'));
      expect(model.type, equals('quran'));
      expect(model.label, equals('Ayat Al-Quran'));
      expect(
        model.translationText,
        equals('Karena sesungguhnya bersama kesulitan ada kemudahan.'),
      );
      expect(model.reference, equals('QS. Al-Insyirah [94]: 6'));
    });

    test('maps all fields dari item hadith dengan benar', () {
      final model = WisdomQuoteModel.fromJson(hadithJson);

      expect(model.id, equals('hadith_006'));
      expect(model.type, equals('hadith'));
      expect(model.label, equals('Hadits'));
      expect(
        model.translationText,
        equals(
          'Orang-orang yang penyayang akan disayangi oleh Allah Yang Maha Penyayang.',
        ),
      );
      expect(
        model.reference,
        equals('HR. Tirmidzi No. 1924 & Abu Dawud No. 4941 (Hasan Shahih)'),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // WisdomQuoteModel.toEntity()
  // ---------------------------------------------------------------------------

  group('WisdomQuoteModel.toEntity()', () {
    test('menghasilkan WisdomQuote dengan field yang benar (quran)', () {
      final model = WisdomQuoteModel.fromJson(quranJson);
      final entity = model.toEntity();

      expect(entity, isA<WisdomQuote>());
      expect(entity.id, equals('quran_001'));
      expect(entity.type, equals('quran'));
      expect(entity.label, equals('Ayat Al-Quran'));
      expect(
        entity.translationText,
        equals('Karena sesungguhnya bersama kesulitan ada kemudahan.'),
      );
      expect(entity.reference, equals('QS. Al-Insyirah [94]: 6'));
    });

    test('menghasilkan WisdomQuote dengan field yang benar (hadith)', () {
      final model = WisdomQuoteModel.fromJson(hadithJson);
      final entity = model.toEntity();

      expect(entity, isA<WisdomQuote>());
      expect(entity.id, equals('hadith_006'));
      expect(entity.type, equals('hadith'));
    });
  });

  // ---------------------------------------------------------------------------
  // Round-trip: fromJson → toEntity — verifikasi konsistensi
  // ---------------------------------------------------------------------------

  group('Round-trip fromJson → toEntity', () {
    test('entity equality berdasarkan id (Equatable props [id])', () {
      final entity1 = WisdomQuoteModel.fromJson(quranJson).toEntity();
      final entity2 = WisdomQuoteModel.fromJson(quranJson).toEntity();

      // Equatable hanya menggunakan id dalam props
      expect(entity1, equals(entity2));
    });

    test(
      'entity dari item berbeda tidak sama meski type dan label sama-sama hadith',
      () {
        final hadith1Json = {
          'id': 'hadith_001',
          'type': 'hadith',
          'label': 'Hadits',
          'translation_text': 'Teks A.',
          'reference': 'HR. Bukhari No. 1',
        };
        final hadith2Json = {
          'id': 'hadith_002',
          'type': 'hadith',
          'label': 'Hadits',
          'translation_text': 'Teks B.',
          'reference': 'HR. Ahmad',
        };

        final entity1 = WisdomQuoteModel.fromJson(hadith1Json).toEntity();
        final entity2 = WisdomQuoteModel.fromJson(hadith2Json).toEntity();

        expect(entity1, isNot(equals(entity2)));
      },
    );
  });
}
