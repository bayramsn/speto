# SepetPro Admin Panel

`admin_panel`, SepetPro platformunun tek tam-yetkili yönetim arayüzüdür. `stock_app`
artık yalnız işletme/vendor operasyonları için kullanılır; admin akışları bu panelde yaşar.

## Geliştirme

```bash
cd admin_panel
npm install
npm run dev
npm test
```

Varsayılan local admin backend adresi:

```env
VITE_ADMIN_API_BASE_URL=http://127.0.0.1:4100/api
```

İsterseniz `.env.example` dosyasını kopyalayarak kendi ortamınızı tanımlayabilirsiniz.

## Temel ekranlar

- Dashboard
- Businesses
- Orders
- Users
- Events
- Finance
- Reports
- Notifications
- Support
- Settings
- Business workspace:
  `/businesses/:businessId/overview|orders|products|campaigns|profile`

## Auth modeli

- Panel yalnız `SUPER_ADMIN` oturumu açar.
- Auth istekleri ayrı admin backend’e gider:
  `POST /admin/auth/login|refresh|logout|me`
- Refresh token frontend storage içinde tutulmaz. Admin backend
  `speto_admin_refresh` HttpOnly cookie set/rotate/clear eder.
- Frontend access token’ı memory’de tutar; sayfa yenilenince
  `/admin/auth/refresh` cookie ile yeni access token alır.
- Cross-origin ortamda admin backend `ADMIN_CORS_ALLOWED_ORIGINS` içinde panel
  origin’ini içermeli ve credentials açık olmalıdır.

## Ürün yönetimi

Business workspace içindeki ürün ekranı:

- kategori alanını seçim listesi olarak sunar
- section alanını seçim listesi olarak sunar
- ürün görseli için data/base64 içerik kabul etmez; güvenli `https://` URL
  kullanır
- ileride gerçek storage bağlanması için `/admin/uploads/presign` provider-ready
  endpoint’i vardır; provider yoksa güvenli şekilde configured değil döner
- gerçek CRUD işlemlerini `/admin/businesses/:id/products` endpointleri ile yapar
