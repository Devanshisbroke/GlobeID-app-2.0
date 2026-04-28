/**
 * Slice-B Phase-11 — local services catalog (region-aware).
 *
 * Curated subset, keyed off the active trip country. Each entry has
 * enough metadata for the UI to render an actionable card (call / map /
 * save) without faking a marketplace.
 */

export type ServiceKind =
  | "embassy"
  | "hospital"
  | "pharmacy"
  | "laundry"
  | "sim_store"
  | "atm"
  | "police"
  | "tourism_info"
  | "lost_property";

export interface LocalService {
  id: string;
  countryIso2: string;
  cityIata: string;
  kind: ServiceKind;
  name: string;
  /** Human address. */
  address: string;
  /** E.164 contact, when applicable. */
  phoneE164: string | null;
  /** 24/7 if true; otherwise typical hours string. */
  hours247: boolean;
  hours: string | null;
  /** Languages spoken at the desk. */
  languages: string[];
  /** Whether the service is free-of-charge for travellers. */
  free: boolean;
  lat: number;
  lng: number;
}

export const localServicesCatalog: LocalService[] = [
  // Singapore
  { id: "ls_sg_indemb", countryIso2: "SG", cityIata: "SIN", kind: "embassy", name: "High Commission of India", address: "31 Grange Rd, Singapore 239702", phoneE164: "+6567126777", hours247: false, hours: "09:00–17:30 Mon–Fri", languages: ["en", "hi"], free: true, lat: 1.302, lng: 103.829 },
  { id: "ls_sg_raffles_hosp", countryIso2: "SG", cityIata: "SIN", kind: "hospital", name: "Raffles Hospital", address: "585 N Bridge Rd, Singapore 188770", phoneE164: "+6563111111", hours247: true, hours: null, languages: ["en", "zh"], free: false, lat: 1.302, lng: 103.857 },
  { id: "ls_sg_simlim_sim", countryIso2: "SG", cityIata: "SIN", kind: "sim_store", name: "Singtel Sim Lim Square", address: "1 Rochor Canal Rd, Singapore 188504", phoneE164: "+6568382299", hours247: false, hours: "11:00–21:00 daily", languages: ["en", "zh"], free: false, lat: 1.305, lng: 103.852 },
  { id: "ls_sg_changi_lost", countryIso2: "SG", cityIata: "SIN", kind: "lost_property", name: "Changi Airport Lost & Found", address: "Changi Airport Terminal 3, Level 1", phoneE164: "+6565956868", hours247: true, hours: null, languages: ["en"], free: true, lat: 1.358, lng: 103.989 },

  // Tokyo
  { id: "ls_jp_indemb", countryIso2: "JP", cityIata: "HND", kind: "embassy", name: "Embassy of India, Tokyo", address: "2-2-11 Kudan Minami, Chiyoda-ku, Tokyo", phoneE164: "+81332622391", hours247: false, hours: "09:00–17:30 Mon–Fri", languages: ["en", "ja", "hi"], free: true, lat: 35.692, lng: 139.745 },
  { id: "ls_jp_st_lukes", countryIso2: "JP", cityIata: "HND", kind: "hospital", name: "St. Luke's International Hospital", address: "9-1 Akashi-cho, Chuo-ku, Tokyo", phoneE164: "+81335415151", hours247: true, hours: null, languages: ["en", "ja"], free: false, lat: 35.668, lng: 139.778 },
  { id: "ls_jp_softbank_sim", countryIso2: "JP", cityIata: "HND", kind: "sim_store", name: "SoftBank Shop Shibuya", address: "Shibuya Center-Gai, Tokyo", phoneE164: null, hours247: false, hours: "10:00–21:00 daily", languages: ["en", "ja"], free: false, lat: 35.660, lng: 139.700 },

  // London
  { id: "ls_gb_indhc", countryIso2: "GB", cityIata: "LHR", kind: "embassy", name: "High Commission of India, London", address: "India House, Aldwych, London WC2B 4NA", phoneE164: "+442078368484", hours247: false, hours: "09:00–17:00 Mon–Fri", languages: ["en", "hi"], free: true, lat: 51.513, lng: -0.117 },
  { id: "ls_gb_uclh", countryIso2: "GB", cityIata: "LHR", kind: "hospital", name: "University College Hospital", address: "235 Euston Rd, London NW1 2BU", phoneE164: "+442034567890", hours247: true, hours: null, languages: ["en"], free: false, lat: 51.524, lng: -0.135 },

  // Dubai
  { id: "ls_ae_indcons", countryIso2: "AE", cityIata: "DXB", kind: "embassy", name: "Consulate General of India, Dubai", address: "Al Hamriya Diplomatic Enclave, Dubai", phoneE164: "+97143971222", hours247: false, hours: "08:30–13:30 Sun–Thu", languages: ["en", "hi", "ar"], free: true, lat: 25.252, lng: 55.318 },
  { id: "ls_ae_rashid_hosp", countryIso2: "AE", cityIata: "DXB", kind: "hospital", name: "Rashid Hospital", address: "Oud Metha, Dubai", phoneE164: "+97143371111", hours247: true, hours: null, languages: ["en", "ar"], free: false, lat: 25.232, lng: 55.328 },

  // New York
  { id: "ls_us_indcons", countryIso2: "US", cityIata: "JFK", kind: "embassy", name: "Consulate General of India, New York", address: "3 East 64th St, New York, NY 10065", phoneE164: "+12127740600", hours247: false, hours: "09:30–13:00 Mon–Fri", languages: ["en", "hi"], free: true, lat: 40.768, lng: -73.969 },
  { id: "ls_us_mtsinai", countryIso2: "US", cityIata: "JFK", kind: "hospital", name: "Mount Sinai Hospital", address: "1 Gustave L Levy Pl, New York, NY 10029", phoneE164: "+12122416500", hours247: true, hours: null, languages: ["en", "es"], free: false, lat: 40.79, lng: -73.953 },

  // Mumbai
  { id: "ls_in_kem", countryIso2: "IN", cityIata: "BOM", kind: "hospital", name: "KEM Hospital", address: "Acharya Donde Marg, Parel, Mumbai", phoneE164: "+912224107000", hours247: true, hours: null, languages: ["en", "hi", "mr"], free: true, lat: 19.0, lng: 72.842 },
  { id: "ls_in_apollo_pharm", countryIso2: "IN", cityIata: "BOM", kind: "pharmacy", name: "Apollo Pharmacy Bandra", address: "Linking Rd, Bandra West, Mumbai", phoneE164: "+91226000000", hours247: true, hours: null, languages: ["en", "hi"], free: false, lat: 19.06, lng: 72.836 },

  // Paris
  { id: "ls_fr_indemb", countryIso2: "FR", cityIata: "CDG", kind: "embassy", name: "Embassy of India, Paris", address: "13-15 Rue Alfred Dehodencq, Paris 75016", phoneE164: "+33140507070", hours247: false, hours: "09:00–17:30 Mon–Fri", languages: ["en", "fr", "hi"], free: true, lat: 48.860, lng: 2.270 },
  { id: "ls_fr_pitie", countryIso2: "FR", cityIata: "CDG", kind: "hospital", name: "Hôpital Pitié-Salpêtrière", address: "47-83 Boulevard de l'Hôpital, Paris 75013", phoneE164: "+33142162000", hours247: true, hours: null, languages: ["en", "fr"], free: false, lat: 48.838, lng: 2.366 },

  // Bangkok
  { id: "ls_th_indemb", countryIso2: "TH", cityIata: "BKK", kind: "embassy", name: "Embassy of India, Bangkok", address: "46 Soi Prasarnmitr (Sukhumvit 23), Bangkok", phoneE164: "+6622580300", hours247: false, hours: "09:00–17:30 Mon–Fri", languages: ["en", "th", "hi"], free: true, lat: 13.738, lng: 100.566 },
  { id: "ls_th_bumrungrad", countryIso2: "TH", cityIata: "BKK", kind: "hospital", name: "Bumrungrad International Hospital", address: "33 Sukhumvit 3, Bangkok", phoneE164: "+6620111111", hours247: true, hours: null, languages: ["en", "th"], free: false, lat: 13.745, lng: 100.553 },
];
