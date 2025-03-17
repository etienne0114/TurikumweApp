// core/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/constants.dart';
import '../../data/models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get the current user
  User? get currentUser => _auth.currentUser;
  
  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
    String email, 
    String password
  ) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create initial user profile in Firestore
      await _createUserDocument(result.user!);
      
      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email, 
    String password
  ) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update user's last active timestamp
      await _updateUserLastActive(result.user!.uid);
      
      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw 'Google sign in aborted';
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final UserCredential result = await _auth.signInWithCredential(credential);
      
      // Check if this is a new user
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(result.user!.uid)
          .get();
      
      if (!userDoc.exists) {
        await _createUserDocument(result.user!);
      } else {
        await _updateUserLastActive(result.user!.uid);
      }
      
      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Save user's last active timestamp before signing out
      if (currentUser != null) {
        await _updateUserLastActive(currentUser!.uid);
      }
      
      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userIdKey);
      await prefs.remove(AppConstants.tokenKey);
      
      // Sign out from Google
      await _googleSignIn.signOut();
      
      // Sign out from Firebase
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      if (currentUser == null) {
        throw 'No user logged in';
      }
      
      await currentUser!.updateDisplayName(displayName);
      await currentUser!.updatePhotoURL(photoURL);
      
      // Update the user document in Firestore
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUser!.uid)
          .update({
        'displayName': displayName,
        'photoUrl': photoURL,
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Create initial user document in Firestore
  Future<void> _createUserDocument(User user) async {
    try {
      final newUser = UserModel(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? user.email?.split('@')[0] ?? 'New User',
        photoUrl: user.photoURL,
        phone: user.phoneNumber,
        district: '',
        bio: '',
        interests: [],
        role: AppConstants.userRole,
        groups: [],
        following: [],
        followers: [],
        isVerified: false,
        createdAt: Timestamp.now(),
        lastActive: Timestamp.now(),
      );
      
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(newUser.toFirestore());
      
      // Save user ID to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userIdKey, user.uid);
    } catch (e) {
      rethrow;
    }
  }

  // Update user's last active timestamp
  Future<void> _updateUserLastActive(String userId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Handle silently as this is not critical
      print('Error updating last active timestamp: $e');
    }
  }

  // Check if user is admin or moderator
  Future<bool> isUserAdmin() async {
    if (currentUser == null) return false;
    
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUser!.uid)
          .get();
      
      if (!userDoc.exists) return false;
      
      final userData = UserModel.fromFirestore(userDoc);
      return userData.role == AppConstants.adminRole;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> isUserModerator() async {
    if (currentUser == null) return false;
    
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUser!.uid)
          .get();
      
      if (!userDoc.exists) return false;
      
      final userData = UserModel.fromFirestore(userDoc);
      return userData.role == AppConstants.moderatorRole ||
             userData.role == AppConstants.adminRole;
    } catch (e) {
      return false;
    }
  }
}