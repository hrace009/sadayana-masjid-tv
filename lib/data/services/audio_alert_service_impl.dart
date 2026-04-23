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

  // Serialisasi command player untuk mencegah race condition play/stop/dispose.
  Future<void> _operationQueue = Future<void>.value();

  bool _isDisposed = false;

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
    if (_isDisposed) {
      return;
    }

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
    await _enqueueOperation(() async {
      if (_isDisposed) {
        return;
      }

      try {
        await _playOnce();
      } catch (e, stackTrace) {
        await _recordPlayError(
          e,
          stackTrace,
          isRetryAttempt: false,
          reason:
              'AudioAlertService: playAlert gagal — MediaPlayer platform error',
        );

        // Timeout 30 detik adalah known pattern di audioplayers Android.
        // Lakukan recreate + retry sekali untuk recovery transient failure.
        if (_isTimeoutPreparationError(e)) {
          await _recreatePlayer();
          try {
            await _playOnce();
            return;
          } catch (retryError, retryStackTrace) {
            await _recordPlayError(
              retryError,
              retryStackTrace,
              isRetryAttempt: true,
              reason:
                  'AudioAlertService: retry playAlert gagal setelah timeout preparation',
            );
          }
        } else {
          // Untuk non-timeout error tetap recreate agar cycle berikutnya sehat.
          await _recreatePlayer();
        }
      }
    });
  }

  @override
  Future<void> stopAlert() async {
    await _enqueueOperation(() async {
      if (_isDisposed) {
        return;
      }

      try {
        await _player.stop();
      } catch (e) {
        debugPrint('AudioAlertService: stopAlert gagal ($e).');
      }
    });
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;

    await _enqueueOperation(() async {
      await _eventSubscription?.cancel();
      _eventSubscription = null;
      try {
        await _player.dispose();
      } catch (e) {
        debugPrint('AudioAlertService: dispose gagal ($e).');
      }
    });
  }

  Future<void> _playOnce() {
    return _player.play(AssetSource(_alertAssetPath));
  }

  bool _isTimeoutPreparationError(Object error) {
    return error is TimeoutException ||
        error.toString().contains('TimeoutException after 0:00:30.000000');
  }

  Future<void> _recordPlayError(
    Object error,
    StackTrace stackTrace, {
    required bool isRetryAttempt,
    required String reason,
  }) async {
    FirebaseCrashlytics.instance.setCustomKey(
      'audio_alert_error_type',
      error.runtimeType.toString(),
    );
    FirebaseCrashlytics.instance.setCustomKey(
      'audio_alert_retry',
      isRetryAttempt,
    );
    FirebaseCrashlytics.instance.setCustomKey(
      'audio_alert_timeout_signature',
      _isTimeoutPreparationError(error),
    );

    await FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: false,
    );
  }

  Future<void> _enqueueOperation(Future<void> Function() operation) {
    _operationQueue = _operationQueue.then((_) => operation()).catchError((
      Object _,
      StackTrace _,
    ) {
      // Jaga queue tetap hidup meskipun ada operasi yang gagal.
    });
    return _operationQueue;
  }

  /// Cancel subscription lama, dispose player yang rusak, lalu buat instance baru.
  ///
  /// Dipanggil saat [playAlert] gagal dengan PlatformException,
  /// sehingga [AudioPlayer] tidak terjebak dalam error state permanen.
  Future<void> _recreatePlayer() async {
    if (_isDisposed) {
      return;
    }

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
