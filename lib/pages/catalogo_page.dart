import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:panaderia_delicia/pages/carrito/carrito_page.dart';
import 'package:panaderia_delicia/pages/carrito_global.dart';
import 'auth/login_page.dart';

// --- Define your custom color palette ---
const Color primaryOrange = Color(0xFFF57C00); // A warm, inviting orange
const Color lightOrange = Color(0xFFFFCC80); // A lighter shade for accents
const Color darkOrange = Color(0xFFE65100); // A deeper shade for emphasis
const Color textOrange = Color(0xFFBF360C); // A burnt orange for text

class CatalogoPage extends StatefulWidget {
  const CatalogoPage({super.key});

  @override
  State<CatalogoPage> createState() => _CatalogoPageState();
}

class _CatalogoPageState extends State<CatalogoPage>
    with SingleTickerProviderStateMixin {
  String _categoriaSeleccionada = 'Todas';

  final List<String> _categorias = [
    'Todas',
    'Panadería básica',
    'Pastelería',
    'Bebidas calientes',
    'Bebidas frías',
    'Postres',
    'Empanadas y salados',
    'Otros',
  ];

  late AnimationController _iconAnimationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _iconAnimationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _iconAnimationController.dispose();
    super.dispose();
  }

  void _agregarAlCarritoLocal(Map<String, dynamic> data, String id) {
    final index = carritoLocal.indexWhere((item) => item['productoId'] == id);

    setState(() {
      if (index != -1) {
        carritoLocal[index]['cantidad']++;
      } else {
        carritoLocal.add({
          'productoId': id,
          'nombre': data['nombre'],
          'precio': data['precio'],
          'cantidad': 1,
          'imagenBase64': data['imagenBase64'] ?? '',
        });
      }
    });

    // Animate the cart icon
    _iconAnimationController.forward().then((_) {
      _iconAnimationController.reverse(); // Bounce animation
    });

    // Show a snackbar notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Producto agregado al carrito',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryOrange.withOpacity(0.9), // Orange snackbar
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  int _obtenerCantidadTotalCarrito() {
    return carritoLocal.fold<int>(
      0,
      (sum, item) => sum + (item['cantidad'] as int? ?? 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      // Custom AppBar with orange gradient
      appBar: AppBar(
        title: const Text(
          '',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false, // Keep this as per original
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
          if (user == null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                icon: const Icon(Icons.login, color: Colors.white),
                label: const Text(
                  'Iniciar Sesión',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.white54, width: 1),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Container(
        // Background image with white overlay
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage(
              'assets/fondo3.jpg',
            ), // Ensure this path is correct in pubspec.yaml
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(
                0.8,
              ), // Adjust opacity for overlay effect
              BlendMode.lighten, // Or BlendMode.srcOver for a direct overlay
            ),
          ),
        ),
        child: Column(
          children: [
            // Welcome message section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    '¡Bienvenido a Panadería Delicia!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textOrange, // Use custom orange for text
                      shadows: [
                        Shadow(
                          offset: const Offset(1, 1),
                          blurRadius: 3.0,
                          color: Colors.black.withOpacity(0.2),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Nuestra misión es brindar productos frescos, artesanales y deliciosos, hechos con pasión cada día para ti y tu familia.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // Category filter dropdown
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: DropdownButtonFormField<String>(
                value: _categoriaSeleccionada,
                decoration: InputDecoration(
                  labelText: 'Filtrar por categoría',
                  labelStyle: TextStyle(
                    color: primaryOrange,
                    fontWeight: FontWeight.bold,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none, // No border for a cleaner look
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: lightOrange,
                      width: 2,
                    ), // Lighter orange border
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: darkOrange,
                      width: 3,
                    ), // Darker orange when focused
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
                dropdownColor: Colors.white, // Dropdown background
                items: _categorias.map((categoria) {
                  return DropdownMenuItem(
                    value: categoria,
                    child: Text(
                      categoria,
                      style: TextStyle(color: Colors.grey[800]),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _categoriaSeleccionada = value!;
                  });
                },
                icon: const Icon(Icons.arrow_drop_down, color: primaryOrange),
              ),
            ),
            // Product list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('productos')
                    .where('disponible', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error al cargar productos: ${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: primaryOrange),
                    );
                  }

                  final productos = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final categoria = data['categoria'] ?? '';
                    return _categoriaSeleccionada == 'Todas' ||
                        categoria == _categoriaSeleccionada;
                  }).toList();

                  if (productos.isEmpty) {
                    return Center(
                      child: Text(
                        'No hay productos disponibles en esta categoría.',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: productos.length,
                    itemBuilder: (context, index) {
                      final producto = productos[index];
                      final data = producto.data() as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(
                            color: lightOrange.withOpacity(0.6),
                            width: 1,
                          ),
                        ),
                        elevation:
                            6, // Increased elevation for a floating effect
                        shadowColor: primaryOrange.withOpacity(
                          0.3,
                        ), // Orange shadow
                        color: Colors.white.withOpacity(
                          0.95,
                        ), // Slightly transparent white card
                        child: Padding(
                          padding: const EdgeInsets.all(
                            8.0,
                          ), // Padding inside the card
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                10,
                              ), // Rounded corners for image
                              child:
                                  data['imagenBase64'] != null &&
                                      data['imagenBase64'] != ''
                                  ? Image.memory(
                                      base64Decode(data['imagenBase64']),
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      // Add a subtle border to the image
                                      frameBuilder:
                                          (
                                            context,
                                            child,
                                            frame,
                                            wasSynchronouslyLoaded,
                                          ) {
                                            if (wasSynchronouslyLoaded)
                                              return child;
                                            return AnimatedOpacity(
                                              opacity: frame == null ? 0 : 1,
                                              duration: const Duration(
                                                seconds: 1,
                                              ),
                                              curve: Curves.easeOut,
                                              child: child,
                                            );
                                          },
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                width: 80,
                                                height: 80,
                                                color: Colors.grey[200],
                                                child: Icon(
                                                  Icons.broken_image,
                                                  size: 40,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                    )
                                  : Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: lightOrange.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: lightOrange,
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.fastfood,
                                        size: 40,
                                        color: primaryOrange,
                                      ), // Food icon for placeholder
                                    ),
                            ),
                            title: Text(
                              data['nombre'] ?? 'Sin nombre',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: darkOrange,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'S/ ${data['precio'].toStringAsFixed(2)}', // Format price to 2 decimal places
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            trailing: Container(
                              decoration: BoxDecoration(
                                color: primaryOrange.withOpacity(
                                  0.1,
                                ), // Light orange background for button
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: primaryOrange,
                                  width: 1,
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.add_shopping_cart,
                                  color: primaryOrange, // Orange icon
                                  size: 28,
                                ),
                                onPressed: () =>
                                    _agregarAlCarritoLocal(data, producto.id),
                                splashColor:
                                    lightOrange, // Visual feedback on tap
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Floating action button for cart
      floatingActionButton: Stack(
        alignment: Alignment.topRight,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: FloatingActionButton(
              heroTag: 'cartFab', // Required if multiple FABs exist
              backgroundColor: primaryOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ), // Squared with rounded corners
              child: const Icon(
                Icons.shopping_cart_rounded, // Use a filled cart icon
                color: Colors.white,
                size: 30,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CarritoPage()),
                );
              },
            ),
          ),
          if (_obtenerCantidadTotalCarrito() > 0)
            Positioned(
              right: 0,
              top: 0,
              child: CircleAvatar(
                radius: 12, // Slightly larger badge
                backgroundColor: Colors.redAccent, // Red for attention
                child: Text(
                  _obtenerCantidadTotalCarrito().toString(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // Keep default location
    );
  }
}
