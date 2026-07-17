import 'dart:convert'; // necesito esto para convertir a JSON
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:relevamientomunicipal/main.dart';
import 'package:relevamientomunicipal/servicios/globals.dart';
import 'package:relevamientomunicipal/relevamiento_screen.dart';

import 'package:http/http.dart' as http;

import 'globals.dart' as globals;

Future<void> dialogAceptar(
  BuildContext context,
  String texto,
  int pasar,
) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Theme(
        data: ThemeData(
          dialogBackgroundColor: Colors.white,
          textTheme: const TextTheme(
            bodyLarge: TextStyle(fontSize: 18, color: Colors.black),
            bodyMedium: TextStyle(fontSize: 18, color: Colors.black),
            labelLarge: TextStyle(fontSize: 18, color: Colors.blue),
          ),
        ),
        child: AlertDialog(
          content: Text(
            texto,
            style: TextStyle(fontSize: 18, color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (pasar == 1) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                } else if (pasar == 2) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RelevamientoMunicipal(),
                    ),
                  );
                } else if (pasar == 0) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text(
                'Aceptar',
                style: TextStyle(fontSize: 18, color: Colors.blue),
              ),
            ),
          ],
        ),
      );
    },
  );
}

//? ACEPTAR
Future<void> _mostrarMensajeGuardar(
  BuildContext context,
  String mensaje,
  int siguiente,
) async {
  BuildContext? validContext = context;
  showDialog(
    context: validContext,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Guardado con Éxito'),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () {
              if (siguiente == 1) {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              } else if (siguiente == 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RelevamientoMunicipal(),
                  ),
                );
              } else if (siguiente == 0) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Aceptar'),
          ),
        ],
      );
    },
  );
}

//?LOGIN

Future<List<RelevamientoMunicipal>?> login(
  BuildContext context,
  String usuario,
  String password,
  int pasar,
) async {
  var url = Uri.parse('https://backend.sim.lacosta.gob.ar/loguear');

  try {
    var response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer ${globals.miTokenGlobal}',
      },
      body: jsonEncode({"usuario": usuario, "password": password}),
    );

    if (response.statusCode == 200) {
      print('Datos enviados exitosamente.');
      final data = jsonDecode(response.body);
      
      bool isOk = data['estado'] == true || data['estado'] == 'true' || data['estado'] == 1 || data['estado'] == '1';

      if (isOk) {
        miTokenGlobal = data['token']?.toString() ?? ''; // Asignar valor a la variable global
        print('token.');
        print(globals.miTokenGlobal);

        if (pasar == 1) {
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const RelevamientoScreen()),
            );
          }
        }
        return null;
      } else {
        print('La respuesta es incorrecta.');
        if (context.mounted) dialogAceptar(context, data['error']?.toString() ?? 'Error desconocido', 0);
        return null;
      }
    } else {
      print('Falló con status: ${response.statusCode}');
      print('Razón: ${response.reasonPhrase}');
      print('Cuerpo de respuesta: ${response.body}');

      return null;
    }
  } catch (error) {
    print('Error al intentar iniciar sesión: $error');
    if (context.mounted) dialogAceptar(context, 'Error: $error', 0);
    return null;
  }
}

Future<Map<String, dynamic>?> buscarDatosLegajo(
  BuildContext context,
  String legajo,
) async {
  var url = Uri.parse(
    'https://backend.sim.lacosta.gob.ar/personal/personal/relevamientoMunicipal/traer',
  );
  try {
    var response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer ${globals.miTokenGlobal}',
      },
      body: jsonEncode({"legajo": legajo}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is Map<String, dynamic> ? data : {"data": data};
    } else {
      print('Error al buscar legajo: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Error buscarDatosLegajo: $e');
    return null;
  }
}

Future<List<dynamic>> fetchLocalidades() async {
  var url = Uri.parse(
    'https://backend.sim.lacosta.gob.ar/generales/localidades',
  );
  try {
    var response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer ${globals.miTokenGlobal}',
      },
      body: jsonEncode({}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      if (data is Map && data.containsKey('data')) return data['data'];
      return [data];
    } else {
      print('Error al buscar localidades: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    print('Error fetchLocalidades: $e');
    return [];
  }
}

Future<List<dynamic>> fetchCalles() async {
  var url = Uri.parse('https://backend.sim.lacosta.gob.ar/generales/calles');
  try {
    var response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer ${globals.miTokenGlobal}',
      },
      body: jsonEncode({}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      if (data is Map && data.containsKey('data')) return data['data'];
      return [data];
    } else {
      print('Error al buscar calles: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    print('Error fetchCalles: $e');
    return [];
  }
}

Future<bool> guardarRelevamiento(
  BuildContext context,
  Map<String, dynamic> payload,
  File? imageFile,
) async {
  var url = Uri.parse(
    'https://backend.sim.lacosta.gob.ar/personal/personal/relevamientoMunicipal/guardar',
  );
  try {
    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer ${globals.miTokenGlobal}';

    payload.forEach((key, value) {
      if (value != null) {
        if (value is List) {
          request.fields[key] = jsonEncode(value);
        } else {
          request.fields[key] = value.toString();
        }
      }
    });

    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('foto', imageFile.path),
      );
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Guardado exitosamente.');
      return true;
    } else {
      print('Falló guardar con status: ${response.statusCode}');
      print('Cuerpo: ${response.body}');
      return false;
    }
  } catch (e) {
    print('Error guardarRelevamiento: $e');
    return false;
  }
}
