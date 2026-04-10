# Customer App Integration Plan

## Summary

- Bu doküman yalnızca müşteri uygulaması içindeki entegrasyon ihtiyaçlarını kapsar.
- Müşteri uygulaması dışındaki tüm yüzeyler kapsam dışıdır.
- Kapsam; route ile açılan ekranları ve route dışı açılan kullanıcı-facing ekranları içerir.
- Ana entegrasyon alanları `auth`, `catalog`, `orders`, `wallet`, `profile` ve `support` domain'leridir.
- Keşif ve katalog yüzeylerinde backend temeli vardır, ancak bazı ekranlar hâlâ lokal veya kısmi veri ile çalışır.
- Özellikle `HappyHour` akışı, parola sıfırlama OTP doğrulaması ve kalıcı kullanıcı tercihleri tarafında ek backend ihtiyacı vardır.

## Auth Integrations

### `LoginScreen`
- Amaç: Kullanıcının e-posta ve şifre ile oturum açmasını sağlamak.
- Backend endpoint: `POST /auth/login`
- Request alanları: `email`, `password`
- Response alanları: `user.email`, `user.displayName`, `user.phone`, `user.avatarUrl`, `user.notificationsEnabled`, `user.role`, `user.vendorScopes`, `tokens.accessToken`
- Mevcut durum: `hazır`

### `RegisterScreen`
- Amaç: Standart müşteri kayıt akışını başlatmak ve kullanıcı bilgilerini toplamak.
- Backend endpoint: `POST /auth/register`
- Request alanları: `email`, `displayName`, `phone`, `password`
- Response alanları: `user.*`, `tokens.accessToken`
- Mevcut durum: `hazır`
- Not: Ekran kayıt taslağını lokal state'te tutar, fakat akış backend register çağrısı ile tamamlanır; staged auth tasarımı bilinçli olarak korunur.

### `StudentEmailRegisterScreen`
- Amaç: Öğrenci e-postası ile kayıt akışını başlatmak.
- Backend endpoint: `POST /auth/register`
- Request alanları: `email`, `displayName`, `phone`, `password`, `studentEmail`
- Response alanları: `user.*`, `tokens.accessToken`
- Mevcut durum: `hazır`
- Not: Öğrenci kayıt akışı staged auth mantığıyla ilerler ve backend register tamamlaması ile sonuçlanır.

### `OtpVerificationScreen`
- Amaç: Kayıt veya şifre sıfırlama akışında tek kullanımlık kod doğrulamasını tamamlamak.
- Backend endpoint: Kayıt tarafında dolaylı olarak `POST /auth/register`; şifre sıfırlama için gerekli yeni endpoint `POST /auth/password/verify-otp`
- Request alanları: `email`, `code`
- Response alanları: `verified`, kayıt senaryosunda `user.*`, `tokens.accessToken`; şifre sıfırlama senaryosunda `verified`, `expiresAt`
- Mevcut durum: `hazır`
- Not: Şifre sıfırlama tarafında OTP doğrulaması artık backend üzerinden kalıcı kayıtla çalışır. Kayıt akışı hâlâ taslak -> register tamamlama mantığını korur.

### `ForgotPasswordScreen`
- Amaç: Parola sıfırlama talebini başlatmak.
- Backend endpoint: `POST /auth/password/request`
- Request alanları: `email`
- Response alanları: `exists`
- Mevcut durum: `hazır`

### `ResetPasswordScreen`
- Amaç: Yeni parolanın backend'e yazılması.
- Backend endpoint: `POST /auth/password/update`
- Request alanları: `email`, `password`
- Response alanları: `success`
- Mevcut durum: `hazır`
- Not: Backend parola güncellemesini artık doğrulanmış OTP kaydı olmadan kabul etmez.

## Catalog and Discovery Integrations

