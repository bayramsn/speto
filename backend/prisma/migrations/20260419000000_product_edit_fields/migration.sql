ALTER TABLE "Product"
  ADD COLUMN "discountedPrice" DECIMAL(10, 2),
  ADD COLUMN "unitType" TEXT NOT NULL DEFAULT 'adet',
  ADD COLUMN "expiryDate" TIMESTAMP(3);
