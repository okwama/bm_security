# BM Security App - Rebuild Business Requirements Document (BRD)

## 🎯 Executive Summary

**What we're building:** A simple, fast, and user-friendly security management app for cash transportation services.

**Why rebuild:** The current app is complex and slow. We want something that's easy to use, fast, and maintainable.

**New Tech Stack:**
- **Frontend:** Flutter with Repository Pattern (clean architecture)
- **Backend:** NestJS with TypeORM and MySQL
- **Focus:** Speed, simplicity, and great user experience

---

## 🧒 Simple Explanation (Like Explaining to a Child)

### What does this app do?
Imagine you have a company that moves money from one place to another (like from a bank to an ATM). This app helps security guards and managers:

1. **Get Jobs** - Like getting a delivery job on your phone
2. **Track Location** - Like sharing your location with friends, but for work
3. **Count Money** - Like counting your piggy bank, but with lots of money
4. **Send Help** - Like calling 911, but for work emergencies
5. **Manage Teams** - Like being a team captain in sports

### How it works:
1. **Manager** creates a job (like "pick up money from Bank A and take it to ATM B")
2. **Security Guard** gets the job on their phone
3. **Guard** goes to the location and confirms pickup
4. **App** tracks the guard's location while they drive
5. **Guard** arrives at destination and confirms delivery
6. **Manager** can see everything that happened

---

## 🏗️ New Architecture (Simple Version)

### Frontend (Flutter App)
```
📱 Flutter App
├── 🎨 UI Layer (Screens & Widgets)
├── 🧠 Business Logic (Use Cases)
├── 📦 Data Layer (Repositories)
└── 🌐 Network Layer (API Calls)
```

### Backend (NestJS)
```
🖥️ NestJS Backend
├── 🎯 Controllers (Handle Requests)
├── 🔧 Services (Business Logic)
├── 📊 Repositories (Database Access)
└── 🗄️ Database (MySQL with TypeORM)
```

**Why this is better:**
- **Repository Pattern** = Clean separation, easy to test
- **NestJS** = Built-in features, less code to write
- **TypeORM** = Easy database operations
- **Clean Architecture** = Easy to understand and maintain

---

## 👥 User Roles (Who Uses the App)

### 1. **Admin/Manager**
- **What they do:** Create jobs, assign teams, monitor everything
- **What they see:** Dashboard with all jobs, team locations, reports
- **Main tasks:** Create requests, assign staff, view reports

### 2. **Crew Commander** (Team Leader)
- **What they do:** Lead a team, complete jobs, manage team members
- **What they see:** Their team's jobs, team member locations, job details
- **Main tasks:** Accept jobs, coordinate team, complete deliveries

### 3. **Security Guard** (Team Member)
- **What they do:** Complete individual tasks, report location
- **What they see:** Their assigned jobs, simple interface
- **Main tasks:** Pick up items, drive to destination, confirm delivery

### 4. **Vault Officer**
- **What they do:** Handle special deliveries to vaults
- **What they see:** Vault-specific jobs, cash counting interface
- **Main tasks:** Receive cash, verify amounts, manage vault inventory

---

## 🚀 Core Features (What the App Does)

### 1. **Job Management** (The Heart of the App)
**What it is:** Like a to-do list, but for security jobs

**How it works:**
- Manager creates a job (pickup location, delivery location, what to transport)
- System assigns it to a team
- Team gets notification
- Team completes the job step by step
- Manager sees the progress

**Job Types:**
- **Pick & Drop** - Simple transportation
- **ATM Collection** - Get money from ATM
- **Bank Transfer** - Move money between banks
- **Vault Delivery** - Deliver to secure vault

### 2. **Location Tracking** (Where Are You?)
**What it is:** Like sharing your location on WhatsApp, but automatic

**How it works:**
- When you start a job, app starts tracking
- App sends your location every 30 seconds
- Manager can see your route on a map
- When job is done, tracking stops

**Why it's important:**
- Safety - know where your team is
- Accountability - prove you went where you should
- Efficiency - optimize routes

