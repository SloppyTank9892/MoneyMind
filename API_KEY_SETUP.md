# 🔑 How to Get Your Gemini API Key

## Step-by-Step Instructions

### Step 1: Access Google AI Studio
1. Open your web browser (Chrome, Firefox, Safari, etc.)
2. Go to: **https://aistudio.google.com/apikey**
   - Alternative: **https://makersuite.google.com/app/apikey**
   - If these don't work, try: **https://ai.google.dev/**

### Step 2: Sign In
1. Click "Sign in" or "Get Started"
2. Use your Google account (Gmail account)
3. If you don't have a Google account, create one first at **gmail.com**

### Step 3: Create API Key
1. Once signed in, you'll see a page with "Create API Key" button
2. Click **"Create API Key"**
3. Select a Google Cloud project (or create a new one)
4. Your API key will be generated (looks like: `AIzaSy...`)

### Step 4: Copy the Key
1. **IMPORTANT**: Copy the entire API key immediately
2. It will look something like: `AIzaSyAbCdEfGhIjKlMnOpQrStUvWxYz1234567`
3. Store it safely - you won't be able to see it again!

### Step 5: Configure in App
1. Open: `lib/config/api_keys.dart` in your project
2. Find the line: `static const String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';`
3. Replace `YOUR_GEMINI_API_KEY_HERE` with your actual key
4. Example: `static const String geminiApiKey = 'AIzaSyAbCdEfGhIjKlMnOpQrStUvWxYz1234567';`
5. Save the file

### Step 6: Restart App
1. Stop your Flutter app completely
2. Run: `flutter clean` (optional but recommended)
3. Run: `flutter pub get`
4. Restart the app (hot restart won't work - need full restart)

## 🔍 Troubleshooting

### Can't Access the Website?
- **Try different browsers**: Chrome, Firefox, Edge
- **Check internet connection**: Make sure you're online
- **Try incognito/private mode**: Sometimes extensions block sites
- **Use mobile data**: If WiFi is blocking the site
- **Try from phone**: Open the link on your mobile browser

### Website Blocked/Not Loading?
- Check if your network/firewall is blocking Google services
- Try using a VPN if available
- Try accessing from a different network (mobile hotspot)

### Don't Have Google Account?
1. Go to **gmail.com**
2. Click "Create account"
3. Follow the signup process
4. Then return to get your API key

## 📝 Alternative: Ask Someone to Help

If you absolutely cannot access the website:
1. Ask a friend/family member with internet access to help
2. They can create the API key for you (it's free)
3. They can send you the key securely
4. You can then configure it in the app

## ⚠️ Security Note

- **Never share your API key publicly**
- **Don't commit it to Git** (it's already in .gitignore)
- **Don't post it online**
- If you accidentally share it, regenerate it immediately

## ✅ Once You Have the Key

After you get your API key, I can help you:
1. Configure it in the app
2. Test if it's working
3. Troubleshoot any issues

Just let me know when you have the key and I'll help you set it up!
