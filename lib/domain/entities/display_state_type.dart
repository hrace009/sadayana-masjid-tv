/// Jenis status tampilan layar berdasarkan waktu sholat.
enum DisplayStateType {
  /// Menunggu waktu sholat berikutnya. Tampilan default.
  standby,

  /// Menjelang waktu sholat (countdown adzan).
  preAdzan,

  /// Sedang berlangsung Adzan.
  adzan,

  /// Menunggu Iqomah (countdown sholat).
  iqomah,

  /// Sedang berlangsung Sholat (layar gelap/silent).
  sholat,
}
