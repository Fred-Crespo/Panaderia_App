import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:panaderia_delicia/pages/auth/login_page.dart';
import '../carrito_global.dart';
import 'boleta_page.dart';

// --- Define your custom color palette (Consistent with previous pages) ---
const Color primaryOrange = Color(0xFFF57C00); // A warm, inviting orange
const Color lightOrange = Color(0xFFFFCC80); // A lighter shade for accents
const Color darkOrange = Color(0xFFE65100); // A deeper shade for emphasis
const Color textOrange = Color(0xFFBF360C); // A burnt orange for text
const Color accentColor = Color(0xFFFFA000); // A brighter orange for highlights
const Color greenSuccess = Color(0xFF4CAF50); // Green for success messages

class CarritoPage extends StatefulWidget {
  const CarritoPage({super.key});

  @override
  State<CarritoPage> createState() => _CarritoPageState();
}

class _CarritoPageState extends State<CarritoPage> {
  User? get user => FirebaseAuth.instance.currentUser;

  // Function to show a custom modal for confirmation
  Future<bool> _showConfirmationDialog(
    BuildContext context,
    String title,
    String content,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                title,
                style: TextStyle(
                  color: primaryOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(content),
              actions: <Widget>[
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(false), // User cancels
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pop(true), // User confirms
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Confirmar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ) ??
        false; // Return false if dialog is dismissed
  }

  Future<void> _procesarCompra() async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Necesitas iniciar sesión para completar la compra.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );

