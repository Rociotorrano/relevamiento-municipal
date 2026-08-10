import 'dart:convert'; // necesito esto para convertir a JSON
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:relevamientomunicipal/main.dart';
import 'package:relevamientomunicipal/relevamiento_screen.dart';

import 'package:http/http.dart' as http;

import 'globals.dart' as globals;

String _normalizarToken(dynamic valor) {
  var token = valor?.toString().trim() ?? '';
  if (token.toLowerCase().startsWith('bearer ')) {
    token = token.substring(7).trim();
  }
  return token;
}

String? _tokenActual() {
  final token = _normalizarToken(globals.miTokenGlobal);
  return token.isEmpty ? null : token;
}

Map<String, String> _headersJsonAutorizados() {
  final token = _tokenActual();
  if (token == null) {
    throw StateError('No hay un token de sesión disponible.');
  }

  return <String, String>{
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };
}

bool _esErrorToken(http.Response response) {
  final body = response.body.toLowerCase();
  return response.statusCode == 401 ||
      response.statusCode == 403 ||
      body.contains('token de autorizacion invalido') ||
      body.contains('token de autorización inválido') ||
      body.contains('(614)');
}

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
      // El endpoint de login no debe recibir un token viejo o vacío.
      headers: const <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
      body: jsonEncode({"usuario": usuario, "password": password}),
    );

    if (response.statusCode == 200) {
      print('Datos enviados exitosamente.');
      final data = jsonDecode(response.body);

      bool isOk =
          data['estado'] == true ||
          data['estado'] == 'true' ||
          data['estado'] == 1 ||
          data['estado'] == '1';

      if (isOk) {
        globals.miTokenGlobal = _normalizarToken(data['token']);

        if (globals.miTokenGlobal.isEmpty) {
          if (context.mounted) {
            await dialogAceptar(
              context,
              'El servidor no devolvió un token de sesión válido.',
              0,
            );
          }
          return null;
        }

        debugPrint(
          'Inicio de sesión correcto. Token recibido: '
          '${globals.miTokenGlobal.length} caracteres.',
        );

        if (pasar == 1) {
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const RelevamientoScreen(),
              ),
            );
          }
        }
        return null;
      } else {
        print('La respuesta es incorrecta. Datos del backend: $data');
        if (context.mounted)
          dialogAceptar(context, 'Usuario o contraseña incorrectos', 0);
        return null;
      }
    } else {
      print('Falló con status: ${response.statusCode}');
      print('Razón: ${response.reasonPhrase}');
      print('Cuerpo de respuesta: ${response.body}');
      if (context.mounted)
        dialogAceptar(context, 'Usuario o contraseña incorrectos', 0);
      return null;
    }
  } catch (error) {
    print('Error al intentar iniciar sesión: $error');
    if (context.mounted)
      dialogAceptar(context, 'Usuario o contraseña incorrectos', 0);
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
    var response = await http
        .post(
          url,
          headers: _headersJsonAutorizados(),
          body: jsonEncode({"legajo": legajo}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }
      return null;
    } else {
      return null;
    }
  } catch (e) {
    print('Error buscarDatosLegajo: $e');
    return null;
  }
}

Future<List<Map<String, dynamic>>> traerLocalidad(String localidades) async {
  var url = Uri.parse(
    'https://backend.sim.lacosta.gob.ar/generales/localidades',
  );

  try {
    final response = await http.post(
      url,
      headers: _headersJsonAutorizados(),
      body: jsonEncode({"localidades": localidades}),
    );

    if (response.statusCode == 200) {
      final dynamic jsonBody = jsonDecode(response.body);

      if (jsonBody is Map &&
          jsonBody.containsKey('data') &&
          jsonBody['data'] is List) {
        return List<Map<String, dynamic>>.from(jsonBody['data']);
      } else if (jsonBody is List) {
        return List<Map<String, dynamic>>.from(jsonBody);
      } else {
        throw Exception('Formato de respuesta inesperado.');
      }
    } else {
      throw Exception('Error en la solicitud: ${response.statusCode}');
    }
  } catch (e) {
    print('Error al obtener localidades: $e');
    return [];
  }
}

Future<List<Map<String, dynamic>>> traerCalle(String fklocalidad) async {
  var url = Uri.parse('https://backend.sim.lacosta.gob.ar/generales/calles');

  try {
    final response = await http.post(
      url,
      headers: _headersJsonAutorizados(),
      body: jsonEncode({"fklocalidad": fklocalidad}),
    );

    if (response.statusCode == 200) {
      final dynamic jsonBody = jsonDecode(response.body);

      if (jsonBody is Map &&
          jsonBody.containsKey('data') &&
          jsonBody['data'] is List) {
        return List<Map<String, dynamic>>.from(jsonBody['data']);
      } else if (jsonBody is List) {
        return List<Map<String, dynamic>>.from(jsonBody);
      } else {
        throw Exception('Formato de respuesta inesperado.');
      }
    } else {
      throw Exception('Error en la solicitud: ${response.statusCode}');
    }
  } catch (e) {
    print('Error al obtener calles: $e');
    return [];
  }
}

