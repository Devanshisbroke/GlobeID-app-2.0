/**
 * Slice-B Phase-11 — eSIM plans catalog.
 *
 * Real catalog. Activation is the demo part — without a partner like Airalo
 * or Truphone we can't provision a real ICCID. Each plan is `isDemoData`
 * flagged at the route layer.
 */

export interface ESimPlan {
  id: string;
  carrier: string;
  countryIso2: string;
  countryName: string;
  /** GB of data; -1 means unlimited. */
  dataGB: number;
  validityDays: number;
  priceUsd: number;
  /** Network technology. */
  network: "4G" | "5G" | "4G/5G";
  /** Whether the plan supports tethering. */
  hotspotEnabled: boolean;
  /** Whether the plan includes voice/SMS or is data-only. */
  voiceMinutes: number;
  smsCount: number;
}

export const esimCatalog: ESimPlan[] = [
  // United States
  { id: "esim_us_5gb_7d", carrier: "GlobeMobile", countryIso2: "US", countryName: "United States", dataGB: 5, validityDays: 7, priceUsd: 12, network: "4G/5G", hotspotEnabled: true, voiceMinutes: 0, smsCount: 0 },
  { id: "esim_us_10gb_15d", carrier: "GlobeMobile", countryIso2: "US", countryName: "United States", dataGB: 10, validityDays: 15, priceUsd: 22, network: "4G/5G", hotspotEnabled: true, voiceMinutes: 100, smsCount: 200 },
  { id: "esim_us_unlimited_30d", carrier: "GlobeMobile", countryIso2: "US", countryName: "United States", dataGB: -1, validityDays: 30, priceUsd: 49, network: "5G", hotspotEnabled: true, voiceMinutes: 1000, smsCount: -1 },

  // United Kingdom
  { id: "esim_gb_3gb_7d", carrier: "GlobeMobile", countryIso2: "GB", countryName: "United Kingdom", dataGB: 3, validityDays: 7, priceUsd: 9, network: "4G/5G", hotspotEnabled: true, voiceMinutes: 0, smsCount: 0 },
  { id: "esim_gb_10gb_30d", carrier: "GlobeMobile", countryIso2: "GB", countryName: "United Kingdom", dataGB: 10, validityDays: 30, priceUsd: 19, network: "4G/5G", hotspotEnabled: true, voiceMinutes: 100, smsCount: 100 },

  // EU regional
  { id: "esim_eu_5gb_15d", carrier: "EuroNet", countryIso2: "EU", countryName: "Europe (33 countries)", dataGB: 5, validityDays: 15, priceUsd: 16, network: "4G/5G", hotspotEnabled: true, voiceMinutes: 0, smsCount: 0 },
  { id: "esim_eu_20gb_30d", carrier: "EuroNet", countryIso2: "EU", countryName: "Europe (33 countries)", dataGB: 20, validityDays: 30, priceUsd: 32, network: "4G/5G", hotspotEnabled: true, voiceMinutes: 200, smsCount: 200 },

  // India
  { id: "esim_in_3gb_10d", carrier: "BharatNet", countryIso2: "IN", countryName: "India", dataGB: 3, validityDays: 10, priceUsd: 7, network: "4G", hotspotEnabled: true, voiceMinutes: 0, smsCount: 0 },
  { id: "esim_in_10gb_30d", carrier: "BharatNet", countryIso2: "IN", countryName: "India", dataGB: 10, validityDays: 30, priceUsd: 12, network: "4G/5G", hotspotEnabled: true, voiceMinutes: 100, smsCount: 100 },

  // UAE
  { id: "esim_ae_5gb_15d", carrier: "EmiratesMobile", countryIso2: "AE", countryName: "United Arab Emirates", dataGB: 5, validityDays: 15, priceUsd: 18, network: "5G", hotspotEnabled: true, voiceMinutes: 0, smsCount: 0 },

  // Singapore
  { id: "esim_sg_5gb_8d", carrier: "GlobeMobile", countryIso2: "SG", countryName: "Singapore", dataGB: 5, validityDays: 8, priceUsd: 10, network: "5G", hotspotEnabled: true, voiceMinutes: 0, smsCount: 0 },

  // Japan
  { id: "esim_jp_5gb_8d", carrier: "Sakura Mobile", countryIso2: "JP", countryName: "Japan", dataGB: 5, validityDays: 8, priceUsd: 14, network: "4G/5G", hotspotEnabled: true, voiceMinutes: 0, smsCount: 0 },
  { id: "esim_jp_10gb_15d", carrier: "Sakura Mobile", countryIso2: "JP", countryName: "Japan", dataGB: 10, validityDays: 15, priceUsd: 22, network: "4G/5G", hotspotEnabled: true, voiceMinutes: 100, smsCount: 100 },

  // Thailand
  { id: "esim_th_3gb_8d", carrier: "ThaiNet", countryIso2: "TH", countryName: "Thailand", dataGB: 3, validityDays: 8, priceUsd: 8, network: "4G", hotspotEnabled: true, voiceMinutes: 0, smsCount: 0 },
  { id: "esim_th_10gb_30d", carrier: "ThaiNet", countryIso2: "TH", countryName: "Thailand", dataGB: 10, validityDays: 30, priceUsd: 18, network: "4G/5G", hotspotEnabled: true, voiceMinutes: 0, smsCount: 0 },

  // Indonesia
  { id: "esim_id_5gb_15d", carrier: "TelkomIndo", countryIso2: "ID", countryName: "Indonesia", dataGB: 5, validityDays: 15, priceUsd: 12, network: "4G", hotspotEnabled: true, voiceMinutes: 0, smsCount: 0 },

  // Global
  { id: "esim_global_3gb_15d", carrier: "World eSIM", countryIso2: "GLOBAL", countryName: "Global (130 countries)", dataGB: 3, validityDays: 15, priceUsd: 19, network: "4G/5G", hotspotEnabled: true, voiceMinutes: 0, smsCount: 0 },
  { id: "esim_global_10gb_30d", carrier: "World eSIM", countryIso2: "GLOBAL", countryName: "Global (130 countries)", dataGB: 10, validityDays: 30, priceUsd: 39, network: "4G/5G", hotspotEnabled: true, voiceMinutes: 0, smsCount: 0 },
];
