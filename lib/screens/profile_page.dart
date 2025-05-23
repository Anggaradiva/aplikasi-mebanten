import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_screen.dart';
import 'package:apk_mebanten/tambahbanten.dart';
import 'package:apk_mebanten/screens/home_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? get currentUser => _auth.currentUser;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final docSnapshot = await _firestore.collection('users').doc(currentUser!.uid).get();
      
      if (docSnapshot.exists) {
        setState(() {
          _userData = docSnapshot.data();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: ${e.toString()}')),
      );
    }
  }

  // Show logout confirmation dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Logout',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin keluar dari akun ini?',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Batal',
                style: GoogleFonts.inter(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _signOut();
              },
              child: Text(
                'Keluar',
                style: GoogleFonts.inter(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}')),
        );
      }
    }
  }

  String _getInitials(String name) {
    List<String> names = name.trim().split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty && names[0].isNotEmpty) {
      return names[0].length >= 2 
          ? names[0].substring(0, 2).toUpperCase()
          : names[0][0].toUpperCase();
    }
    return 'U';
  }

  String _getUserName() {
    return _userData?['name'] ?? 
           currentUser?.displayName ?? 
           currentUser?.email?.split('@')[0] ?? 
           'User';
  }

  String _getUserHandle() {
    String username = _userData?['username'] ?? 
                     currentUser?.email?.split('@')[0] ?? 
                     'user';
    return '@${username.toLowerCase()}';
  }

  @override
  Widget build(BuildContext context) {
    // If no user is logged in, show login prompt
    if (currentUser == null) {
      return _buildNotLoggedInScreen();
    }

    // Main profile screen
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Profil',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4CAF50),
              ),
            )
          : _buildProfileContent(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // Not logged in screen
  Widget _buildNotLoggedInScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Profil',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Anda belum login',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Silakan login untuk mengakses profil',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Login',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // Profile content when logged in
  Widget _buildProfileContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // Profile Avatar and Info
          _buildProfileHeader(),
          
          const SizedBox(height: 60),
          
          // Menu Items
          _buildMenuItems(),
        ],
      ),
    );
  }

  // Profile header with avatar and info
  Widget _buildProfileHeader() {
    return Column(
      children: [
        // Avatar with edit badge
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.blue[300]!,
                    Colors.blue[500]!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _userData?['photoURL'] != null
                  ? ClipOval(
                      child: Image.network(
                        _userData!['photoURL'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              _getInitials(_getUserName()),
                              style: GoogleFonts.inter(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Text(
                        _getInitials(_getUserName()),
                        style: GoogleFonts.inter(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
            // Edit badge
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Name
        Text(
          _getUserName(),
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Username/Handle
        Text(
          _getUserHandle(),
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Menu items section
  Widget _buildMenuItems() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings akan segera tersedia'),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.description_outlined,
            title: 'Terms and condition',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Terms and condition akan segera tersedia'),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy settings',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Privacy settings akan segera tersedia'),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications akan segera tersedia'),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'Help center',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Help center akan segera tersedia'),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.feedback_outlined,
            title: 'Feedback',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Feedback akan segera tersedia'),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          // Logout Button
          _buildLogoutButton(),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Individual menu item
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.grey[700],
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Logout button
  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _showLogoutDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[50],
          foregroundColor: Colors.red[600],
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.red[200]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout,
              size: 20,
              color: Colors.red[600],
            ),
            const SizedBox(width: 12),
            Text(
              'Logout',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Consistent bottom navigation
  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 2, // Profile tab active
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey[400],
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        onTap: (index) async {
          switch (index) {
            case 0:
              // Navigate to Home/Explore
              try {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
              } catch (e) {
                print('Navigation error: $e');
              }
              break;
            case 1:
              // Navigate to Add Banten
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TambahBantenPage()),
              );
              break;
            case 2:
              // Already on Profile - do nothing
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined, size: 24),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add, size: 24),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 24),
            activeIcon: Icon(Icons.person, size: 24),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}