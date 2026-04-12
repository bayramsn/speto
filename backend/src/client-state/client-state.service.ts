import { BadRequestException, Injectable } from '@nestjs/common';

type JsonObject = Record<string, unknown>;

@Injectable()
export class ClientStateService {
  private session: JsonObject | null = null;
  private registrationDraft: JsonObject | null = null;
  private passwordResetEmail: string | null = null;
  private readonly accountPasswords = new Map<string, string>();
  private readonly commerceSnapshots = new Map<string, JsonObject>();

  readSession() {
    return this.wrap(this.session);
  }

  writeSession(payload: unknown) {
    this.session = this.asJsonObject(payload, 'session');
    return this.wrap(this.session);
  }

  clearSession() {
    this.session = null;
    return { success: true };
  }

  readRegistrationDraft() {
    return this.wrap(this.registrationDraft);
  }

  writeRegistrationDraft(payload: unknown) {
    this.registrationDraft = this.asJsonObject(payload, 'registrationDraft');
    return this.wrap(this.registrationDraft);
  }

  clearRegistrationDraft() {
    this.registrationDraft = null;
    return { success: true };
  }

  readPasswordResetEmail() {
    return this.wrap(this.passwordResetEmail);
  }

  writePasswordResetEmail(email: string) {
    this.passwordResetEmail = this.normalizeEmail(email);
    return this.wrap(this.passwordResetEmail);
  }

  clearPasswordResetEmail() {
    this.passwordResetEmail = null;
    return { success: true };
  }

  readAccountPassword(email: string) {
    return this.wrap(this.accountPasswords.get(this.normalizeEmail(email)) ?? null);
  }

  writeAccountPassword(email: string, password: string) {
    this.accountPasswords.set(this.normalizeEmail(email), password);
    return { success: true };
  }

  deleteAccountPassword(email: string) {
    this.accountPasswords.delete(this.normalizeEmail(email));
    return { success: true };
  }

  readCommerceSnapshot(scopeKey?: string) {
    const snapshot = this.commerceSnapshots.get(this.normalizeScopeKey(scopeKey)) ?? null;
    return this.wrap(snapshot);
  }

  writeCommerceSnapshot(payload: unknown, scopeKey?: string) {
    const snapshot = this.asJsonObject(payload, 'commerceSnapshot');
    this.commerceSnapshots.set(this.normalizeScopeKey(scopeKey), snapshot);
    return this.wrap(snapshot);
  }

  private wrap(data: unknown) {
    return { data: this.clone(data) };
  }

  private asJsonObject(payload: unknown, label: string) {
    if (payload == null || Array.isArray(payload) || typeof payload !== 'object') {
      throw new BadRequestException(`${label} must be a JSON object`);
    }
    return this.clone(payload as JsonObject);
  }

  private normalizeEmail(email: string) {
    return email.trim().toLowerCase();
  }

  private normalizeScopeKey(scopeKey?: string) {
    const normalized = scopeKey?.trim().toLowerCase();
    return normalized && normalized.length > 0 ? normalized : 'guest';
  }

  private clone<T>(value: T): T {
    if (value == null) {
      return value;
    }
    return JSON.parse(JSON.stringify(value)) as T;
  }
}
