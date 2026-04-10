# Customer App Backend Contract

## Summary

- Bu doküman müşteri uygulamasını besleyen backend sözleşmesini tanımlar.
- Kapsam yalnızca müşteri uygulamasının kullandığı domain'lerdir: `auth`, `catalog`, `profile`, `orders`, `wallet`, `support`.
- Müşteri uygulaması dışındaki tüm yüzeyler kapsam dışıdır.
- Mevcut backend şeması müşteri akışlarını destekler; parola sıfırlama OTP ve sipariş puanı kalıcılığı Prisma modelleri ile çözüldü.
- `HappyHour` yüzeyleri ayrı tablo yerine katalog + ürün + stok verisinden türetilen backend payload ile beslenir; böylece admin paneldeki ürün/vitrin değişiklikleri müşteri uygulamasına doğrudan yansır.
- Bazı alanlar kalıcı kolon değil, API response katmanında türetilmiş field olarak dönmelidir.

## Core Entities

- `User`: oturum açan müşterinin kimlik ve profil bilgileri
- `SavedPlace`: kullanıcı adresleri ve pickup tercihleri
- `PaymentMethod`: kayıtlı ödeme kartları
- `Vendor`: restoran ve market storefront kaydı
- `PickupPoint`: vendor bazlı gel-al noktaları
- `VendorHighlight`: storefront öne çıkan bilgiler
- `CatalogSection`: vendor içi menü veya kategori kırılımı
- `Product`: müşteri uygulamasında listelenen satın alınabilir ürün
- `Event`: Pro puan ile açılabilen etkinlik kaydı
- `ContentBlock`: ana sayfa hero, quick filter ve discovery içerikleri
- `Order`: müşteri siparişi
- `OrderItem`: sipariş satırları
- `WalletLedgerEntry`: Pro puan hareketleri
- `Ticket`: satın alınmış veya açılmış dijital etkinlik bileti
- `SupportTicket`: yardım merkezi destek kayıtları
- `Favorite`: müşteri tercihleri ve takip ilişkileri

## Required Fields by Entity

### `User`
- Zorunlu alanlar: `id`, `email`, `password`, `displayName`, `phone`, `role`, `vendorId`, `studentVerifiedAt`, `notificationsEnabled`, `avatarUrl`, `createdAt`, `updatedAt`
- Customer app kullanım alanları: oturum, profil, hesap ayarları, öğrenci doğrulama, bildirim tercihi

### `SavedPlace`
- Zorunlu alanlar: `id`, `userId`, `label`, `address`, `iconKey`, `isPrimary`, `createdAt`, `updatedAt`
- Customer app kullanım alanları: checkout adres seçimi, profil adres yönetimi

### `PaymentMethod`
- Zorunlu alanlar: `id`, `userId`, `provider`, `providerToken`, `brand`, `last4`, `expiryMonth`, `expiryYear`, `holderName`, `isDefault`, `createdAt`, `updatedAt`
- Customer app kullanım alanları: ödeme yöntemi listesi, checkout ödeme seçimi

### `Vendor`
- Zorunlu alanlar: `id`, `name`, `slug`, `category`, `storefrontType`, `subtitle`, `metaLabel`, `imageUrl`, `badge`, `rewardLabel`, `promoLabel`, `ratingValue`, `distanceLabel`, `etaMin`, `etaMax`, `workingHoursLabel`, `reviewCountLabel`, `announcement`, `bundleTitle`, `bundleDescription`, `bundlePrice`, `heroTitle`, `heroSubtitle`, `displayOrder`, `studentFriendly`, `isFeatured`, `isActive`
- Customer app kullanım alanları: home, market, restoran, storefront detayları

### `PickupPoint`
- Zorunlu alanlar: `id`, `vendorId`, `label`, `address`, `isActive`, `createdAt`, `updatedAt`
- Customer app kullanım alanları: checkout pickup seçimi, storefront teslim alma bilgisi

