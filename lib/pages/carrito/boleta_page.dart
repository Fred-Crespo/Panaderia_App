import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../inicio_page.dart'; // Import InicioPage for navigation
import 'package:confetti/confetti.dart'; // Import the confetti package
import 'dart:math'; // For pi

// --- Define your custom color palette (Consistent with previous pages) ---
const Color primaryOrange = Color(0xFFF57C00); // A warm, inviting orange
const Color lightOrange = Color(0xFFFFCC80); // A lighter shade for accents
const Color darkOrange = Color(0xFFE65100); // A deeper shade for emphasis
const Color textOrange = Color(0xFFBF360C); // A burnt orange for text
const Color successGreen = Color(0xFF4CAF50); // Green for success status

class BoletaPage extends StatefulWidget {
  const BoletaPage({super.key});

  @override
  State<BoletaPage> createState() => _BoletaPageState();
}

class _BoletaPageState extends State<BoletaPage> {
  // Store the last fetched order data
  Map<String, dynamic>? _lastOrder;
  bool _isLoading = true;
  String? _errorMessage;
  late ConfettiController _confettiController; // Confetti controller

  @override
  void initState() {
    super.initState();
    // Initialize the confetti controller
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _fetchLastOrder();
  }

  @override
  void dispose() {
    _confettiController.dispose(); // Dispose the confetti controller
    super.dispose();
  }