### `HomeDashboardScreen`
- Amaç: Ana sayfa hero kartlarını, quick filter alanlarını ve keşif giriş noktalarını göstermek.
- Backend endpoint: `GET /catalog/bootstrap`
- Request alanları: yok
- Response alanları: `contentVersion`, `home.heroes`, `home.quickFilters`, `home.discoveryFilters`, `featured.restaurants`, `featured.events`, `restaurants`, `markets`, `events`
- Mevcut durum: `hazır`
- Not: Ana içerik backend bootstrap ile yüklenir ve foreground refresh ile güncellenir; kalan sabit arama önerileri yalnız UI yardımcı içeriğidir.

### `MarketListScreen`
- Amaç: Market listesini ve kampanya kartlarını göstermek.
- Backend endpoint: `GET /catalog/bootstrap` veya alternatif olarak `GET /catalog/markets`
- Request alanları: yok
- Response alanları: `markets[].id`, `markets[].title`, `markets[].subtitle`, `markets[].image`, `markets[].badge`, `markets[].rewardLabel`, `markets[].ratingLabel`, `markets[].distanceLabel`, `markets[].etaLabel`, `markets[].bundleTitle`, `markets[].bundleDescription`
- Mevcut durum: `hazır`
- Not: Liste bootstrap ile beslenir; favori durumu artık backend preference kaydı ile kalıcıdır.

### `MarketStoreScreen`
- Amaç: Seçili marketin vitrinini, section bazlı ürünlerini ve sepete ekleme akışını göstermek.
- Backend endpoint: `GET /catalog/vendors/:vendorId`
- Request alanları: `vendorId`
- Response alanları: `vendor.id`, `vendor.title`, `vendor.image`, `vendor.pickupPoints`, `vendor.highlights`, `vendor.sections[].products[]`, ürün bazında `stockStatus`
- Mevcut durum: `hazır`
- Not: Ekran backend bootstrap ile doldurulan canlı katalog state'ini kullanır; uygulama foreground olduğunda veri yeniden çekilir.

### `MarketStoreDetailScreen`
- Amaç: Market içindeki öne çıkan paket veya seçili ürün grubunun detayını göstermek.
- Backend endpoint: `GET /catalog/vendors/:vendorId`
- Request alanları: `vendorId`
- Response alanları: `vendor.bundleTitle`, `vendor.bundleDescription`, `vendor.bundlePrice`, `vendor.sections[].products[]`, `vendor.pickupPoints`
- Mevcut durum: `hazır`
- Not: Detay yüzeyi backend kaynaklı runtime vendor objesini kullanır ve katalog refresh döngüsüne dahildir.

### `RestaurantListScreen`
- Amaç: Restoran listesini göstermek ve filtrelemek.
- Backend endpoint: `GET /catalog/bootstrap` veya alternatif olarak `GET /catalog/restaurants`
- Request alanları: yok
- Response alanları: `restaurants[].id`, `restaurants[].title`, `restaurants[].image`, `restaurants[].cuisine`, `restaurants[].etaMin`, `restaurants[].etaMax`, `restaurants[].ratingValue`, `restaurants[].promo`, `restaurants[].studentFriendly`
- Mevcut durum: `hazır`
- Not: Liste bootstrap ile güncellenir; favori durumu backend preference kaydı ile cihazlar arası korunur.

### `RestaurantDetailScreen`
- Amaç: Restoran detayını, menu section'larını ve ürün listesini göstermek.
- Backend endpoint: `GET /catalog/vendors/:vendorId`
- Request alanları: `vendorId`
- Response alanları: `vendor.title`, `vendor.image`, `vendor.ratingLabel`, `vendor.distanceLabel`, `vendor.etaLabel`, `vendor.pickupPoints`, `vendor.highlights`, `vendor.sections[].products[]`
- Mevcut durum: `hazır`
- Not: Restoran detayı backend bootstrap ile preload edilen canlı katalog verisini tüketir; veri foreground refresh ile güncellenir.