### `VendorHighlight`
- Zorunlu alanlar: `id`, `vendorId`, `label`, `iconKey`, `displayOrder`, `createdAt`, `updatedAt`
- Customer app kullanım alanları: restoran ve market detay kartları

### `CatalogSection`
- Zorunlu alanlar: `id`, `vendorId`, `key`, `label`, `displayOrder`, `isActive`, `createdAt`, `updatedAt`
- Customer app kullanım alanları: restoran ve market category/menu tab'leri

### `Product`
- Zorunlu alanlar: `id`, `vendorId`, `catalogSectionId`, `title`, `description`, `unitPrice`, `imageUrl`, `kind`, `sku`, `barcode`, `externalCode`, `displaySubtitle`, `displayBadge`, `displayOrder`, `isFeatured`, `isVisibleInApp`, `searchKeywords`, `legacyAliases`, `trackStock`, `reorderLevel`, `isArchived`, `isActive`, `createdAt`, `updatedAt`
- Customer app kullanım alanları: ürün listeleri, ürün detayları, sepet, checkout

### `Event`
- Zorunlu alanlar: `id`, `vendorId`, `title`, `venue`, `district`, `imageUrl`, `startsAt`, `pointsCost`, `capacity`, `remainingCount`, `primaryTag`, `secondaryTag`, `description`, `organizer`, `participantLabel`, `ticketCategory`, `locationTitle`, `locationSubtitle`, `displayOrder`, `isFeatured`, `isActive`, `createdAt`, `updatedAt`
- Customer app kullanım alanları: etkinlik keşfi, etkinlik detay, bilet açma

### `ContentBlock`
- Zorunlu alanlar: `id`, `type`, `key`, `title`, `subtitle`, `badge`, `imageUrl`, `actionLabel`, `screen`, `iconKey`, `highlight`, `displayOrder`, `isActive`, `payload`, `createdAt`, `updatedAt`
- Customer app kullanım alanları: ana sayfa hero alanları, quick filter, discovery filter

### `Order`
- Zorunlu alanlar: `id`, `userId`, `vendorId`, `pickupPointId`, `fulfillmentMode`, `status`, `pickupCode`, `etaLabel`, `subtotal`, `discountAmount`, `totalAmount`, `promoCode`, `paymentMethodId`, `createdAt`, `updatedAt`
- Customer app kullanım alanları: sipariş geçmişi, sipariş takibi, fiş, checkout sonrası state

### `OrderItem`
- Zorunlu alanlar: `id`, `orderId`, `productId`, `title`, `quantity`, `unitPrice`
- Customer app kullanım alanları: sepet özeti, fiş, order detail

### `WalletLedgerEntry`
- Zorunlu alanlar: `id`, `userId`, `delta`, `reason`, `referenceId`, `createdAt`
- Customer app kullanım alanları: Pro bakiye hesaplama ve hareket referansı

### `Ticket`
- Zorunlu alanlar: `id`, `userId`, `eventId`, `qrCode`, `zone`, `seat`, `gate`, `redeemedAt`, `createdAt`
- Customer app kullanım alanları: dijital bilet, ticket success, Pro bilet listesi

### `SupportTicket`
- Zorunlu alanlar: `id`, `userId`, `subject`, `message`, `channel`, `status`, `createdAt`, `updatedAt`
- Customer app kullanım alanları: yardım merkezi listeleme ve kayıt oluşturma

### `Favorite`
- Zorunlu alanlar: `id`, `userId`, `entityType`, `entityId`, `createdAt`
- Customer app kullanım alanları: restoran favorileri, etkinlik favorileri, market favorileri, organizatör takibi
- Not: `entityType` en az `RESTAURANT`, `EVENT`, `MARKET`, `ORGANIZER` değerlerini desteklemelidir.

## Required Derived Fields

- `dateLabel`
  - Kaynak: `Event.startsAt`
  - Kullanım: etkinlik listesi, etkinlik detay, ticket

- `timeLabel`
  - Kaynak: `Event.startsAt`
  - Kullanım: etkinlik yüzeyleri ve bilet ekranları

