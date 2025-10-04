import '../../utils/environment_config.dart';

class AppConstants {
  // API Configuration
  static String get baseUrl => EnvironmentConfig.baseUrl;
  static Duration get apiTimeout => EnvironmentConfig.apiTimeout;
  
  // App Configuration
  static const String appName = 'BM Security';
  static const String appVersion = '1.0.0';
  
  // Storage Keys - Consolidated and consistent
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
  
  // Auth Token (placeholder - should be retrieved from storage)
  static String authToken = '';
  
  // API Endpoints - Consolidated
  static const String authLoginEndpoint = '/auth/login';
  static const String authRegisterEndpoint = '/auth/register';
  static const String authRefreshEndpoint = '/auth/refresh';
  static const String authLogoutEndpoint = '/auth/logout';
  static const String authVerifyEndpoint = '/auth/verify';
  static const String authProfileEndpoint = '/profile';
  
  static const String requestsEndpoint = '/requests';
  static const String requestsPendingEndpoint = '/requests/pending';
  static const String requestsInProgressEndpoint = '/requests/in-progress';
  static const String requestsCompletedEndpoint = '/requests/completed';
  static const String requestsTodayEndpoint = '/requests/today';
  static const String requestsStatusEndpoint = '/requests/status';
  static const String requestsCashCountEndpoint = '/requests/cash-count';
  static const String requestsDeliveryEndpoint = '/requests/delivery';
  
  static const String sosEndpoint = '/sos';
  static const String sosActiveEndpoint = '/sos/active';
  static const String sosMyEndpoint = '/sos/my-sos';
  
  static const String locationUpdateEndpoint = '/location/update';
  static const String locationHistoryEndpoint = '/location/history';
  
  static const String teamsEndpoint = '/teams';
  static const String teamsMyTeamEndpoint = '/teams/my-team';
  static const String teamsMembersEndpoint = '/teams/members';
  static const String teamsAddStaffEndpoint = '/teams/add-staff';
  
  // HTTP Headers
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer ';
  static const String contentTypeHeader = 'Content-Type';
  static const String applicationJson = 'application/json';
  
  // Location Configuration
  static const double defaultLatitude = -1.2921;
  static const double defaultLongitude = 36.8219;
  static const int locationUpdateInterval = 30; // seconds
  
  // UI Configuration
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 8.0;
  static const double defaultElevation = 2.0;
  
  // Colors (from BRD)
  static const int primaryColorValue = 0xFF0C5A99;
  static const int successColorValue = 0xFF4CAF50;
  static const int warningColorValue = 0xFFFF9800;
  static const int errorColorValue = 0xFFF44336;
  static const int backgroundColorValue = 0xFFF5F5F5;
  
  // Request Status (matching database myStatus field)
  static const int statusPending = 1;      // myStatus: 1 = Pending
  static const int statusInProgress = 2;    // myStatus: 2 = In Progress
  static const int statusCompleted = 3;     // myStatus: 3 = Completed
  static const int statusCancelled = 0;     // myStatus: 0 = Cancelled
  
  // User Roles (matching database)
  static const String roleAdmin = 'Admin';
  static const String roleSupervisor = 'Supervisor';
  static const String roleTeamLeader = 'Team Leader';
  static const String rolePolice = 'Police';
  static const String roleDriver = 'Driver';
  
  // Service Types (matching database)
  static const String serviceTypePickAndDrop = 'Pick and Drop';
  static const String serviceTypeBSS = 'BSS';
  static const String serviceTypeCDMCollection = 'CDM Collection';
  static const String serviceTypeATMLoading = 'ATM Loading';
  static const String serviceTypeAirlift = 'Airlift';
  static const String serviceTypeATMCollection = 'ATM Collection';
  static const String serviceTypeBankTransfer = 'Bank Transfer';
  static const String serviceTypeCallout = 'Callout';
  static const String serviceTypeMaintenance = 'Maintenance';
  
  // Cash Denominations
  static const List<int> cashDenominations = [1, 5, 10, 20, 50, 100, 200, 500, 1000];
  
  // File Upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];
  
  // Helper methods
  static String formatCurrency(double amount) {
    return amount.toStringAsFixed(2);
  }
  
  // Token helper methods
  static String getBearerToken(String token) {
    return '$bearerPrefix$token';
  }
  
  static String? extractTokenFromBearer(String? bearerToken) {
    if (bearerToken == null || !bearerToken.startsWith(bearerPrefix)) {
      return null;
    }
    return bearerToken.substring(bearerPrefix.length);
  }
  
  // API URL helper methods
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
  
  static String getAuthUrl(String endpoint) {
    return getFullUrl(endpoint);
  }
  
  static String getRequestsUrl(String endpoint) {
    return getFullUrl(endpoint);
  }
  
  static String getSosUrl(String endpoint) {
    return getFullUrl(endpoint);
  }
  
  static String getLocationUrl(String endpoint) {
    return getFullUrl(endpoint);
  }
  
  static String getTeamsUrl(String endpoint) {
    return getFullUrl(endpoint);
  }
}
