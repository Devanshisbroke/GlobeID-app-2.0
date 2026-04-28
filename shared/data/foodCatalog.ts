/**
 * Slice-B Phase-11 — restaurants + menus catalog.
 *
 * Real cuisine catalog. Order placement is the demo part — without partner
 * APIs (Swiggy, Zomato, DoorDash) we can't dispatch a real courier.
 */

export type Cuisine =
  | "indian"
  | "thai"
  | "japanese"
  | "italian"
  | "american"
  | "chinese"
  | "mexican"
  | "vegan"
  | "cafe";

export type PriceTier = "$" | "$$" | "$$$";

export interface MenuItem {
  id: string;
  name: string;
  description: string;
  priceUsd: number;
  category: "main" | "starter" | "drink" | "dessert" | "side";
  vegetarian: boolean;
  spiceLevel: 0 | 1 | 2 | 3;
}

export interface Restaurant {
  id: string;
  name: string;
  cityIata: string;
  countryIso2: string;
  cuisine: Cuisine;
  priceTier: PriceTier;
  rating: number;
  reviews: number;
  /** Average prep + delivery time minutes. */
  etaMinutes: number;
  deliveryFeeUsd: number;
  imageQuery: string;
  menu: MenuItem[];
}

export const restaurantsCatalog: Restaurant[] = [
  // Singapore
  {
    id: "r_sin_jumbo",
    name: "Jumbo Seafood",
    cityIata: "SIN",
    countryIso2: "SG",
    cuisine: "chinese",
    priceTier: "$$$",
    rating: 4.5,
    reviews: 9210,
    etaMinutes: 45,
    deliveryFeeUsd: 4.5,
    imageQuery: "chilli crab singapore",
    menu: [
      { id: "rsi_1", name: "Chilli crab (1kg)", description: "Singapore chilli crab with mantou buns", priceUsd: 68, category: "main", vegetarian: false, spiceLevel: 2 },
      { id: "rsi_2", name: "Black pepper crab", description: "Whole crab with house black pepper sauce", priceUsd: 72, category: "main", vegetarian: false, spiceLevel: 2 },
      { id: "rsi_3", name: "Cereal prawns", description: "Crispy prawns tossed in cereal butter", priceUsd: 28, category: "starter", vegetarian: false, spiceLevel: 0 },
    ],
  },
  {
    id: "r_sin_maxwell",
    name: "Maxwell Hawker — Tian Tian Chicken Rice",
    cityIata: "SIN",
    countryIso2: "SG",
    cuisine: "chinese",
    priceTier: "$",
    rating: 4.4,
    reviews: 18210,
    etaMinutes: 30,
    deliveryFeeUsd: 2.5,
    imageQuery: "hainanese chicken rice singapore",
    menu: [
      { id: "rsm_1", name: "Hainanese chicken rice", description: "Steamed chicken, fragrant rice, chilli sauce", priceUsd: 6.5, category: "main", vegetarian: false, spiceLevel: 1 },
      { id: "rsm_2", name: "Roast chicken rice", description: "Soya-roasted chicken with rice", priceUsd: 7, category: "main", vegetarian: false, spiceLevel: 0 },
    ],
  },

  // Tokyo
  {
    id: "r_tok_ichiran",
    name: "Ichiran Shibuya",
    cityIata: "HND",
    countryIso2: "JP",
    cuisine: "japanese",
    priceTier: "$$",
    rating: 4.5,
    reviews: 22410,
    etaMinutes: 35,
    deliveryFeeUsd: 3.5,
    imageQuery: "ichiran ramen tokyo",
    menu: [
      { id: "rti_1", name: "Tonkotsu ramen", description: "Classic pork-broth ramen with chashu", priceUsd: 12, category: "main", vegetarian: false, spiceLevel: 1 },
      { id: "rti_2", name: "Extra noodles (kaedama)", description: "Half portion noodle refill", priceUsd: 2.5, category: "side", vegetarian: false, spiceLevel: 0 },
    ],
  },

  // London
  {
    id: "r_lon_dishoom",
    name: "Dishoom Shoreditch",
    cityIata: "LHR",
    countryIso2: "GB",
    cuisine: "indian",
    priceTier: "$$",
    rating: 4.6,
    reviews: 31420,
    etaMinutes: 40,
    deliveryFeeUsd: 4,
    imageQuery: "dishoom london",
    menu: [
      { id: "rld_1", name: "Black house daal", description: "24-hour cooked black urad daal", priceUsd: 14, category: "main", vegetarian: true, spiceLevel: 1 },
      { id: "rld_2", name: "Chicken berry britannia", description: "Chicken biryani with sour barberries", priceUsd: 18, category: "main", vegetarian: false, spiceLevel: 1 },
      { id: "rld_3", name: "Bacon naan roll", description: "Smoked streaky bacon, cream cheese, chilli tomato jam", priceUsd: 11, category: "starter", vegetarian: false, spiceLevel: 1 },
    ],
  },

  // Bangkok
  {
    id: "r_bkk_jay_fai",
    name: "Jay Fai (Raan Jay Fai)",
    cityIata: "BKK",
    countryIso2: "TH",
    cuisine: "thai",
    priceTier: "$$$",
    rating: 4.6,
    reviews: 8210,
    etaMinutes: 60,
    deliveryFeeUsd: 5,
    imageQuery: "jay fai crab omelette bangkok",
    menu: [
      { id: "rbj_1", name: "Crab omelette", description: "Whole crab inside crispy omelette", priceUsd: 38, category: "main", vegetarian: false, spiceLevel: 0 },
      { id: "rbj_2", name: "Drunken noodles", description: "Pad kee mao with seafood", priceUsd: 14, category: "main", vegetarian: false, spiceLevel: 3 },
    ],
  },
  {
    id: "r_bkk_som_tam",
    name: "Som Tam Nua",
    cityIata: "BKK",
    countryIso2: "TH",
    cuisine: "thai",
    priceTier: "$",
    rating: 4.3,
    reviews: 9810,
    etaMinutes: 30,
    deliveryFeeUsd: 2,
    imageQuery: "som tam thai",
    menu: [
      { id: "rbs_1", name: "Som tam Thai", description: "Green papaya salad with peanut and dried shrimp", priceUsd: 5, category: "main", vegetarian: false, spiceLevel: 3 },
      { id: "rbs_2", name: "Larb gai", description: "Spicy minced chicken salad", priceUsd: 6, category: "main", vegetarian: false, spiceLevel: 2 },
    ],
  },

  // Mumbai
  {
    id: "r_bom_britannia",
    name: "Britannia & Co.",
    cityIata: "BOM",
    countryIso2: "IN",
    cuisine: "indian",
    priceTier: "$$",
    rating: 4.5,
    reviews: 6210,
    etaMinutes: 45,
    deliveryFeeUsd: 2,
    imageQuery: "berry pulao mumbai",
    menu: [
      { id: "rbb_1", name: "Berry pulao", description: "Persian-style mutton/chicken pulao with barberries", priceUsd: 7, category: "main", vegetarian: false, spiceLevel: 1 },
      { id: "rbb_2", name: "Salli boti", description: "Parsi mutton with crispy potato sticks", priceUsd: 9, category: "main", vegetarian: false, spiceLevel: 1 },
    ],
  },
  {
    id: "r_bom_swati",
    name: "Swati Snacks",
    cityIata: "BOM",
    countryIso2: "IN",
    cuisine: "vegan",
    priceTier: "$$",
    rating: 4.4,
    reviews: 4120,
    etaMinutes: 35,
    deliveryFeeUsd: 1.5,
    imageQuery: "panki dahi puri mumbai",
    menu: [
      { id: "rbsw_1", name: "Pani puri", description: "Six crispy puris with spiced water", priceUsd: 4, category: "starter", vegetarian: true, spiceLevel: 2 },
      { id: "rbsw_2", name: "Pankhi (3pc)", description: "Banana-leaf rice crepe", priceUsd: 5, category: "main", vegetarian: true, spiceLevel: 1 },
    ],
  },

  // Dubai
  {
    id: "r_dxb_ravi",
    name: "Ravi Restaurant Satwa",
    cityIata: "DXB",
    countryIso2: "AE",
    cuisine: "indian",
    priceTier: "$",
    rating: 4.4,
    reviews: 12810,
    etaMinutes: 40,
    deliveryFeeUsd: 3,
    imageQuery: "ravi restaurant dubai",
    menu: [
      { id: "rdr_1", name: "Mutton karahi", description: "Slow-cooked mutton in spiced gravy", priceUsd: 9, category: "main", vegetarian: false, spiceLevel: 2 },
      { id: "rdr_2", name: "Chicken biryani (full)", description: "Aromatic basmati biryani with chicken", priceUsd: 7, category: "main", vegetarian: false, spiceLevel: 1 },
    ],
  },

  // New York
  {
    id: "r_nyc_katz",
    name: "Katz's Delicatessen",
    cityIata: "JFK",
    countryIso2: "US",
    cuisine: "american",
    priceTier: "$$",
    rating: 4.5,
    reviews: 41210,
    etaMinutes: 35,
    deliveryFeeUsd: 4,
    imageQuery: "katz pastrami sandwich",
    menu: [
      { id: "rnk_1", name: "Pastrami on rye", description: "Hand-cut pastrami, rye, mustard, pickles", priceUsd: 24, category: "main", vegetarian: false, spiceLevel: 0 },
      { id: "rnk_2", name: "Matzo ball soup", description: "Chicken broth with matzo balls", priceUsd: 9, category: "starter", vegetarian: false, spiceLevel: 0 },
    ],
  },
];