Future<List<Map<String, dynamic>>> traerSecretarias(String secretarias) async {
  var url = Uri.parse('https://backend.sim.lacosta.gob.ar/generales/secretarias');

  try {
    final response = await http.post(
      url,
      headers: _headersJsonAutorizados(),
      body: jsonEncode({"secretarias": secretarias}),
    );

    if (response.statusCode == 200) {
      final dynamic jsonBody = jsonDecode(response.body);

      if (jsonBody is Map &&
          jsonBody.containsKey('data') &&
          jsonBody['data'] is List) {
        return List<Map<String, dynamic>>.from(jsonBody['data']);
      } else if (jsonBody is List) {
        return List<Map<String, dynamic>>.from(jsonBody);
      } else {
        throw Exception('Formato de respuesta inesperado.');
      }
    } else {
      throw Exception('Error en la solicitud: ${response.statusCode}');
    }
  } catch (e) {
    print('Error al obtener secretarias: $e');
    return [];
  }
}

Future<List<Map<String, dynamic>>> traerOficinas(String oficinas) async {
  var url = Uri.parse('https://backend.sim.lacosta.gob.ar/generales/oficinas');

  try {
    final response = await http.post(
      url,
      headers: _headersJsonAutorizados(),
      body: jsonEncode({"oficinas": oficinas}),
    );

    if (response.statusCode == 200) {
      final dynamic jsonBody = jsonDecode(response.body);

      if (jsonBody is Map &&
          jsonBody.containsKey('data') &&
          jsonBody['data'] is List) {
        return List<Map<String, dynamic>>.from(jsonBody['data']);
      } else if (jsonBody is List) {
        return List<Map<String, dynamic>>.from(jsonBody);
      } else {
        throw Exception('Formato de respuesta inesperado.');
      }
    } else {
      throw Exception('Error en la solicitud: ${response.statusCode}');
    }
  } catch (e) {
    print('Error al obtener oficinas: $e');
    return [];
  }
}

bool _mismoValor(dynamic a, dynamic b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  return a.toString().trim() == b.toString().trim();
}

List<int> _listaIds(dynamic value) {
  if (value is! List) return <int>[];
  return value
      .map((item) {
        if (item is Map) {
          final dynamic id = item['id'] ?? item['pkactividad'];
          return int.tryParse(id?.toString() ?? '');
        }
        return int.tryParse(item.toString());
      })
      .whereType<int>()
      .toSet()
      .toList()
    ..sort();
}

Future<Map<String, dynamic>?> _traerParaVerificar(String legajo) async {
  final Uri url = Uri.parse(
    'https://backend.sim.lacosta.gob.ar/personal/personal/relevamientoMunicipal/traer',
  );

  final http.Response response = await http
      .post(
        url,
        headers: _headersJsonAutorizados(),
        body: jsonEncode(<String, dynamic>{'legajo': legajo}),
      )
      .timeout(const Duration(seconds: 15));

  debugPrint('Verificación traer status: ${response.statusCode}');
  debugPrint('Verificación traer body: ${response.body}');

  if (response.statusCode < 200 || response.statusCode >= 300) return null;
  final dynamic decoded = jsonDecode(response.body);
  return decoded is Map<String, dynamic> ? decoded : null;
}

