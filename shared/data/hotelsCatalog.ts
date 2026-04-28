/**
 * Slice-B Phase-11 — hotels catalog.
 *
 * Curated demo dataset (real partner integrations like Booking.com require a
 * commercial agreement). Search/filter/sort/availability is all real on top
 * of this catalog. Booking endpoints flag `isDemoBooking: true`.
 */

export type HotelStarRating = 3 | 4 | 5;

export interface Hotel {
  id: string;
  name: string;
  cityIata: string;
  countryIso2: string;
  starRating: HotelStarRating;
  /** Per-night base rate in USD before taxes/fees. */
  pricePerNightUsd: number;
  /** 0..5 user-rating average. */
  rating: number;
  reviews: number;
  amenities: string[];
  imageQuery: string;
  lat: number;
  lng: number;
  /** Distance to city centre in km. */
  cityCentreKm: number;
}

export const hotelsCatalog: Hotel[] = [
  // Singapore (SIN)
  { id: "h_sin_marina", name: "Marina Bay Sands", cityIata: "SIN", countryIso2: "SG", starRating: 5, pricePerNightUsd: 480, rating: 4.6, reviews: 18420, amenities: ["pool", "spa", "gym", "wifi", "breakfast", "skybar"], imageQuery: "marina bay sands singapore", lat: 1.2834, lng: 103.8607, cityCentreKm: 1.1 },
  { id: "h_sin_raffles", name: "Raffles Singapore", cityIata: "SIN", countryIso2: "SG", starRating: 5, pricePerNightUsd: 720, rating: 4.8, reviews: 5210, amenities: ["pool", "spa", "wifi", "concierge", "restaurant"], imageQuery: "raffles hotel singapore", lat: 1.2945, lng: 103.8546, cityCentreKm: 0.6 },
  { id: "h_sin_pod", name: "The Pod @ Beach Road", cityIata: "SIN", countryIso2: "SG", starRating: 3, pricePerNightUsd: 78, rating: 4.2, reviews: 3120, amenities: ["wifi", "lounge", "kitchen"], imageQuery: "capsule hotel singapore", lat: 1.3024, lng: 103.8585, cityCentreKm: 1.4 },
  { id: "h_sin_clarke", name: "Park Hotel Clarke Quay", cityIata: "SIN", countryIso2: "SG", starRating: 4, pricePerNightUsd: 165, rating: 4.4, reviews: 4220, amenities: ["pool", "wifi", "gym", "breakfast"], imageQuery: "park hotel clarke quay", lat: 1.2899, lng: 103.8462, cityCentreKm: 1.8 },

  // Tokyo (NRT/HND)
  { id: "h_tok_park", name: "Park Hyatt Tokyo", cityIata: "HND", countryIso2: "JP", starRating: 5, pricePerNightUsd: 620, rating: 4.7, reviews: 7910, amenities: ["spa", "pool", "wifi", "gym", "skybar"], imageQuery: "park hyatt tokyo", lat: 35.6859, lng: 139.6913, cityCentreKm: 2.6 },
  { id: "h_tok_shibuya", name: "Shibuya Excel Tokyu", cityIata: "HND", countryIso2: "JP", starRating: 4, pricePerNightUsd: 220, rating: 4.5, reviews: 6810, amenities: ["wifi", "breakfast", "concierge"], imageQuery: "shibuya hotel tokyo", lat: 35.658, lng: 139.7016, cityCentreKm: 1.0 },
  { id: "h_tok_capsule", name: "Nine Hours Shinjuku", cityIata: "HND", countryIso2: "JP", starRating: 3, pricePerNightUsd: 38, rating: 4.0, reviews: 5210, amenities: ["wifi", "shower", "lounge"], imageQuery: "capsule hotel tokyo", lat: 35.6938, lng: 139.7036, cityCentreKm: 0.9 },

  // London (LHR)
  { id: "h_lon_savoy", name: "The Savoy", cityIata: "LHR", countryIso2: "GB", starRating: 5, pricePerNightUsd: 760, rating: 4.7, reviews: 9120, amenities: ["spa", "wifi", "concierge", "restaurant", "bar"], imageQuery: "savoy hotel london", lat: 51.5103, lng: -0.1207, cityCentreKm: 0.5 },
  { id: "h_lon_premier", name: "Premier Inn London Bank", cityIata: "LHR", countryIso2: "GB", starRating: 4, pricePerNightUsd: 165, rating: 4.4, reviews: 12340, amenities: ["wifi", "breakfast", "restaurant"], imageQuery: "premier inn london", lat: 51.5125, lng: -0.0905, cityCentreKm: 1.6 },
  { id: "h_lon_yotel", name: "YOTEL London Shoreditch", cityIata: "LHR", countryIso2: "GB", starRating: 3, pricePerNightUsd: 89, rating: 4.1, reviews: 4210, amenities: ["wifi", "lounge", "kitchen"], imageQuery: "yotel london", lat: 51.5263, lng: -0.0782, cityCentreKm: 2.4 },

  // Dubai (DXB)
  { id: "h_dxb_burj", name: "Burj Al Arab", cityIata: "DXB", countryIso2: "AE", starRating: 5, pricePerNightUsd: 1480, rating: 4.8, reviews: 6720, amenities: ["spa", "pool", "wifi", "private beach", "butler"], imageQuery: "burj al arab dubai", lat: 25.1413, lng: 55.1853, cityCentreKm: 14 },
  { id: "h_dxb_atlantis", name: "Atlantis The Palm", cityIata: "DXB", countryIso2: "AE", starRating: 5, pricePerNightUsd: 540, rating: 4.5, reviews: 24220, amenities: ["pool", "waterpark", "spa", "wifi", "aquarium"], imageQuery: "atlantis the palm dubai", lat: 25.1306, lng: 55.117, cityCentreKm: 22 },
  { id: "h_dxb_rove", name: "Rove Downtown", cityIata: "DXB", countryIso2: "AE", starRating: 4, pricePerNightUsd: 95, rating: 4.4, reviews: 9120, amenities: ["pool", "wifi", "gym", "breakfast"], imageQuery: "rove downtown dubai", lat: 25.193, lng: 55.2769, cityCentreKm: 0.8 },

  // New York (JFK)
  { id: "h_nyc_plaza", name: "The Plaza", cityIata: "JFK", countryIso2: "US", starRating: 5, pricePerNightUsd: 920, rating: 4.6, reviews: 7820, amenities: ["spa", "wifi", "concierge", "restaurant"], imageQuery: "plaza hotel nyc", lat: 40.7644, lng: -73.9743, cityCentreKm: 2.4 },
  { id: "h_nyc_pod", name: "Pod 51", cityIata: "JFK", countryIso2: "US", starRating: 3, pricePerNightUsd: 145, rating: 4.0, reviews: 8420, amenities: ["wifi", "lounge"], imageQuery: "pod hotel nyc", lat: 40.7561, lng: -73.9697, cityCentreKm: 1.2 },
  { id: "h_nyc_marriott", name: "Marriott Marquis Times Square", cityIata: "JFK", countryIso2: "US", starRating: 4, pricePerNightUsd: 320, rating: 4.4, reviews: 21320, amenities: ["pool", "wifi", "gym", "restaurant"], imageQuery: "marriott marquis nyc", lat: 40.7589, lng: -73.985, cityCentreKm: 0.4 },

  // Paris (CDG)
  { id: "h_par_ritz", name: "Ritz Paris", cityIata: "CDG", countryIso2: "FR", starRating: 5, pricePerNightUsd: 1100, rating: 4.8, reviews: 4810, amenities: ["spa", "pool", "wifi", "restaurant", "bar"], imageQuery: "ritz paris", lat: 48.8682, lng: 2.3284, cityCentreKm: 0.6 },
  { id: "h_par_generator", name: "Generator Paris", cityIata: "CDG", countryIso2: "FR", starRating: 3, pricePerNightUsd: 95, rating: 4.2, reviews: 6210, amenities: ["wifi", "bar", "lounge"], imageQuery: "generator paris hostel", lat: 48.8821, lng: 2.3712, cityCentreKm: 3.0 },

  // Bangkok (BKK)
  { id: "h_bkk_mandarin", name: "Mandarin Oriental Bangkok", cityIata: "BKK", countryIso2: "TH", starRating: 5, pricePerNightUsd: 380, rating: 4.8, reviews: 11210, amenities: ["pool", "spa", "wifi", "river view"], imageQuery: "mandarin oriental bangkok", lat: 13.7235, lng: 100.5142, cityCentreKm: 4.0 },
  { id: "h_bkk_silom", name: "Silom Studio 9", cityIata: "BKK", countryIso2: "TH", starRating: 3, pricePerNightUsd: 28, rating: 4.0, reviews: 1820, amenities: ["wifi", "breakfast"], imageQuery: "silom hotel bangkok", lat: 13.7263, lng: 100.5232, cityCentreKm: 3.4 },

  // Mumbai (BOM)
  { id: "h_bom_taj", name: "The Taj Mahal Palace", cityIata: "BOM", countryIso2: "IN", starRating: 5, pricePerNightUsd: 320, rating: 4.7, reviews: 14210, amenities: ["pool", "spa", "wifi", "concierge"], imageQuery: "taj mahal palace mumbai", lat: 18.9217, lng: 72.8332, cityCentreKm: 1.2 },
  { id: "h_bom_treebo", name: "Treebo Trend Suba Galaxy", cityIata: "BOM", countryIso2: "IN", starRating: 3, pricePerNightUsd: 35, rating: 4.1, reviews: 2410, amenities: ["wifi", "breakfast"], imageQuery: "mumbai budget hotel", lat: 19.0760, lng: 72.8777, cityCentreKm: 16 },
];
