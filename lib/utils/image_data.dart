const Map<String, String> districtImages = {
  'Alappuzha':
      'https://images.unsplash.com/photo-1593693397690-362cb9666fc2?auto=format&fit=crop&q=80', // Houseboats
  'Ernakulam':
      'https://images.unsplash.com/photo-1582510003544-4d00b1f74d6d?auto=format&fit=crop&q=80', // Marine drive / Kochi city
  'Idukki':
      'https://images.unsplash.com/photo-1642435775438-e6b360ae6f5c?auto=format&fit=crop&q=80', // Munnar tea gardens
  'Kannur':
      'https://images.unsplash.com/photo-1626082896492-766af4eb65ed?auto=format&fit=crop&q=80', // Theyyam/Beaches
  'Kasaragod':
      'https://images.unsplash.com/photo-1590050720448-971cc73d6e53?auto=format&fit=crop&q=80', // Forts
  'Kollam':
      'https://images.unsplash.com/photo-1563721345-42099f691dfc?auto=format&fit=crop&q=80', // Ashtamudi lake
  'Kottayam':
      'https://images.unsplash.com/photo-1596773344605-df1a3f6ee160?auto=format&fit=crop&q=80', // Backwaters/Churches
  'Kozhikode':
      'https://images.unsplash.com/photo-1628103130177-33a7dbeceaa3?auto=format&fit=crop&q=80', // Beach
  'Malappuram':
      'https://images.unsplash.com/photo-1647854612349-f53e34b17c7d?auto=format&fit=crop&q=80', // Teak Museum area / Hills
  'Palakkad':
      'https://images.unsplash.com/photo-1605389476742-df12921aa216?auto=format&fit=crop&q=80', // Palakkad Fort / Gap
  'Pathanamthitta':
      'https://images.unsplash.com/photo-1625904835711-0eb11a684b91?auto=format&fit=crop&q=80', // Sabarimala / Hills
  'Thiruvananthapuram':
      'https://images.unsplash.com/photo-1598448374880-97b7de3d7395?auto=format&fit=crop&q=80', // Padmanabhaswamy / Kovalam
  'Thrissur':
      'https://images.unsplash.com/photo-1623812239690-3ae3a702b8e3?auto=format&fit=crop&q=80', // Pooram / Temples
  'Wayanad':
      'https://images.unsplash.com/photo-1596205327263-547e81cc30fa?auto=format&fit=crop&q=80', // Ghats / Chembra
};

const Map<String, String> defaultCityImages = {
  // Ernakulam Specific
  'Kakkanad':
      'https://images.unsplash.com/photo-1497215728101-856f4ea42174?auto=format&fit=crop&q=80', // Tech park vibe
  'Kalamassery':
      'https://images.unsplash.com/photo-1517486808906-6ca8b3f04846?auto=format&fit=crop&q=80',
  'Edappally':
      'https://images.unsplash.com/photo-1555529733-0e670560f4e1?auto=format&fit=crop&q=80', // Mall vibe
  'MG Road':
      'https://images.unsplash.com/photo-1519001389470-34a9ef4f85e3?auto=format&fit=crop&q=80', // City street

  // Fallback for others
  'default':
      'https://images.unsplash.com/photo-1449844908441-8829872d2607?auto=format&fit=crop&q=80', // General aesthetic city/town
};

String getCityImage(String city) {
  return defaultCityImages[city] ?? defaultCityImages['default']!;
}

String getDistrictImage(String district) {
  return districtImages[district] ?? defaultCityImages['default']!;
}
