import { Injectable } from '@nestjs/common';
import { Role as PrismaRole } from '@prisma/client';
import { AsyncLocalStorage } from 'node:async_hooks';

export type RequestContextAuthState = {
  accessToken?: string;
  userId?: string;
  email?: string;
  role?: PrismaRole;
  vendorId?: string | null;
};

@Injectable()
export class RequestContextService {
  private readonly storage = new AsyncLocalStorage<RequestContextAuthState>();

  run<T>(state: RequestContextAuthState, callback: () => T): T {
    return this.storage.run(state, callback);
  }

  setAuth(state: RequestContextAuthState) {
    const currentState = this.storage.getStore();
    if (currentState == null) {
      return;
    }
    Object.assign(currentState, state);
  }

  get accessToken(): string | undefined {
    return this.storage.getStore()?.accessToken;
  }

  get userId(): string | undefined {
    return this.storage.getStore()?.userId;
  }

  get email(): string | undefined {
    return this.storage.getStore()?.email;
  }

  get role(): PrismaRole | undefined {
    return this.storage.getStore()?.role;
  }

  get vendorId(): string | null | undefined {
    return this.storage.getStore()?.vendorId;
  }
}
