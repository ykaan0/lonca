# Lonca — Grup Çalışma ve Yönetim Uygulaması (Flutter / Android)

Siyah ve altın tonlarında tasarlanmış, çalışma oturumlarıyla seviye atlayan grup (lonca) yönetimi uygulaması.

## Özellikler

- **Hesap Sistemi:** E-posta, isim, şifre ve benzersiz kullanıcı ID (`@handle`) ile kayıt ve giriş.
- **Kullanıcı Seviyesi & Profil:** Çalışma oturumları açık kaldıkça artan kullanıcı seviyesi; profilde üye olunan loncaları görüntüleme ve isteğe bağlı gizleme anahtarı.
- **Lonca (Grup) Sistemi:**
  - Keşfet ekranında loncalar toplam çalışma süresine (seviyeye) göre sıralanır.
  - Katılma isteği gönderme ve lider/yardımcı onayıyla giriş.
  - **Yönetim Paneli (Sadece Lider & Yardımcılar):**
    - Katılma isteklerini onaylama / reddetme
    - Üye susturma (susturulan üye sohbette mesaj gönderemez) ve gruptan çıkarma
    - **Yalnızca Lider:** Yardımcı atama / alma ve liderliği devretme
  - **Canlı Çalışma Oturumları:** Üyeler lonca içindeyken ne üzerinde çalıştığını yazarak oturum başlatır. Grup ekranındaki kare kartlarda kimin aktif olduğu, ne yaptığı ve canlı sayacı görünür.
  - **Yan Sohbet Paneli:** Grup ekranında sağdan içe kayarak açılıp kapanabilen gerçek zamanlı sohbet çekmecesi.

## Kurulum (Android)

Bu depoda uygulamanın tüm Dart kaynak kodu (`lib/`), `pubspec.yaml` ve `firestore.rules` yer almaktadır. Android platform klasörünü ve Firebase bağlantısını kendi ortamında oluşturmak için:

1. **Android platform dosyalarını oluştur:**
   ```bash
   flutter create --platforms=android .
   ```
   *(Var olan `lib/` ve `pubspec.yaml` korunur.)*

2. **Paketleri indir:**
   ```bash
   flutter pub get
   ```

3. **Firebase'i bağla:**
   - Firebase Console'da yeni bir proje oluştur, **Authentication (E-posta/Şifre)** ve **Cloud Firestore** servislerini etkinleştir.
   - `firestore.rules` dosyasındaki kuralları Firestore Rules sekmesine yükle.
   - Proje klasöründe FlutterFire CLI ile yapılandır:
     ```bash
     flutterfire configure
     ```
     Bu komut `lib/firebase_options.dart` ve `android/app/google-services.json` dosyalarını otomatik oluşturacaktır.

4. **Çalıştır:**
   ```bash
   flutter run
   ```

