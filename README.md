# Flutter Web Authentication Application

A Flutter web application with authentication, hash generation, and calculator features, connected to a Node.js backend with CSV-based user authentication and integrated with Dynatrace Real User Monitoring (RUM).

## Project Structure

```
.
├── lib/
│   └── main.dart              # Flutter app with login, menu, hash, and calculator pages
├── web/
│   ├── index.html             # HTML entry point with Dynatrace RUM
│   └── manifest.json          # Web app manifest
├── backend_sample/
│   ├── server.js              # Node.js Express server with authentication & APIs
│   ├── users.csv              # User credentials database
│   ├── package.json           # Node.js dependencies
│   └── README.md              # Backend documentation
├── pubspec.yaml               # Flutter dependencies
└── README.md                  # This file
```

## Features

- ✅ **User Authentication** - Login with username/password from CSV file
- ✅ **Menu System** - Choose between hash generation and calculator
- ✅ **Hash Generator** - Generate SHA-256 hash from text messages
- ✅ **Simple Calculator** - Perform basic arithmetic (+, -, *, /)
- ✅ Clean Material Design 3 UI with navigation
- ✅ Form validation and error handling
- ✅ HTTP POST requests to backend
- ✅ Loading states and success/error messages
- ✅ Dynatrace RUM integration
- ✅ CORS-enabled Node.js backend

## Default Users

The following users are available in `backend_sample/users.csv`:

| Username | Password |
|----------|----------|
| admin | admin123 |
| user1 | password1 |
| user2 | password2 |
| testuser | test123 |

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
   
   **Note:** The app is configured to use the HTML renderer (set in `web/index.html`) for better compatibility and smaller bundle size.

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

### 1. Login
1. Ensure both the Flutter app and Node.js backend are running
2. Open the Flutter app in Chrome
3. Use one of the default credentials (e.g., `admin` / `admin123`)
4. Click "Login"

### 2. Select Feature from Menu
After successful login, you'll see two options:

#### Generate Hash
- Enter any text message
- Click "Generate Hash"
- The backend will calculate the SHA-256 hash
- The hash will be displayed and can be copied

#### Simple Calculator
- Enter the first number
- Select an operator (+, -, *, /)
- Enter the second number
- Click "Calculate"
- The result will be displayed

### 3. Logout
Click the logout icon in the app bar to return to the login screen.

## API Endpoints

### POST /api/login
Authenticate user credentials.

**Request:**
```json
{
  "username": "admin",
  "password": "admin123"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Login successful",
  "username": "admin"
}
```

**Response (401):**
```json
{
  "success": false,
  "message": "Invalid username or password"
}
```

### POST /api/hash
Generate SHA-256 hash from message.

**Request:**
```json
{
  "message": "Hello, World!"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Hash generated successfully",
  "originalMessage": "Hello, World!",
  "hash": "dffd6021bb2bd5b0af676290809ec3a53191dd81c7f70a4b28688a362182986f",
  "algorithm": "SHA-256",
  "timestamp": "2026-01-22T12:00:00.000Z"
}
```

### POST /api/calculate
Perform basic arithmetic calculation.

**Request:**
```json
{
  "firstNumber": "10",
  "operator": "+",
  "secondNumber": "5"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Calculation completed",
  "firstNumber": 10,
  "operator": "+",
  "secondNumber": 5,
  "result": 15,
  "timestamp": "2026-01-22T12:00:00.000Z"
}
```

**Response (400 - Division by zero):**
```json
{
  "success": false,
  "message": "Cannot divide by zero"
}
```

### GET /health
Health check endpoint.

**Response:**
```json
{
  "status": "ok",
  "usersLoaded": 4,
  "timestamp": "2026-01-22T12:00:00.000Z"
}
```

## Monitoring with Dynatrace

Once configured, Dynatrace will automatically capture:
- User sessions and authentication flows
- Page load performance across all screens
- User actions (login attempts, hash generation, calculations)
- XHR/Fetch requests to all backend endpoints
- JavaScript errors
- Resource loading times
- User navigation patterns between screens

**View your data:**
1. Go to your Dynatrace tenant
2. Navigate to **Applications & Microservices → Frontend**
3. Select your application
4. Explore user sessions, performance metrics, and user behavior
5. Track conversion funnels (login → menu → feature usage)

## Troubleshooting

### Flutter app shows blank screen
- Check the browser console (F12) for errors
- Ensure `flutter.js` is loading correctly
- Try running: `flutter clean && flutter pub get`

### CORS errors
- Ensure the Node.js backend is running
- Check that CORS is properly configured in `backend_sample/server.js`
- Verify all backend URLs in `lib/main.dart` match your server (default: `http://localhost:3000`)

### Connection refused / ERR_FAILED
- Make sure the Node.js backend is running on port 3000
- Check for port conflicts with other applications
- Run `lsof -i :3000` to see if another process is using the port
- Ensure `users.csv` exists and is readable by the backend

### Login fails with valid credentials
- Check that `backend_sample/users.csv` exists and has the correct format
- Verify the backend logs show "Loaded X users from CSV"
- Check for trailing spaces or special characters in the CSV file
- Ensure the backend restarted after adding/modifying users

### Dynatrace not capturing data
- Verify the RUM script is loading (check Network tab in DevTools)
- Ensure the script loads before the Flutter app initializes
- Check that your Dynatrace application is properly configured
- Sessions may take a few minutes to appear in Dynatrace

## Development

### Modifying the Flutter App

Edit `lib/main.dart` to customize the UI, add new features, or modify existing screens. The app has four main screens:
- `LoginPage` - Authentication screen
- `MenuPage` - Main menu with feature selection
- `HashGeneratorPage` - Hash generation feature
- `CalculatorPage` - Calculator feature

After making changes:
```bash
# Hot reload is supported - just press 'r' in the terminal
# Or for a full restart, press 'R'
```

### Modifying the Backend

Edit `backend_sample/server.js` to add new endpoints or modify behavior. If using nodemon:
```bash
npm run dev  # Auto-reloads on file changes
```

### Adding Users

Edit `backend_sample/users.csv` to add or modify user credentials:
```csv
username,password
newuser,newpassword
```

Restart the backend server for changes to take effect.

## Building for Production

### Flutter Web

```bash
flutter build web
```

The output will be in the `build/web` directory. Deploy these files to any static hosting service (Firebase Hosting, Netlify, Vercel, etc.).

**Why HTML renderer?**
- Smaller download size (no CanvasKit WebAssembly)
- Better text rendering and accessibility
- Faster initial load time
- Better compatibility with older browsers
- Configured in `web/index.html` with `renderer: "html"`

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
