import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../inicio_page.dart';

// --- Define your custom color palette ---
const Color primaryOrange = Color(0xFFF57C00); // A warm, inviting orange
const Color lightOrange = Color(0xFFFFCC80); // A lighter shade for accents
const Color darkOrange = Color(0xFFE65100); // A deeper shade for emphasis
const Color textOrange = Color(0xFFBF360C); // A burnt orange for text

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _edadController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();

  String? _generoSeleccionado;
  String? _error;
  String? _imagenBase64;
  File? _imagenFile;

  // State to manage password visibility
  bool _obscureText = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    _edadController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imagenFile = File(picked.path);
        _imagenBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> _register() async {
    setState(() {
      _error = null; // Clear previous errors
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _error =
            'Por favor, completa todos los campos requeridos y corrige los errores.';
      });
      return;
    }

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(cred.user!.uid)
          .set({
            'correo': _emailController.text.trim(),
            'nombre': _nombreController.text.trim(),
            'edad': int.tryParse(_edadController.text.trim()) ?? 0,
            'genero': _generoSeleccionado ?? '',
            'telefono': _telefonoController.text.trim(),
            'direccion': _direccionController.text.trim(),
            'rol': 'cliente',
            'fotoPerfil': _imagenBase64 ?? '',
            'fechaRegistro': FieldValue.serverTimestamp(),
          });

      if (context.mounted) {
        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '¡Registro exitoso! Bienvenido.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const InicioPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'weak-password') {
        errorMessage =
            'La contraseña es demasiado débil. Usa al menos 6 caracteres.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'El correo electrónico ya está en uso.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'El formato del correo electrónico es inválido.';
      } else {
        errorMessage = 'Error en el registro. Intenta de nuevo: ${e.message}';
      }
      setState(() {
        _error = errorMessage;
      });
    } catch (e) {
      setState(() {
        _error = 'Ocurrió un error inesperado durante el registro.';
      });
    }
  }

  // Helper function to create themed TextFormFields
  TextFormField _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
    IconData? icon,
    bool showPasswordToggle = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: darkOrange),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: darkOrange.withOpacity(0.8)),
        prefixIcon: icon != null ? Icon(icon, color: primaryOrange) : null,
        suffixIcon: showPasswordToggle
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility : Icons.visibility_off,
                  color: primaryOrange,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
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
        ), // Style for validation errors
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Crear Cuenta',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [lightOrange, primaryOrange, darkOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.1, 0.5, 0.9],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black38,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // Error Message Display
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Profile Image Picker
                  GestureDetector(
                    onTap: _seleccionarImagen,
                    child: CircleAvatar(
                      radius: 60, // Slightly larger avatar
                      backgroundColor: Colors.white.withOpacity(
                        0.9,
                      ), // White background for avatar
                      backgroundImage: _imagenFile != null
                          ? FileImage(_imagenFile!)
                          : null,
                      child: _imagenFile == null
                          ? Icon(
                              Icons.camera_alt,
                              size: 50,
                              color: primaryOrange.withOpacity(
                                0.7,
                              ), // Orange camera icon
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Toca para elegir tu foto de perfil',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 30),

                  _buildTextFormField(
                    controller: _nombreController,
                    labelText: 'Nombre completo',
                    icon: Icons.person,
                    validator: (value) =>
                        value!.isEmpty ? 'El nombre es requerido' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildTextFormField(
                    controller: _emailController,
                    labelText: 'Correo electrónico',
                    keyboardType: TextInputType.emailAddress,
                    icon: Icons.email,
                    validator: (value) {
                      if (value!.isEmpty) return 'El correo es requerido';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
                        return 'Ingresa un correo válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildTextFormField(
                    controller: _passwordController,
                    labelText: 'Contraseña',
                    obscureText: _obscureText,
                    icon: Icons.lock,
                    showPasswordToggle: true,
                    validator: (value) {
                      if (value!.isEmpty) return 'La contraseña es requerida';
                      if (value.length < 6)
                        return 'La contraseña debe tener al menos 6 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildTextFormField(
                    controller: _edadController,
                    labelText: 'Edad',
                    keyboardType: TextInputType.number,
                    icon: Icons.cake,
                    validator: (value) {
                      if (value!.isNotEmpty && int.tryParse(value) == null)
                        return 'Ingresa una edad válida';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Gender Dropdown
                  DropdownButtonFormField<String>(
                    value: _generoSeleccionado,
                    decoration: InputDecoration(
                      labelText: 'Género',
                      labelStyle: TextStyle(color: darkOrange.withOpacity(0.8)),
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
                    onChanged: (value) =>
                        setState(() => _generoSeleccionado = value),
                    style: const TextStyle(
                      color: darkOrange,
                    ), // Ensure text color inside dropdown is visible
                  ),
                  const SizedBox(height: 20),
                  _buildTextFormField(
                    controller: _telefonoController,
                    labelText: 'Teléfono',
                    keyboardType: TextInputType.phone,
                    icon: Icons.phone,
                  ),
                  const SizedBox(height: 20),
                  _buildTextFormField(
                    controller: _direccionController,
                    labelText: 'Dirección',
                    icon: Icons.location_on,
                  ),
                  const SizedBox(height: 30),

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 8,
                      ),
                      child: const Text(
                        'Registrarse',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
