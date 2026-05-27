class AppConfig {
  /// URL Base untuk Backend Laravel Anda.
  /// 
  /// UBAH nilai ini saat aplikasi dideploy ke lingkungan production 
  /// (contoh: 'https://admin.jabatkopi.com').
  /// 
  /// Nilai default kosong ('') akan otomatis melakukan fallback ke localhost
  /// (127.0.0.1:8000 / 10.0.2.2:8000) untuk mendukung local development.
  static const String laravelBaseUrl = 'https://jabatkopi.my.id';
}