### `MenuItemDetailScreen`
- Amaç: Tek bir ürünün detayını, özetini ve sepete ekleme akışını göstermek.
- Backend endpoint: `GET /catalog/vendors/:vendorId` içindeki ürün verisi; stok görünürlüğü için dolaylı `stockStatus`
- Request alanları: `vendorId` veya seçili ürünün parent vendor'ı
- Response alanları: `product.id`, `product.title`, `product.description`, `product.image`, `product.unitPrice`, `product.priceText`, `product.displaySubtitle`, `product.displayBadge`, `product.stockStatus`
- Mevcut durum: `hazır`
- Not: Ürün yüzeyi parent vendor payload'ı ve inventory snapshot'ı ile canlı fiyat/stok görünürlüğünü backend'den alır.

### `EventsDiscoveryScreen`
- Amaç: Etkinlik listesi, kategori filtresi ve bilet açma giriş akışını göstermek.
- Backend endpoint: `GET /catalog/bootstrap` veya alternatif olarak `GET /catalog/events`
- Request alanları: yok
- Response alanları: `events[].id`, `events[].title`, `events[].venue`, `events[].district`, `events[].dateLabel`, `events[].timeLabel`, `events[].image`, `events[].pointsCost`, `events[].primaryTag`, `events[].secondaryTag`, `events[].participantLabel`
- Mevcut durum: `hazır`
- Not: Etkinlik keşif datası backend bootstrap ile gelir; sabit koltuk seçenekleri yalnız satın alma UI yardımcı içeriğidir.

### `EventDetailScreen`
- Amaç: Etkinlik detayını göstermek ve bilet açma işlemini başlatmak.
- Backend endpoint: `GET /catalog/events/:eventId`, bilet açma için `POST /wallet/redeem/:eventId`
- Request alanları: `eventId`; redeem için `zone`, `seat`, `gate`
- Response alanları: etkinlik için `title`, `description`, `organizer`, `ticketCategory`, `locationTitle`, `locationSubtitle`, `remainingCount`, `capacity`; redeem için `ticket.id`, `ticket.code`, `ticket.zone`, `ticket.seat`, `ticket.gate`
- Mevcut durum: `hazır`
- Not: Favoriye alma ve organizatör takip etme davranışı artık backend preference kaydı ile kalıcıdır.

### `HappyHourListScreen`
- Amaç: Süreli Happy Hour teklif listesini göstermek.
- Backend endpoint: gerekli yeni endpoint `GET /offers/happy-hour`
- Request alanları: isteğe bağlı `type`, `category`, `vendorId`, `activeOnly`
- Response alanları: `offers[].id`, `offers[].title`, `offers[].subtitle`, `offers[].image`, `offers[].discountedPrice`, `offers[].originalPrice`, `offers[].rewardPoints`, `offers[].endsAt`, `offers[].vendor`
- Mevcut durum: `hazır`
- Not: Teklifler backend tarafından katalog ürünlerinden türetilir; bu yüzden admin paneldeki ürün/stok değişiklikleri happy hour listesine yansır.

### `HappyHourOfferDetailScreen`
- Amaç: Tek bir Happy Hour teklifinin detayını göstermek.
- Backend endpoint: gerekli yeni endpoint `GET /offers/happy-hour/:id`
- Request alanları: `id`
- Response alanları: `offer.id`, `offer.title`, `offer.description`, `offer.imageUrl`, `offer.discountedPrice`, `offer.originalPrice`, `offer.rewardPoints`, `offer.startsAt`, `offer.endsAt`, `offer.pickupPoint`, `offer.vendor`, `offer.items`
- Mevcut durum: `hazır`
- Not: Detay ekranı backend offer payload kullanır ve stok uygunluğunu inventory verisiyle birlikte gösterir.

## Checkout, Orders, Wallet Integrations

