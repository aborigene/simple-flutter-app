# Flutter Web Form Application

A simple Flutter web application with a form that sends POST requests to a Node.js backend, integrated with Dynatrace Real User Monitoring (RUM).

## Project Structure

```
.
├── lib/
│   └── main.dart              # Flutter app main file with form UI
├── web/
│   ├── index.html             # HTML entry point with Dynatrace RUM
│   └── manifest.json          # Web app manifest
├── backend_sample/
│   ├── server.js              # Node.js Express server
│   ├── package.json           # Node.js dependencies
│   └── README.md              # Backend documentation
├── pubspec.yaml               # Flutter dependencies
└── README.md                  # This file
```

## Features

- ✅ Clean Material Design 3 UI
- ✅ Form validation
- ✅ HTTP POST requests to backend
- ✅ Loading states and error handling
- ✅ Dynatrace RUM integration
- ✅ CORS-enabled Node.js backend

## Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.0.0 or higher)
- [Node.js](https://nodejs.org/) (v14 or higher)
- npm (comes with Node.js)
- Chrome browser (for web development)

## Setup Instructions

### 1. Flutter Web App Setup

1. **Navigate to the project root:**
   ```bash
   cd "Flutter Web"
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the Flutter web app:**
   ```bash
   flutter run -d chrome
   ```
   
   The app will open in Chrome, typically at `http://localhost:[random-port]`

### 2. Node.js Backend Setup

1. **Open a new terminal and navigate to the backend folder:**
   ```bash
   cd backend_sample
   ```

2. **Install Node.js dependencies:**
   ```bash
   npm install
   ```

3. **Start the backend server:**
   ```bash
   npm start
   ```
   
   The server will run on `http://localhost:3000`

   **For development with auto-reload:**
   ```bash
   npm run dev
   ```

### 3. Dynatrace RUM Configuration

The app is already configured with Dynatrace RUM. The JavaScript agent is loaded from:
```
https://js-cdn.dynatrace.com/jstag/148709fdc4b/bf15468yso/241c855da2eb6c97_complete.js
```

**To use your own Dynatrace tenant:**

1. Go to your Dynatrace tenant
2. Navigate to: **Settings → Web and mobile monitoring → Applications**
3. Create a new application or select an existing one
4. Go to the **Setup** tab and copy your RUM snippet
5. Replace the script tag in `web/index.html` (line 16)
6. Restart the Flutter app

## Usage

1. Ensure both the Flutter app and Node.js backend are running
2. Open the Flutter app in Chrome
3. Enter a message in the text field
4. Click "Send Message"
5. The app will POST the message to the backend as JSON: `{"greeting":"your message"}`
6. Success/error status will be displayed below the button

## API Endpoint

**POST** `/api/greeting`

**Request Body:**
```json
{
  "greeting": "Hello, World!"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Greeting received successfully",
  "receivedGreeting": "Hello, World!",
  "timestamp": "2026-01-20T12:00:00.000Z"
}
```

## Monitoring with Dynatrace

Once configured, Dynatrace will automatically capture:
- User sessions
- Page load performance
- User actions (button clicks, form submissions)
- XHR/Fetch requests to the backend
- JavaScript errors
- Resource loading times

**View your data:**
1. Go to your Dynatrace tenant
2. Navigate to **Applications & Microservices → Frontend**
3. Select your application
4. Explore user sessions, performance metrics, and user behavior

## Troubleshooting

### Flutter app shows blank screen
- Check the browser console (F12) for errors
- Ensure `flutter.js` is loading correctly
- Try running: `flutter clean && flutter pub get`

### CORS errors
- Ensure the Node.js backend is running
- Check that CORS is properly configured in `backend_sample/server.js`
- Verify the backend URL in `lib/main.dart` matches your server (default: `http://localhost:3000`)

### Connection refused / ERR_FAILED
- Make sure the Node.js backend is running on port 3000
- Check for port conflicts with other applications
- Run `lsof -i :3000` to see if another process is using the port

### Dynatrace not capturing data
- Verify the RUM script is loading (check Network tab in DevTools)
- Ensure the script loads before the Flutter app initializes
- Check that your Dynatrace application is properly configured
- Sessions may take a few minutes to appear in Dynatrace

## Development

### Modifying the Flutter App

Edit `lib/main.dart` to customize the UI or functionality. After making changes:
```bash
# Hot reload is supported - just press 'r' in the terminal
# Or for a full restart, press 'R'
```

### Modifying the Backend

Edit `backend_sample/server.js` to add new endpoints or modify behavior. If using nodemon:
```bash
npm run dev  # Auto-reloads on file changes
```

## Building for Production

### Flutter Web

```bash
flutter build web
```

The output will be in the `build/web` directory. Deploy these files to any static hosting service (Firebase Hosting, Netlify, Vercel, etc.).

### Node.js Backend

Deploy to any Node.js hosting platform:
- Heroku
- AWS Elastic Beanstalk
- Google Cloud Run
- Azure App Service
- DigitalOcean App Platform

**Remember to update the backend URL in `lib/main.dart` to your production API endpoint.**

## License

This is a sample application for demonstration purposes.

## Support

For issues related to:
- **Flutter**: [Flutter Documentation](https://flutter.dev/docs)
- **Dynatrace RUM**: [Dynatrace Documentation](https://www.dynatrace.com/support/help/platform-modules/digital-experience/web-applications)
- **Node.js/Express**: [Express Documentation](https://expressjs.com/)
