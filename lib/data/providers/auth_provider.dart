// data/providers/auth_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';
import '../../config/constants.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  final UserRepository _userRepository = UserRepository();
  
  User? get currentUser => _authRepository.currentUser;
  Stream<User?> get authStateChanges => _authRepository.authStateChanges;
  
  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    final result = await _authRepository.registerWithEmailAndPassword(
      email, 
      password,
    );
    
    // Update display name
    await result.user?.updateDisplayName(displayName);
    
    // Create initial user document
    await _userRepository.createUserDocument(
      uid: result.user!.uid,
      email: email,
      displayName: displayName,
    );
    
    return result;
  }
  
  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final result = await _authRepository.signInWithEmailAndPassword(
      email,
      password,
    );
    
    // Save user ID to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userIdKey, result.user!.uid);
    
    // Update last active
    await _userRepository.updateUserLastActive(result.user!.uid);
    
    notifyListeners();
    return result;
  }
  
  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    final result = await _authRepository.signInWithGoogle();
    
    // Save user ID to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userIdKey, result.user!.uid);
    
    // Check if this is a new user
    final isNewUser = result.additionalUserInfo?.isNewUser ?? false;
    
    if (isNewUser) {
      // Create initial user document
      await _userRepository.createUserDocument(
        uid: result.user!.uid,
        email: result.user!.email ?? '',
        displayName: result.user!.displayName ?? 'User',
        photoUrl: result.user!.photoURL,
      );
    } else {
      // Update last active
      await _userRepository.updateUserLastActive(result.user!.uid);
    }
    
    notifyListeners();
    return isNewUser;
  }
  
  // Sign out
  Future<void> signOut() async {
    // Update last active before signing out
    if (currentUser != null) {
      await _userRepository.updateUserLastActive(currentUser!.uid);
    }
    
    // Clear local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.tokenKey);
    
    await _authRepository.signOut();
    notifyListeners();
  }
  
  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _authRepository.sendPasswordResetEmail(email);
  }
}