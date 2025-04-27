import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for Timestamp

// Import services and models
import '../../data/datasources/firebase/firestore_service.dart'; // Ensure this has saveUserData
import '../../data/models/user_model.dart'; // Ensure this model includes role, assignedLocationId/Name

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService; // Ensure this is passed in constructor

  User? _user; // Firebase Auth user
  UserModel? _currentUserData; // User data from Firestore
  bool _isLoadingUserData = false; // Loading state for Firestore user data

  bool _isLoading = false; // Loading state for auth operations (login, signup, create)
  String? _errorMessage;
  StreamSubscription? _authStateSubscription;

  // --- Getters ---
  User? get currentUser => _user;
  bool get isLoading => _isLoading; // General loading for auth actions
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  UserModel? get currentUserData => _currentUserData;
  bool get isLoadingUserData => _isLoadingUserData;
  String? get currentUserRole => _currentUserData?.role;
  // ----------------

  AuthProvider(this._firestoreService) {
    _authStateSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);
    print("AuthProvider initialized. Listening for auth changes.");
    if (_auth.currentUser != null) {
      _user = _auth.currentUser;
      _loadCurrentUserData(); // Load data if already logged in
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;
    print("AuthProvider: Auth state changed. User UID: ${_user?.uid}");
    if (_user != null) {
      await _loadCurrentUserData(); // Load Firestore data on login/change
    } else {
      _currentUserData = null; // Clear Firestore data on logout
      _isLoadingUserData = false;
      _errorMessage = null;
    }
    // Notify after potential data load/clear
    if (_user == null) {
        notifyListeners();
    }
  }

  Future<void> _loadCurrentUserData() async {
    if (_user == null) return;
    _isLoadingUserData = true;
    _errorMessage = null;
    notifyListeners();
    try {
      print("AuthProvider: Loading Firestore data for UID: ${_user!.uid}");
      // Ensure firestoreService.getUserData exists and works
      _currentUserData = await _firestoreService.getUserData(_user!.uid);
      if (_currentUserData == null) {
        print("AuthProvider WARNING: No Firestore data found for user ${_user!.uid}.");
        _errorMessage = "Could not load profile details.";
      } else {
         print("AuthProvider: Data loaded: Role=${_currentUserData?.role}");
         _errorMessage = null;
      }
    } catch (e) {
      print("AuthProvider ERROR loading Firestore data: $e");
      _errorMessage = "Error loading profile data.";
      _currentUserData = null;
    } finally {
      _isLoadingUserData = false;
      notifyListeners();
    }
  }


  // --- signUp (for user self-registration - no changes needed now) ---
  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    _setLoading(true);
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      // Check if user creation was successful before accessing userCredential.user!
      if (userCredential.user == null) {
        throw Exception("User creation failed, user is null.");
      }
      final newUser = userCredential.user!; // Safe to use ! now

      final userModel = UserModel(
        uid: newUser.uid,
        firstName: firstName,
        lastName: lastName,
        email: email.trim(),
        phone: phone,
        role: 'user', // Default role for self-registration
        createdAt: Timestamp.now(),
        // assignedLocationId and Name are null for self-registration
      );

      await _firestoreService.saveUserData(userModel);
      _errorMessage = null;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthExceptionMessage(e.code);
      // Ensure user state is cleared if signup fails
      _user = null;
      _currentUserData = null;
    } catch (e) {
      _errorMessage = "An unexpected error occurred during sign up.";
       _user = null;
      _currentUserData = null;
    } finally {
      _setLoading(false);
    }
  }


  // --- createUserByAdmin IMPLEMENTED ---
  Future<void> createUserByAdmin({
    required String email,
    required String password, // Initial password
    required String firstName,
    required String lastName,
    required String phone,
    required String role, // Role assigned by admin
    String? assignedLocationId, // Optional, depends on role
    String? assignedLocationName, // Optional
  }) async {
    _setLoading(true); // Use general loading indicator

    // --- Workaround for client-side user creation by admin ---
    User? tempUser;
    User? adminUser = _auth.currentUser; // Store current admin user

    try {
      print("AuthProvider (Admin): Attempting to create user: $email");

      // 1. Create user in Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(), // Use the provided initial password
      );

      tempUser = userCredential.user; // Get the newly created user object
      if (tempUser == null) {
        throw Exception("User creation failed in Auth, user object is null.");
      }
      print("AuthProvider (Admin): User created in Auth (UID: ${tempUser.uid}). Signing out temp user...");

      // 2. Sign out the newly created user IMMEDIATELY
      await _auth.signOut();

      // 3. Restore admin user state (Simplified - does not re-authenticate)
      if (adminUser != null) {
         _user = adminUser; // Restore the admin user object in the provider state
         print("AuthProvider (Admin): Admin user state restored (UID: ${adminUser.uid}).");
      } else {
         print("AuthProvider (Admin) WARNING: Could not restore admin user state after temp user sign out.");
         // Consider forcing admin logout or showing an error
      }


      // 4. Create the UserModel with all details
      // Ensure UserModel includes assignedLocationId/Name fields
      final userModel = UserModel(
        uid: tempUser.uid, // Use the UID from the created user
        firstName: firstName,
        lastName: lastName,
        email: email.trim(),
        phone: phone,
        role: role, // Assign the specified role
        assignedLocationId: assignedLocationId, // Pass location details
        assignedLocationName: assignedLocationName,
        createdAt: Timestamp.now(),
      );

      // 5. Save the complete user data to Firestore
      print("AuthProvider (Admin): Saving user data to Firestore for UID: ${tempUser.uid}");
      // Ensure firestoreService.saveUserData exists and works
      await _firestoreService.saveUserData(userModel);

      _errorMessage = null; // Clear errors on success
      print("AuthProvider (Admin): User creation and data saving complete for UID: ${tempUser.uid}");

    } on FirebaseAuthException catch (e) {
      print("AuthProvider (Admin): FirebaseAuth Error - Code: ${e.code}");
      _errorMessage = _mapFirebaseAuthExceptionMessage(e.code);
      // Attempt to restore admin state if creation failed
      if (adminUser != null && _auth.currentUser == null) {
          _user = adminUser;
          print("AuthProvider (Admin): Restored admin state after failed user creation.");
      }
    } catch (e) {
      print("AuthProvider (Admin): Unexpected error in createUserByAdmin: $e");
      _errorMessage = "An unexpected error occurred while creating the user.";
      // Attempt to restore admin state after other errors
      if (adminUser != null && _auth.currentUser == null) {
          _user = adminUser;
           print("AuthProvider (Admin): Restored admin state after unexpected error.");
      }
    } finally {
      _setLoading(false); // Turn off loading indicator
    }
  }
  // --- FIN createUserByAdmin ---


  // --- signIn ---
  Future<void> signIn(String email, String password) async {
     _setLoading(true);
     _currentUserData = null;
     _isLoadingUserData = false;
     try {
       await _auth.signInWithEmailAndPassword(email: email.trim(), password: password.trim());
       _errorMessage = null;
       // _onAuthStateChanged will trigger _loadCurrentUserData
     } on FirebaseAuthException catch (e) {
        _errorMessage = _mapFirebaseAuthExceptionMessage(e.code);
        _user = null; _currentUserData = null;
     } catch (e) {
        _errorMessage = "An unexpected error occurred during sign in.";
        _user = null; _currentUserData = null;
     } finally {
        _setLoading(false);
     }
  }

  // --- signOut ---
  Future<void> signOut() async {
     _setLoading(true);
     try {
        await _auth.signOut();
        // _onAuthStateChanged will clear _user and _currentUserData
        _errorMessage = null;
     } catch (e) {
       _errorMessage = "Error signing out: ${e.toString()}";
     } finally {
       _setLoading(false);
     }
  }

  // --- Helper _setLoading ---
  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _errorMessage = null;
    notifyListeners();
  }

  // --- Helper _mapFirebaseAuthExceptionMessage ---
  String _mapFirebaseAuthExceptionMessage(String code) {
     switch (code) {
      case 'weak-password': return 'The password provided is too weak.';
      case 'email-already-in-use': return 'An account already exists for that email.';
      case 'invalid-email': return 'The email address is not valid.';
      case 'operation-not-allowed': return 'Email/password accounts are not enabled.';
      case 'user-disabled': return 'This user account has been disabled.';
      case 'user-not-found': return 'No user found for that email.';
      case 'wrong-password': return 'Wrong password provided for that user.';
      default: return 'An authentication error occurred ($code)';
    }
  }
}
