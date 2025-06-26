import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:panaderia_delicia/services/firebase_service.dart';

class AddProductosPage extends StatefulWidget {
  const AddProductosPage({super.key});

  @override
  State<AddProductosPage> createState() => _AddProductosPageState();
}

class _AddProductosPageState extends State<AddProductosPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _ingredientesController = TextEditingController();

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

  Future<void> seleccionarImagenGaleria() async {
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

  Future<void> _guardarProducto() async {
    if (_formKey.currentState!.validate() && _imagenBase64 != null) {
      final data = {
        'nombre': _nombreController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'precio': double.parse(_precioController.text.trim()),
        'categoria': _categoriaSeleccionada,
        'disponible': _disponible,
        'ingredientes': _ingredientesController.text.trim(),
        'imagenBase64': _imagenBase64,
        'creadoEn': DateTime.now(),
      };

      try {
        await FirebaseService().addProducto(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto agregado correctamente')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al agregar: $e')));
      }
    } else if (_imagenBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una imagen.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Producto')),
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
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                maxLines: 2,
              ),
              TextFormField(
                controller: _ingredientesController,
                decoration: const InputDecoration(labelText: 'Ingredientes'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                maxLines: 2,
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
              _imagenSeleccionada != null
                  ? Image.file(_imagenSeleccionada!, height: 150)
                  : const Text('Ninguna imagen seleccionada'),
              TextButton.icon(
                icon: const Icon(Icons.image),
                label: const Text('Seleccionar imagen'),
                onPressed: seleccionarImagenGaleria,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _guardarProducto,
                child: const Text('Guardar producto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