  // Function to fetch the last order for the current user from Firestore
  Future<void> _fetchLastOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage =
            'No hay usuario autenticado. Inicia sesión para ver tu boleta.';
        _isLoading = false;
      });
      return;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('pedidos')
          .where('usuario', isEqualTo: user.uid)
          .orderBy('fecha', descending: true) // Get the most recent order
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _lastOrder = querySnapshot.docs.first.data() as Map<String, dynamic>;
          _isLoading = false;
        });
        // Play confetti only if the order was successfully fetched and displayed
        _confettiController.play();
      } else {
        setState(() {
          _errorMessage = 'No se encontró ninguna compra reciente.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar los datos de la boleta: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the content based on loading, error, or data
    Widget bodyContent;

    if (_isLoading) {
      bodyContent = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryOrange),
            const SizedBox(height: 15),
            Text(
              'Cargando boleta...',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      );
    } else if (_errorMessage != null) {
      bodyContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.redAccent),
              const SizedBox(height: 20),
              Text(
                '¡Ups! Ha ocurrido un error.',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true; // Set to loading to re-fetch
                    _errorMessage = null; // Clear error
                  });
                  _fetchLastOrder(); // Retry fetching
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Reintentar',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_lastOrder == null || _lastOrder!.isEmpty) {
      bodyContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 80, color: lightOrange),
              const SizedBox(height: 20),
              Text(
                'No se encontraron detalles de tu última compra.',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textOrange,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Es posible que no hayas realizado compras aún o hubo un problema al cargar.',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate back to the Catalog page
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const InicioPage()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.home, color: Colors.white),
                label: const Text(
                  'Ir al Inicio',
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
    } else {
      // Data is available, build the Boleta Card
      final fechaHora = (_lastOrder!['fecha'] as Timestamp).toDate();
      // Use the actual user's name if available from a previous fetch or Firebase Auth
      final clienteNombre =
          _lastOrder!['nombreUsuario'] ??
          (FirebaseAuth.instance.currentUser?.displayName ?? 'Cliente');
      // Use the order ID from Firestore if available, otherwise simulate
      final numeroBoleta =
          _lastOrder!['orderId'] ??
          '#${fechaHora.millisecondsSinceEpoch.toString().substring(8)}';
      final productos = _lastOrder!['productos'] as List<dynamic>? ?? [];
      final totalCompra = _lastOrder!['total'] ?? 0.0;
      final estadoPedido =
          _lastOrder!['estado'] ?? 'Desconocido'; // Get order status

      bodyContent = Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 12,
              color: Colors.white.withOpacity(0.95),
              shadowColor: primaryOrange.withOpacity(0.5),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Thank You Section
                    Icon(
                      Icons.check_circle_outline,
                      size: 90,
                      color: successGreen, // Use a success green color
                    ),
                    const SizedBox(height: 15),
                    Text(
                      '¡Gracias por tu compra!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: darkOrange,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tu pedido ha sido registrado con éxito.',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 25),
                    Divider(color: lightOrange, thickness: 1.5),
                    const SizedBox(height: 15),

                    // Order Summary Details
                    _buildInfoRow(
                      icon: Icons.assignment,
                      label: 'Estado del Pedido:',
                      value: estadoPedido,
                      valueColor: estadoPedido == 'Pendiente'
                          ? primaryOrange
                          : successGreen, // Style based on status
                      isBoldValue: true,
                    ),
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      label: 'Fecha:',
                      value: fechaHora.toLocal().toString().split('.')[0],
                    ),
                    _buildInfoRow(
                      icon: Icons.confirmation_number,
                      label: 'Boleta N°:',
                      value: numeroBoleta,
                    ),
                    _buildInfoRow(
                      icon: Icons.person,
                      label: 'Cliente:',
                      value: clienteNombre,
                    ),
                    const SizedBox(height: 25),
                    Divider(color: lightOrange, thickness: 1.5),
                    const SizedBox(height: 15),

                    // Product Details Section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Detalle de la Compra:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: textOrange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      children: productos.map<Widget>((producto) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${producto['nombre']} x${producto['cantidad']}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[800],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ), // Espacio entre los textos
                              Text(
                                'S/ ${(producto['precio'] * producto['cantidad']).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: darkOrange,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: lightOrange, thickness: 1.5),
                    const SizedBox(height: 15),

                    // Total Amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total a Pagar:',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textOrange,
                          ),
                        ),
                        Text(
                          'S/ ${totalCompra.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: darkOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // Payment Method & QR Section (Simulated)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Método de Pago Sugerido:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textOrange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: lightOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: primaryOrange.withOpacity(0.5),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.qr_code_rounded,
                                size: 30,
                                color: primaryOrange,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  'Yape (Pago Contra Entrega)',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: textOrange,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),
                          Image.asset(
                            'assets/yape_qr.png', // Ensure this asset is in pubspec.yaml
                            height: 120,
                            width: 120,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  height: 120,
                                  width: 120,
                                  color: Colors.grey[200],
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 60,
                                    color: Colors.grey[500],
                                  ),
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Escanea este código QR con Yape al recibir tu pedido.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Button to return to home
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const InicioPage(),
                            ),
                            (route) => false,
                          );
                        },
                        icon: const Icon(
                          Icons.home_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        label: const Text(
                          'Volver al Inicio',
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
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar:
          true, // AppBar is transparent, body extends behind
      appBar: AppBar(
        title: const Text(
          'Detalle de Compra',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image with overlay
          Image.asset(
            'assets/boleta_fondo.jpg', // Ensure this asset is in pubspec.yaml
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[200], // Fallback color
              child: Icon(
                Icons.image_not_supported,
                size: 80,
                color: Colors.grey[500],
              ),
            ),
          ),
          // Orange gradient overlay for better contrast
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryOrange.withOpacity(0.3),
                  darkOrange.withOpacity(0.5),
                  Colors.black.withOpacity(0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.1, 0.5, 0.9],
              ),
            ),
          ),
          bodyContent, // The dynamic content based on state
          // Confetti layer
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -pi / 2, // Blast upwards
              emissionFrequency: 0.05,
              numberOfParticles: 20, // number of particles to emit
              maxBlastForce: 100,
              minBlastForce: 80,
              gravity: 0.3, // how quickly it falls
              colors: const [
                // confetti colors
                primaryOrange,
                lightOrange,
                darkOrange,
                Colors.white,
                Colors.amber,
                successGreen, // Add success green to confetti
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build consistent info rows
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isBoldValue = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryOrange, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isBoldValue ? FontWeight.bold : FontWeight.normal,
                color: valueColor ?? textOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
