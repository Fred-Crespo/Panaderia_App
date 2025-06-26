import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'dart:convert';

import 'package:panaderia_delicia/pages/auth/login_page.dart'; // For base64Decode

// --- Define your custom color palette (Consistent with previous pages) ---
const Color primaryOrange = Color(0xFFF57C00); // A warm, inviting orange
const Color lightOrange = Color(0xFFFFCC80); // A lighter shade for accents
const Color darkOrange = Color(0xFFE65100); // A deeper shade for emphasis
const Color textOrange = Color(0xFFBF360C); // A burnt orange for text
const Color accentColor = Color(0xFFFFA000); // A brighter orange for highlights
const Color successGreen = Color(0xFF4CAF50); // Green for success status
const Color pendingBlue = Color(0xFF2196F3); // Blue for pending status

class HistorialPage extends StatelessWidget {
  const HistorialPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Custom App Bar for both states (logged in or not)
    final customAppBar = AppBar(
      title: const Text(
        'Historial de Pedidos',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 22,
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
      automaticallyImplyLeading: true, // Allow back button
    );

    if (user == null) {
      return Scaffold(
        appBar: customAppBar,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 80, color: lightOrange),
                const SizedBox(height: 20),
                Text(
                  'Acceso Restringido',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textOrange,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Debes iniciar sesión para ver tu historial de pedidos.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to Login Page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: const Text(
                    'Iniciar Sesión',
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
        ),
      );
    }

    return Scaffold(
      appBar: customAppBar,
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50, // Light background for list
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('pedidos')
              .where('usuario', isEqualTo: user.uid)
              .orderBy('fecha', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error al cargar el historial: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: primaryOrange),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_toggle_off,
                        size: 100,
                        color: lightOrange,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Aún no tienes pedidos.',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textOrange,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '¡Explora nuestro catálogo y haz tu primera compra!',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to Catalog Page (assuming it's at index 0 of InicioPage's pages)
                          // You might need a more robust navigation for this if not directly from InicioPage
                          Navigator.pop(
                            context,
                          ); // Go back to InicioPage to show Catalog
                        },
                        icon: const Icon(
                          Icons.bakery_dining,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Ir al Catálogo',
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

            final pedidos = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: pedidos.length,
              itemBuilder: (context, index) {
                final data = pedidos[index].data() as Map<String, dynamic>;
                final productos = List<Map<String, dynamic>>.from(
                  data['productos'],
                );
                final total = data['total'] ?? 0.0;
                final fecha = (data['fecha'] as Timestamp).toDate();
                final estado =
                    data['estado'] ?? 'Pendiente'; // Get order status

                IconData statusIcon;
                Color statusColor;
                switch (estado) {
                  case 'Completado':
                    statusIcon = Icons.check_circle_rounded;
                    statusColor = successGreen;
                    break;
                  case 'Cancelado':
                    statusIcon = Icons.cancel_rounded;
                    statusColor = Colors.redAccent;
                    break;
                  case 'Enviado':
                    statusIcon = Icons.local_shipping_rounded;
                    statusColor = primaryOrange;
                    break;
                  default: // Pendiente
                    statusIcon = Icons.hourglass_empty_rounded;
                    statusColor = pendingBlue;
                    break;
                }

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
                  color: Colors.white.withOpacity(0.98),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Icon(statusIcon, color: statusColor, size: 30),
                    title: Text(
                      'Pedido #${pedidos.length - index} - ${DateFormat('dd/MM/yyyy HH:mm').format(fecha)}', // Order number and formatted date
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: darkOrange,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Total: S/ ${total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Estado: $estado',
                          style: TextStyle(
                            fontSize: 14,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Divider(
                        color: lightOrange.withOpacity(0.5),
                        indent: 16,
                        endIndent: 16,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Productos en este pedido:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textOrange,
                            ),
                          ),
                        ),
                      ),
                      ...productos.map((producto) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 4.0,
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child:
                                    producto['imagenBase64'] != null &&
                                        producto['imagenBase64'] != ''
                                    ? Image.memory(
                                        base64Decode(producto['imagenBase64']),
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  width: 50,
                                                  height: 50,
                                                  color: Colors.grey[200],
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    size: 25,
                                                    color: Colors.grey[500],
                                                  ),
                                                ),
                                      )
                                    : Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: lightOrange.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: lightOrange,
                                            width: 1,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.fastfood,
                                          size: 25,
                                          color: primaryOrange,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      producto['nombre'] ??
                                          'Producto Desconocido',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: darkOrange,
                                      ),
                                    ),
                                    Text(
                                      'Cantidad: ${producto['cantidad']} - S/ ${producto['precio'].toStringAsFixed(2)} c/u',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      'Subtotal: S/ ${(producto['cantidad'] * producto['precio']).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: textOrange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(
                        height: 10,
                      ), // Add spacing at the bottom of expansion
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
