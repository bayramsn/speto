# SepetPro Admin Panel

`admin_panel`, SepetPro platformunun tek tam-yetkili yönetim arayüzüdür. `stock_app`
artık yalnız işletme/vendor operasyonları için kullanılır; admin akışları bu panelde yaşar.

## Geliştirme

```bash
cd admin_panel
npm install
npm run dev
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
  `POST /admin/auth/login|refresh|logout`
- Panel session bilgisini local storage içinde `sepetpro.admin.session` anahtarı ile tutar.

## Ürün yönetimi

Business workspace içindeki ürün ekranı:

- kategori alanını seçim listesi olarak sunar
- section alanını seçim listesi olarak sunar
- ürün görselini dosya seçiciyle `imageUrl` alanına taşır
- gerçek CRUD işlemlerini `/admin/businesses/:id/products` endpointleri ile yapar
