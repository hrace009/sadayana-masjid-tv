import 'package:audioplayers/audioplayers.dart';
import 'package:miqotul_khoir_tv/domain/services/audio_alert_service.dart';

/// Implementasi konkret [AudioAlertService] menggunakan package `audioplayers`.
///
/// Memutar file audio alarm dari bundled asset tanpa memerlukan koneksi
/// internet atau permission storage eksternal (SEC-002).
///
/// Instance ini dikelola oleh `DisplayStateCubit` dan wajib di-[dispose]
/// saat cubit di-close untuk mencegah memory leak (CON-006).
///
/// Ref: plan/feature-alarm-alert-1.md — TASK-009, CON-004, CON-006
class AudioAlertServiceImpl implements AudioAlertService {
  final AudioPlayer _player = AudioPlayer();

  /// Path audio relatif terhadap direktori `assets/`.
  ///
  /// Prefix `assets/` adalah default package dari `audioplayers`,
  /// sehingga path dimulai dari subdirektori `sound/` (CON-004).
  static const String _alertAssetPath =
      'sound/alarm_before_adhan_and_iqamah.mp3';

  @override
  Future<void> playAlert() async {
    await _player.play(AssetSource(_alertAssetPath));
  }

  @override
  Future<void> stopAlert() async {
    await _player.stop();
  }

  @override
  Future<void> dispose() async {
    await _player.dispose();
  }
}
