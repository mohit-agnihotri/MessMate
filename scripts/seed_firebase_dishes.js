// =============================================================
// seed_firebase_dishes.js
// One-time seeder: populates Firestore `global_dishes` collection
// with 1000 Indian mess dishes + HD images from Pexels API.
//
// Rules:
//  1. Before calling Pexels, check if dish already exists in
//     Firestore with a valid imageUrl -> skip if yes.
//  2. Pexels is called ONCE per dish, result cached in Firestore.
//  3. Safe to re-run -- idempotent, no duplicates created.
//
// Usage:
//  1. cd scripts && npm install
//  2. Copy .env.example to .env and set PEXELS_API_KEY
//  3. Place Firebase service account JSON as scripts/serviceAccountKey.json
//  4. node seed_firebase_dishes.js
// =============================================================

require('dotenv').config();
const admin = require('firebase-admin');
const fetch = require('node-fetch');

// -- Firebase Init
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();
const COLLECTION = 'global_dishes';

// -- Config
const PEXELS_API_KEY = process.env.PEXELS_API_KEY;
const DELAY_MS = 350; // polite delay between Pexels requests (avoid rate limits)

if (!PEXELS_API_KEY) {
  console.error('ERROR: PEXELS_API_KEY not set in .env file. Aborting.');
  process.exit(1);
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// -- Fetch HD image from Pexels (called ONLY when imageUrl is missing)
async function fetchPexelsImage(dishName) {
  const query = encodeURIComponent(dishName + ' indian food');
  const url = 'https://api.pexels.com/v1/search?query=' + query + '&per_page=1&orientation=landscape';
  try {
    const res = await fetch(url, { headers: { Authorization: PEXELS_API_KEY } });
    if (!res.ok) { console.warn('  Pexels HTTP ' + res.status + ' for: ' + dishName); return null; }
    const data = await res.json();
    if (data.photos && data.photos.length > 0) return data.photos[0].src.large;
    return null;
  } catch (e) {
    console.warn('  Network error for ' + dishName + ': ' + e.message);
    return null;
  }
}

function generateKeywords(name) {
  const words = name.toLowerCase().split(/[\s\-\/]+/);
  return [...new Set([name.toLowerCase(), ...words])].filter((k) => k.length > 1);
}

// -- The 1000 Indian Mess Dishes [name, category]
const DISHES = [
  ['Dal Tadka','dal'],['Dal Makhani','dal'],['Dal Fry','dal'],['Chana Dal','dal'],
  ['Masoor Dal','dal'],['Moong Dal','dal'],['Urad Dal','dal'],['Toor Dal','dal'],
  ['Rajma','dal'],['Kala Chana','dal'],['Kabuli Chana','dal'],['Panchmel Dal','dal'],
  ['Dal Baati','dal'],['Dal Palak','dal'],['Lauki Dal','dal'],['Moong Dal Tadka','dal'],
  ['Arhar Dal','dal'],['Sabut Masoor','dal'],['Dal Dhokli','dal'],['Chana Masala','dal'],
  ['Paneer Butter Masala','veg'],['Paneer Tikka Masala','veg'],['Paneer Bhurji','veg'],
  ['Paneer Kadai','veg'],['Shahi Paneer','veg'],['Palak Paneer','veg'],
  ['Matar Paneer','veg'],['Paneer Do Pyaza','veg'],['Paneer Lababdar','veg'],
  ['Paneer Korma','veg'],['Paneer Tikka','veg'],['Paneer Pasanda','veg'],
  ['Paneer Masala','veg'],['Paneer Capsicum','veg'],['Paneer Saag','veg'],
  ['Paneer Khurchan','veg'],['Paneer Achari','veg'],['Paneer Makhani','veg'],
  ['Paneer Kofta','veg'],['Paneer Peshwari','veg'],
  ['Aloo Gobi','veg'],['Aloo Matar','veg'],['Aloo Jeera','veg'],['Aloo Tamatar','veg'],
  ['Aloo Baingan','veg'],['Aloo Palak','veg'],['Aloo Methi','veg'],['Aloo Pyaz','veg'],
  ['Aloo Beans','veg'],['Aloo Shimla Mirch','veg'],['Mix Veg','veg'],
  ['Bhindi Masala','veg'],['Bhindi Do Pyaza','veg'],['Baingan Bharta','veg'],
  ['Baingan Masala','veg'],['Lauki Sabzi','veg'],['Lauki Kofta','veg'],
  ['Tinda Sabzi','veg'],['Kaddu Sabzi','veg'],['Parwal Sabzi','veg'],
  ['Arbi Masala','veg'],['Mushroom Masala','veg'],['Mushroom Matar','veg'],
  ['Corn Masala','veg'],['Soya Chunks Masala','veg'],['Raw Banana Sabzi','veg'],
  ['Dahi Aloo','veg'],['Dum Aloo','veg'],['Kashmiri Dum Aloo','veg'],
  ['Aloo Rasedar','veg'],['Methi Aloo','veg'],['Methi Matar Malai','veg'],
  ['Kadai Vegetables','veg'],['Navratan Korma','veg'],['Veg Handi','veg'],
  ['Matar Masala','veg'],['Gobhi Masala','veg'],['Sarson Ka Saag','veg'],
  ['Batata Bhaji','veg'],['Gatte Ki Sabzi','veg'],['Ker Sangri','veg'],
  ['Bharli Vangi','veg'],['Makhana Curry','veg'],['Lotus Stem Curry','veg'],
  ['Bitter Gourd Sabzi','veg'],['Karela Masala','veg'],['Yam Curry','veg'],
  ['Colocasia Curry','veg'],['Suran Sabzi','veg'],
  ['Steamed Rice','rice'],['Jeera Rice','rice'],['Veg Biryani','rice'],
  ['Paneer Biryani','rice'],['Fried Rice','rice'],['Veg Fried Rice','rice'],
  ['Lemon Rice','rice'],['Tamarind Rice','rice'],['Coconut Rice','rice'],
  ['Tomato Rice','rice'],['Curd Rice','rice'],['Peas Pulao','rice'],
  ['Vegetable Pulao','rice'],['Matar Pulao','rice'],['Kashmiri Pulao','rice'],
  ['Khichdi','rice'],['Moong Dal Khichdi','rice'],['Sabudana Khichdi','rice'],
  ['Tehri','rice'],['Rajma Rice','rice'],['Dal Rice','rice'],
  ['Sambar Rice','rice'],['Bisi Bele Bath','rice'],['Masala Khichdi','rice'],
  ['Brown Rice','rice'],['Quinoa Pulao','rice'],['Meethe Chawal','rice'],
  ['Chicken Biryani','nonveg'],['Egg Biryani','nonveg'],['Egg Fried Rice','nonveg'],
  ['Mutton Biryani','nonveg'],['Shahi Biryani','rice'],
  ['Plain Roti','roti'],['Phulka','roti'],['Chapati','roti'],['Tawa Roti','roti'],
  ['Tandoori Roti','roti'],['Butter Roti','roti'],['Plain Paratha','roti'],
  ['Aloo Paratha','roti'],['Gobhi Paratha','roti'],['Onion Paratha','roti'],
  ['Paneer Paratha','roti'],['Methi Paratha','roti'],['Mooli Paratha','roti'],
  ['Lachha Paratha','roti'],['Missi Roti','roti'],['Makki Ki Roti','roti'],
  ['Bajra Roti','roti'],['Jowar Roti','roti'],['Naan','roti'],
  ['Butter Naan','roti'],['Garlic Naan','roti'],['Puri','roti'],
  ['Bhatura','roti'],['Thepla','roti'],['Rumali Roti','roti'],
  ['Matar Paratha','roti'],['Dal Paratha','roti'],['Palak Paratha','roti'],
  ['Mixed Paratha','roti'],['Keema Paratha','nonveg'],['Bajra Paratha','roti'],
  ['Akki Roti','roti'],['Jolada Roti','roti'],['Ragi Roti','roti'],
  ['Malabar Parotta','roti'],['Appam','roti'],['Luchi','roti'],
  ['Radhaballabi','roti'],['Makki Di Roti','roti'],['Amritsari Kulcha','roti'],
  ['Chicken Curry','nonveg'],['Chicken Masala','nonveg'],['Butter Chicken','nonveg'],
  ['Chicken Tikka Masala','nonveg'],['Chicken Kadai','nonveg'],
  ['Chicken Do Pyaza','nonveg'],['Chicken Korma','nonveg'],['Chicken Bhuna','nonveg'],
  ['Chicken Saag','nonveg'],['Chicken Rogan Josh','nonveg'],
  ['Chicken Vindaloo','nonveg'],['Chicken Keema','nonveg'],['Chicken Fry','nonveg'],
  ['Chicken 65','nonveg'],['Lemon Chicken','nonveg'],['Garlic Chicken','nonveg'],
  ['Chilli Chicken','nonveg'],['Chicken Handi','nonveg'],
  ['Chicken Kali Mirch','nonveg'],['Murgh Makhani','nonveg'],
  ['Chicken Lababdar','nonveg'],['Chicken Dhaba Style','nonveg'],
  ['Chicken Achari','nonveg'],['Chicken Dum','nonveg'],['Chicken Xacuti','nonveg'],
  ['Chicken Chettinad','nonveg'],['Chicken Kolhapuri','nonveg'],
  ['Tandoori Chicken','nonveg'],['Mughlai Chicken','nonveg'],
  ['Mutton Curry','nonveg'],['Mutton Masala','nonveg'],
  ['Mutton Rogan Josh','nonveg'],['Mutton Keema','nonveg'],
  ['Mutton Korma','nonveg'],['Mutton Do Pyaza','nonveg'],['Mutton Saag','nonveg'],
  ['Mutton Vindaloo','nonveg'],['Mutton Dum','nonveg'],
  ['Mutton Kolhapuri','nonveg'],['Mutton Haleem','nonveg'],
  ['Mutton Kofta','nonveg'],['Nihari','nonveg'],['Paya','nonveg'],
  ['Kheema Matar','nonveg'],['Kosha Mangsho','nonveg'],['Laal Maas','nonveg'],
  ['Seekh Kebab','nonveg'],['Shami Kebab','nonveg'],['Kakori Kebab','nonveg'],
  ['Galouti Kebab','nonveg'],['Kori Rotti','nonveg'],
  ['Egg Curry','nonveg'],['Egg Masala','nonveg'],['Egg Bhurji','nonveg'],
  ['Egg Do Pyaza','nonveg'],['Omelette','nonveg'],['Boiled Eggs','nonveg'],
  ['Scrambled Eggs','nonveg'],['Egg Fry','nonveg'],['Egg Korma','nonveg'],
  ['Half Fry Egg','nonveg'],['Bread Omelette','nonveg'],['Egg Toast','nonveg'],
  ['Fish Curry','nonveg'],['Fish Masala','nonveg'],['Fish Fry','nonveg'],
  ['Prawn Curry','nonveg'],['Prawn Masala','nonveg'],['Prawn Biryani','nonveg'],
  ['Fish Kadai','nonveg'],['Goan Fish Curry','nonveg'],
  ['Bengali Fish Curry','nonveg'],['Macher Jhol','nonveg'],
  ['Shorshe Ilish','nonveg'],['Karimeen Pollichathu','nonveg'],
  ['Fish Molee','nonveg'],['Prawn Theeyal','nonveg'],['Kori Rotti','nonveg'],
  ['Chicken Stew','nonveg'],['Appam Stew','nonveg'],['Mutta Curry','nonveg'],
  ['Poha','snack'],['Upma','snack'],['Idli','snack'],['Dosa','snack'],
  ['Masala Dosa','snack'],['Uttapam','snack'],['Medu Vada','snack'],
  ['Sambhar Vada','snack'],['Rava Idli','snack'],['Rava Dosa','snack'],
  ['Set Dosa','snack'],['Pongal','snack'],['Ven Pongal','snack'],
  ['Aloo Puri','snack'],['Chole Bhature','snack'],['Chole Puri','snack'],
  ['Pav Bhaji','snack'],['Misal Pav','snack'],['Bread Butter','snack'],
  ['Bread Jam','snack'],['Poha Aloo','snack'],['Sabudana Vada','snack'],
  ['Aloo Tikki','snack'],['Samosa','snack'],['Kachori','snack'],
  ['Pyaz Kachori','snack'],['Dal Kachori','snack'],['Bread Pakoda','snack'],
  ['Besan Chilla','snack'],['Moong Dal Chilla','snack'],['Rava Upma','snack'],
  ['Plain Dosa','snack'],['Cheese Dosa','snack'],['Egg Dosa','nonveg'],
  ['Onion Dosa','snack'],['Ghee Roast Dosa','snack'],
  ['Mysore Masala Dosa','snack'],['Pesarattu','snack'],
  ['Vada Pav','snack'],['Dabeli','snack'],['Dhokla','snack'],
  ['Khandvi','snack'],['Khakhra','snack'],['Fafda','snack'],
  ['Jalebi Fafda','snack'],['Handvo','snack'],['Muthia','snack'],
  ['Surti Locho','snack'],['Litti Chokha','snack'],['Thekua','sweet'],
  ['Dahi Puri','snack'],['Pani Puri','snack'],['Bhel Puri','snack'],
  ['Sev Puri','snack'],['Aloo Chaat','snack'],['Papdi Chaat','snack'],
  ['Ragda Pattice','snack'],['Chana Chaat','snack'],['Dahi Bhalla','snack'],
  ['Basket Chaat','snack'],['Momos','snack'],['Veg Momos','snack'],
  ['Corn Chaat','snack'],['Sweet Potato Chaat','snack'],['Makhana Chaat','snack'],
  ['Veg Cutlet','snack'],['Corn Cutlet','snack'],['Soya Cutlet','snack'],
  ['Beetroot Cutlet','snack'],['Mixed Veg Cutlet','snack'],
  ['Mushroom Cutlet','snack'],['Aloo Bonda','snack'],['Mysore Bonda','snack'],
  ['Rava Vada','snack'],['Punugulu','snack'],['Ragi Mudde','snack'],
  ['Neer Dosa','snack'],['String Hoppers','snack'],['Puttu','snack'],
  ['Idiyappam','snack'],['Puttu Kadala','snack'],['Chana Sundal','snack'],
  ['Papad','snack'],['Masala Papad','snack'],['Roasted Papad','snack'],
  ['Kadhi Pakoda','veg'],['Rajasthani Kadhi','veg'],
  ['Gujarati Kadhi','veg'],['Sindhi Kadhi','veg'],
  ['Rasam','veg'],['Sambar','veg'],['Kootu','veg'],['Avial','veg'],
  ['Thoran','veg'],['Olan','veg'],['Erissery','veg'],['Sukto','veg'],
  ['Aloo Posto','veg'],['Dhokar Dalna','veg'],['Begun Bhaja','veg'],
  ['Undhiyu','veg'],['Sev Tameta','veg'],['Ringan No Olo','veg'],
  ['Kadala Curry','dal'],['Mung Bean Curry','dal'],
  ['Black Eyed Peas','dal'],['Matki Usal','dal'],['Pindi Chole','dal'],
  ['Chole Masala','dal'],['Mah Di Dal','dal'],
  ['Veg Manchurian','veg'],['Gobi Manchurian','veg'],
  ['Paneer Manchurian','veg'],['Chilli Paneer','veg'],
  ['Chilli Mushroom','veg'],['Veg Hakka Noodles','veg'],
  ['Chicken Hakka Noodles','nonveg'],['Spring Rolls','veg'],
  ['Boondi Raita','veg'],['Lauki Raita','veg'],['Cucumber Raita','veg'],
  ['Mixed Vegetable Raita','veg'],['Onion Raita','veg'],
  ['Mint Raita','veg'],['Pineapple Raita','veg'],
  ['Tomato Chutney','veg'],['Green Chutney','veg'],
  ['Tamarind Chutney','veg'],['Coconut Chutney','veg'],
  ['Garlic Chutney','veg'],['Mango Chutney','veg'],
  ['Kachumber Salad','veg'],['Fruit Salad','veg'],['Sprout Salad','veg'],
  ['Onion Salad','veg'],['Beetroot Salad','veg'],['Moong Sprouts','veg'],
  ['Chana Salad','veg'],['Tomato Soup','veg'],['Sweet Corn Soup','veg'],
  ['Vegetable Soup','veg'],['Chicken Soup','nonveg'],['Spinach Soup','veg'],
  ['Mushroom Soup','veg'],['Lentil Soup','dal'],['Hot And Sour Soup','veg'],
  ['Rasam Soup','veg'],['Mulligatawny Soup','nonveg'],
  ['Parotta Kurma','veg'],['Poori Kurma','veg'],['Coconut Stew','veg'],
  ['Ishtew','veg'],['Veg Stew','veg'],
  ['Mango Pickle','veg'],['Lime Pickle','veg'],['Mixed Pickle','veg'],
  ['Masala Chai','beverage'],['Ginger Tea','beverage'],['Lemon Tea','beverage'],
  ['Green Tea','beverage'],['Lassi','beverage'],['Sweet Lassi','beverage'],
  ['Mango Lassi','beverage'],['Buttermilk','beverage'],['Chaas','beverage'],
  ['Shikanjvi','beverage'],['Aam Panna','beverage'],['Jaljeera','beverage'],
  ['Thandai','beverage'],['Filter Coffee','beverage'],['Cold Coffee','beverage'],
  ['Coconut Water','beverage'],['Fresh Lime Water','beverage'],
  ['Sattu Drink','beverage'],['Kashmiri Kahwa','beverage'],
  ['Irani Chai','beverage'],['Doodh Pati Chai','beverage'],
  ['Nun Chai','beverage'],['Tulsi Tea','beverage'],['Cardamom Tea','beverage'],
  ['Jaggery Tea','beverage'],['Mango Shake','beverage'],
  ['Banana Shake','beverage'],['Rose Sharbat','beverage'],
  ['Kokum Sharbat','beverage'],['Sol Kadhi','beverage'],
  ['Gulab Jamun','sweet'],['Rasgulla','sweet'],['Kheer','sweet'],
  ['Halwa','sweet'],['Gajar Halwa','sweet'],['Suji Halwa','sweet'],
  ['Moong Dal Halwa','sweet'],['Lapsi','sweet'],['Sheera','sweet'],
  ['Phirni','sweet'],['Rice Kheer','sweet'],['Sevaiyan Kheer','sweet'],
  ['Rabri','sweet'],['Jalebi','sweet'],['Imarti','sweet'],['Ladoo','sweet'],
  ['Besan Ladoo','sweet'],['Motichur Ladoo','sweet'],['Til Ladoo','sweet'],
  ['Churma Ladoo','sweet'],['Coconut Ladoo','sweet'],['Peda','sweet'],
  ['Milk Cake','sweet'],['Kalakand','sweet'],['Barfi','sweet'],
  ['Kaju Barfi','sweet'],['Milk Barfi','sweet'],['Badam Halwa','sweet'],
  ['Sandesh','sweet'],['Mishti Doi','sweet'],['Cham Cham','sweet'],
  ['Rasmalai','sweet'],['Shrikhand','sweet'],['Amrakhand','sweet'],
  ['Kulfi','sweet'],['Mango Kulfi','sweet'],['Fruit Custard','sweet'],
  ['Payesh','sweet'],['Pinni','sweet'],['Atta Ladoo','sweet'],
  ['Churma','sweet'],['Mohanthal','sweet'],['Basundi','sweet'],
  ['Malpua','sweet'],['Ghewar','sweet'],['Balushahi','sweet'],
  ['Shahi Tukda','sweet'],['Double Ka Meetha','sweet'],
  ['Puran Poli','sweet'],['Modak','sweet'],['Khaja','sweet'],
  ['Payasam','sweet'],['Ada Payasam','sweet'],['Paal Payasam','sweet'],
  ['Semiya Payasam','sweet'],['Chakka Pradhaman','sweet'],
  ['Chakkara Pongal','sweet'],['Kesari Bath','sweet'],
  ['Rava Kesari','sweet'],['Kozhukattai','sweet'],
  ['Suji Halwa','sweet'],['Rava Kheer','sweet'],
  ['Sabudana Kheer','sweet'],['Lauki Kheer','sweet'],
  ['Makhana Kheer','sweet'],['Badam Kheer','sweet'],
  ['Sabudana Payasam','sweet'],['Kadala Payasam','sweet'],
  ['Boondi Ladoo','sweet'],['Zarda','sweet'],['Gujiyas','sweet'],
  ['Karanji','sweet'],['Patishapta','sweet'],['Khurchan','sweet'],
  ['Rajbhog','sweet'],['Langcha','sweet'],['Pantua','sweet'],
  ['Carrot Halwa','sweet'],['Bottle Gourd Halwa','sweet'],
  ['Bread Halwa','sweet'],['Pumpkin Halwa','sweet'],['Wheat Halwa','sweet'],
  ['Atta Halwa','sweet'],['Sattu Halwa','sweet'],['Oats Halwa','sweet'],
  ['Apple Halwa','sweet'],['Banana Halwa','sweet'],
  ['Seviyan Halwa','sweet'],['Kaddu Halwa','sweet'],
  ['Doodh Jalebi','sweet'],['Mawa Jalebi','sweet'],
  
  // -- Hostel & Mess Specials
  ['Gilki Ki Sabzi', 'veg'], ['Turai Ki Sabzi', 'veg'], ['Tori Ki Sabzi', 'veg'],
  ['Lauki Chana Dal', 'dal'], ['Lauki Gatte', 'veg'], ['Palak Dal', 'dal'],
  ['Palak Kofta', 'veg'], ['Bhindi Aloo', 'veg'], ['Kurkuri Bhindi', 'veg'],
  ['Aloo Parwal', 'veg'], ['Kundru Sabzi', 'veg'], ['Kathal Ki Sabzi', 'veg'],
  ['Tinda Masala', 'veg'], ['Lobia Masala', 'dal'], ['Soya Aloo', 'veg'],
  ['Nutrela Curry', 'veg'], ['Cabbage Matar', 'veg'], ['Patta Gobi Sabzi', 'veg'],
  ['Gajar Matar', 'veg'], ['Aloo Shimla Mirch', 'veg'], ['Aloo Gobi Matar', 'veg'],
  ['Chana Masala Hostel Style', 'dal'], ['Rajma Masala', 'dal'], ['Dal Pachmel', 'dal'],
  ['Kadi Pakora', 'veg'], ['Dahi Kadhi', 'veg'], ['Moong Dal Chilka', 'dal'],
  ['Urad Chana Dal', 'dal'], ['Toor Dal Tadka', 'dal'], ['Masoor Dal Tadka', 'dal'],
  ['Mix Dal', 'dal'], ['Aloo Soyabean', 'veg'], ['Soyabean Ki Sabzi', 'veg'],
  ['Mooli Ki Sabzi', 'veg'], ['Arbi Sabzi', 'veg'], ['Kaddu Ki Sabzi', 'veg'],
  ['Khatta Meetha Kaddu', 'veg'], ['Aloo Nutrela', 'veg'], ['Dry Mix Veg', 'veg'],
  ['Cabbage Aloo', 'veg'], ['Aloo Matar Tariwala', 'veg'], ['Tamatar Chutney', 'veg'],
  ['Papad Ki Sabzi', 'veg'], ['Sev Tamatar', 'veg'], ['Baingan Aloo', 'veg']
  ,['Gobi Masala', 'veg'],['Gobi Curry', 'veg'],['Gobi Fry', 'veg'],['Gobi Bhurji', 'veg'],['Gobi Kadai', 'veg'],['Gobi Makhani', 'veg'],['Gobi Korma', 'veg'],['Gobi Do Pyaza', 'veg'],['Gobi Saag', 'veg'],['Gobi Achari', 'veg'],['Gobi Handi', 'veg'],['Gobi Kolhapuri', 'veg'],['Gobi Tikka', 'veg'],['Gobi Pasanda', 'veg'],['Gobi Kofta', 'veg'],['Gobi Lababdar', 'veg'],['Gobi Rogan Josh', 'veg'],['Gobi Vindaloo', 'veg'],['Gobi Chettinad', 'veg'],['Matar Masala', 'veg'],['Matar Curry', 'veg'],['Matar Fry', 'veg'],['Matar Bhurji', 'veg'],['Matar Kadai', 'veg'],['Matar Makhani', 'veg'],['Matar Korma', 'veg'],['Matar Do Pyaza', 'veg'],['Matar Saag', 'veg'],['Matar Achari', 'veg'],['Matar Handi', 'veg'],['Matar Kolhapuri', 'veg'],['Matar Tikka', 'veg'],['Matar Pasanda', 'veg'],['Matar Kofta', 'veg'],['Matar Lababdar', 'veg'],['Matar Rogan Josh', 'veg'],['Matar Vindaloo', 'veg'],['Matar Chettinad', 'veg'],['Mushroom Masala', 'veg'],['Mushroom Curry', 'veg'],['Mushroom Fry', 'veg'],['Mushroom Bhurji', 'veg'],['Mushroom Kadai', 'veg'],['Mushroom Makhani', 'veg'],['Mushroom Korma', 'veg'],['Mushroom Do Pyaza', 'veg'],['Mushroom Saag', 'veg'],['Mushroom Achari', 'veg'],['Mushroom Handi', 'veg'],['Mushroom Kolhapuri', 'veg'],['Mushroom Tikka', 'veg'],['Mushroom Pasanda', 'veg'],['Mushroom Kofta', 'veg'],['Mushroom Lababdar', 'veg'],['Mushroom Rogan Josh', 'veg'],['Mushroom Vindaloo', 'veg'],['Mushroom Chettinad', 'veg'],['Soya Masala', 'veg'],['Soya Curry', 'veg'],['Soya Fry', 'veg'],['Soya Bhurji', 'veg'],['Soya Kadai', 'veg'],['Soya Makhani', 'veg'],['Soya Korma', 'veg'],['Soya Do Pyaza', 'veg'],['Soya Saag', 'veg'],['Soya Achari', 'veg'],['Soya Handi', 'veg'],['Soya Kolhapuri', 'veg'],['Soya Tikka', 'veg'],['Soya Pasanda', 'veg'],['Soya Kofta', 'veg'],['Soya Lababdar', 'veg'],['Soya Rogan Josh', 'veg'],['Soya Vindaloo', 'veg'],['Soya Chettinad', 'veg'],['Cabbage Masala', 'veg'],['Cabbage Curry', 'veg'],['Cabbage Fry', 'veg'],['Cabbage Bhurji', 'veg'],['Cabbage Kadai', 'veg'],['Cabbage Makhani', 'veg'],['Cabbage Korma', 'veg'],['Cabbage Do Pyaza', 'veg'],['Cabbage Saag', 'veg'],['Cabbage Achari', 'veg'],['Cabbage Handi', 'veg'],['Cabbage Kolhapuri', 'veg'],['Cabbage Tikka', 'veg'],['Cabbage Pasanda', 'veg'],['Cabbage Kofta', 'veg'],['Cabbage Lababdar', 'veg'],['Cabbage Rogan Josh', 'veg'],['Cabbage Vindaloo', 'veg'],['Cabbage Chettinad', 'veg'],['Baingan Masala', 'veg'],['Baingan Curry', 'veg'],['Baingan Fry', 'veg'],['Baingan Bhurji', 'veg'],['Baingan Kadai', 'veg'],['Baingan Makhani', 'veg'],['Baingan Korma', 'veg'],['Baingan Do Pyaza', 'veg'],['Baingan Saag', 'veg'],['Baingan Achari', 'veg'],['Baingan Handi', 'veg'],['Baingan Kolhapuri', 'veg'],['Baingan Tikka', 'veg'],['Baingan Pasanda', 'veg'],['Baingan Kofta', 'veg'],['Baingan Lababdar', 'veg'],['Baingan Rogan Josh', 'veg'],['Baingan Vindaloo', 'veg'],['Baingan Chettinad', 'veg'],['Bhindi Masala', 'veg'],['Bhindi Curry', 'veg'],['Bhindi Fry', 'veg'],['Bhindi Bhurji', 'veg'],['Bhindi Kadai', 'veg'],['Bhindi Makhani', 'veg'],['Bhindi Korma', 'veg'],['Bhindi Do Pyaza', 'veg'],['Bhindi Saag', 'veg'],['Bhindi Achari', 'veg'],['Bhindi Handi', 'veg'],['Bhindi Kolhapuri', 'veg'],['Bhindi Tikka', 'veg'],['Bhindi Pasanda', 'veg'],['Bhindi Kofta', 'veg'],['Bhindi Lababdar', 'veg'],['Bhindi Rogan Josh', 'veg'],['Bhindi Vindaloo', 'veg'],['Bhindi Chettinad', 'veg'],['Karela Masala', 'veg'],['Karela Curry', 'veg'],['Karela Fry', 'veg'],['Karela Bhurji', 'veg'],['Karela Kadai', 'veg'],['Karela Makhani', 'veg'],['Karela Korma', 'veg'],['Karela Do Pyaza', 'veg'],['Karela Saag', 'veg'],['Karela Achari', 'veg'],['Karela Handi', 'veg'],['Karela Kolhapuri', 'veg'],['Karela Tikka', 'veg'],['Karela Pasanda', 'veg'],['Karela Kofta', 'veg'],['Karela Lababdar', 'veg'],['Karela Rogan Josh', 'veg'],['Karela Vindaloo', 'veg'],['Karela Chettinad', 'veg'],['Tinda Masala', 'veg'],['Tinda Curry', 'veg'],['Tinda Fry', 'veg'],['Tinda Bhurji', 'veg'],['Tinda Kadai', 'veg'],['Tinda Makhani', 'veg'],['Tinda Korma', 'veg'],['Tinda Do Pyaza', 'veg'],['Tinda Saag', 'veg'],['Tinda Achari', 'veg'],['Tinda Handi', 'veg'],['Tinda Kolhapuri', 'veg'],['Tinda Tikka', 'veg'],['Tinda Pasanda', 'veg'],['Tinda Kofta', 'veg'],['Tinda Lababdar', 'veg'],['Tinda Rogan Josh', 'veg'],['Tinda Vindaloo', 'veg'],['Tinda Chettinad', 'veg'],['Parwal Masala', 'veg'],['Parwal Curry', 'veg'],['Parwal Fry', 'veg'],['Parwal Bhurji', 'veg'],['Parwal Kadai', 'veg'],['Parwal Makhani', 'veg'],['Parwal Korma', 'veg'],['Parwal Do Pyaza', 'veg'],['Parwal Saag', 'veg'],['Parwal Achari', 'veg'],['Parwal Handi', 'veg'],['Parwal Kolhapuri', 'veg'],['Parwal Tikka', 'veg'],['Parwal Pasanda', 'veg'],['Parwal Kofta', 'veg'],['Parwal Lababdar', 'veg'],['Parwal Rogan Josh', 'veg'],['Parwal Vindaloo', 'veg'],['Parwal Chettinad', 'veg'],['Capsicum Masala', 'veg'],['Capsicum Curry', 'veg'],['Capsicum Fry', 'veg'],['Capsicum Bhurji', 'veg'],['Capsicum Kadai', 'veg'],['Capsicum Makhani', 'veg'],['Capsicum Korma', 'veg'],['Capsicum Do Pyaza', 'veg'],['Capsicum Saag', 'veg'],['Capsicum Achari', 'veg'],['Capsicum Handi', 'veg'],['Capsicum Kolhapuri', 'veg'],['Capsicum Tikka', 'veg'],['Capsicum Pasanda', 'veg'],['Capsicum Kofta', 'veg'],['Capsicum Lababdar', 'veg'],['Capsicum Rogan Josh', 'veg'],['Capsicum Vindaloo', 'veg'],['Capsicum Chettinad', 'veg'],['Baby Corn Masala', 'veg'],['Baby Corn Curry', 'veg'],['Baby Corn Fry', 'veg'],['Baby Corn Bhurji', 'veg'],['Baby Corn Kadai', 'veg'],['Baby Corn Makhani', 'veg'],['Baby Corn Korma', 'veg'],['Baby Corn Do Pyaza', 'veg'],['Baby Corn Saag', 'veg'],['Baby Corn Achari', 'veg'],['Baby Corn Handi', 'veg'],['Baby Corn Kolhapuri', 'veg'],['Baby Corn Tikka', 'veg'],['Baby Corn Pasanda', 'veg'],['Baby Corn Kofta', 'veg'],['Baby Corn Lababdar', 'veg'],['Baby Corn Rogan Josh', 'veg'],['Baby Corn Vindaloo', 'veg'],['Baby Corn Chettinad', 'veg'],['Broccoli Masala', 'veg'],['Broccoli Curry', 'veg'],['Broccoli Fry', 'veg'],['Broccoli Bhurji', 'veg'],['Broccoli Kadai', 'veg'],['Broccoli Makhani', 'veg'],['Broccoli Korma', 'veg'],['Broccoli Do Pyaza', 'veg'],['Broccoli Saag', 'veg'],['Broccoli Achari', 'veg'],['Broccoli Handi', 'veg'],['Broccoli Kolhapuri', 'veg'],['Broccoli Tikka', 'veg'],['Broccoli Pasanda', 'veg'],['Broccoli Kofta', 'veg'],['Broccoli Lababdar', 'veg'],['Broccoli Rogan Josh', 'veg'],['Broccoli Vindaloo', 'veg'],['Broccoli Chettinad', 'veg'],['Paneer Masala', 'veg'],['Paneer Curry', 'veg'],['Paneer Fry', 'veg'],['Paneer Bhurji', 'veg'],['Paneer Kadai', 'veg'],['Paneer Makhani', 'veg'],['Paneer Korma', 'veg'],['Paneer Do Pyaza', 'veg'],['Paneer Saag', 'veg'],['Paneer Achari', 'veg'],['Paneer Handi', 'veg'],['Paneer Kolhapuri', 'veg'],['Paneer Tikka', 'veg'],['Paneer Pasanda', 'veg'],['Paneer Kofta', 'veg'],['Paneer Lababdar', 'veg'],['Paneer Rogan Josh', 'veg'],['Paneer Vindaloo', 'veg'],['Paneer Chettinad', 'veg'],['Aloo Masala', 'veg'],['Aloo Curry', 'veg'],['Aloo Fry', 'veg'],['Aloo Bhurji', 'veg'],['Aloo Kadai', 'veg'],['Aloo Makhani', 'veg'],['Aloo Korma', 'veg'],['Aloo Do Pyaza', 'veg'],['Aloo Saag', 'veg'],['Aloo Achari', 'veg'],['Aloo Handi', 'veg'],['Aloo Kolhapuri', 'veg'],['Aloo Tikka', 'veg'],['Aloo Pasanda', 'veg'],['Aloo Kofta', 'veg'],['Aloo Lababdar', 'veg'],['Aloo Rogan Josh', 'veg'],['Aloo Vindaloo', 'veg'],['Aloo Chettinad', 'veg'],['Mixed Veg Masala', 'veg'],['Mixed Veg Curry', 'veg'],['Mixed Veg Fry', 'veg'],['Mixed Veg Bhurji', 'veg'],['Mixed Veg Kadai', 'veg'],['Mixed Veg Makhani', 'veg'],['Mixed Veg Korma', 'veg'],['Mixed Veg Do Pyaza', 'veg'],['Mixed Veg Saag', 'veg'],['Mixed Veg Achari', 'veg'],['Mixed Veg Handi', 'veg'],['Mixed Veg Kolhapuri', 'veg'],['Mixed Veg Tikka', 'veg'],['Mixed Veg Pasanda', 'veg'],['Mixed Veg Kofta', 'veg'],['Mixed Veg Lababdar', 'veg'],['Mixed Veg Rogan Josh', 'veg'],['Mixed Veg Vindaloo', 'veg'],['Mixed Veg Chettinad', 'veg'],['Navratan Masala', 'veg'],['Navratan Curry', 'veg'],['Navratan Fry', 'veg'],['Navratan Bhurji', 'veg'],['Navratan Kadai', 'veg'],['Navratan Makhani', 'veg'],['Navratan Korma', 'veg'],['Navratan Do Pyaza', 'veg'],['Navratan Saag', 'veg'],['Navratan Achari', 'veg'],['Navratan Handi', 'veg'],['Navratan Kolhapuri', 'veg'],['Navratan Tikka', 'veg'],['Navratan Pasanda', 'veg'],['Navratan Kofta', 'veg'],['Navratan Lababdar', 'veg'],['Navratan Rogan Josh', 'veg'],['Navratan Vindaloo', 'veg'],['Navratan Chettinad', 'veg'],['Jeera Pulao', 'rice'],['Jeera Biryani', 'rice'],['Jeera Fried Rice', 'rice'],['Jeera Khichdi', 'rice'],['Jeera Rice', 'rice'],['Matar Pulao', 'rice'],['Matar Biryani', 'rice'],['Matar Fried Rice', 'rice'],['Matar Khichdi', 'rice'],['Matar Rice', 'rice'],['Paneer Pulao', 'rice'],['Paneer Biryani', 'rice'],['Paneer Fried Rice', 'rice'],['Paneer Khichdi', 'rice'],['Paneer Rice', 'rice'],['Mushroom Pulao', 'rice'],['Mushroom Biryani', 'rice'],['Mushroom Fried Rice', 'rice'],['Mushroom Khichdi', 'rice'],['Mushroom Rice', 'rice'],['Veg Pulao', 'rice'],['Veg Biryani', 'rice'],['Veg Fried Rice', 'rice'],['Veg Khichdi', 'rice'],['Veg Rice', 'rice'],['Chicken Pulao', 'rice'],['Chicken Biryani', 'rice'],['Chicken Fried Rice', 'rice'],['Chicken Khichdi', 'rice'],['Chicken Rice', 'rice'],['Mutton Pulao', 'rice'],['Mutton Biryani', 'rice'],['Mutton Fried Rice', 'rice'],['Mutton Khichdi', 'rice'],['Mutton Rice', 'rice'],['Egg Pulao', 'rice'],['Egg Biryani', 'rice'],['Egg Fried Rice', 'rice'],['Egg Khichdi', 'rice'],['Egg Rice', 'rice'],['Fish Pulao', 'rice'],['Fish Biryani', 'rice'],['Fish Fried Rice', 'rice'],['Fish Khichdi', 'rice'],['Fish Rice', 'rice'],['Prawn Pulao', 'rice'],['Prawn Biryani', 'rice'],['Prawn Fried Rice', 'rice'],['Prawn Khichdi', 'rice'],['Prawn Rice', 'rice'],['Kashmiri Pulao', 'rice'],['Kashmiri Biryani', 'rice'],['Kashmiri Fried Rice', 'rice'],['Kashmiri Khichdi', 'rice'],['Kashmiri Rice', 'rice'],['Ghee Pulao', 'rice'],['Ghee Biryani', 'rice'],['Ghee Fried Rice', 'rice'],['Ghee Khichdi', 'rice'],['Ghee Rice', 'rice'],['Lemon Pulao', 'rice'],['Lemon Biryani', 'rice'],['Lemon Fried Rice', 'rice'],['Lemon Khichdi', 'rice'],['Lemon Rice', 'rice'],['Tomato Pulao', 'rice'],['Tomato Biryani', 'rice'],['Tomato Fried Rice', 'rice'],['Tomato Khichdi', 'rice'],['Tomato Rice', 'rice'],['Curd Pulao', 'rice'],['Curd Biryani', 'rice'],['Curd Fried Rice', 'rice'],['Curd Khichdi', 'rice'],['Curd Rice', 'rice'],['Tamarind Pulao', 'rice'],['Tamarind Biryani', 'rice'],['Tamarind Fried Rice', 'rice'],['Tamarind Khichdi', 'rice'],['Tamarind Rice', 'rice'],['Coconut Pulao', 'rice'],['Coconut Biryani', 'rice'],['Coconut Fried Rice', 'rice'],['Coconut Khichdi', 'rice'],['Coconut Rice', 'rice'],['Mint Pulao', 'rice'],['Mint Biryani', 'rice'],['Mint Fried Rice', 'rice'],['Mint Khichdi', 'rice'],['Mint Rice', 'rice'],['Coriander Pulao', 'rice'],['Coriander Biryani', 'rice'],['Coriander Fried Rice', 'rice'],['Coriander Khichdi', 'rice'],['Coriander Rice', 'rice'],['Garlic Pulao', 'rice'],['Garlic Biryani', 'rice'],['Garlic Fried Rice', 'rice'],['Garlic Khichdi', 'rice'],['Garlic Rice', 'rice'],['Plain Roti', 'roti'],['Plain Naan', 'roti'],['Plain Paratha', 'roti'],['Plain Kulcha', 'roti'],['Plain Bhatura', 'roti'],['Plain Puri', 'roti'],['Plain Chapati', 'roti'],['Plain Phulka', 'roti'],['Butter Roti', 'roti'],['Butter Naan', 'roti'],['Butter Paratha', 'roti'],['Butter Kulcha', 'roti'],['Butter Bhatura', 'roti'],['Butter Puri', 'roti'],['Butter Chapati', 'roti'],['Butter Phulka', 'roti'],['Garlic Roti', 'roti'],['Garlic Naan', 'roti'],['Garlic Paratha', 'roti'],['Garlic Kulcha', 'roti'],['Garlic Bhatura', 'roti'],['Garlic Puri', 'roti'],['Garlic Chapati', 'roti'],['Garlic Phulka', 'roti'],['Cheese Roti', 'roti'],['Cheese Naan', 'roti'],['Cheese Paratha', 'roti'],['Cheese Kulcha', 'roti'],['Cheese Bhatura', 'roti'],['Cheese Puri', 'roti'],['Cheese Chapati', 'roti'],['Cheese Phulka', 'roti'],['Paneer Roti', 'roti'],['Paneer Naan', 'roti'],['Paneer Paratha', 'roti'],['Paneer Kulcha', 'roti'],['Paneer Bhatura', 'roti'],['Paneer Puri', 'roti'],['Paneer Chapati', 'roti'],['Paneer Phulka', 'roti'],['Aloo Roti', 'roti'],['Aloo Naan', 'roti'],['Aloo Paratha', 'roti'],['Aloo Kulcha', 'roti'],['Aloo Bhatura', 'roti'],['Aloo Puri', 'roti'],['Aloo Chapati', 'roti'],['Aloo Phulka', 'roti'],['Gobi Roti', 'roti'],['Gobi Naan', 'roti'],['Gobi Paratha', 'roti'],['Gobi Kulcha', 'roti'],['Gobi Bhatura', 'roti'],['Gobi Puri', 'roti'],['Gobi Chapati', 'roti'],['Gobi Phulka', 'roti'],['Pudhina Roti', 'roti'],['Pudhina Naan', 'roti'],['Pudhina Paratha', 'roti'],['Pudhina Kulcha', 'roti'],['Pudhina Bhatura', 'roti'],['Pudhina Puri', 'roti'],['Pudhina Chapati', 'roti'],['Pudhina Phulka', 'roti'],['Methi Roti', 'roti'],['Methi Naan', 'roti'],['Methi Paratha', 'roti'],['Methi Kulcha', 'roti'],['Methi Bhatura', 'roti'],['Methi Puri', 'roti'],['Methi Chapati', 'roti'],['Methi Phulka', 'roti'],['Onion Roti', 'roti'],['Onion Naan', 'roti'],['Onion Paratha', 'roti'],['Onion Kulcha', 'roti'],['Onion Bhatura', 'roti']
];

// -- Main
async function seed() {
  console.log('Starting seed: ' + DISHES.length + ' dishes to process...');
  let added = 0, skipped = 0, failed = 0;

  for (const [name, category] of DISHES) {
    // Check Firestore first
    const snap = await db.collection(COLLECTION).where('name', '==', name).limit(1).get();
    if (!snap.empty) {
      const doc = snap.docs[0].data();
      if (doc.imageUrl && doc.imageUrl.startsWith('http')) {
        console.log('  SKIP (exists + imageUrl ok): ' + name);
        skipped++;
        continue;
      }
    }

    // Pexels call - only if image missing
    console.log('  Pexels fetch: ' + name);
    const imageUrl = await fetchPexelsImage(name);
    if (!imageUrl) { console.warn('  FAIL - no image: ' + name); failed++; await sleep(DELAY_MS); continue; }

    const keywords = generateKeywords(name);
    if (!snap.empty) {
      await snap.docs[0].ref.update({ imageUrl, searchKeywords: keywords });
    } else {
      await db.collection(COLLECTION).add({
        name, category, imageUrl, searchKeywords: keywords,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    console.log('  SAVED: ' + name);
    added++;
    await sleep(DELAY_MS);
  }

  console.log('\nSeeding complete! Added: ' + added + '  Skipped: ' + skipped + '  Failed: ' + failed);
  process.exit(0);
}

seed().catch((e) => { console.error('Fatal:', e); process.exit(1); });