### 3. **Cash Management** (Counting Money)
**What it is:** Like a calculator, but for counting different types of money

**How it works:**
- App shows different money types (1s, 5s, 10s, 20s, 50s, 100s, etc.)
- You count and enter the numbers
- App calculates total automatically
- Takes photo as proof
- Manager can verify later

### 4. **Emergency System** (SOS Button)
**What it is:** Like a panic button for emergencies

**How it works:**
- Big red SOS button on main screen
- Tap it when in trouble
- App sends your location to manager
- Calls emergency contacts
- Creates emergency record

### 5. **Team Management** (Who's in Your Team?)
**What it is:** Like a contact list, but for work teams

**How it works:**
- Create teams with different people
- Assign roles (commander, guard, etc.)
- See who's available
- Track team performance

---

## 📱 App Screens (What Users See)

### 1. **Login Screen**
- **Simple:** Just username and password
- **Fast:** Login in 2 seconds
- **Secure:** Remember login for convenience

### 2. **Home Dashboard**
- **Clean:** Big buttons for main actions
- **Quick:** See important info at a glance
- **Personal:** Shows your role and permissions

### 3. **Jobs List**
- **Organized:** Pending, In Progress, Completed tabs
- **Visual:** Color-coded by status
- **Quick:** Swipe actions for common tasks

### 4. **Job Details**
- **Complete:** All info needed in one place
- **Step-by-step:** Clear instructions
- **Progress:** See what's done and what's next

### 5. **Location Map**
- **Real-time:** Live location updates
- **Route:** See the path taken
- **Simple:** Easy to understand map view

### 6. **Cash Counting**
- **Visual:** Big buttons for each money type
- **Smart:** Auto-calculates totals
- **Photo:** Take picture as proof

### 7. **SOS Screen**
- **Big button:** Easy to find in emergency
- **Quick:** One tap to send alert
- **Clear:** Shows what happens when you tap

---

## 🎨 User Experience (UX) Principles

### 1. **Simplicity First**
- **One action per screen** - Don't overwhelm users
- **Big buttons** - Easy to tap
- **Clear labels** - No confusion
- **Minimal text** - Get to the point

### 2. **Speed Matters**
- **Fast loading** - No waiting
- **Offline support** - Works without internet
- **Quick actions** - Common tasks in 1-2 taps
- **Smart caching** - Remember what you need

### 3. **Visual Clarity**
- **Color coding** - Green for good, red for problems
- **Icons** - Pictures instead of words
- **Progress bars** - Show how much is done
- **Status indicators** - Always know what's happening

### 4. **Error Prevention**
- **Confirmation dialogs** - "Are you sure?"
- **Input validation** - Catch mistakes early
- **Helpful messages** - Tell users what to do
- **Undo options** - Fix mistakes easily

---

## 🗄️ Database Design (Simple Version)

### Main Tables (What We Store)

#### 1. **Users** (Who can use the app)
- ID, Name, Email, Role, Team
- Like a contact list

#### 2. **Jobs** (What needs to be done)
- ID, Type, Pickup Location, Delivery Location, Status
- Like a to-do list

#### 3. **Teams** (Groups of people)
- ID, Name, Members, Leader
- Like a sports team

#### 4. **Locations** (Where people are)
- ID, User ID, Latitude, Longitude, Time
- Like a GPS history

#### 5. **Cash Counts** (Money records)
- ID, Job ID, Different money types, Total, Photo
- Like a receipt

#### 6. **Emergencies** (SOS records)
- ID, User ID, Location, Time, Status
- Like a 911 call log

---

## 🔄 App Flow (How It Works)

### 1. **Job Creation Flow**
```
Manager → Create Job → Assign Team → Team Gets Notification
```

### 2. **Job Execution Flow**
```
Team Gets Job → Accept Job → Go to Pickup → Confirm Pickup → 
Start Tracking → Drive to Delivery → Confirm Delivery → Job Complete
```

### 3. **Emergency Flow**
```
Emergency Happens → Tap SOS → Send Location → Notify Manager → 
Call Emergency Contacts → Create Record
```

