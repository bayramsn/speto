import { Role as PrismaRole } from '@prisma/client';

export interface AccessTokenPayload {
  sub: string;
  email: string;
  role: PrismaRole;
  vendorId: string | null;
}
