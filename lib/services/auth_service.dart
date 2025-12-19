import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  User? get currentUser => _auth.currentUser;
  AppUser? _currentAppUser;
  AppUser? get currentAppUser => _currentAppUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _loadUserData(user.uid);
      } else {
        _currentAppUser = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      // Read Firestore user doc (for role and other profile data)
      Map<String, dynamic>? firestoreData;
      try {
        final doc = await _firestore.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          firestoreData = Map<String, dynamic>.from(doc.data()!);
        }
      } catch (_) {}

      // Source of truth for report count: Realtime Database users/<uid>/reportsSubmitted
      int rtdbCount = 0;
      try {
        final rtdbSnap = await _database.ref().child('users').child(uid).get();
        if (rtdbSnap.exists && rtdbSnap.value is Map) {
          final data = Map<String, dynamic>.from(rtdbSnap.value as Map);
          if (data['reportsSubmitted'] is int) {
            rtdbCount = data['reportsSubmitted'] as int;
          } else if (data['reportsSubmitted'] != null) {
            rtdbCount = int.tryParse('${data['reportsSubmitted']}') ?? 0;
          }
        }
      } catch (_) {}

      // Build AppUser by merging FirebaseAuth, RTDB count, and Firestore role
      if (_auth.currentUser != null) {
        final u = _auth.currentUser!;
        final roleStr = firestoreData != null ? (firestoreData['role'] as String?) : null;
        final role = roleStr != null && roleStr.isNotEmpty
            ? UserRole.values.firstWhere(
                (e) => e.name == roleStr,
                orElse: () => UserRole.user,
              )
            : UserRole.user;

        _currentAppUser = AppUser(
          uid: u.uid,
          email: u.email ?? '',
          displayName: u.displayName ?? 'Anonymous',
          photoUrl: u.photoURL,
          createdAt: u.metadata.creationTime ?? DateTime.now(),
          reportsSubmitted: rtdbCount,
          role: role,
        );
        return;
      }

      // Otherwise, fallback to Firestore mapping if available
      if (firestoreData != null) {
        _currentAppUser = AppUser.fromMap(firestoreData);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user data: $e');
      }
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Create or update user document in Firestore
      if (userCredential.user != null) {
        await _createOrUpdateUser(userCredential.user!);
      }

      _isLoading = false;
      notifyListeners();
      return userCredential;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('Error signing in with Google: $e');
      }
      rethrow;
    }
  }

  Future<void> _createOrUpdateUser(User user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    // Ensure RTDB user node exists with reportsSubmitted
    try {
      final userRef = _database.ref().child('users').child(user.uid);
      final snap = await userRef.get();
      int current = 0;
      if (snap.exists && snap.value is Map) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        if (data['reportsSubmitted'] is int) {
          current = data['reportsSubmitted'] as int;
        } else if (data['reportsSubmitted'] != null) {
          current = int.tryParse('${data['reportsSubmitted']}') ?? 0;
        }
      }
      await userRef.set({'reportsSubmitted': current});
    } catch (e) {
      if (kDebugMode) {
        print('Warning: failed to init RTDB user node: $e');
      }
    }

    if (!docSnapshot.exists) {
      // Create new user with reportsSubmitted initialized to 0 (Firestore copy)
      final appUser = AppUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'Anonymous',
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
        reportsSubmitted: 0,
        role: UserRole.user,
      );
      await userDoc.set(appUser.toMap());
      _currentAppUser = appUser;
    } else {
      // Update existing user
      await userDoc.update({
        'displayName': user.displayName ?? 'Anonymous',
        'photoUrl': user.photoURL,
      });
      // Reload user data to get the latest reportsSubmitted count
      await _loadUserData(user.uid);
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      _currentAppUser = null;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out: $e');
      }
      rethrow;
    }
  }

  Future<void> updateUserPhoto(String photoUrl) async {
    if (currentUser == null) return;

    try {
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'photoUrl': photoUrl,
      });

      if (_currentAppUser != null) {
        _currentAppUser = _currentAppUser!.copyWith(photoUrl: photoUrl);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user photo: $e');
      }
      rethrow;
    }
  }

  // Refresh user data (useful after submitting reports)
  Future<void> refreshUserData() async {
    if (currentUser != null) {
      await _loadUserData(currentUser!.uid);
      notifyListeners();
    }
  }

  // Admin: fetch all users from Firestore
  Future<List<AppUser>> fetchAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final users = <AppUser>[];
      for (final doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        // Ensure createdAt is a String for AppUser.fromMap
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
        }
        if (data['createdAt'] == null) {
          data['createdAt'] = DateTime.now().toIso8601String();
        }
        users.add(AppUser.fromMap(data));
      }
      users.sort((a, b) => a.displayName.compareTo(b.displayName));
      return users;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching all users: $e');
      }
      rethrow;
    }
  }

  // Admin: update another user's role in Firestore
  Future<void> updateUserRole(String uid, UserRole role) async {
    // Client-side guard: require admin
    if (_currentAppUser?.role != UserRole.admin) {
      throw Exception('Only admins can change user roles');
    }
    try {
      await _firestore.collection('users').doc(uid).set({
        'role': role.name,
      }, SetOptions(merge: true));
      // If updating own role, refresh cached app user
      if (currentUser?.uid == uid) {
        await refreshUserData();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user role: $e');
      }
      rethrow;
    }
  }
}
