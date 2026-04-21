import { Injectable, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit {
  async onModuleInit() {
    await this.$connect();
    await this.ensureOtherBusinessStorefrontSupport();
  }

  private async ensureOtherBusinessStorefrontSupport() {
    await this.$executeRawUnsafe(
      `ALTER TYPE "StorefrontType" ADD VALUE IF NOT EXISTS 'OTHER_BUSINESS'`,
    );
    await this.$executeRawUnsafe(`
      UPDATE "Vendor"
      SET
        "storefrontType" = 'OTHER_BUSINESS'::"StorefrontType",
        "category" = 'Diğer İşletme'
      WHERE "category" IN ('Happy Hour', 'Diğer İşletme', 'Diger Isletme', 'Other Business')
         OR "storefrontType"::text = 'OTHER_BUSINESS'
    `);
  }
}
