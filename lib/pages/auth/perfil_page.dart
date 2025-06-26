import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:panaderia_delicia/pages/auth/login_page.dart'; // Import LoginPage for redirection

// --- Define your custom color palette (Consistent with previous pages) ---
const Color primaryOrange = Color(0xFFF57C00); // A warm, inviting orange
const Color lightOrange = Color(0xFFFFCC80); // A lighter shade for accents
const Color darkOrange = Color(0xFFE65100); // A deeper shade for emphasis
const Color textOrange = Color(0xFFBF360C); // A burnt orange for text
const Color accentColor = Color(0xFFFFA000); // A brighter orange for highlights
const Color successGreen = Color(0xFF4CAF50); // Green for success messages

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final _formKey = GlobalKey<FormState>();
  final user = FirebaseAuth.instance.currentUser;

  final nombreCtrl = TextEditingController();
  final edadCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
  final direccionCtrl = TextEditingController();

  String? _generoSeleccionado; // Changed to nullable String for Dropdown
  String rol = "cliente";
  String? fotoBase64;
  bool _isLoading = true; // State to manage loading data

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    if (user == null) {
      setState(() {
        _isLoading = false; // Not loading if no user
      });
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user!.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          nombreCtrl.text = data['nombre'] ?? '';
          edadCtrl.text = (data['edad'] ?? '').toString();
          _generoSeleccionado =
              data['genero'] ?? null; // Assign to nullable string
          telefonoCtrl.text = data['telefono'] ?? '';
          direccionCtrl.text = data['direccion'] ?? '';
          rol = data['rol'] ?? 'cliente';
          fotoBase64 = data['fotoBase64'];
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
        // Optionally show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al cargar perfil: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      });
    }
  }

  Future<void> _guardarCambios() async {
    if (_formKey.currentState!.validate() && user != null) {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(width: 15),
              Text(
                'Guardando cambios...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: primaryOrange,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      try {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user!.uid)
            .update({
              'nombre': nombreCtrl.text.trim(),
              'edad': int.tryParse(edadCtrl.text.trim()) ?? 0,
              'genero': _generoSeleccionado ?? '', // Use _generoSeleccionado
              'telefono': telefonoCtrl.text.trim(),
              'direccion': direccionCtrl.text.trim(),
              'fotoBase64':
                  fotoBase64, // Changed from 'fotoBase64' to 'fotoPerfil'
            });

        ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Datos actualizados correctamente.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: successGreen,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al guardar cambios: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _elegirImagen() async {
    final picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (imagen != null) {
      final bytes = await imagen.readAsBytes();
      setState(() {
        fotoBase64 = base64Encode(bytes);
      });
    }
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    edadCtrl.dispose();
    telefonoCtrl.dispose();
    direccionCtrl.dispose();
    super.dispose();
  }

  // Helper function to create themed TextFormFields
  TextFormField _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: darkOrange),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: darkOrange.withOpacity(0.8)),
        prefixIcon: icon != null ? Icon(icon, color: primaryOrange) : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: darkOrange, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: lightOrange.withOpacity(0.8), width: 1),
        ),
        errorStyle: const TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.bold,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Custom App Bar
    final customAppBar = AppBar(
      title: const Text(
        'Mi Perfil',
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
                Icon(Icons.account_circle, size: 100, color: lightOrange),
                const SizedBox(height: 20),
                Text(
                  'No has iniciado sesión.',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textOrange,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Por favor, inicia sesión para ver y editar tu perfil.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () {
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
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryOrange),
                  const SizedBox(height: 15),
                  Text(
                    'Cargando perfil...',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            )
          : Container(
              color: Colors.grey.shade50, // Light background for the form
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      // Profile Picture Section
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundImage: fotoBase64 != null
                                  ? MemoryImage(base64Decode(fotoBase64!))
                                  : null,
                              child: fotoBase64 == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.grey,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                onPressed: _elegirImagen,
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      darkOrange, // Darker orange camera button
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(10),
                                  elevation: 5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          'Toca el avatar para cambiar tu foto',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // User Email (Non-editable)
                      _buildTextFormField(
                        controller: TextEditingController(
                          text: user?.email ?? '',
                        ), // Pre-fill with user email
                        labelText: 'Correo Electrónico',
                        icon: Icons.email,
                      ),
                      const SizedBox(height: 20),

                      // Form Fields
                      _buildTextFormField(
                        controller: nombreCtrl,
                        labelText: 'Nombre completo',
                        icon: Icons.person,
                        validator: (value) =>
                            value!.isEmpty ? 'El nombre es requerido' : null,
                      ),
                      const SizedBox(height: 20),
                      _buildTextFormField(
                        controller: edadCtrl,
                        labelText: 'Edad',
                        keyboardType: TextInputType.number,
                        icon: Icons.cake,
                        validator: (value) {
                          if (value!.isNotEmpty &&
                              int.tryParse(value) == null) {
                            return 'Ingresa una edad válida';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _generoSeleccionado,
                        decoration: InputDecoration(
                          labelText: 'Género',
                          labelStyle: TextStyle(
                            color: darkOrange.withOpacity(0.8),
                          ),
                          prefixIcon: const Icon(
                            Icons.people,
                            color: primaryOrange,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: lightOrange.withOpacity(0.8),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: darkOrange,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                        ),
                        dropdownColor: Colors.white,
                        items: const [
                          DropdownMenuItem(
                            value: 'Masculino',
                            child: Text(
                              'Masculino',
                              style: TextStyle(color: darkOrange),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Femenino',
                            child: Text(
                              'Femenino',
                              style: TextStyle(color: darkOrange),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Otro',
                            child: Text(
                              'Otro',
                              style: TextStyle(color: darkOrange),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Prefiero no decirlo',
                            child: Text(
                              'Prefiero no decirlo',
                              style: TextStyle(color: darkOrange),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _generoSeleccionado = value;
                          });
                        },
                        validator: (value) => value == null || value.isEmpty
                            ? 'El género es requerido'
                            : null,
                        style: const TextStyle(color: darkOrange),
                      ),
                      const SizedBox(height: 20),
                      _buildTextFormField(
                        controller: telefonoCtrl,
                        labelText: 'Teléfono',
                        keyboardType: TextInputType.phone,
                        icon: Icons.phone,
                      ),
                      const SizedBox(height: 20),
                      _buildTextFormField(
                        controller: direccionCtrl,
                        labelText: 'Dirección',
                        icon: Icons.location_on,
                      ),
                      const SizedBox(height: 20),

                      // User Role Display
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: lightOrange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: primaryOrange.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.admin_panel_settings,
                              color: primaryOrange,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Rol de usuario: ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textOrange,
                              ),
                            ),
                            Text(
                              rol == 'admin' ? 'Administrador' : 'Cliente',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: rol == 'admin'
                                    ? darkOrange
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Save Changes Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: _guardarCambios,
                          icon: const Icon(
                            Icons.save,
                            color: Colors.white,
                            size: 28,
                          ),
                          label: const Text(
                            'Guardar Cambios',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: darkOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 8,
                            shadowColor: darkOrange.withOpacity(0.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
