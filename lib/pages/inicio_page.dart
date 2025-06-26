import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:panaderia_delicia/pages/auth/perfil_page.dart';
import 'package:panaderia_delicia/pages/catalogo_page.dart';
import 'package:panaderia_delicia/pages/historial_page.dart';
import 'package:panaderia_delicia/pages/productos/productos_page.dart';
import 'package:panaderia_delicia/pages/theme_provider.dart';
import 'package:provider/provider.dart';
import 'carrito/carrito_page.dart';

// --- Define your custom color palette (Consistent with previous pages) ---
const Color primaryOrange = Color(0xFFF57C00); // A warm, inviting orange
const Color lightOrange = Color(0xFFFFCC80); // A lighter shade for accents
const Color darkOrange = Color(0xFFE65100); // A deeper shade for emphasis
const Color textOrange = Color(0xFFBF360C); // A burnt orange for text
const Color accentColor = Color(0xFFFFA000); // A brighter orange for highlights

class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  int _selectedIndex = 0;
  bool isAdmin = false;
  // Removed local nombre and imagenBase64 as they are now fetched in StreamBuilder for DrawerHeader
  // String? nombre;
  // String? imagenBase64;

  @override
  void initState() {
    super.initState();
    // No need to _cargarUsuario here anymore as StreamBuilder handles it for drawer.
    // However, if isAdmin is used outside the drawer, you might want to keep a simpler check.
    // For now, let's assume isAdmin is primarily for drawer and pages list.
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          isAdmin = data?['rol'] == 'admin';
        });
      }
    }
  }

  void _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();

    if (mounted) {
      // Navigate to CatalogoPage after logout and remove all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CatalogoPage()),
        (route) => false,
      );

      // Show a snackbar notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Sesión cerrada correctamente',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: primaryOrange.withOpacity(0.9),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context); // Close the Drawer
  }

  @override
  Widget build(BuildContext context) {
    // Dynamically build the list of pages based on admin status
    final List<Widget> pages = [
      const CatalogoPage(),
      const CarritoPage(),
      const HistorialPage(),
      if (isAdmin) const ProductosPage(), // Only include if isAdmin is true
      const PerfilPage(),
    ];

    // Adjust the index for PerfilPage if isAdmin affects the list length
    // This is crucial if ProductosPage is sometimes present, sometimes not.
    // The PerfilPage index will be 3 if isAdmin is false, and 4 if isAdmin is true.
    final int perfilPageIndex = isAdmin ? 4 : 3;

    return Scaffold(
      // Custom AppBar with orange gradient
      appBar: AppBar(
        title: const Text(
          'Panadería Delicia',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryOrange, darkOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          // Logout Button - Only show if a user is logged in
          if (FirebaseAuth.instance.currentUser != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Cerrar sesión',
                onPressed: _cerrarSesion,
                splashColor: lightOrange, // Visual feedback on tap
              ),
            ),
        ],
      ),
      // Custom Drawer
      drawer: Drawer(
        // Use a container with BoxDecoration for gradient or solid color
        // The Drawer itself will have the gradient applied to its header,
        // and the body of the drawer will be a plain white/light background.
        child: Column(
          children: [
            // UserAccountsDrawerHeader with StreamBuilder for real-time user data
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return UserAccountsDrawerHeader(
                    accountName: const Text(
                      'Cargando...',
                      style: TextStyle(color: Colors.white),
                    ),
                    accountEmail: const Text(
                      '',
                      style: TextStyle(color: Colors.white70),
                    ),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.8),
                      child: const CircularProgressIndicator(
                        color: primaryOrange,
                      ),
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryOrange, accentColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return UserAccountsDrawerHeader(
                    accountName: const Text(
                      'Error',
                      style: TextStyle(color: Colors.white),
                    ),
                    accountEmail: Text(
                      '${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.8),
                      child: const Icon(Icons.error, color: Colors.red),
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryOrange, accentColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  );
                }

                final userData = snapshot.data?.data() as Map<String, dynamic>?;
                final String displayNombre = userData?['nombre'] ?? 'Invitado';
                final String displayEmail =
                    FirebaseAuth.instance.currentUser?.email ??
                    'correo@ejemplo.com';
                final String? fotoBase64 =
                    userData?['fotoBase64']; // ✅ Campo correcto

                return UserAccountsDrawerHeader(
                  accountName: Text(
                    displayNombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  accountEmail: Text(
                    displayEmail,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(
                      0.9,
                    ), // White background for the avatar
                    backgroundImage: fotoBase64 != null && fotoBase64.isNotEmpty
                        ? MemoryImage(base64Decode(fotoBase64))
                        : null,
                    child: (fotoBase64 == null || fotoBase64.isEmpty)
                        ? Icon(
                            Icons.person,
                            size: 40,
                            color: primaryOrange.withOpacity(
                              0.7,
                            ), // Orange person icon
                          )
                        : null,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        darkOrange,
                        primaryOrange,
                      ], // Deeper orange gradient for header
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      // Add a subtle shadow to the drawer header
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8.0,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                );
              },
            ),
            // Drawer items
            Expanded(
              // Use Expanded to ensure ListView takes remaining space
              child: ListView(
                padding: EdgeInsets.zero, // Remove default ListView padding
                children: [
                  _buildDrawerItem(
                    icon: Icons.home,
                    title: 'Catálogo',
                    index: 0,
                    context: context,
                  ),
                  _buildDrawerItem(
                    icon: Icons.shopping_cart,
                    title: 'Carrito',
                    index: 1,
                    context: context,
                  ),
                  _buildDrawerItem(
                    icon: Icons.receipt,
                    title: 'Historial',
                    index: 2,
                    context: context,
                  ),
                  if (isAdmin)
                    _buildDrawerItem(
                      icon: Icons.manage_accounts,
                      title: 'Gestión de Productos',
                      index: 3,
                      context: context,
                    ),
                  _buildDrawerItem(
                    icon: Icons.person,
                    title: 'Perfil',
                    index: perfilPageIndex, // Dynamic index for PerfilPage
                    context: context,
                  ),
                  Divider(
                    color: lightOrange.withOpacity(0.5), // Subtle divider
                    indent: 16,
                    endIndent: 16,
                    height: 32, // Space around the divider
                  ),
                  // Dark Mode Toggle
                  ListTile(
                    leading: const Icon(
                      Icons.brightness_6,
                      color: primaryOrange,
                    ),
                    title: const Text(
                      'Modo Oscuro',
                      style: TextStyle(
                        color: textOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) => Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (value) => themeProvider.toggleTheme(value),
                        activeColor: darkOrange, // Active color for the switch
                        inactiveThumbColor: lightOrange, // Thumb color when off
                        inactiveTrackColor: lightOrange.withOpacity(
                          0.5,
                        ), // Track color when off
                      ),
                    ),
                    onTap: () {
                      // Toggling the switch directly is usually enough
                      Provider.of<ThemeProvider>(
                        context,
                        listen: false,
                      ).toggleTheme(
                        !Provider.of<ThemeProvider>(
                          context,
                          listen: false,
                        ).isDarkMode,
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.logout,
                      color: Colors.redAccent,
                    ), // Red for logout
                    title: const Text(
                      'Cerrar Sesión',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: _cerrarSesion,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: pages[_selectedIndex], // Display the selected page
    );
  }

  // Helper method for consistent DrawerListTile styling
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
    required BuildContext context,
  }) {
    // Get the current theme provider to check dark mode status
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDarkMode = themeProvider.isDarkMode;

    // Define colors based on selected state and dark/light mode
    final Color selectedIconColor = Colors.white;
    final Color selectedTextColor = Colors.white;
    final Color selectedTileColor =
        darkOrange; // Dark orange background for selected item

    final Color defaultIconColor = primaryOrange;
    final Color defaultTextColor = textOrange;
    final Color defaultTileColor = isDarkMode
        ? Colors.grey[850]!
        : Colors.white; // Dark mode background or white

    final bool isSelected = _selectedIndex == index;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? selectedIconColor : defaultIconColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? selectedTextColor : defaultTextColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 16,
        ),
      ),
      tileColor: isSelected
          ? selectedTileColor
          : defaultTileColor, // Background color
      selectedTileColor: selectedTileColor, // Explicitly for selected state
      onTap: () => _onItemTapped(index),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // Slightly rounded tiles
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ), // Padding
      // Add a subtle splash color for unselected items
      splashColor: lightOrange.withOpacity(0.5),
    );
  }
}
