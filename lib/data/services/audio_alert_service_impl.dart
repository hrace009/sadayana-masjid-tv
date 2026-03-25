import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:miqotul_khoir_tv/domain/services/audio_alert_service.dart';

/// Implementasi konkret [AudioAlertService] menggunakan package `audioplayers`.
///
/// Memutar file audio alarm dari bundled asset tanpa memerlukan koneksi
/// internet atau permission storage eksternal (SEC-002).
///
/// Instance ini dikelola oleh `DisplayStateCubit` dan wajib di-[dispose]
/// saat cubit di-close untuk mencegah memory leak (CON-006).
///
/// Error handling:
/// - Semua platform exception dari MediaPlayer ditangkap secara lokal
///   sehingga tidak menjadi unhandled Future error / fatal crash di Crashlytics.
/// - Jika [playAlert] gagal, [AudioPlayer] di-recreate agar siklus alarm
///   berikutnya tetap bisa berjalan (self-healing).
///
/// Ref: plan/feature-alarm-alert-1.md — TASK-009, CON-004, CON-006
class AudioAlertServiceImpl implements AudioAlertService {
  // Mutable agar bisa di-recreate setelah platform error.
  AudioPlayer _player = AudioPlayer();

  /// Path audio relatif terhadap direktori `assets/`.
  ///
  /// Prefix `assets/` adalah default package dari `audioplayers`,
  /// sehingga path dimulai dari subdirektori `sound/` (CON-004).
  static const String _alertAssetPath =
      'sound/alarm_before_adhan_and_iqamah.mp3';

  @override
  Future<void> playAlert() async {
    try {
      await _player.play(AssetSource(_alertAssetPath));
    } catch (e, stackTrace) {
      // Laporkan ke Crashlytics sebagai non-fatal agar DKM bisa memantau
      // frekuensi kegagalan alarm di dashboard Firebase (bukan fatal crash).
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason:
            'AudioAlertService: playAlert gagal — MediaPlayer platform error',
        fatal: false,
      );
      // Player masuk error state setelah PlatformException — recreate untuk recovery
      // agar siklus alarm berikutnya (waktu sholat berikutnya) tetap bisa berbunyi.
      await _recreatePlayer();
    }
  }

  @override
  Future<void> stopAlert() async {
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('AudioAlertService: stopAlert gagal ($e).');
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (e) {
      debugPrint('AudioAlertService: dispose gagal ($e).');
    }
  }

  /// Dispose player yang rusak lalu buat instance baru.
  ///
  /// Dipanggil saat [playAlert] gagal dengan PlatformException,
  /// sehingga [AudioPlayer] tidak terjebak dalam error state permanen.
  Future<void> _recreatePlayer() async {
    try {
      await _player.dispose();
    } catch (_) {
      // Abaikan error dispose pada player yang sudah rusak.
    }
    _player = AudioPlayer();
  }
}
