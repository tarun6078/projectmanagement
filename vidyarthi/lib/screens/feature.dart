import 'package:Vidyarthi/pages/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Vidyarthi/screens/login_screen.dart';
import 'package:Vidyarthi/screens/notification.dart';
import 'package:local_auth/local_auth.dart';
import 'package:Vidyarthi/screens/geofencing.dart';
import 'package:Vidyarthi/screens/meet.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String userEmail; // Email of the logged-in user
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();
    fetchUserEmail(); // Fetch the user's email on screen initialization
    _checkBiometrics();
  }

  // Function to fetch the user's email from Firebase authentication
  void fetchUserEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userEmail = user.email!;
      });
    }
  }

  // Function to check if biometrics is available
  Future<void> _checkBiometrics() async {
    bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
    setState(() {
      _isBiometricAvailable = canCheckBiometrics;
    });
  }

  // Function to authenticate with biometrics
  Future<bool> _authenticateWithBiometrics() async {
    bool authenticated = false;
    try {
      authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access Vidyarthi App feature',
      );
    } catch (e) {
      print("Error authenticating: $e");
    }
    return authenticated;
  }

  // Function to handle logout
  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false, // Clear the navigation stack
      );
    } catch (e) {
      print("Error logging out: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent,
              ),
              child: Text(
                'Welcome, $userEmail!', // Display user's email here
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            ListTile(
              title: Text('Logout'),
              leading: Icon(Icons.exit_to_app),
              onTap: _logout, // Call logout function on tap
            ),
          ],
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/back.gif', // Replace with your image path
            fit: BoxFit.cover,
          ),
          // Content on top of the background image
          Container(
            color: Colors.transparent, // Make container transparent
            padding: EdgeInsets.all(20),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (_isBiometricAvailable) {
                        bool authenticated = await _authenticateWithBiometrics();
                        if (authenticated) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ChatScreen(title: 'Start Chatting')),
                          );
                        } else {
                          // Handle authentication failure
                        }
                      } else {
                        // Handle case where biometrics is not available
                      }
                    },
                    icon: Icon(Icons.chat, size: 32),
                    label: Text(
                      'Lets Chat',
                      style: TextStyle(fontSize: 20),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                      elevation: 5,
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                      minimumSize: Size(double.infinity, 40),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (_isBiometricAvailable) {
                        bool authenticated = await _authenticateWithBiometrics();
                        if (authenticated) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MyGeofencePage(title: 'Geofence Attendance',)),
                          );
                        } else {
                          // Handle authentication failure
                        }
                      } else {
                        // Handle case where biometrics is not available
                      }
                    },
                    icon: Icon(Icons.location_on, size: 32),
                    label: Text(
                      'Geofencing Attendance',
                      style: TextStyle(fontSize: 20),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                      elevation: 5,
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                      minimumSize: Size(double.infinity, 40),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Mymeet()),
                      );
                      // TODO: Implement chat functionality
                    },
                    icon: Icon(Icons.meeting_room, size: 32),
                    label: Text(
                      'Lets meet',
                      style: TextStyle(fontSize: 20),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                      elevation: 5,
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                      minimumSize: Size(double.infinity, 40),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddTaskReminder()),
                      );
                      // TODO: Implement notification functionality
                    },
                    icon: Icon(Icons.notifications, size: 32),
                    label: Text(
                      'Notifications',
                      style: TextStyle(fontSize: 20),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                      elevation: 5,
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                      minimumSize: Size(double.infinity, 40),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