### 4. **Cash Counting Flow**
```
Start Counting → Enter Amounts → Take Photo → Confirm Total → 
Save Record → Continue with Job
```

---

## 🎯 Success Metrics (How We Know It's Working)

### 1. **Speed Metrics**
- **App loads in under 3 seconds**
- **Actions complete in under 2 seconds**
- **Location updates every 30 seconds**
- **No crashes or freezes**

### 2. **User Experience Metrics**
- **Users can complete jobs without help**
- **Less than 5 taps to do common tasks**
- **Clear error messages**
- **Intuitive navigation**

### 3. **Business Metrics**
- **Jobs completed on time**
- **Accurate cash counting**
- **No lost items or money**
- **Team coordination improved**

---

## 🛠️ Technical Requirements (Simple Version)

### Frontend (Flutter)
- **Repository Pattern** - Clean code organization
- **State Management** - Keep app data organized
- **Offline Support** - Work without internet
- **Background Services** - Keep tracking when app is closed
- **Push Notifications** - Alert users of new jobs

### Backend (NestJS)
- **REST API** - Simple communication
- **Authentication** - Secure user access
- **Real-time Updates** - Live location tracking
- **File Upload** - Handle photos and documents
- **Database Optimization** - Fast queries

### Database (MySQL + TypeORM)
- **Clean Schema** - Easy to understand
- **Proper Indexing** - Fast searches
- **Data Validation** - Prevent bad data
- **Backup Strategy** - Don't lose data

---

## 📋 Development Phases (Step by Step)

### Phase 1: Foundation (Week 1-2)
- Set up project structure
- Create basic authentication
- Design database schema
- Build simple UI screens

### Phase 2: Core Features (Week 3-4)
- Job management system
- Basic location tracking
- User role management
- Simple cash counting

### Phase 3: Advanced Features (Week 5-6)
- Real-time location tracking
- Emergency SOS system
- Team management
- Photo uploads

### Phase 4: Polish & Testing (Week 7-8)
- UI/UX improvements
- Performance optimization
- Bug fixes
- User testing

---

## 🎨 UI/UX Guidelines (Design Rules)

