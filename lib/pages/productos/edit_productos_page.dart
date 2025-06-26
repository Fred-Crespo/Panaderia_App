import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:panaderia_delicia/services/firebase_service.dart';

class EditProductosPage extends StatefulWidget {
  final String id;
  final Map<String, dynamic> producto;

  const EditProductosPage({
    super.key,
    required this.id,
    required this.producto,
  });

  @override
  State<EditProductosPage> createState() => _EditProductosPageState();
}

class _EditProductosPageState extends State<EditProductosPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _precioController;
  late TextEditingController _ingredientesController;

  String _categoriaSeleccionada = 'Panadería básica';
  bool _disponible = true;
  File? _imagenSeleccionada;
  String? _imagenBase64;

  final List<String> _categorias = [
    'Panadería básica',
    'Pastelería',
    'Bebidas calientes',
    'Bebidas frías',
    'Postres',
    'Empanadas y salados',
    'Otros',
  ];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final data = widget.producto;

    _nombreController = TextEditingController(text: data['nombre']);
    _descripcionController = TextEditingController(text: data['descripcion']);
    _precioController = TextEditingController(text: data['precio'].toString());
    _ingredientesController = TextEditingController(text: data['ingredientes']);
    _categoriaSeleccionada = data['categoria'] ?? 'Panadería básica';
    _disponible = data['disponible'] ?? true;
    _imagenBase64 = data['imagenBase64'];
  }

  Future<void> seleccionarNuevaImagen() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (picked != null) {
      final bytes = await File(picked.path).readAsBytes();
      setState(() {
        _imagenSeleccionada = File(picked.path);
        _imagenBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> _actualizarProducto() async {
    if (_formKey.currentState!.validate() && _imagenBase64 != null) {
      final data = {
        'nombre': _nombreController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'precio': double.parse(_precioController.text.trim()),
        'categoria': _categoriaSeleccionada,
        'disponible': _disponible,
        'ingredientes': _ingredientesController.text.trim(),
        'imagenBase64': _imagenBase64,
        'actualizadoEn': DateTime.now(),
      };

      try {
        await FirebaseService().updateProducto(widget.id, data);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Producto actualizado')));
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagenPreview = _imagenSeleccionada != null
        ? Image.file(_imagenSeleccionada!, height: 150)
        : _imagenBase64 != null
        ? Image.memory(base64Decode(_imagenBase64!), height: 150)
        : const Text('Ninguna imagen disponible');

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Producto')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 2,
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _ingredientesController,
                decoration: const InputDecoration(labelText: 'Ingredientes'),
                maxLines: 2,
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _precioController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Precio (S/)'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              DropdownButtonFormField<String>(
                value: _categoriaSeleccionada,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: _categorias.map((categoria) {
                  return DropdownMenuItem(
                    value: categoria,
                    child: Text(categoria),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _categoriaSeleccionada = value!;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Disponible'),
                value: _disponible,
                onChanged: (value) {
                  setState(() {
                    _disponible = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Imagen del producto',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              imagenPreview,
              TextButton.icon(
                icon: const Icon(Icons.image),
                label: const Text('Cambiar imagen'),
                onPressed: seleccionarNuevaImagen,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _actualizarProducto,
                child: const Text('Actualizar producto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
