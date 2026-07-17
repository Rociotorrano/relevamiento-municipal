import 'dart:io';

import 'package:flutter/material.dart';
import 'package:relevamientomunicipal/servicios/guardado.dart';

import 'package:provider/provider.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => LoginData())],
      child: const RelevamientoMunicipal(),
    ),
  );
}

class RelevamientoMunicipal extends StatelessWidget {
  const RelevamientoMunicipal({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LoginData(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF40A5DD),
          colorScheme: ColorScheme.fromSwatch().copyWith(
            secondary: const Color(0xFF40A5DD),
          ),
        ),
        home: const LoginPage(),
      ),
    );
  }

  getToken() {}
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class LoginData with ChangeNotifier {
  String? _usuario;
  String? _password;

  String? get usuario => _usuario;
  String? get password => _password;

  void setLoginData(String usuario, String password) {
    _usuario = usuario;
    _password = password;
    notifyListeners();
  }

  void toggleLoading(bool bool) {}
}

class _LoginPageState extends State<LoginPage> {
  String nombreUsuario = '';
  String contrasena = '';
  bool mostrarContrasena = false;

  void iniciarSesion(BuildContext context) async {
    var loginData = Provider.of<LoginData>(context, listen: false);
    loginData.setLoginData(nombreUsuario, contrasena);

    // Verificar la validez del nombre de usuario y la contraseña aquí
    // if (nombreUsuario == 'rocio' && contrasena == 'torrano') {
    //   Navigator.pushReplacement(
    //     context,
    //     MaterialPageRoute(builder: (context) => TransporteApp()),
    //   );
    // } else {
    //   showDialog(
    //     context: context,
    //     builder: (BuildContext context) {
    //       return AlertDialog(
    //         content: Text('Nombre de usuario o contraseña incorrectos.'),
    //         actions: [
    //           TextButton(
    //             onPressed: () {
    //               Navigator.of(context).pop();
    //             },
    //             child: Text('Aceptar'),
    //           ),
    //         ],
    //       );
    //     },
    //   );
    // }
    login(context, nombreUsuario, contrasena, 1);
  }

  @override
  Widget build(BuildContext context) {
    var keyboardIsOpen = MediaQuery.of(context).viewInsets.bottom != 0.0;
    final texto = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;
    print('${size.height} ${size.width}');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: null,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 60.0),
                  height: MediaQuery.of(context).size.height * 0.20,
                  child: Image.asset(
                    'assets/LOGO_MUNI_2024_COLOR.jpg',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 40.0),
                if (!keyboardIsOpen)
                  Text(
                    'Relevamiento',
                    style: size.width >= 550
                        ? texto.headlineLarge!.copyWith(
                            fontSize: 40,
                            color: const Color(0xFF40A5DD),
                            fontWeight: FontWeight.bold,
                          )
                        : texto.headlineSmall!.copyWith(
                            fontSize: 45,
                            color: const Color(0xFF40A5DD),
                            fontWeight: FontWeight.bold,
                          ),
                  ),
                if (!keyboardIsOpen)
                  Text(
                    'Municipal',
                    style: size.width >= 550
                        ? texto.headlineLarge!.copyWith(
                            fontSize: 40,
                            color: const Color(0xFF40A5DD),
                            fontWeight: FontWeight.bold,
                          )
                        : texto.headlineSmall!.copyWith(
                            fontSize: 45,
                            color: const Color(0xFF40A5DD),
                            fontWeight: FontWeight.bold,
                          ),
                  ),
              ],
            ),
          ),
          Align(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 150.0),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    height: 45,
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        TextField(
                          onChanged: (value) {
                            setState(() {
                              nombreUsuario = value;
                            });
                          },
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            labelText: "USUARIO",
                            labelStyle: TextStyle(color: Colors.grey),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF40A5DD)),
                              borderRadius: BorderRadius.all(
                                Radius.circular(50),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xFF40A5DD),
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(50),
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(50),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    height: 45,
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        TextField(
                          onChanged: (value) {
                            setState(() {
                              contrasena = value;
                            });
                          },
                          textAlign: TextAlign.center,
                          obscureText: !mostrarContrasena,
                          decoration: const InputDecoration(
                            labelText: "CONTRASEÑA",
                            labelStyle: TextStyle(color: Colors.grey),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF40A5DD)),
                              borderRadius: BorderRadius.all(
                                Radius.circular(50),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xFF40A5DD),
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(50),
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(50),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            mostrarContrasena
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              mostrarContrasena = !mostrarContrasena;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 1.0),
                    child: ElevatedButton(
                      onPressed: () => iniciarSesion(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: const Text(
                        'INGRESAR',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