- `ratingLabel`
  - Kaynak: `Vendor.ratingValue`
  - Kullanım: market ve restoran kartları

- `etaLabel`
  - Kaynak: `Vendor.etaMin`, `Vendor.etaMax` veya `Order.etaLabel`
  - Kullanım: storefront kartları ve sipariş ekranları

- `priceText`
  - Kaynak: `Product.unitPrice`
  - Kullanım: ürün kartları ve ürün detay yüzeyleri

- `createdAtLabel`
  - Kaynak: `SupportTicket.createdAt`, gerekirse `Order.createdAt`
  - Kullanım: yardım merkezi ve müşteri facing zaman etiketleri

- `actionLabel`
  - Kaynak: `Order.status`
  - Kullanım: sipariş kartlarındaki CTA metni

- `stockStatus`
  - Kaynak: `Product.trackStock` + internal stok hesaplaması
  - Kullanım: restoran ve market ürün görünürlüğü, sepete ekleme kontrolü
  - Not: Public entity olarak expose edilmezse bile response içinde mutlaka dönmelidir.

- `wallet.balance`
  - Kaynak: `WalletLedgerEntry.delta` toplamı
  - Kullanım: Pro bakiye, ticket purchase eligibility

## Implementation Notes

### `PasswordResetOtp`
- Amaç: Parola sıfırlama doğrulama kodlarını güvenli şekilde tutmak
- Gerekli alanlar: `id`, `email`, `purpose`, `codeHash`, `expiresAt`, `consumedAt`, `createdAt`
- Etkilenen ekranlar: `OtpVerificationScreen`, `ResetPasswordScreen`
- Durum: Prisma modeli ve backend akışı ile aktif kullanımdadır.

### `HappyHourOffer`
- Amaç: süreli teklif, kampanya ve Happy Hour yüzeylerini beslemek
- Etkilenen ekranlar: `HappyHourListScreen`, `HappyHourOfferDetailScreen`
- Durum: ayrı tablo yerine katalog ürünü, vendor vitrini ve stok verisinden türetilen backend payload olarak sağlanır. Bu seçim, admin paneldeki ürün/fiyat/stok değişikliklerinin offer ekranına doğrudan yansımasını sağlar.

### `OrderRating`
- Amaç: müşteri sipariş puanlamasını kalıcı hale getirmek
- Gerekli alanlar: `id`, `userId`, `orderId`, `stars`, `createdAt`, `updatedAt`
- Etkilenen ekranlar: `OrderHistoryScreen`, `OrderReceiptScreen`
- Durum: Prisma modeli ve `POST /orders/:orderId/rating` uçları ile aktif kullanımdadır.

## Required API Shapes

### `POST /auth/login`
- Request:
  - `email`
  - `password`
- Response:
  - `user.email`
  - `user.displayName`
  - `user.phone`
  - `user.avatarUrl`
  - `user.notificationsEnabled`
  - `user.role`
  - `user.vendorScopes`
  - `tokens.accessToken`

### `POST /auth/register`
- Request:
  - `email`
  - `displayName`
  - `phone`
  - `password`
  - `studentEmail`
- Response:
  - `user.*`
  - `tokens.accessToken`

### `POST /auth/password/request`
- Request:
  - `email`
- Response:
  - `exists`
- İsteğe bağlı: `maskedEmail`, `expiresAt`

### `POST /auth/password/verify-otp`
- Request:
  - `email`
  - `code`
- Response:
  - `verified`
  - `expiresAt`

### `POST /auth/password/update`
- Request:
  - `email`
  - `password`
- Response:
  - `success`

### `GET /catalog/bootstrap`
- Request:
  - yok
- Response:
  - `contentVersion`
  - `home.heroes[]`
  - `home.quickFilters[]`
  - `home.discoveryFilters[]`
  - `restaurants[]`
  - `markets[]`
  - `events[]`
  - `featured.restaurants[]`
  - `featured.events[]`

### `GET /catalog/vendors/:vendorId`
- Request:
  - `vendorId`
