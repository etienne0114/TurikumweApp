import 'package:flutter/material.dart';
import '../presentation/screens/admin/admin_dashboard_screen.dart';
import '../presentation/screens/admin/moderation_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/auth/profile_setup_screen.dart';
import '../presentation/screens/events/events_screen.dart';
import '../presentation/screens/events/event_detail_screen.dart';
import '../presentation/screens/groups/groups_screen.dart';
import '../presentation/screens/groups/group_detail_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/messages/chats_list_screen.dart';
import '../presentation/screens/messages/chat_detail_screen.dart';
import '../presentation/screens/notifications/notifications_screen.dart';
import '../presentation/screens/onboarding/onboarding_screen.dart';
import '../presentation/screens/onboarding/splash_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/screens/stories/stories_screen.dart';
import '../presentation/screens/stories/story_detail_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String profileSetup = '/profile-setup';
  static const String home = '/home';
  static const String groups = '/groups';
  static const String groupDetail = '/group-detail';
  static const String events = '/events';
  static const String eventDetail = '/event-detail';
  static const String messages = '/messages';
  static const String chatDetail = '/chat-detail';
  static const String stories = '/stories';
  static const String storyDetail = '/story-detail';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String adminDashboard = '/admin-dashboard';
  static const String moderation = '/moderation';
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => SplashScreen());
      case AppRoutes.onboarding:
        return MaterialPageRoute(builder: (_) => OnboardingScreen());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => RegisterScreen());
      case AppRoutes.profileSetup:
        return MaterialPageRoute(builder: (_) => ProfileSetupScreen());
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => HomeScreen());
      case AppRoutes.groups:
        return MaterialPageRoute(builder: (_) => GroupsScreen());
      case AppRoutes.groupDetail:
        final groupId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => GroupDetailScreen(groupId: groupId),
        );
      case AppRoutes.events:
        return MaterialPageRoute(builder: (_) => EventsScreen());
      case AppRoutes.eventDetail:
        final eventId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => EventDetailScreen(eventId: eventId),
        );
      case AppRoutes.messages:
        return MaterialPageRoute(builder: (_) => ChatsListScreen());
      case AppRoutes.chatDetail:
        final arguments = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            chatId: arguments['chatId'],
            isGroup: arguments['isGroup'] ?? false,
          ),
        );
      case AppRoutes.stories:
        return MaterialPageRoute(builder: (_) => StoriesScreen());
      case AppRoutes.storyDetail:
        final storyId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => StoryDetailScreen(storyId: storyId),
        );
      case AppRoutes.profile:
        final userId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => ProfileScreen(userId: userId),
        );
      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => NotificationsScreen());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => SettingsScreen());
      case AppRoutes.adminDashboard:
        return MaterialPageRoute(builder: (_) => AdminDashboardScreen());
      case AppRoutes.moderation:
        return MaterialPageRoute(builder: (_) => ModerationScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}