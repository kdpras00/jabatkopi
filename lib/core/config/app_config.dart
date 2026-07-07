class AppConfig {
  // 1. GUNA UNTUK PRODUCTION (ONLINE)
  static const String laravelBaseUrl = 'https://jabatkopi.my.id';
  
  // 2. GUNA UNTUK EMULATOR / WEB LOCAL
  // static const String laravelBaseUrl = 'http://127.0.0.1:8000';

  // 3. GUNA UNTUK HP FISIK (Hubungkan HP & Laptop ke Wi-Fi yang sama, isi dengan IP Lokal Laptop Anda)
  // Cara cek IP lokal macOS di Terminal: ipconfig getifaddr en0
  // Jalankan Laravel dengan: php artisan serve --host=0.0.0.0 --port=8000
  // static const String laravelBaseUrl = 'http://192.168.1.100:8000';
}
