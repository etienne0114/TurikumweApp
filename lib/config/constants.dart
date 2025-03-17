// config/constants.dart
class AppConstants {
  // App Info
  static const String appName = 'Turikumwe';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Unite. Connect. Grow.';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String postsCollection = 'posts';
  static const String commentsCollection = 'comments';
  static const String groupsCollection = 'groups';
  static const String eventsCollection = 'events';
  static const String storiesCollection = 'stories';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String notificationsCollection = 'notifications';
  
  // Storage Paths
  static const String profileImagesPath = 'profile_images';
  static const String postImagesPath = 'post_images';
  static const String groupImagesPath = 'group_images';
  static const String eventImagesPath = 'event_images';
  static const String storyImagesPath = 'story_images';
  
  // Shared Preferences Keys
  static const String userIdKey = 'user_id';
  static const String onboardingCompletedKey = 'onboarding_completed';
  static const String tokenKey = 'token';
  static const String themeKey = 'theme';
  static const String languageKey = 'language';
  
  // User Roles
  static const String userRole = 'user';
  static const String moderatorRole = 'moderator';
  static const String adminRole = 'admin';
  
  // Rwanda Districts
  static const List<String> rwandaDistricts = [
    'Bugesera', 'Burera', 'Gakenke', 'Gasabo', 'Gatsibo',
    'Gicumbi', 'Gisagara', 'Huye', 'Kamonyi', 'Karongi',
    'Kayonza', 'Kicukiro', 'Kirehe', 'Muhanga', 'Musanze',
    'Ngoma', 'Ngororero', 'Nyabihu', 'Nyagatare', 'Nyamagabe',
    'Nyamasheke', 'Nyanza', 'Nyarugenge', 'Nyaruguru', 'Rubavu',
    'Ruhango', 'Rulindo', 'Rusizi', 'Rutsiro', 'Rwamagana'
  ];
  
  // Default Settings
  static const int defaultPageSize = 20;
  static const int maxProfileImageSize = 2 * 1024 * 1024; // 2MB
  static const int maxPostImageSize = 5 * 1024 * 1024; // 5MB
  static const Duration sessionTimeout = Duration(days: 30);
}