require('dotenv').config();
const fetch = require('node-fetch');

async function testGoogleApi() {
  const cx = process.env.GOOGLE_CX;
  const key = process.env.GOOGLE_API_KEY;
  const query = 'Bhindi Achari Indian recipe sabzi food';
  const url = `https://www.googleapis.com/customsearch/v1?q=${encodeURIComponent(query)}&cx=${cx}&key=${key}&searchType=image&num=1`;
  
  console.log('Fetching:', url);
  try {
    const res = await fetch(url);
    const data = await res.json();
    console.log(JSON.stringify(data, null, 2));
  } catch (e) {
    console.error(e);
  }
}

testGoogleApi();
