import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'Speto'**
  String get appTitle;

  /// No description provided for @explore.
  ///
  /// In tr, this message translates to:
  /// **'Keşfet'**
  String get explore;

  /// No description provided for @orders.
  ///
  /// In tr, this message translates to:
  /// **'Siparişler'**
  String get orders;

  /// No description provided for @basket.
  ///
  /// In tr, this message translates to:
  /// **'Sepet'**
  String get basket;

  /// No description provided for @points.
  ///
  /// In tr, this message translates to:
  /// **'Puanlar'**
  String get points;

  /// No description provided for @profile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @login.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get login;

  /// No description provided for @register.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Ol'**
  String get register;

  /// No description provided for @forgotPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifremi Unuttum'**
  String get forgotPassword;

  /// No description provided for @logout.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get email;

  /// No description provided for @password.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad'**
  String get fullName;

  /// No description provided for @phone.
  ///
  /// In tr, this message translates to:
  /// **'Telefon Numarası'**
  String get phone;

  /// No description provided for @next.
  ///
  /// In tr, this message translates to:
  /// **'İleri'**
  String get next;

  /// No description provided for @confirm.
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get close;

  /// No description provided for @search.
  ///
  /// In tr, this message translates to:
  /// **'Ara'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In tr, this message translates to:
  /// **'Filtrele'**
  String get filter;

  /// No description provided for @all.
  ///
  /// In tr, this message translates to:
  /// **'Hepsi'**
  String get all;

  /// No description provided for @nearby.
  ///
  /// In tr, this message translates to:
  /// **'Yakında'**
  String get nearby;

  /// No description provided for @market.
  ///
  /// In tr, this message translates to:
  /// **'Market'**
  String get market;

  /// No description provided for @restaurants.
  ///
  /// In tr, this message translates to:
  /// **'Restoranlar'**
  String get restaurants;

  /// No description provided for @events.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlikler'**
  String get events;

  /// No description provided for @happyHour.
  ///
  /// In tr, this message translates to:
  /// **'Happy Hour'**
  String get happyHour;

  /// No description provided for @proPoints.
  ///
  /// In tr, this message translates to:
  /// **'Pro Puanlar'**
  String get proPoints;

  /// No description provided for @addresses.
  ///
  /// In tr, this message translates to:
  /// **'Adreslerim'**
  String get addresses;

  /// No description provided for @paymentMethods.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme Yöntemleri'**
  String get paymentMethods;

  /// No description provided for @accountSettings.
  ///
  /// In tr, this message translates to:
  /// **'Hesap Ayarları'**
  String get accountSettings;

  /// No description provided for @helpCenter.
  ///
  /// In tr, this message translates to:
  /// **'Yardım Merkezi'**
  String get helpCenter;

  /// No description provided for @appMap.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama Haritası'**
  String get appMap;

  /// No description provided for @addToCart.
  ///
  /// In tr, this message translates to:
  /// **'Sepete Ekle'**
  String get addToCart;

  /// No description provided for @addedToCart.
  ///
  /// In tr, this message translates to:
  /// **'{item} sepete eklendi.'**
  String addedToCart(String item);

  /// No description provided for @checkout.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme'**
  String get checkout;

  /// No description provided for @orderHistory.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş Geçmişi'**
  String get orderHistory;

  /// No description provided for @orderTracking.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş Takibi'**
  String get orderTracking;

  /// No description provided for @receipt.
  ///
  /// In tr, this message translates to:
  /// **'Fiş'**
  String get receipt;

  /// No description provided for @preparing.
  ///
  /// In tr, this message translates to:
  /// **'Hazırlanıyor'**
  String get preparing;

  /// No description provided for @completed.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlandı'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancelled;

  /// No description provided for @deliveryMode.
  ///
  /// In tr, this message translates to:
  /// **'Teslimat Modu'**
  String get deliveryMode;

  /// No description provided for @pickupCode.
  ///
  /// In tr, this message translates to:
  /// **'Gel-Al Kodu'**
  String get pickupCode;

  /// No description provided for @totalPrice.
  ///
  /// In tr, this message translates to:
  /// **'Toplam'**
  String get totalPrice;

  /// No description provided for @rewardPoints.
  ///
  /// In tr, this message translates to:
  /// **'Kazanılan Puan'**
  String get rewardPoints;

  /// No description provided for @studentRegistration.
  ///
  /// In tr, this message translates to:
  /// **'Öğrenci Kaydı'**
  String get studentRegistration;

  /// No description provided for @otpVerification.
  ///
  /// In tr, this message translates to:
  /// **'Kodu Girin'**
  String get otpVerification;

  /// No description provided for @resetPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifre Sıfırla'**
  String get resetPassword;

  /// No description provided for @passwordSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Şifre Güncellendi'**
  String get passwordSuccess;

  /// No description provided for @notifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get notifications;

  /// No description provided for @darkMode.
  ///
  /// In tr, this message translates to:
  /// **'Karanlık Mod'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In tr, this message translates to:
  /// **'Açık Mod'**
  String get lightMode;

  /// No description provided for @noItems.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir şey yok'**
  String get noItems;

  /// No description provided for @retry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In tr, this message translates to:
  /// **'Bir hata oluştu'**
  String get error;

  /// No description provided for @signInWithGoogle.
  ///
  /// In tr, this message translates to:
  /// **'Google ile Giriş Yap'**
  String get signInWithGoogle;

  /// No description provided for @signInWithApple.
  ///
  /// In tr, this message translates to:
  /// **'Apple ile Giriş Yap'**
  String get signInWithApple;

  /// No description provided for @or.
  ///
  /// In tr, this message translates to:
  /// **'veya'**
  String get or;

  /// No description provided for @termsAccept.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı sözleşmesini okudum ve onaylıyorum.'**
  String get termsAccept;

  /// No description provided for @kvkkAccept.
  ///
  /// In tr, this message translates to:
  /// **'KVKK Metnini okudum ve kabul ediyorum.'**
  String get kvkkAccept;

  /// No description provided for @sendCode.
  ///
  /// In tr, this message translates to:
  /// **'Kodu Gönder'**
  String get sendCode;

  /// No description provided for @resendCode.
  ///
  /// In tr, this message translates to:
  /// **'Kodu tekrar gönder'**
  String get resendCode;

  /// No description provided for @home.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get home;

  /// No description provided for @digitalTicket.
  ///
  /// In tr, this message translates to:
  /// **'Dijital Bilet'**
  String get digitalTicket;

  /// No description provided for @priceTL.
  ///
  /// In tr, this message translates to:
  /// **'{price} TL'**
  String priceTL(String price);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
