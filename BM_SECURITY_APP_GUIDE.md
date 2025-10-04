# BM Security App - Complete Development Guide

## 🎯 Quick Summary for Students

**What is this app?** BM Security is a mobile application for managing security operations, particularly cash transportation services. Think of it like Uber, but for security companies that transport money between banks, ATMs, and vaults.

**What will you learn?** This project teaches you how to build a complete full-stack mobile application with:
- Real-time GPS tracking
- User authentication and role management
- Complex business workflows (cash counting, seal management)
- Background services and notifications
- Emergency response systems

**Difficulty Level:** Intermediate to Advanced (8-week project)
**Technologies:** Flutter, Node.js, MySQL, JWT Authentication, GPS/Location Services

**Perfect for:** Students learning mobile development, backend APIs, real-time systems, and business application development.

---

## 📋 Table of Contents
1. [App Overview](#app-overview)
2. [System Architecture](#system-architecture)
3. [Core Features](#core-features)
4. [Technology Stack](#technology-stack)
5. [Database Design](#database-design)
6. [Backend API Development](#backend-api-development)
7. [Flutter Frontend Development](#flutter-frontend-development)
8. [Key Implementation Details](#key-implementation-details)
9. [Step-by-Step Development Process](#step-by-step-development-process)
10. [Testing & Deployment](#testing--deployment)

---

## 🎯 App Overview

**BM Security** is a comprehensive security management system designed for cash transportation and security services. The app manages different types of security operations including ATM collections, cash pickups, bank-to-bank transfers, and emergency response systems.

### Main Purpose
- **Cash Transportation Management**: Track and manage cash collection and delivery operations
- **Security Personnel Management**: Manage security teams, assignments, and real-time tracking
- **Emergency Response**: SOS functionality with location tracking
- **Service Request Management**: Handle different types of security service requests
- **Real-time Location Tracking**: Monitor security personnel during operations

---

## 🏗️ System Architecture

### Architecture Pattern
- **Frontend**: Flutter (Cross-platform mobile app)
- **Backend**: Node.js with Express.js
- **Database**: MySQL with Prisma ORM
- **Authentication**: JWT-based authentication
- **Real-time Features**: Location tracking with background services

### System Components
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │◄──►│   Node.js API   │◄──►│   MySQL DB      │
│                 │    │                 │    │                 │
│ • Authentication│    │ • REST APIs     │    │ • User Data     │
│ • Location Track│    │ • JWT Auth      │    │ • Requests      │
│ • Service Mgmt  │    │ • Real-time     │    │ • Locations     │
│ • SOS System    │    │ • File Upload   │    │ • Transactions  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Service Flow Architecture
```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   PENDING   │───►│ IN PROGRESS │───►│ COMPLETED   │    │   SOS       │
│             │    │             │    │             │    │             │
│ • New Req   │    │ • Pickup    │    │ • Delivery  │    │ • Emergency │
│ • Assignment│    │ • Tracking  │    │ • Confirmed │    │ • Location  │
│ • Planning  │    │ • Cash Count│    │ • History   │    │ • Alert     │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │                   │
       └───────────────────┼───────────────────┼───────────────────┘
                           │                   │
                    ┌─────────────┐    ┌─────────────┐
                    │  LOCATION   │    │   CASH      │
                    │  TRACKING   │    │ MANAGEMENT  │
                    │             │    │             │
                    │ • GPS       │    │ • Counting  │
                    │ • History   │    │ • Seals     │
                    │ • Routes    │    │ • Verification│
                    └─────────────┘    └─────────────┘
```

---

## 🚀 Core Features

### 1. **Authentication & User Management**
- Employee-based login system
- Role-based access control (Crew Commander, Vault Officer, etc.)
- JWT token management with refresh tokens
- User profile management

### 2. **Service Request Management**
- **Pick and Drop**: Simple cash transportation
- **ATM Collection**: ATM cash collection with seal management
- **BSS (Bank to Bank)**: Bank-to-bank cash transfers
- **BSS Vault**: Bank to vault transfers
- **CDM Collection**: Cash deposit machine collections

### 3. **Real-time Location Tracking**
- GPS-based location tracking
- Background location services
- Route tracking during operations
- Location history storage

### 4. **SOS Emergency System**
- Emergency alert functionality
- Automatic location sharing
- Emergency contact integration
- Real-time emergency status updates

### 5. **Team Management**
- Security team creation and management
- Team member assignments
- Crew commander oversight
- Team performance tracking

### 6. **Cash Management**
- Cash denomination counting
- Seal number management
- Cash verification systems
- Transaction recording

---

## 🛠️ Technology Stack

### Frontend (Flutter)
```yaml
dependencies:
  # State Management
  get: ^4.6.5
  get_storage: ^2.1.1
  
  # UI & Styling
  google_fonts: ^6.2.1
  flutter_svg: ^2.0.5
  shimmer: ^3.0.0
  
  # Location & Maps
  geolocator: ^11.0.0
  google_maps_flutter: ^2.5.3
  
  # Network & Data
  http: ^1.2.0
  dio: ^5.4.3+1
  
  # Permissions & Background
  permission_handler: ^11.3.1
  workmanager: ^0.5.2
  flutter_background_service: ^5.0.1
  
  # Media & Files
  image_picker: ^1.1.2
  cached_network_image: ^3.3.1
```

### Backend (Node.js)
```json
{
  "dependencies": {
    "express": "^4.18.2",
    "prisma": "^5.0.0",
    "@prisma/client": "^5.0.0",
    "jsonwebtoken": "^9.0.0",
    "bcryptjs": "^2.4.3",
    "multer": "^1.4.5",
    "cors": "^2.8.5",
    "helmet": "^7.0.0"
  }
}
```

### Database (MySQL)
- **Primary Database**: MySQL
- **ORM**: Prisma
- **Key Tables**: Users, Requests, Locations, Teams, Cash Counts

---

## 🗄️ Database Design

### Core Tables

#### 1. **Staff Table** (Users)
```sql
CREATE TABLE staff (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(200) NOT NULL,
  phone VARCHAR(20),
  password VARCHAR(255),
  roleId INT DEFAULT 0,
  role VARCHAR(200),
  emplNo VARCHAR(100) UNIQUE,
  idNo INT,
  photoUrl VARCHAR(200),
  status INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 2. **Requests Table** (Service Requests)
```sql
CREATE TABLE requests (
  id INT PRIMARY KEY AUTO_INCREMENT,
  userId INT,
  userName VARCHAR(255),
  serviceTypeId INT,
  price DECIMAL(11,2),
  pickupLocation VARCHAR(255),
  deliveryLocation VARCHAR(255),
  pickupDate DATETIME,
  description TEXT,
  status VARCHAR(20),
  staff_id INT,
  latitude FLOAT,
  longitude FLOAT,
  branch_id INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 3. **Service Types**
```sql
CREATE TABLE service_types (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 4. **Location Tracking**
```sql
CREATE TABLE crew_locations (
  id INT PRIMARY KEY AUTO_INCREMENT,
  requestId INT,
  staffId INT,
  latitude FLOAT,
  longitude FLOAT,
  capturedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 5. **Cash Management**
```sql
CREATE TABLE cash_counts (
  id INT PRIMARY KEY AUTO_INCREMENT,
  request_id INT,
  staff_id INT,
  ones INT DEFAULT 0,
  fives INT DEFAULT 0,
  tens INT DEFAULT 0,
  twenties INT DEFAULT 0,
  forties INT DEFAULT 0,
  fifties INT DEFAULT 0,
  hundreds INT DEFAULT 0,
  twoHundreds INT DEFAULT 0,
  fiveHundreds INT DEFAULT 0,
  thousands INT DEFAULT 0,
  totalAmount INT DEFAULT 0,
  sealNumber VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## 🔧 Backend API Development

### 1. **Project Structure**
```
api/
├── controllers/
│   ├── auth.controller.js
│   ├── request.controller.js
│   └── location.controller.js
├── middleware/
│   ├── auth.js
│   └── validation.js
├── services/
│   ├── auth.service.js
│   └── request.service.js
├── prisma/
│   ├── schema.prisma
│   └── migrations/
├── routes/
│   ├── auth.js
│   ├── requests.js
│   └── locations.js
└── app.js
```

### 2. **Authentication Controller**
```javascript
// api/controllers/auth.controller.js
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

const login = async (req, res) => {
  try {
    const { emplNo, password } = req.body;
    
    // Find user by employee number
    const user = await prisma.staff.findFirst({
      where: { emplNo: emplNo.toString().trim() }
    });

    if (!user) {
      return res.status(401).json({ 
        message: 'Invalid credentials' 
      });
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ 
        message: 'Invalid credentials' 
      });
    }

    // Generate JWT tokens
    const accessToken = jwt.sign(
      { userId: user.id, emplNo: user.emplNo },
      process.env.JWT_SECRET,
      { expiresIn: '8h' }
    );

    res.json({
      message: 'Login successful',
      user: {
        id: user.id,
        name: user.name,
        emplNo: user.emplNo,
        role: user.role
      },
      accessToken
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
};
```

### 3. **Request Management Controller**
```javascript
// api/controllers/request.controller.js
const getPendingRequests = async (req, res) => {
  try {
    const requests = await prisma.request.findMany({
      where: { status: 'pending' },
      include: {
        ServiceType: true,
        user: true,
        branches: true
      }
    });

    res.json(requests);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching requests' });
  }
};

const confirmPickup = async (req, res) => {
  try {
    const { requestId } = req.params;
    const { cashCounts, sealNumber } = req.body;

    // Update request status
    await prisma.request.update({
      where: { id: parseInt(requestId) },
      data: { status: 'in_progress' }
    });

    // Create cash count record if provided
    if (cashCounts) {
      await prisma.cash_counts.create({
        data: {
          request_id: parseInt(requestId),
          staff_id: req.user.userId,
          ...cashCounts
        }
      });
    }

    res.json({ message: 'Pickup confirmed successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Error confirming pickup' });
  }
};
```

---

## 📱 Flutter Frontend Development

### 1. **Project Structure**
```
lib/
├── controllers/
│   ├── auth_controller.dart
│   └── home_controller.dart
├── services/
│   ├── http/
│   │   ├── auth_service.dart
│   │   └── api_service.dart
│   ├── location/
│   │   ├── location_service.dart
│   │   └── location_manager.dart
│   └── requisitions/
│       ├── requisitions_service.dart
│       └── request_fetcher.dart
├── pages/
│   ├── login/
│   ├── home/
│   ├── requisitions/
│   │   ├── pending/
│   │   ├── inProgress/
│   │   └── completed/
│   ├── sos/
│   └── profile/
├── components/
└── utils/
```

### 2. **Authentication Service**
```dart
// lib/services/http/auth_service.dart
class AuthService {
  static const String _baseUrl = 'YOUR_API_BASE_URL';
  
  Future<Map<String, dynamic>> login(String emplNo, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'emplNo': emplNo,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveToken(data['accessToken']);
        return data;
      } else {
        throw Exception('Login failed');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    final storage = GetStorage();
    await storage.write('token', token);
  }
}
```

### 3. **Location Tracking Service**
```dart
// lib/services/location/location_service.dart
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  bool _isTracking = false;
  String? _currentRequestId;
  Timer? _locationTimer;

  Future<bool> startTracking(String requestId) async {
    try {
      _currentRequestId = requestId;
      _isTracking = true;

      // Get initial position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _sendLocationUpdate(position);

      // Start periodic updates
      _locationTimer = Timer.periodic(
        Duration(seconds: 30),
        (timer) => _updateLocation(),
      );

      return true;
    } catch (e) {
      _isTracking = false;
      return false;
    }
  }

  Future<void> _updateLocation() async {
    if (!_isTracking) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _sendLocationUpdate(position);
    } catch (e) {
      print('Location update failed: $e');
    }
  }

  Future<void> _sendLocationUpdate(Position position) async {
    // Send location to server
    final response = await http.post(
      Uri.parse('$_baseUrl/locations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _getToken()}',
      },
      body: jsonEncode({
        'requestId': _currentRequestId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
  }
}
```

### 4. **Home Page with Navigation**
```dart
// lib/pages/home/home_page.dart
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BM Security'),
        backgroundColor: Color(0xFF0C5A99),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(16),
        children: [
          MenuTile(
            title: 'PENDING',
            icon: Icons.pending_outlined,
            onTap: () => Get.to(() => PendingRequestsPage()),
          ),
          MenuTile(
            title: 'IN PROGRESS',
            icon: Icons.watch_later_outlined,
            onTap: () => Get.to(() => InProgressPage()),
          ),
          MenuTile(
            title: 'COMPLETED',
            icon: Icons.done_all_outlined,
            onTap: () => Get.to(() => CompletedPage()),
          ),
          MenuTile(
            title: 'SOS',
            icon: Icons.emergency_outlined,
            onTap: () => Get.to(() => SOSPage()),
          ),
          MenuTile(
            title: 'My Team',
            icon: Icons.group,
            onTap: () => Get.to(() => MyTeamPage()),
          ),
          MenuTile(
            title: 'Profile',
            icon: Icons.person,
            onTap: () => Get.to(() => ProfilePage()),
          ),
        ],
      ),
    );
  }
}
```

---

## 🔑 Key Implementation Details

### 1. **State Management with GetX**
```dart
// lib/controllers/auth_controller.dart
class AuthController extends GetxController {
  final _isAuthenticated = false.obs;
  final _user = Rxn<User>();
  
  bool get isAuthenticated => _isAuthenticated.value;
  User? get user => _user.value;

  Future<void> login(String emplNo, String password) async {
    try {
      final result = await AuthService().login(emplNo, password);
      _user.value = User.fromJson(result['user']);
      _isAuthenticated.value = true;
      Get.offAllNamed('/home');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }
}
```

### 2. **Permission Handling**
```dart
// lib/utils/permissions.dart
class PermissionHandler {
  static Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    return permission == LocationPermission.whileInUse ||
           permission == LocationPermission.always;
  }

  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status == PermissionStatus.granted;
  }
}
```

### 3. **Background Location Tracking**
```dart
// lib/services/background_service.dart
class BackgroundLocationService {
  static void initialize() {
    Workmanager().initialize(callbackDispatcher);
  }

  static void startLocationTracking(String requestId) {
    Workmanager().registerPeriodicTask(
      "location-tracking-$requestId",
      "location-tracking",
      frequency: Duration(minutes: 1),
      inputData: {"requestId": requestId},
    );
  }
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == "location-tracking") {
      // Get location and send to server
      final position = await Geolocator.getCurrentPosition();
      await sendLocationToServer(position, inputData['requestId']);
    }
    return Future.value(true);
  });
}
```

---

## 📋 Step-by-Step Development Process

### Phase 1: Project Setup (Week 1)
1. **Backend Setup**
   ```bash
   mkdir bm-security-api
   cd bm-security-api
   npm init -y
   npm install express prisma @prisma/client jsonwebtoken bcryptjs cors
   npx prisma init
   ```

2. **Flutter Setup**
   ```bash
   flutter create bm_security
   cd bm_security
   # Add dependencies to pubspec.yaml
   flutter pub get
   ```

3. **Database Setup**
   - Create MySQL database
   - Configure Prisma schema
   - Run migrations

### Phase 2: Authentication System (Week 2)
1. **Backend Authentication**
   - Create user model and authentication endpoints
   - Implement JWT token generation and validation
   - Add password hashing with bcrypt

2. **Flutter Authentication**
   - Create login UI
   - Implement authentication service
   - Add token storage with GetStorage
   - Create authentication controller

### Phase 3: Core Features (Week 3-4)
1. **Request Management**
   - Create request models and API endpoints
   - Implement CRUD operations for requests
   - Add service type management

2. **Flutter UI Development**
   - Create home page with navigation
   - Build request listing pages
   - Implement request detail views

### Phase 4: Location Tracking (Week 5)
1. **Location Services**
   - Implement GPS location tracking
   - Create background location service
   - Add location data storage

2. **Real-time Updates**
   - Implement periodic location updates
   - Add location history tracking
   - Create location visualization

### Phase 5: Advanced Features (Week 6-7)
1. **SOS System**
   - Create emergency alert functionality
   - Implement automatic location sharing
   - Add emergency contact integration

2. **Cash Management**
   - Implement cash counting system
   - Add seal number management
   - Create cash verification workflows

### Phase 6: Testing & Polish (Week 8)
1. **Testing**
   - Unit tests for services
   - Integration tests for API endpoints
   - UI testing for critical flows

2. **Performance Optimization**
   - Optimize location tracking
   - Implement caching strategies
   - Add loading states and error handling

---

## 🧪 Testing & Deployment

### 1. **Testing Strategy**
```dart
// test/services/auth_service_test.dart
void main() {
  group('AuthService Tests', () {
    test('should login successfully with valid credentials', () async {
      // Mock HTTP response
      when(mockHttp.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response('{"accessToken": "token"}', 200));
      
      final result = await AuthService().login('12345', 'password');
      expect(result['accessToken'], isNotNull);
    });
  });
}
```

### 2. **Deployment Checklist**
- [ ] Environment variables configured
- [ ] Database migrations applied
- [ ] SSL certificates installed
- [ ] API endpoints tested
- [ ] Mobile app signed and built
- [ ] Background services configured
- [ ] Push notifications set up

### 3. **Production Considerations**
- **Security**: Implement rate limiting, input validation, and secure headers
- **Performance**: Add database indexing, implement caching, optimize queries
- **Monitoring**: Set up logging, error tracking, and performance monitoring
- **Backup**: Implement automated database backups and disaster recovery

---

## 🎓 Learning Outcomes

After completing this project, students will understand:

1. **Full-Stack Development**: Building complete mobile applications with backend APIs
2. **Real-time Systems**: Implementing location tracking and background services
3. **Security**: Authentication, authorization, and secure data handling
4. **Database Design**: Complex relational database schemas and ORM usage
5. **Mobile Development**: Flutter app development with state management
6. **API Development**: RESTful API design and implementation
7. **System Architecture**: Scalable application architecture patterns

---

## 📚 Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Prisma Documentation](https://www.prisma.io/docs/)
- [Express.js Guide](https://expressjs.com/)
- [JWT Authentication](https://jwt.io/introduction)
- [Google Maps Flutter Plugin](https://pub.dev/packages/google_maps_flutter)
- [GetX State Management](https://github.com/jonataslaw/getx)

---

## 🚀 Getting Started

1. **Clone the repository structure**
2. **Set up your development environment**
3. **Follow the step-by-step process**
4. **Customize features based on your requirements**
5. **Test thoroughly before deployment**

This guide provides a comprehensive foundation for building a security management system similar to BM Security. Adapt the features and complexity based on your specific requirements and learning objectives.