- Response:
  - `id`
  - `vendorId`
  - `storefrontType`
  - `title`
  - `subtitle`
  - `image`
  - `badge`
  - `rewardLabel`
  - `ratingLabel`
  - `distanceLabel`
  - `etaLabel`
  - `workingHoursLabel`
  - `announcement`
  - `bundleTitle`
  - `bundleDescription`
  - `bundlePrice`
  - `heroTitle`
  - `heroSubtitle`
  - `pickupPoints[]`
  - `highlights[]`
  - `sections[].products[]`
  - `stockStatus`

### `GET /catalog/events/:eventId`
- Request:
  - `eventId`
- Response:
  - `id`
  - `title`
  - `venue`
  - `district`
  - `dateLabel`
  - `timeLabel`
  - `image`
  - `pointsCost`
  - `primaryTag`
  - `secondaryTag`
  - `description`
  - `organizer`
  - `participantLabel`
  - `ticketCategory`
  - `locationTitle`
  - `locationSubtitle`
  - `remainingCount`
  - `capacity`

### `GET /me/snapshot`
- Request:
  - yok
- Response:
  - `profile`
  - `addresses[]`
  - `paymentMethods[]`
  - `activeOrders[]`
  - `historyOrders[]`
  - `supportTickets[]`
  - `wallet.balance`
  - `wallet.ownedTickets[]`

### `PATCH /me`
- Request:
  - `displayName`
  - `email`
  - `phone`
  - `avatarUrl`
  - `notificationsEnabled`
- Response:
  - `email`
  - `displayName`
  - `phone`
  - `avatarUrl`
  - `notificationsEnabled`

### `GET /me/addresses`
- Request:
  - yok
- Response:
  - `addresses[].id`
  - `addresses[].label`
  - `addresses[].address`
  - `addresses[].iconKey`
  - `addresses[].isPrimary`

### `POST /me/addresses`
- Request:
  - `id`
  - `label`
  - `address`
  - `iconKey`
  - `isPrimary`
- Response:
  - `id`
  - `label`
  - `address`
  - `iconKey`
  - `isPrimary`

### `DELETE /me/addresses/:id`
- Request:
  - `id`
- Response:
  - `204 No Content` veya silinen kaydın özeti

### `GET /me/payment-methods`
- Request:
  - yok
- Response:
  - `paymentMethods[].id`
  - `paymentMethods[].brand`
  - `paymentMethods[].last4`
  - `paymentMethods[].expiry`
  - `paymentMethods[].holderName`
  - `paymentMethods[].isDefault`

### `POST /me/payment-methods`
- Request:
  - `id`
  - `brand`
  - `last4`
  - `expiry`
  - `holderName`
  - `isDefault`
  - `token`
- Response:
  - `id`
  - `brand`
  - `last4`
  - `expiry`
  - `holderName`
  - `isDefault`

### `DELETE /me/payment-methods/:id`
- Request:
  - `id`
- Response:
  - `204 No Content` veya silinen kaydın özeti

### `POST /orders/checkout`
- Request:
  - `fulfillmentMode`
  - `pickupPointId`
  - `paymentMethodToken`
  - `paymentMethodLabel`
  - `items[].productId`
  - `items[].quantity`
  - `items[].vendor`
  - `items[].title`
  - `items[].image`
  - `items[].unitPrice`
  - `promoCode`
- Response:
  - `id`
  - `vendor`
  - `image`
  - `items[]`
  - `placedAtLabel`
  - `etaLabel`
  - `status`
  - `actionLabel`
  - `pickupCode`
  - `rewardPoints`
  - `deliveryMode`
  - `deliveryAddress`
  - `paymentMethod`
  - `promoCode`
  - `deliveryFee`
  - `discountAmount`

### `GET /orders/:orderId`
- Request:
  - `orderId`
- Response:
  - tam `SpetoOrder` shape'i

### `POST /orders/:orderId/complete`
- Request:
  - `orderId`
- Response:
  - güncellenmiş `SpetoOrder`

