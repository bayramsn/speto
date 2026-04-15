// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'SepetPro';

  @override
  String get explore => 'Keşfet';

  @override
  String get orders => 'Siparişler';

  @override
  String get basket => 'Sepet';

  @override
  String get points => 'Puanlar';

  @override
  String get profile => 'Profil';

  @override
  String get login => 'Giriş Yap';

  @override
  String get register => 'Kayıt Ol';

  @override
  String get forgotPassword => 'Şifremi Unuttum';

  @override
  String get logout => 'Çıkış Yap';

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get fullName => 'Ad Soyad';

  @override
  String get phone => 'Telefon Numarası';

  @override
  String get next => 'İleri';

  @override
  String get confirm => 'Onayla';

  @override
  String get cancel => 'İptal';

  @override
  String get save => 'Kaydet';

  @override
  String get delete => 'Sil';

  @override
  String get close => 'Kapat';

  @override
  String get search => 'Ara';

  @override
  String get filter => 'Filtrele';

  @override
  String get all => 'Hepsi';

  @override
  String get nearby => 'Yakında';

  @override
  String get market => 'Market';

  @override
  String get restaurants => 'Restoranlar';

  @override
  String get events => 'Etkinlikler';

  @override
  String get happyHour => 'Happy Hour';

  @override
  String get proPoints => 'Pro Puanlar';

  @override
  String get addresses => 'Adreslerim';

  @override
  String get paymentMethods => 'Ödeme Yöntemleri';

  @override
  String get accountSettings => 'Hesap Ayarları';

  @override
  String get helpCenter => 'Yardım Merkezi';

  @override
  String get appMap => 'Uygulama Haritası';

  @override
  String get addToCart => 'Sepete Ekle';

  @override
  String addedToCart(String item) {
    return '$item sepete eklendi.';
  }

  @override
  String get checkout => 'Ödeme';

  @override
  String get orderHistory => 'Sipariş Geçmişi';

  @override
  String get orderTracking => 'Sipariş Takibi';

  @override
  String get receipt => 'Fiş';

  @override
  String get preparing => 'Hazırlanıyor';

  @override
  String get completed => 'Tamamlandı';

  @override
  String get cancelled => 'İptal';

  @override
  String get deliveryMode => 'Teslimat Modu';

  @override
  String get pickupCode => 'Gel-Al Kodu';

  @override
  String get totalPrice => 'Toplam';

  @override
  String get rewardPoints => 'Kazanılan Puan';

  @override
  String get studentRegistration => 'Öğrenci Kaydı';

  @override
  String get otpVerification => 'Kodu Girin';

  @override
  String get resetPassword => 'Şifre Sıfırla';

  @override
  String get passwordSuccess => 'Şifre Güncellendi';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get darkMode => 'Karanlık Mod';

  @override
  String get lightMode => 'Açık Mod';

  @override
  String get noItems => 'Henüz bir şey yok';

  @override
  String get retry => 'Tekrar Dene';

  @override
  String get loading => 'Yükleniyor...';

  @override
  String get error => 'Bir hata oluştu';

  @override
  String get signInWithGoogle => 'Google ile Giriş Yap';

  @override
  String get signInWithApple => 'Apple ile Giriş Yap';

  @override
  String get or => 'veya';

  @override
  String get termsAccept => 'Kullanıcı sözleşmesini okudum ve onaylıyorum.';

  @override
  String get kvkkAccept => 'KVKK Metnini okudum ve kabul ediyorum.';

  @override
  String get sendCode => 'Kodu Gönder';

  @override
  String get resendCode => 'Kodu tekrar gönder';

  @override
  String get home => 'Ana Sayfa';

  @override
  String get digitalTicket => 'Dijital Bilet';

  @override
  String priceTL(String price) {
    return '$price TL';
  }
}
