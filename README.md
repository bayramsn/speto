# Speto

Speto, pickup odakli siparis deneyimini restoran, market ve etkinlik akislariyla birlestiren bir Flutter uygulamasi ve onu besleyen NestJS backend monoreposudur.

Bu repo tek bir urun yerine birden fazla yuzeyi birlikte barindirir:

- Musteri uygulamasi: onboarding, auth, restoran, market, happy hour, etkinlik, dijital bilet, siparis ve profil akislar
- Operasyon paneli: vendor ve admin hesaplari icin stok, siparis operasyonu ve entegrasyon ekranlari
- Backend API: auth, catalog, orders, inventory, ops, support ve entegrasyon endpoint'leri
- Shared package: her iki Flutter uygulamasinin kullandigi ortak modeller ve API istemcisi

## Ozellikler

- Pickup-only ticaret kurgusu
- E-posta ile kayit, giris ve sifre sifirlama akislar
- Restoran listesi, menu detaylari ve urun bazli checkout deneyimi
- Market ve happy hour teklif ekranlari
- Etkinlik kesfi, dijital bilet ve bilet basarili satin alma akislar
- Siparis gecmisi, siparis takibi ve makbuz ekranlari
- Profil, adres, odeme yontemi, destek ve puan yonetimi
- Vendor/admin icin stok dashboard, urun listesi, siparis operasyonu ve POS/ERP senkronu

## Repo Yapisi

```text
.
|-- lib/                    # Ana Speto Flutter uygulamasi
|-- stock_app/              # Vendor/admin operasyon istemcisi
|-- backend/                # NestJS + Prisma backend
|-- packages/speto_shared/  # Ortak modeller ve remote API istemcisi
|-- assets/                 # Katalog, animasyon ve lokal varliklar
|-- android/ ios/ web/...   # Ana uygulama platform klasorleri
```

## Mimari Ozet

- `lib/` altindaki ana uygulama `Riverpod` ile state yonetimi ve `go_router` ile navigasyon kullanir.
- `packages/speto_shared/` iki Flutter istemcisinin ayni domain modellerini ve typed API client katmanini paylasir.
- `backend/` altinda `NestJS`, `Fastify`, `Prisma`, `PostgreSQL` ve `Redis` tabanli bir API bulunur.
- Ana uygulama katalog, hesap ve siparis durumunu SepetPro backend API uzerinden senkronize eder; local persistence yalniz son oturum/snapshot bilgisini korur.
- `stock_app` fallback yerine dogrudan backend baglantisina dayanir; operasyon paneli icin API'nin ayakta olmasi gerekir.

## Hizli Baslangic

### 1. Backend'i ayaga kaldirin

```bash
cp backend/.env.example backend/.env
cd backend
docker compose up -d
npm install
npm run prisma:generate
npm run prisma:push
npm run start:dev
```

Backend varsayilan olarak su adreslerde acilir:

- API: `http://localhost:4000/api`
- Swagger: `http://localhost:4000/docs`
- Health check: `http://localhost:4000/api/health`

Demo seed varsayilani kapali gelir (`ENABLE_DEMO_SEED=false`). Daha once yuklenmis demo kayitlar backend acilisinda temizlenir.

### 2. Ana Flutter uygulamasini calistirin

```bash
flutter pub get
flutter run
```

Varsayilan API adresleri:

- Web ve desktop: `http://127.0.0.1:4000/api`
- Android emulator: `http://10.0.2.2:4000/api`
- Fiziksel telefon fallback: `http://192.168.1.2:4000/api`

Farkli bir backend adresi kullanacaksaniz `SPETO_API_BASE_URL` override edebilirsiniz:

```bash
flutter run --dart-define=SPETO_API_BASE_URL=https://your-api.example.com/api
```

Lokal ag IP'niz degisirse fiziksel cihaz fallback adresini de override edebilirsiniz:

```bash
flutter run --dart-define=SPETO_LAN_API_BASE_URL=http://192.168.1.2:4000/api
```

### 3. Operasyon uygulamasini calistirin

```bash
cd stock_app
flutter pub get
flutter run
```

`stock_app` admin veya vendor roluyle backend'e baglanir. Lokal gelistirmede genellikle web hedefiyle kullanmak pratiktir:

```bash
cd stock_app
flutter run -d chrome
```

## Kimlik ve OTP

- Musteri ve operator oturumlari gercek backend kullanicilariyla acilir; repo icinde hazir demo hesap tutulmaz.
- Test OTP akisi gerekiyorsa backend tarafinda `OTP_TEST_MODE=true` ve `OTP_TEST_CODE=12345` kullanilabilir.

## Teknoloji Yigini

- Flutter
- Riverpod
- go_router
- NestJS
- Fastify
- Prisma
- PostgreSQL
- Redis

## Mevcut Kapsam

- Proje pickup-only akisa odaklanir.
- Kurye/delivery akisi bilincli olarak kapsam disidir.
- Repo canli API akislarina odaklanir; production hardening ve gizli veri yonetimi ayrica ele alinmalidir.