### `HappyHourCheckoutScreen`
- Amaç: Sepeti onaylamak, teslim alma noktasını seçmek, kartı seçmek ve siparişi oluşturmak.
- Backend endpoint: `POST /orders/checkout`, adres yönetimi için `GET/POST/DELETE /me/addresses`, kart yönetimi için `GET/POST/DELETE /me/payment-methods`
- Request alanları: `fulfillmentMode`, `pickupPointId`, `paymentMethodToken`, `paymentMethodLabel`, `items[]`, `promoCode`
- Response alanları: sipariş için `order.id`, `order.items`, `order.pickupCode`, `order.rewardPoints`, `order.deliveryAddress`, `order.paymentMethod`; adres ve kart CRUD response'ları
- Mevcut durum: `hazır`

### `OrderHistoryScreen`
- Amaç: Aktif ve geçmiş siparişleri göstermek.
- Backend endpoint: `GET /me/snapshot`
- Request alanları: yok
- Response alanları: `activeOrders[]`, `historyOrders[]`
- Mevcut durum: `hazır`
- Not: Sipariş puanları backend tarafında kaydedilir ve snapshot/wallet cevabına geri yansır.

### `OrderTrackingScreen`
- Amaç: Seçili siparişin anlık durumunu göstermek.
- Backend endpoint: minimum `GET /me/snapshot`; tercih edilen detay endpoint `GET /orders/:orderId`
- Request alanları: `orderId`
- Response alanları: `order.id`, `order.status`, `order.etaLabel`, `order.pickupCode`, `order.items`, `order.vendor`, `order.image`, `order.actionLabel`
- Mevcut durum: `hazır`
- Not: Ekran backend snapshot ile senkron app state'i kullanır; polling/live channel şu an zorunlu olmayan geliştirme alanıdır.

### `OrderReceiptScreen`
- Amaç: Sipariş fişini göstermek, siparişi tamamlamak ve puanlama başlatmak.
- Backend endpoint: `GET /orders/:orderId`, `POST /orders/:orderId/complete`
- Request alanları: `orderId`
- Response alanları: `order.items`, `order.paymentMethod`, `order.deliveryMode`, `order.deliveryAddress`, `order.discountAmount`, `order.rewardPoints`, complete sonrası güncel `order.status`
- Mevcut durum: `hazır`
- Not: Siparişi tamamlama akışı mevcut; puanlama da artık backend `POST /orders/:orderId/rating` ile kalıcıdır.

### `ProPointsScreen`
- Amaç: Kullanıcının Pro bakiye ve sahip olduğu biletleri göstermek.
- Backend endpoint: `GET /me/snapshot` ve/veya `GET /wallet`
- Request alanları: yok
- Response alanları: `wallet.balance`, `wallet.ownedTickets[]`
- Mevcut durum: `hazır`
- Not: Bakiye ve biletler backend kaynaklıdır; kalan açıklama blokları salt içerik olduğu için client-side kalabilir.

### `DigitalTicketScreen`
- Amaç: Dijital bileti QR kod ve koltuk bilgileriyle göstermek.
- Backend endpoint: `GET /tickets` veya `GET /wallet`
- Request alanları: yok
- Response alanları: `tickets[].id`, `tickets[].title`, `tickets[].venue`, `tickets[].dateLabel`, `tickets[].timeLabel`, `tickets[].zone`, `tickets[].seat`, `tickets[].gate`, `tickets[].code`, `tickets[].image`
- Mevcut durum: `hazır`

### `TicketSuccessScreen`
- Amaç: Bilet satın alma/açma sonrası başarı özetini göstermek.
- Backend endpoint: `POST /wallet/redeem/:eventId` sonrası `GET /wallet` veya `GET /me/snapshot`
- Request alanları: `eventId`, `zone`, `seat`, `gate`
- Response alanları: `ticket.*`, `wallet.balance`
- Mevcut durum: `hazır`

## Profile and Support Integrations