### 1. **Color Scheme**
- **Primary:** Blue (#0C5A99) - Trust and security
- **Success:** Green (#4CAF50) - Completed tasks
- **Warning:** Orange (#FF9800) - Attention needed
- **Error:** Red (#F44336) - Problems or emergencies
- **Background:** Light Gray (#F5F5F5) - Easy on eyes

### 2. **Typography**
- **Headers:** Bold, large, easy to read
- **Body Text:** Medium size, good contrast
- **Buttons:** Clear, action-oriented text
- **Labels:** Short, descriptive

### 3. **Layout**
- **Grid System:** Consistent spacing
- **Card Design:** Group related information
- **Navigation:** Bottom tabs for main sections
- **Actions:** Floating action buttons for primary actions

### 4. **Interactions**
- **Tap Feedback:** Visual response to touches
- **Loading States:** Show progress indicators
- **Error States:** Clear error messages
- **Success States:** Confirmation of actions

---

## 🔒 Security & Privacy (Keeping Things Safe)

### 1. **Data Protection**
- **Encrypt sensitive data** - Protect user information
- **Secure API calls** - Use HTTPS
- **Token-based auth** - Secure login system
- **Role-based access** - Users only see what they need

### 2. **Location Privacy**
- **Only track during work** - Stop when job is done
- **Secure storage** - Protect location data
- **User consent** - Clear permission requests
- **Data retention** - Delete old location data

### 3. **Financial Security**
- **Audit trails** - Track all money movements
- **Photo verification** - Visual proof of transactions
- **Approval workflows** - Multiple people verify
- **Backup systems** - Don't lose financial data

---

## 📊 Performance Requirements (How Fast It Should Be)

### 1. **Response Times**
- **App startup:** Under 3 seconds
- **Screen transitions:** Under 1 second
- **API calls:** Under 2 seconds
- **Location updates:** Every 30 seconds
- **Photo uploads:** Under 10 seconds

### 2. **Resource Usage**
- **Battery:** Minimal impact on phone battery
- **Data:** Efficient use of mobile data
- **Storage:** Small app size, efficient data storage
- **Memory:** Smooth performance on older phones

### 3. **Reliability**
- **Uptime:** 99.9% availability
- **Error rate:** Less than 1% of actions fail
- **Recovery:** Quick recovery from errors
- **Backup:** Automatic data backup

---

## 🧪 Testing Strategy (Making Sure It Works)

### 1. **User Testing**
- **Real users** - Test with actual security guards
- **Different scenarios** - Test various job types
- **Edge cases** - Test unusual situations
- **Feedback collection** - Listen to user suggestions

### 2. **Technical Testing**
- **Unit tests** - Test individual functions
- **Integration tests** - Test how parts work together
- **Performance tests** - Test speed and efficiency
- **Security tests** - Test for vulnerabilities

### 3. **Device Testing**
- **Different phones** - Test on various devices
- **Different networks** - Test on WiFi and mobile data
- **Different locations** - Test GPS in various areas
- **Different conditions** - Test in good and bad conditions

---

## 🚀 Deployment Strategy (Going Live)

### 1. **Staging Environment**
- **Test version** - Try everything before going live
- **Real data** - Use actual data for testing
- **User feedback** - Get input from real users
- **Bug fixes** - Fix problems before launch

### 2. **Production Deployment**
- **Gradual rollout** - Start with small group
- **Monitoring** - Watch for problems
- **Quick fixes** - Fix issues immediately
- **User support** - Help users with problems

### 3. **Maintenance**
- **Regular updates** - Keep app current
- **Bug fixes** - Fix problems as they arise
- **Feature additions** - Add new features based on feedback
- **Performance monitoring** - Keep app running smoothly

---

## 📈 Future Enhancements (What We Can Add Later)

### 1. **Advanced Features**
- **Route optimization** - Find best paths
- **Predictive analytics** - Predict job completion times
- **Integration with other systems** - Connect with bank systems
- **Advanced reporting** - Detailed analytics and reports

### 2. **Mobile Features**
- **Offline mode** - Work without internet
- **Voice commands** - Control app with voice
- **Biometric login** - Use fingerprint or face
- **Smart notifications** - Intelligent alerts

### 3. **Business Features**
- **Cost tracking** - Monitor expenses
- **Performance metrics** - Team and individual stats
- **Compliance reporting** - Meet regulatory requirements
- **Integration APIs** - Connect with other business systems

---

## 🎯 Success Criteria (How We Know We Succeeded)

### 1. **User Adoption**
- **Easy onboarding** - New users can start quickly
- **High usage** - Users actively use the app
- **Positive feedback** - Users like the app
- **Low support requests** - App works without help

### 2. **Business Impact**
- **Faster job completion** - Jobs done quicker
- **Better accuracy** - Fewer mistakes
- **Improved safety** - Better emergency response
- **Cost savings** - More efficient operations

### 3. **Technical Excellence**
- **Fast performance** - App runs smoothly
- **Reliable operation** - Works when needed
- **Easy maintenance** - Easy to update and fix
- **Scalable architecture** - Can grow with business

---

## 📝 Conclusion

This BRD outlines a complete rebuild of the BM Security app with a focus on:

1. **Simplicity** - Easy to understand and use
2. **Speed** - Fast performance and quick actions
3. **Reliability** - Works when you need it
4. **Maintainability** - Easy to update and improve

The new architecture using Repository pattern, NestJS, and TypeORM will provide a solid foundation for a modern, scalable security management application.

**Key Success Factors:**
- Clean, intuitive user interface
- Fast, reliable performance
- Simple, maintainable code
- Comprehensive testing
- User-focused design

This approach will result in an app that security professionals will love to use and that will significantly improve their daily operations.

---

*This BRD serves as the foundation for rebuilding the BM Security app with modern technologies and user-centered design principles.*
