import { Role as PrismaRole } from '@prisma/client';
import { SetMetadata } from '@nestjs/common';

export const ROLES_KEY = 'speto:roles';
export const Roles = (...roles: PrismaRole[]) => SetMetadata(ROLES_KEY, roles);
