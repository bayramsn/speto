import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

export interface CatalogManifestProduct {
  id: string;
  title: string;
  description: string;
  priceText: string;
  unitPrice: number;
  image: string;
  displayOrder: number;
}

export interface CatalogManifestSection {
  id: string;
  key: string;
  label: string;
  displayOrder: number;
  products: CatalogManifestProduct[];
}

export interface CatalogManifestRestaurant {
  id: string;
  vendorId: string;
  title: string;
  image: string;
  cuisine: string;
  etaMin: number;
  etaMax: number;
  ratingValue: number;
  promo: string;
  studentFriendly: boolean;
  displayOrder: number;
  sections: CatalogManifestSection[];
}

export interface CatalogManifestHighlight {
  id: string;
  label: string;
  icon: string;
  displayOrder: number;
}

export interface CatalogManifestMarket {
  id: string;
  vendorId: string;
  title: string;
  subtitle: string;
  meta: string;
  image: string;
  badge: string;
  rewardLabel: string;
  ratingLabel: string;
  distanceLabel: string;
  etaLabel: string;
  promoLabel: string;
  workingHoursLabel: string;
  minOrderLabel: string;
  deliveryWindowLabel: string;
  reviewCountLabel: string;
  announcement: string;
  bundleTitle: string;
  bundleDescription: string;
  bundlePrice: string;
  heroTitle: string;
  heroSubtitle: string;
  displayOrder: number;
  highlights: CatalogManifestHighlight[];
  sections: CatalogManifestSection[];
}

export interface CatalogManifestEvent {
  id: string;
  title: string;
  venue: string;
  district: string;
  dateLabel: string;
  timeLabel: string;
  image: string;
  pointsCost: number;
  primaryTag: string;
  secondaryTag: string;
  description: string;
  organizer: string;
  participantLabel: string;
  ticketCategory: string;
  locationTitle: string;
  locationSubtitle: string;
  displayOrder: number;
}

export interface CatalogManifestHomeHero {
  id: string;
  title: string;
  subtitle: string;
  badge: string;
  image: string;
  actionLabel: string;
  screen: string;
  displayOrder: number;
}

export interface CatalogManifestQuickFilter {
  id: string;
  label: string;
  icon: string;
  screen: string;
  highlight: boolean;
  displayOrder: number;
}

export interface CatalogManifestDiscoveryFilter {
  id: string;
  label: string;
  displayOrder: number;
}

export interface CatalogManifest {
  contentVersion: string;
  home: {
    heroes: CatalogManifestHomeHero[];
    quickFilters: CatalogManifestQuickFilter[];
    discoveryFilters: CatalogManifestDiscoveryFilter[];
  };
  restaurants: CatalogManifestRestaurant[];
  markets: CatalogManifestMarket[];
  events: CatalogManifestEvent[];
}

let cachedManifest: CatalogManifest | null = null;

export function loadCatalogManifest(): CatalogManifest {
  if (cachedManifest) {
    return cachedManifest;
  }

  const manifestPath = resolve(process.cwd(), '../assets/data/catalog_manifest.json');
  const manifest = JSON.parse(readFileSync(manifestPath, 'utf8')) as CatalogManifest;
  cachedManifest = manifest;
  return manifest;
}
