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

## Demo operasyon hesapları

- `admin@speto.app / admin123`
- `burger@speto.app / vendor123`
- `market@speto.app / vendor123`

## İlk entegrasyon hedefleri

- Flutter `SpetoAuthRepository` yerine token tabanlı auth client
- Flutter `SpetoCommerceRepository` yerine cart/order/wallet/ticket endpoint'leri
- `courierEnabled = false` capability bayrağı ile pickup-only davranış
- `inventory/*`, `ops/*`, `integrations/*` endpoint'leri ile ayrı `stock_app` uygulaması