      // Check if user is logged in after returning from LoginPage
      if (FirebaseAuth.instance.currentUser != null) {
        // Reattempt purchase if login was successful
        _procesarCompra();
      }
      return;
    }

    if (carritoLocal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'El carrito está vacío. Agrega productos para comprar.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.grey,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Show confirmation dialog before processing purchase
    final bool confirm = await _showConfirmationDialog(
      context,
      'Confirmar Compra',
      '¿Estás seguro de que deseas procesar esta compra? El total es S/ ${total.toStringAsFixed(2)}',
    );

    if (!confirm) {
      return; // User cancelled the purchase
    }

    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: primaryOrange),
              SizedBox(height: 15),
              Text(
                'Procesando tu compra...',
                style: TextStyle(color: textOrange),
              ),
            ],
          ),
        );
      },
    );

    try {
      final pedido = {
        'usuario': user!.uid,
        'fecha': Timestamp.now(),
        'estado': 'Pendiente', // Initial state
        'productos': carritoLocal
            .map(
              (item) => {
                // Create a new map to avoid modifying the original
                'productoId': item['productoId'],
                'nombre': item['nombre'],
                'precio': item['precio'],
                'cantidad': item['cantidad'],
                // Exclude imagenBase64 from Firestore if it's too large or not needed
                // 'imagenBase64': item['imagenBase64'] ?? '',
              },
            )
            .toList(),
        'total': carritoLocal.fold<double>(
          0.0,
          (sum, item) =>
              sum + ((item['precio'] ?? 0.0) * (item['cantidad'] ?? 1)),
        ),
      };

      await FirebaseFirestore.instance.collection('pedidos').add(pedido);

      // Clear the local cart after successful purchase
      setState(() {
        carritoLocal.clear();
      });

      // Dismiss loading indicator
      if (mounted) Navigator.of(context).pop();

      // Navigate to BoletaPage and show success message
      if (!mounted) return; // Check mounted again before navigation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BoletaPage()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '¡Compra realizada con éxito!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: greenSuccess,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      // Dismiss loading indicator in case of error
      if (mounted) Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al procesar la compra: $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _aumentarCantidad(int index) {
    setState(() {
      carritoLocal[index]['cantidad']++;
    });
  }

  void _disminuirCantidad(int index) {
    setState(() {
      if (carritoLocal[index]['cantidad'] > 1) {
        carritoLocal[index]['cantidad']--;
      } else {
        // Confirm removal if quantity becomes 0
        _showConfirmationDialog(
          context,
          'Eliminar Producto',
          '¿Estás seguro de que deseas eliminar este producto del carrito?',
        ).then((confirmed) {
          if (confirmed) {
            setState(() {
              carritoLocal.removeAt(index);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Producto eliminado del carrito',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: primaryOrange,
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            });
          }
        });
      }
    });
  }

  // Helper method to calculate total
  double get total {
    return carritoLocal.fold(
      0.0,
      (sum, item) => sum + ((item['precio'] ?? 0.0) * (item['cantidad'] ?? 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If cart is empty, show a dedicated empty cart view
    if (carritoLocal.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Carrito de Compras',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryOrange, darkOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          automaticallyImplyLeading: true, // Allow back navigation
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 100, color: lightOrange),
              const SizedBox(height: 20),
              Text(
                'Tu carrito está vacío.',
                style: TextStyle(
                  fontSize: 22,
                  color: textOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '¡Añade algunos productos deliciosos!',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate back to the Catalog page
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.bakery_dining, color: Colors.white),
                label: const Text(
                  'Ver Catálogo',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  elevation: 5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tu Carrito de Compras',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryOrange, darkOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        automaticallyImplyLeading: true, // Allow back navigation
        // Add a clear cart button in the AppBar actions
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            tooltip: 'Vaciar Carrito',
            onPressed: () async {
              final bool confirm = await _showConfirmationDialog(
                context,
                'Vaciar Carrito',
                '¿Estás seguro de que deseas eliminar todos los productos de tu carrito?',
              );
              if (confirm) {
                setState(() {
                  carritoLocal.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Carrito vaciado',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: primaryOrange,
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                });
              }
            },
          ),
          const SizedBox(width: 8), // Padding
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50, // A light background for the list items
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: carritoLocal.length,
                itemBuilder: (context, index) {
                  final item = carritoLocal[index];
                  final cantidad = item['cantidad'] ?? 1;
                  final precio = item['precio'] ?? 0.0;
                  final nombre = item['nombre'] ?? 'Producto';
                  final imagen = item['imagenBase64'];

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
                    elevation: 6,
                    shadowColor: primaryOrange.withOpacity(0.3),
                    color: Colors.white.withOpacity(
                      0.98,
                    ), // Almost opaque white card
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          // Product Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: imagen != null && imagen.isNotEmpty
                                ? Image.memory(
                                    base64Decode(imagen),
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
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
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 15),
                          // Product Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nombre,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: darkOrange,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'S/ ${precio.toStringAsFixed(2)} c/u', // Price per unit
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Quantity Controls
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Cantidad:',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: lightOrange.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: primaryOrange.withOpacity(0.5),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.remove,
                                              color: primaryOrange,
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                _disminuirCantidad(index),
                                            constraints:
                                                BoxConstraints.tightFor(
                                                  width: 36,
                                                  height: 36,
                                                ),
                                            splashColor: lightOrange,
                                          ),
                                          Text(
                                            '$cantidad',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: textOrange,
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.add,
                                              color: primaryOrange,
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                _aumentarCantidad(index),
                                            constraints:
                                                BoxConstraints.tightFor(
                                                  width: 36,
                                                  height: 36,
                                                ),
                                            splashColor: lightOrange,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Delete Button
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                  size: 30,
                                ),
                                onPressed: () {
                                  _showConfirmationDialog(
                                    context,
                                    'Eliminar Producto',
                                    '¿Estás seguro de que deseas eliminar ${item['nombre']} del carrito?',
                                  ).then((confirmed) {
                                    if (confirmed) {
                                      setState(
                                        () => carritoLocal.removeAt(index),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${item['nombre']} eliminado',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor: primaryOrange,
                                          duration: const Duration(seconds: 1),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  });
                                },
                                tooltip: 'Eliminar producto',
                              ),
                              // Spacer to align delete button
                              SizedBox(height: 20),
                              Text(
                                'S/ ${(precio * cantidad).toStringAsFixed(2)}', // Total for this item
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: darkOrange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Total and Buy Button Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 5,
                    blurRadius: 10,
                    offset: const Offset(0, -3), // Shadow at the top
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textOrange,
                        ),
                      ),
                      Text(
                        'S/ ${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: darkOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _procesarCompra,
                      icon: const Icon(
                        Icons.credit_card,
                        color: Colors.white,
                        size: 28,
                      ),
                      label: const Text(
                        'Procesar Compra',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 8,
                        shadowColor: primaryOrange.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