### `GET /wallet`
- Request:
  - yok
- Response:
  - `balance`
  - `ownedTickets[]`
  - `favoriteRestaurantIds[]`
  - `favoriteEventIds[]`
  - `favoriteMarketIds[]`
  - `followedOrganizerIds[]`
  - `orderRatings`

### `GET /tickets`
- Request:
  - yok
- Response:
  - `tickets[]`

### `POST /wallet/redeem/:eventId`
- Request:
  - `zone`
  - `seat`
  - `gate`
- Response:
  - `ticket.id`

### `GET /me/preferences`
- Request:
  - yok
- Response:
  - `favoriteRestaurantIds[]`
  - `favoriteEventIds[]`
  - `favoriteMarketIds[]`
  - `followedOrganizerIds[]`
  - `orderRatings`

### `POST /me/preferences`
- Request:
  - `entityType`
  - `entityId`
  - `enabled`
- Response:
  - `favoriteRestaurantIds[]`
  - `favoriteEventIds[]`
  - `favoriteMarketIds[]`
  - `followedOrganizerIds[]`
  - `orderRatings`

### `POST /orders/:orderId/rating`
- Request:
  - `orderId`
  - `stars`
- Response:
  - `orderId`
  - `stars`
  - `ticket.title`
  - `ticket.venue`
  - `ticket.dateLabel`
  - `ticket.timeLabel`
  - `ticket.zone`
  - `ticket.seat`
  - `ticket.gate`
  - `ticket.code`
  - `ticket.image`
  - `ticket.pointsCost`

### `GET /support/tickets`
- Request:
  - yok
- Response:
  - `tickets[].id`
  - `tickets[].subject`
  - `tickets[].message`
  - `tickets[].channel`
  - `tickets[].createdAtLabel`
  - `tickets[].status`

### `POST /support/tickets`
- Request:
  - `subject`
  - `message`
  - `channel`
- Response:
  - oluşturulan `SupportTicket`

### `GET /offers/happy-hour`
- Request:
- isteğe bağlı `category`, `vendorId`, `activeOnly`
- Response:
  - `offers[].id`
  - `offers[].title`
  - `offers[].subtitle`
  - `offers[].imageUrl`
  - `offers[].originalPrice`
  - `offers[].discountedPrice`
  - `offers[].rewardPoints`
  - `offers[].endsAt`
  - `offers[].vendor`

### `GET /offers/happy-hour/:id`
- Request:
  - `id`
- Response:
  - `id`
  - `title`
  - `subtitle`
  - `description`
  - `imageUrl`
  - `badge`
  - `originalPrice`
  - `discountedPrice`
  - `rewardPoints`
  - `startsAt`
  - `endsAt`
  - `pickupPoint`
  - `vendor`
  - `items[]`

## Contract Gaps

- Şifre sıfırlama OTP doğrulama endpoint'i yok; müşteri app güvenli parola yenileme akışı tamamlanamıyor.
- Happy Hour için dedicated domain modeli ve API yok; iki ekran tamamen lokal sabit veriyle çalışıyor.
- Favoriler, market beğenileri, organizatör takipleri ve sipariş puanları backend'de kalıcı değil.
- `GET /orders/:orderId` müşteri uygulamasında gerçek zamanlı takip ve fiş güncellemesi için fiilen gerekli hale geliyor.
- `stockStatus` müşteri app tarafından bekleniyor; response üretiminde bu alanın tutarlı derivation kuralı net olmalı.

## Notes

- Stok verisi müşteri app public kontratında doğrudan expose edilmek zorunda değildir; ancak `stockStatus` alanını üretmek için internal kaynak olarak kullanılmalıdır.
- `Favorite` tablosu genişletilirse organizatör takibi için ayrı bir tablo açmadan müşteri uygulaması ihtiyaçları karşılanabilir.
- `client-state` endpoint'leri fallback ve oturum senkronizasyonu için kullanılabilir, ancak kalıcı müşteri verisinin ana kaynağı olarak domain tabloları esas alınmalıdır.