### `AddressesScreen`
- Amaç: Kullanıcı adreslerini listelemek, eklemek, güncellemek ve silmek.
- Backend endpoint: `GET /me/addresses`, `POST /me/addresses`, `DELETE /me/addresses/:id`
- Request alanları: `id`, `label`, `address`, `iconKey`, `isPrimary`
- Response alanları: `address.id`, `address.label`, `address.address`, `address.iconKey`, `address.isPrimary`
- Mevcut durum: `hazır`

### `PaymentMethodsScreen`
- Amaç: Kullanıcının kayıtlı kartlarını yönetmek.
- Backend endpoint: `GET /me/payment-methods`, `POST /me/payment-methods`, `DELETE /me/payment-methods/:id`
- Request alanları: `id`, `brand`, `last4`, `expiry`, `holderName`, `isDefault`, `token`
- Response alanları: `paymentMethod.id`, `paymentMethod.brand`, `paymentMethod.last4`, `paymentMethod.expiry`, `paymentMethod.holderName`, `paymentMethod.isDefault`
- Mevcut durum: `hazır`

### `AccountSettingsScreen`
- Amaç: Profil bilgisini güncellemek, bildirim tercihini değiştirmek ve hesabı silmek.
- Backend endpoint: `GET /me`, `PATCH /me`, `DELETE /me`
- Request alanları: `displayName`, `email`, `phone`, `avatarUrl`, `notificationsEnabled`
- Response alanları: `profile.email`, `profile.displayName`, `profile.phone`, `profile.avatarUrl`, `profile.notificationsEnabled`
- Mevcut durum: `hazır`

### `HelpCenterScreen`
- Amaç: Destek taleplerini görüntülemek ve yeni destek talebi oluşturmak.
- Backend endpoint: `GET /support/tickets` veya `GET /me/snapshot`, yeni kayıt için `POST /support/tickets`
- Request alanları: `subject`, `message`, `channel`
- Response alanları: `tickets[].id`, `tickets[].subject`, `tickets[].message`, `tickets[].channel`, `tickets[].createdAtLabel`, `tickets[].status`
- Mevcut durum: `hazır`

## Static Screens

### `OnboardingScreen`
- Amaç: Ürün tanıtım ve ilk deneyim akışını göstermek.
- Backend endpoint: yok
- Request alanları: yok
- Response alanları: yok
- Mevcut durum: `gereksiz`

### `PasswordSuccessScreen`
- Amaç: Parola güncelleme sonrası başarı mesajını göstermek.
- Backend endpoint: yok
- Request alanları: yok
- Response alanları: yok
- Mevcut durum: `gereksiz`

### `AppMapScreen`
- Amaç: Uygulama içindeki ekran geçiş haritasını göstermek.
- Backend endpoint: yok
- Request alanları: yok
- Response alanları: yok
- Mevcut durum: `gereksiz`

## Missing Integrations

### Kapanan eksikler
- `POST /auth/password/verify-otp` eklendi ve parola sıfırlama doğrulaması kalıcı OTP kaydı ile çalışıyor.
- `GET /offers/happy-hour` ve `GET /offers/happy-hour/:id` eklendi; teklif payload’ı katalog ürünlerinden türetiliyor.
- Kullanıcı tercihleri ve sipariş puanları backend’e taşındı:
  - restoran favorileri
  - etkinlik favorileri
  - market favorileri
  - organizatör takipleri
  - sipariş puanları

## Notes

- `MarketStoreScreen` ve `MarketStoreDetailScreen` route üzerinden değil, doğrudan push ile açılan kullanıcı-facing ekranlardır; bu yüzden entegrasyon planına dahil edilmiştir.
- `HomeDashboardScreen`, `RestaurantListScreen`, `RestaurantDetailScreen`, `EventsDiscoveryScreen` ve market akışları bugün `catalog/bootstrap` tabanlı runtime veriyle çalışabilir durumdadır.
- `HappyHour` akışı ise müşteri uygulamasında en belirgin şekilde backend datası bekleyen fakat henüz tamamlanmamış yüzeydir.
