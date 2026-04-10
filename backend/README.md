# Speto Backend

Pickup-only backend iskeleti. Kurye akışı bilinçli olarak kapsam dışıdır.

## Modüller

- `auth`: kayıt, giriş ve oturum kontratları
- `catalog`: restoran, market ve etkinlik bootstrap verileri
- `inventory`: stok dashboard, ürün listesi, hareket geçmişi, manuel düzeltme
- `ops`: sipariş operasyon akışı (`CREATED -> ACCEPTED -> PREPARING -> READY -> COMPLETED`)
- `integrations`: generic POS/ERP bağlantıları, sync ve webhook uçları
- `orders`: pickup-only checkout session ve sipariş özetleri
- `health`: liveness/readiness endpoint'leri

## Kurulum

```bash
cd backend
docker compose up -d
npm install
npm run prisma:generate
npm run prisma:push
npm run start:dev
```

API varsayılan olarak `http://localhost:4000/api` altında açılır.
Swagger çıktısı `http://localhost:4000/docs` altında yayınlanır.

`DATABASE_URL` için örnek değer [backend/.env.example](/Users/bayramsenbay/Downloads/speto/backend/.env.example) içinde bulunur. Varsayılan local portlar çakışmayı önlemek için `55432` (Postgres) ve `6380` (Redis) olarak ayarlanmıştır. Backend ilk başarılı bağlantıda demo vendor, ürün, stok, sipariş ve entegrasyon verilerini Postgres'e seed eder.

## OTP / E-posta ayarları

Şifre sıfırlama OTP akışı Resend ile e-posta gönderebilir. Local geliştirme için `.env` içine şu alanlar eklenir:

```env
OTP_TEST_MODE=true
OTP_TEST_CODE=12345
RESEND_API_BASE_URL=https://api.resend.com
RESEND_API_KEY=your_resend_key
RESEND_FROM_EMAIL="Speto <onboarding@resend.dev>"
```

- `OTP_TEST_MODE=true`: OTP mail göndermez, test kodunu backend içinde sabit üretir.
- `OTP_TEST_MODE=false`: backend Resend API ile gerçek e-posta gönderir.
- `RESEND_FROM_EMAIL`: domain doğrulaması yapılmadıysa `onboarding@resend.dev` ile test edilebilir.

## Demo operasyon hesapları

- `admin@speto.app / admin123`
- `burger@speto.app / vendor123`
- `market@speto.app / vendor123`

## İlk entegrasyon hedefleri

- Flutter `SpetoAuthRepository` yerine token tabanlı auth client
- Flutter `SpetoCommerceRepository` yerine cart/order/wallet/ticket endpoint'leri
- `courierEnabled = false` capability bayrağı ile pickup-only davranış
- `inventory/*`, `ops/*`, `integrations/*` endpoint'leri ile ayrı `stock_app` uygulaması
