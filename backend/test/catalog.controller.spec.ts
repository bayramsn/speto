import 'reflect-metadata';

import { Role as PrismaRole } from '@prisma/client';

import { CatalogController } from '../src/catalog/catalog.controller';
import { ROLES_KEY } from '../src/security/roles.decorator';

function methodRoles(name: keyof CatalogController) {
  return Reflect.getMetadata(ROLES_KEY, CatalogController.prototype[name]) as
    | PrismaRole[]
    | undefined;
}

describe('CatalogController role metadata', () => {
  it('allows vendor access on vendor-scoped catalog endpoints', () => {
    expect(methodRoles('adminVendors')).toEqual([
      PrismaRole.ADMIN,
      PrismaRole.VENDOR,
    ]);
    expect(methodRoles('updateVendor')).toEqual([
      PrismaRole.ADMIN,
      PrismaRole.VENDOR,
    ]);
    expect(methodRoles('adminSections')).toEqual([
      PrismaRole.ADMIN,
      PrismaRole.VENDOR,
    ]);
    expect(methodRoles('createSection')).toEqual([
      PrismaRole.ADMIN,
      PrismaRole.VENDOR,
    ]);
    expect(methodRoles('updateSection')).toEqual([
      PrismaRole.ADMIN,
      PrismaRole.VENDOR,
    ]);
    expect(methodRoles('adminProducts')).toEqual([
      PrismaRole.ADMIN,
      PrismaRole.VENDOR,
    ]);
    expect(methodRoles('createProduct')).toEqual([
      PrismaRole.ADMIN,
      PrismaRole.VENDOR,
    ]);
    expect(methodRoles('updateProduct')).toEqual([
      PrismaRole.ADMIN,
      PrismaRole.VENDOR,
    ]);
  });

  it('keeps admin-only catalog endpoints restricted', () => {
    expect(methodRoles('createVendor')).toEqual([PrismaRole.ADMIN]);
    expect(methodRoles('adminEvents')).toEqual([PrismaRole.ADMIN]);
    expect(methodRoles('updateEvent')).toEqual([PrismaRole.ADMIN]);
    expect(methodRoles('adminContentBlocks')).toEqual([PrismaRole.ADMIN]);
    expect(methodRoles('updateContentBlock')).toEqual([PrismaRole.ADMIN]);
  });
});
