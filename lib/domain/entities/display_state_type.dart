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

  /// Menampilkan Slideshow Pengumuman Masjid secara periodik.
  slideshowAnnouncement,

  /// Menampilkan Jadwal Imam Sholat Berjamaah hari ini secara periodik.
  imamSchedule,

  /// Menampilkan Kata Mutiara Islam secara periodik.
  wisdomQuote,

  /// Layar hemat daya tengah malam — hitam mutlak dengan jam dan info Subuh.
  midnightStandby,
}
