import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:panaderia_delicia/services/firebase_service.dart';

import 'add_productos_page.dart';
import 'edit_productos_page.dart';
import '../inicio_page.dart';
import '../carrito_global.dart';

class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  final FirebaseService _firebaseService = FirebaseService();
  String _searchQuery = '';

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.toLowerCase();
    });
  }

  void _confirmarEliminar(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar producto?'),
        content: const Text('¿Estás seguro de eliminar este producto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await _firebaseService.deleteProducto(id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Producto eliminado')),
              );
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _agregarAlCarrito(Map<String, dynamic> producto) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // No logueado: agregar a carritoLocal
      carritoLocal.add({...producto, 'cantidad': 1});
      return;
    }

    final carritoRef = FirebaseFirestore.instance
        .collection('carritos')
        .doc(user.uid)
        .collection('items');

    final productoExistente = await carritoRef
        .where('nombre', isEqualTo: producto['nombre'])
        .limit(1)
        .get();

    if (productoExistente.docs.isNotEmpty) {
      final doc = productoExistente.docs.first;
      await carritoRef.doc(doc.id).update({
        'cantidad': (doc['cantidad'] ?? 1) + 1,
      });
    } else {
      await carritoRef.add({...producto, 'cantidad': 1});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos de la Panadería'),
        backgroundColor: Colors.orange,
        leading: IconButton(
          icon: const Icon(Icons.home),
          tooltip: 'Volver a inicio',
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const InicioPage()),
              (Route<dynamic> route) => false,
            );
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, categoría o descripción...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firebaseService.getProductos(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar productos'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final productos = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nombre = (data['nombre'] ?? '').toLowerCase();
                  final descripcion = (data['descripcion'] ?? '').toLowerCase();
                  final categoria = (data['categoria'] ?? '').toLowerCase();
                  return nombre.contains(_searchQuery) ||
                      descripcion.contains(_searchQuery) ||
                      categoria.contains(_searchQuery);
                }).toList();

                if (productos.isEmpty) {
                  return const Center(child: Text('No hay productos.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: productos.length,
                  itemBuilder: (context, index) {
                    final producto = productos[index];
                    final data = producto.data() as Map<String, dynamic>;

                    final nombre = data['nombre'] ?? 'Sin nombre';
                    final descripcion = data['descripcion'] ?? '';
                    final precio = data['precio'] ?? 0.0;
                    final categoria = data['categoria'] ?? '';
                    final ingredientes = data['ingredientes'] ?? '';
                    final disponible = data['disponible'] ?? false;
                    final imagenBase64 = data['imagenBase64'];

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Imagen
                            if (imagenBase64 != null && imagenBase64 != '')
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  base64Decode(imagenBase64),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              const Icon(
                                Icons.image_not_supported,
                                size: 100,
                                color: Colors.grey,
                              ),

                            const SizedBox(width: 16),

                            // Info del producto
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nombre,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Descripción: $descripcion'),
                                  Text('Categoría: $categoria'),
                                  Text('Ingredientes: $ingredientes'),
                                  Text('Precio: S/ $precio'),
                                  Text(
                                    'Disponible: ${disponible ? 'Sí' : 'No'}',
                                    style: TextStyle(
                                      color: disponible
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => EditProductosPage(
                                                id: producto.id,
                                                producto: data,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _confirmarEliminar(producto.id),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_shopping_cart,
                                          color: Colors.green,
                                        ),
                                        onPressed: () =>
                                            _agregarAlCarrito(data),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductosPage()),
          );
        },
        tooltip: 'Agregar producto',
        child: const Icon(Icons.add),
      ),
    );
  }
}