Future<bool> _verificarRelevamientoGuardado(
  Map<String, dynamic> payload, {
  required bool requiereFoto,
}) async {
  final String legajo = payload['legajo']?.toString() ?? '';
  final dynamic datosPayload = payload['datos'];
  if (legajo.isEmpty || datosPayload is! Map) return false;

  final Map<String, dynamic> esperado = Map<String, dynamic>.from(datosPayload);

  Map<String, dynamic>? respuesta;
  for (int intento = 1; intento <= 3; intento++) {
    await Future<void>.delayed(Duration(milliseconds: 350 * intento));
    respuesta = await _traerParaVerificar(legajo);
    final dynamic formulario = respuesta?['formulario'];
    if (formulario is Map && formulario.isNotEmpty) break;
  }

  final dynamic formularioActual = respuesta?['formulario'];
  if (formularioActual is! Map || formularioActual.isEmpty) {
    debugPrint(
      'VERIFICACIÓN FALLIDA: /traer devolvió formulario null o vacío.',
    );
    return false;
  }

  const List<String> clavesAComprobar = <String>[
    'fk_genero_nacer',
    'fk_genero_identidad',
    'tiene_discapacidad',
    'fk_nivel_educacional',
    'fk_estado_civil',
    'conoce_ioma',
    'fk_conformacion_hogar',
    'fk_mayor_aporte_ingresos_hogar',
    'fk_situacion_vivienda_actual',
    'cuida_otros_familiares',
    'fk_recuperacion_post_licencia',
    'observaciones',
  ];

  for (final String clave in clavesAComprobar) {
    final dynamic valorEsperado = esperado[clave];
    if (valorEsperado == null) continue;

    final dynamic valorGuardado = formularioActual[clave];
    if (!_mismoValor(valorGuardado, valorEsperado)) {
      debugPrint(
        'VERIFICACIÓN FALLIDA en $clave: esperado=$valorEsperado, '
        'guardado=$valorGuardado',
      );
      return false;
    }
  }

  final List<int> vacacionesEsperadas = _listaIds(
    esperado['actividades_vacaciones_habituales'],
  );
  final List<int> vacacionesGuardadas = _listaIds(
    (respuesta?['selecciones'] is Map)
        ? (respuesta!['selecciones']
              as Map)['actividades_vacaciones_habituales']
        : formularioActual['actividades_vacaciones_habituales'],
  );

  if (vacacionesEsperadas.join(',') != vacacionesGuardadas.join(',')) {
    debugPrint(
      'VERIFICACIÓN FALLIDA en vacaciones: esperado=$vacacionesEsperadas, '
      'guardado=$vacacionesGuardadas',
    );
    return false;
  }

  if (requiereFoto) {
    final dynamic fotoGuardada = formularioActual['foto'];
    if (fotoGuardada == null || fotoGuardada.toString().trim().isEmpty) {
      debugPrint(
        'VERIFICACIÓN FALLIDA: las respuestas se guardaron, pero foto sigue null.',
      );
      return false;
    }
    debugPrint('VERIFICACIÓN FOTO OK: $fotoGuardada');
  }

  final dynamic plataforma =
      formularioActual['plataforma'] ??
      formularioActual['origen'] ??
      respuesta?['plataforma'] ??
      respuesta?['origen'];

  if (plataforma != null) {
    if (plataforma.toString().trim().toUpperCase() != 'APP') {
      debugPrint(
        'VERIFICACIÓN FALLIDA: plataforma guardada=$plataforma, esperado=APP.',
      );
      return false;
    }
    debugPrint('VERIFICACIÓN PLATAFORMA OK: APP');
  } else {
    debugPrint(
      'Aviso: /traer no expone la plataforma; debe comprobarse en el listado.',
    );
  }

  debugPrint(
    'VERIFICACIÓN OK: respuestas${requiereFoto ? ', foto' : ''} guardadas.',
  );
  return true;
}

Future<bool> guardarRelevamiento(
  BuildContext context,
  Map<String, dynamic> payload,
  File? imageFile,
) async {
  final Uri url = Uri.parse(
    'https://backend.sim.lacosta.gob.ar/personal/personal/relevamientoMunicipal/guardar',
  );

  try {
    final String? token = _tokenActual();
    if (token == null) {
      debugPrint('No hay una sesión válida para guardar.');
      return false;
    }

    final dynamic legajoRaw = payload['legajo'];
    final dynamic datosRaw = payload['datos'];

    if (legajoRaw == null || datosRaw is! Map) {
      debugPrint('Payload inválido: deben existir legajo y datos.');
      return false;
    }

    final Map<String, dynamic> datos = Map<String, dynamic>.from(datosRaw);

    // El backend diferencia una carga móvil mediante app=true y recibe la foto
    // como multipart. Se conserva el mismo contrato de la web dentro del campo
    // `datos`, y además se duplican los campos simples en la raíz para ser
    // compatible con la rama móvil anterior del backend.
    final http.MultipartRequest request = http.MultipartRequest('POST', url);
    request.headers.addAll(<String, String>{
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    request.fields['app'] = 'true';
    request.fields['legajo'] = legajoRaw.toString();
    request.fields['datos'] = jsonEncode(datos);

    datos.forEach((String key, dynamic value) {
      if (value == null) return;
      request.fields[key] = value is List || value is Map
          ? jsonEncode(value)
          : value.toString();
    });

    if (imageFile != null && await imageFile.exists()) {
      request.files.add(
        await http.MultipartFile.fromPath('foto', imageFile.path),
      );
    }

    debugPrint('========== PAYLOAD APP MULTIPART ==========');
    debugPrint("legajo=${request.fields['legajo']}");
    debugPrint("app=${request.fields['app']}");
    debugPrint("datos=${request.fields['datos']}");
    debugPrint(
      "foto=${request.files.isEmpty ? 'NO ADJUNTA' : request.files.first.filename}",
    );
    debugPrint('===========================================');

    final http.StreamedResponse streamedResponse = await request.send().timeout(
      const Duration(seconds: 35),
    );
    final http.Response response = await http.Response.fromStream(
      streamedResponse,
    );

    debugPrint('Guardado APP status: ${response.statusCode}');
    debugPrint('Guardado APP body: ${response.body}');

    if (_esErrorToken(response)) {
      globals.miTokenGlobal = '';
      return false;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return false;
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is Map) {
      final dynamic estado = decoded['estado'];
      final bool ok =
          estado == true || estado == 1 || estado == '1' || estado == 'true';
      if (!ok) return false;
    }

    return await _verificarRelevamientoGuardado(
      payload,
      requiereFoto: imageFile != null,
    );
  } catch (error, stackTrace) {
    debugPrint('Error guardarRelevamiento APP: $error');
    debugPrintStack(stackTrace: stackTrace);
    return false;
  }
}
