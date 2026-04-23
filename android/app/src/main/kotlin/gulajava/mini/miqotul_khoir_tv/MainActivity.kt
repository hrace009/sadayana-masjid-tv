package gulajava.mini.miqotul_khoir_tv

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Mencegah layar mati saat app aktif di foreground.
        // Wajib untuk perangkat TV/kiosk yang tidak boleh terputus oleh screen timeout sistem.
        // Flag otomatis tidak berlaku saat app masuk background — Android mengembalikan
        // kontrol screen timeout ke sistem secara normal.
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }
}
