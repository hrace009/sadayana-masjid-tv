import 'package:miqotul_khoir_tv/domain/entities/wisdom_quote.dart';

/// Data model untuk mengkonversi antara JSON map dan [WisdomQuote] entity.
///
/// Digunakan oleh [WisdomQuoteLocalDataSource] saat mem-parse
/// `assets/data/wisdom_quotes.json`.
///
/// Mapping conventions:
/// - JSON key names: `snake_case`
/// - Dart field names: `camelCase`
class WisdomQuoteModel {
  final String id;
  final String type;
  final String label;
  final String translationText;
  final String reference;

  const WisdomQuoteModel({
    required this.id,
    required this.type,
    required this.label,
    required this.translationText,
    required this.reference,
  });

  /// Membuat [WisdomQuoteModel] dari raw JSON map.
  factory WisdomQuoteModel.fromJson(Map<String, dynamic> json) {
    return WisdomQuoteModel(
      id: json['id'] as String,
      type: json['type'] as String,
      label: json['label'] as String,
      translationText: json['translation_text'] as String,
      reference: json['reference'] as String,
    );
  }

  /// Mengkonversi model ke [WisdomQuote] domain entity.
  WisdomQuote toEntity() {
    return WisdomQuote(
      id: id,
      type: type,
      label: label,
      translationText: translationText,
      reference: reference,
    );
  }
}
