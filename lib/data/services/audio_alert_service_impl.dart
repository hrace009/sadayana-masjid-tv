import 'dart:async';

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
/// Error handling — dua lapisan:
/// 1. **try-catch** di [playAlert]: menangkap PlatformException yang dilempar
///    secara synchronous saat pemanggilan `player.play()`.
/// 2. **eventStream.onError listener**: menangkap MEDIA_ERROR_SYSTEM yang
///    dipropagasi secara asinkron melalui event channel setelah `play()` selesai.
///    Tanpa listener ini, stream error akan naik ke `PlatformDispatcher.onError`
///    di main.dart dan dicatat sebagai fatal crash di Crashlytics.
///
/// Ref: plan/feature-alarm-alert-1.md — TASK-009, CON-004, CON-006
class AudioAlertServiceImpl implements AudioAlertService {
  // Mutable agar bisa di-recreate setelah platform error.
  late AudioPlayer _player;

  // Subscription untuk eventStream error listener.
  // Wajib di-cancel saat player di-dispose atau di-recreate.
  StreamSubscription<AudioEvent>? _eventSubscription;

  /// Path audio relatif terhadap direktori `assets/`.
  ///
  /// Prefix `assets/` adalah default package dari `audioplayers`,
  /// sehingga path dimulai dari subdirektori `sound/` (CON-004).
  static const String _alertAssetPath =
      'sound/alarm_before_adhan_and_iqamah.mp3';

  AudioAlertServiceImpl() {
    _initPlayer();
  }

  /// Membuat instance [AudioPlayer] baru dan memasang error listener
  /// pada [AudioPlayer.eventStream].
  ///
  /// Listener `onError` pada stream mencegah MEDIA_ERROR_SYSTEM yang dipropagasi
  /// secara asinkron dari platform Android naik ke `PlatformDispatcher.onError`
  /// sebagai fatal crash. Error tetap dicatat di Crashlytics sebagai non-fatal.
  void _initPlayer() {
    _player = AudioPlayer();
    _eventSubscription = _player.eventStream.listen(
      null, // data events tidak diproses
      onError: (Object e, StackTrace stackTrace) {
        // Absorb asynchronous stream errors dari native MediaPlayer/ExoPlayer.
        // Tanpa listener ini, error naik ke PlatformDispatcher → fatal Crashlytics.
        FirebaseCrashlytics.instance.recordError(
          e,
          stackTrace,
          reason:
              'AudioAlertService: stream error dari AudioPlayer (MEDIA_ERROR_SYSTEM)',
          fatal: false,
        );
      },
      // cancelOnError: false agar subscription tidak otomatis dibatalkan
      // setelah satu error — player mungkin bisa recover atau di-recreate.
      cancelOnError: false,
    );
  }

  @override
  Future<void> playAlert() async {
    try {
      await _player.play(AssetSource(_alertAssetPath));
    } catch (e, stackTrace) {
      // Tangkap PlatformException synchronous dari play().
      // Laporkan ke Crashlytics sebagai non-fatal.
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
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    try {
      await _player.dispose();
    } catch (e) {
      debugPrint('AudioAlertService: dispose gagal ($e).');
    }
  }

  /// Cancel subscription lama, dispose player yang rusak, lalu buat instance baru.
  ///
  /// Dipanggil saat [playAlert] gagal dengan PlatformException,
  /// sehingga [AudioPlayer] tidak terjebak dalam error state permanen.
  Future<void> _recreatePlayer() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    try {
      await _player.dispose();
    } catch (_) {
      // Abaikan error dispose pada player yang sudah rusak.
    }
    _initPlayer();
  }
}
