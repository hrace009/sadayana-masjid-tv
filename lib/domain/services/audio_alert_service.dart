/// Abstraksi untuk layanan pemutaran suara alarm tanda waktu.
///
/// Interface ini didefinisikan di domain layer sesuai dengan
/// Dependency Inversion Principle (DIP). Implementasi konkret
/// berada di data layer (`lib/data/services/`).
///
/// Ref: plan/feature-alarm-alert-1.md — TASK-003, CON-002
abstract class AudioAlertService {
  /// Memainkan suara alarm.
  ///
  /// Dipanggil saat threshold waktu sebelum Adzan atau Iqomah tercapai.
  Future<void> playAlert();

  /// Menghentikan suara alarm yang sedang berjalan.
  ///
  /// Dipanggil saat state bertransisi keluar dari [PreAdzanState]
  /// atau [IqomahState] untuk mencegah audio overlap dengan state berikutnya.
  Future<void> stopAlert();

  /// Melepaskan resource audio player.
  ///
  /// Wajib dipanggil saat [DisplayStateCubit] di-close untuk
  /// mencegah memory leak.
  Future<void> dispose();
}
