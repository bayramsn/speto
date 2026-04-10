import {
  MiddlewareConsumer,
  Module,
  NestModule,
  RequestMethod,
} from '@nestjs/common';

import { AppDataModule } from './app-data/app-data.module';
import { RequestContextMiddleware } from './app-data/request-context.middleware';
import { AuthModule } from './auth/auth.module';
import { CatalogModule } from './catalog/catalog.module';
import { ClientStateModule } from './client-state/client-state.module';
import { HealthModule } from './health/health.module';
import { IntegrationsModule } from './integrations/integrations.module';
import { InventoryModule } from './inventory/inventory.module';
import { OpsModule } from './ops/ops.module';
import { OffersModule } from './offers/offers.module';
import { OrdersModule } from './orders/orders.module';
import { ProfileModule } from './profile/profile.module';
import { SupportModule } from './support/support.module';
import { WalletModule } from './wallet/wallet.module';

@Module({
  imports: [
    AppDataModule,
    HealthModule,
    AuthModule,
    CatalogModule,
    ClientStateModule,
    InventoryModule,
    OpsModule,
    OffersModule,
    IntegrationsModule,
    OrdersModule,
    ProfileModule,
    SupportModule,
    WalletModule,
  ],
  providers: [RequestContextMiddleware],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(RequestContextMiddleware).forRoutes({
      path: '*path',
      method: RequestMethod.ALL,
    });
  }
}
