UPDATE "Vendor"
SET
  "storefrontType" = 'OTHER_BUSINESS'::"StorefrontType",
  "category" = 'Diğer İşletme'
WHERE "category" IN ('Happy Hour', 'Diğer İşletme', 'Diger Isletme', 'Other Business')
   OR "storefrontType"::text = 'OTHER_BUSINESS';
