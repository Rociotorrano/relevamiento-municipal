import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:relevamientomunicipal/servicios/guardado.dart';
import 'package:relevamientomunicipal/main.dart';

class RelevamientoScreen extends StatefulWidget {
  const RelevamientoScreen({Key? key}) : super(key: key);

  @override
  _RelevamientoScreenState createState() => _RelevamientoScreenState();
}

class _RelevamientoScreenState extends State<RelevamientoScreen> {
  static const Map<String, String> _secretariasPorCodigo = {
    'HE': 'SECRETARIA DE HACIENDA, ECONOMIA Y PLANIFICACION ESTRATEGICA',
  };

  static const Map<String, String> _dependenciasPorCodigo = {
    '450': 'INFORMATICA',
  };

  final TextEditingController _legajoController = TextEditingController();
  final TextEditingController _prefijoController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();
  final TextEditingController _numeroCalleController = TextEditingController();
  final TextEditingController _otroGeneroController = TextEditingController();
  final TextEditingController _otraAdaptacionController =
      TextEditingController();
  final TextEditingController _dniConyugeController = TextEditingController();
  final TextEditingController _nombreConyugeController =
      TextEditingController();
  final TextEditingController _otroIngresosController = TextEditingController();
  final TextEditingController _otroViviendaController = TextEditingController();
  final TextEditingController _otroVacacionesController =
      TextEditingController();
  bool _mostrarCuestionario = false;
  bool _buscandoLegajo = false;

  Map<String, dynamic>? datosPersonales;
  List<dynamic> localidades = [];
  List<dynamic> calles = [];

  String? selectedLocalidad;
  String? selectedCalle;
  File? _imageFile;

  // Question states
  String? q1SexoDni;
  String? q2IdentidadGenero;
  String? q3Discapacidad;
  String? q3_1DiscapacidadAdaptacion;
  String? q4Estudios;
  String? q5IOMA;
  String? q6EstadoCivil;
  String? q7Hogar;
  String? q7_1HijosMenores;
  String? q7_2HijosDiscapacidad;
  String? q7_3HijosEscolarizados;
  String? q8Ingresos;
  String? q9Vivienda;
  String? q10Cuidado;
  String? q10_1CuidadoDiscapacidad;
  List<String> q11Vacaciones = [];
  bool _otroVacacionesChecked = false;
  String? q12Recuperacion;
  final TextEditingController _observacionesController =
      TextEditingController();
  int _preguntaActual = 0;
  static const int _totalPreguntas = 16;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final locs = await traerLocalidad('');
    setState(() {
      localidades = locs;
    });
  }

  Future<void> _cargarCalles(
    String fklocalidad, {
    String? domicilioCompleto,
  }) async {
    final cals = await traerCalle(fklocalidad);
    setState(() {
      calles = cals;
      if (domicilioCompleto != null && domicilioCompleto.isNotEmpty) {
        String domUpper = domicilioCompleto.trim().toUpperCase();
        Map<String, dynamic>? bestMatch;
        int longestMatchLength = 0;

        for (var item in cals) {
          String calleName = (item['calle']?.toString() ?? '')
              .trim()
              .toUpperCase();
          if (calleName.isNotEmpty && domUpper.startsWith(calleName)) {
            if (calleName.length > longestMatchLength) {
              longestMatchLength = calleName.length;
              bestMatch = Map<String, dynamic>.from(item);
            }
          }
        }

        if (bestMatch != null) {
          selectedCalle =
              bestMatch['pkcalle']?.toString() ?? bestMatch['id']?.toString();
          String resto = domicilioCompleto.substring(longestMatchLength).trim();
          _numeroCalleController.text = resto;
        } else {
          selectedCalle = null;
          _numeroCalleController.text = domicilioCompleto;
        }
      } else {
        selectedCalle = null;
      }
    });
  }

  Future<void> _buscarDatos() async {
    if (_legajoController.text.isEmpty || _buscandoLegajo) return;

    setState(() => _buscandoLegajo = true);

    Map<String, dynamic>? datos;
    try {
      datos = await buscarDatosLegajo(context, _legajoController.text);
    } catch (_) {
      datos = null;
    } finally {
      if (mounted) {
        setState(() => _buscandoLegajo = false);
      }
    }

    if (!mounted) return;

    if (datos != null && datos.isNotEmpty) {
      final datosOk = datos;
      setState(() {
        datosPersonales = datosOk;

        // Procesar teléfono de forma inteligente
        String? telRaw = datosOk['telefono']?.toString();
        if (telRaw != null && telRaw.isNotEmpty) {
          String cleanTel = telRaw.replaceAll('-', ' ').trim();
          cleanTel = cleanTel.replaceAll(RegExp(r'\s+'), ' ');
          final parts = cleanTel.split(' ');
          if (parts.length > 1) {
            _prefijoController.text = parts[0];
            _celularController.text = parts.sublist(1).join(' ');
          } else {
            String num = cleanTel;
            if (num.startsWith('02246')) {
              _prefijoController.text = '02246';
              _celularController.text = num.substring(5);
            } else if (num.startsWith('2246')) {
              _prefijoController.text = '2246';
              _celularController.text = num.substring(4);
            } else if (num.length > 6) {
              int splitPos = num.length > 8 ? 4 : 3;
              _prefijoController.text = num.substring(0, splitPos);
              _celularController.text = num.substring(splitPos);
            } else {
              _prefijoController.text = '';
              _celularController.text = num;
            }
          }
        } else {
          _prefijoController.text = '';
          _celularController.text = '';
        }

        // Localidad viene como texto, buscamos coincidencia por nombre
        String? locNombre = datosOk['localidad']?.toString().trim();
        final locMatch = localidades.cast<Map<String, dynamic>?>().firstWhere(
          (e) =>
              e != null &&
              (e['localidad']?.toString().trim().toUpperCase() ==
                  locNombre?.toUpperCase()),
          orElse: () => null,
        );
        selectedLocalidad = locMatch != null
            ? locMatch['pklocalidad']?.toString()
            : null;
        selectedCalle = null;
        calles = []; // limpiar calles hasta que se carguen
      });

      // Cargar calles de la localidad del legajo e intentar emparejar calle y número
      if (selectedLocalidad != null) {
        String? domRaw = datosOk['domicilio']?.toString();
        _cargarCalles(selectedLocalidad!, domicilioCompleto: domRaw);
      } else {
        _numeroCalleController.text = datosOk['domicilio']?.toString() ?? '';
      }
    } else {
      await _mostrarErrorLegajo();
    }
  }

  Future<void> _mostrarErrorLegajo() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF16F75), width: 4),
                ),
                child: const Icon(
                  Icons.close,
                  size: 58,
                  color: Color(0xFFF16F75),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Error',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF555555),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'No se pudieron cargar los datos personales. Verifique el legajo ingresado.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, color: Color(0xFF555555)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Asegurar que no quede ningún estado de carga activo
                  if (_buscandoLegajo) {
                    setState(() => _buscandoLegajo = false);
                  }
                  Navigator.of(dialogContext).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF658EBC),
                ),
                child: const Text(
                  'ACEPTAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _limpiarDatos() {
    setState(() {
      _legajoController.clear();
      datosPersonales = null;
      _prefijoController.clear();
      _celularController.clear();
      _numeroCalleController.clear();
      _otroGeneroController.clear();
      _otraAdaptacionController.clear();
      _dniConyugeController.clear();
      _nombreConyugeController.clear();
      _otroIngresosController.clear();
      _otroViviendaController.clear();
      _otroVacacionesController.clear();
      selectedLocalidad = null;
      selectedCalle = null;
      _imageFile = null;

      q1SexoDni = null;
      q2IdentidadGenero = null;
      q3Discapacidad = null;
      q3_1DiscapacidadAdaptacion = null;
      q4Estudios = null;
      q5IOMA = null;
      q6EstadoCivil = null;
      q7Hogar = null;
      q7_1HijosMenores = null;
      q7_2HijosDiscapacidad = null;
      q7_3HijosEscolarizados = null;
      q8Ingresos = null;
      q9Vivienda = null;
      q10Cuidado = null;
      q10_1CuidadoDiscapacidad = null;
      q11Vacaciones.clear();
      _otroVacacionesChecked = false;
      q12Recuperacion = null;
      _observacionesController.clear();
      _preguntaActual = 0;
      _mostrarCuestionario = false;
    });
  }

  Future<void> _tomarFoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _imageFile = File(photo.path);
      });
    }
  }

  void _irAlCuestionario() {
    setState(() => _mostrarCuestionario = true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_mostrarCuestionario,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _mostrarCuestionario) {
          setState(() => _mostrarCuestionario = false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _mostrarCuestionario ? 'Relevamiento' : 'Formulario',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF40A5DD),
          leading: _mostrarCuestionario
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  tooltip: 'Volver al formulario',
                  onPressed: () => setState(() => _mostrarCuestionario = false),
                )
              : null,
          actions: _mostrarCuestionario
              ? []
              : [
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                  ),
                ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: _mostrarCuestionario
              ? _buildPreguntasForm()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildIniciarRelevamientoCard(),
                    const SizedBox(height: 16),
                    if (datosPersonales != null) _buildDatosPersonalesCard(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildIniciarRelevamientoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Iniciar relevamiento',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF40A5DD), // Celeste
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _legajoController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: 'Numero de legajo',
                prefixIcon: const Icon(Icons.badge, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _buscandoLegajo ? null : _buscarDatos,
                icon: _buscandoLegajo
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.search, color: Colors.white),
                label: Text(
                  _buscandoLegajo ? 'BUSCANDO...' : 'BUSCAR DATOS',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade600, // Gris opaco
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatosPersonalesCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Datos personales',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF284b72),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _limpiarDatos,
                  icon: const Icon(Icons.refresh, color: Colors.red),
                  label: const Text(
                    'LIMPIAR',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildReadOnlyField(
              'Numero de legajo',
              datosPersonales?['legajo']?.toString() ?? '',
              Icons.badge,
            ),
            const SizedBox(height: 12),
            _buildReadOnlyField(
              'Nombre y apellido',
              datosPersonales?['nombre_apellido']?.toString() ?? '',
              Icons.person_outline,
            ),
            const SizedBox(height: 12),
            _buildReadOnlyField(
              'DNI',
              datosPersonales?['dni']?.toString() ?? '',
              Icons.badge_outlined,
            ),
            const SizedBox(height: 12),
            _buildReadOnlyField(
              'Fecha de nacimiento',
              datosPersonales?['fecha_nacimiento']?.toString() ?? '',
              Icons.calendar_today,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _prefijoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Prefijo',
                prefixIcon: Icon(Icons.phone, color: Colors.grey),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _celularController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Numero de celular',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Localidad',
                prefixIcon: Icon(Icons.location_on, color: Colors.grey),
                border: OutlineInputBorder(),
              ),
              value: selectedLocalidad,
              isExpanded: true,
              items: localidades
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value:
                          item['pklocalidad']?.toString() ??
                          item['id']?.toString() ??
                          item.toString(),
                      child: Text(
                        item['localidad']?.toString() ??
                            item['nombre']?.toString() ??
                            item.toString(),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                setState(() {
                  selectedLocalidad = val;
                  selectedCalle = null;
                  calles = [];
                });
                if (val != null) _cargarCalles(val);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Calle',
                prefixIcon: Icon(Icons.add_road, color: Colors.grey),
                border: OutlineInputBorder(),
              ),
              value: selectedCalle,
              isExpanded: true,
              items: calles
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value:
                          item['pkcalle']?.toString() ??
                          item['id']?.toString() ??
                          item.toString(),
                      child: Text(
                        item['calle']?.toString() ??
                            item['nombre']?.toString() ??
                            item.toString(),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => selectedCalle = val),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _numeroCalleController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Numero',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF40A5DD), thickness: 1.5),
            const SizedBox(height: 16),
            const Text(
              'Lugar de trabajo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF284b72),
              ),
            ),
            const SizedBox(height: 16),
            _buildReadOnlyField(
              'Secretaria',
              _nombreLugarTrabajo(datosPersonales, const [
                'nombre_secretaria',
                'secretaria_nombre',
                'secretaria',
              ], _secretariasPorCodigo),
              Icons.business,
            ),
            const SizedBox(height: 12),
            _buildReadOnlyField(
              'Nombre del lugar de trabajo',
              _nombreLugarTrabajo(datosPersonales, const [
                'nombre_dependencia',
                'dependencia_nombre',
                'nombre_lugar_trabajo',
                'lugar_trabajo',
                'dependencia',
              ], _dependenciasPorCodigo),
              Icons.work,
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF40A5DD), thickness: 1.5),
            const SizedBox(height: 16),
            Stack(
              children: [
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4F8),
                    border: Border.all(
                      color: const Color(0xFFB0C4DE),
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person, size: 100, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'Foto de perfil',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                ),
                if (_imageFile != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => setState(() => _imageFile = null),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _tomarFoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('TOMAR FOTO', style: TextStyle(fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF284b72),
                  side: const BorderSide(color: Color(0xFF284b72)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton.filled(
                tooltip: 'Ir al cuestionario',
                onPressed: _irAlCuestionario,
                icon: const Icon(Icons.arrow_forward),
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF284b72),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: const OutlineInputBorder(),
        enabled: false,
      ),
      child: Text(
        value.isEmpty ? '-' : value,
        style: const TextStyle(fontSize: 16, color: Colors.black),
      ),
    );
  }

  String _nombreLugarTrabajo(
    Map<String, dynamic>? datos,
    List<String> keys,
    Map<String, String> nombresPorCodigo,
  ) {
    if (datos == null) return '';

    for (final key in keys) {
      final valor = datos[key]?.toString().trim();
      if (valor == null || valor.isEmpty) continue;

      if (key.contains('nombre')) return valor;
      return nombresPorCodigo[valor.toUpperCase()] ?? valor;
    }
    return '';
  }

  Widget _buildPreguntasForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pregunta ${_preguntaActual + 1} de $_totalPreguntas',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF284b72),
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (_preguntaActual + 1) / _totalPreguntas,
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
          backgroundColor: const Color(0xFFDCE7F1),
          valueColor: const AlwaysStoppedAnimation(Color(0xFF40A5DD)),
        ),
        const SizedBox(height: 20),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildPreguntaActual(),
          ),
        ),
      ],
    );
  }

  Widget _buildPreguntaActual() {
    final preguntas = <Widget>[
      _radioPaso(
        '1. ¿Cuál es el sexo según figura en el DNI?',
        ['Femenino', 'Masculino', 'X'],
        q1SexoDni,
        (v) => q1SexoDni = v,
      ),
      _preguntaIdentidadGeneroWidget(isLegacy: false),
      _preguntaDiscapacidadWidget(isLegacy: false),
      _radioPaso(
        '4. ¿Cuál es su nivel de estudios alcanzado?',
        [
          'Primario Incompleto',
          'Primario Completo',
          'Secundario Incompleto',
          'Secundario Completo',
          'Terciario Incompleto',
          'Terciario Completo',
          'Universitario Incompleto',
          'Universitario Completo',
          'Sin Estudios',
        ],
        q4Estudios,
        (v) => q4Estudios = v,
      ),
      _radioPaso(
        '5. ¿Sabe que siendo empleado municipal puede usar IOMA?',
        ['Sí', 'No'],
        q5IOMA,
        (v) => q5IOMA = v,
      ),
      _preguntaEstadoCivilWidget(isLegacy: false),
      _preguntaHogar(),
      _radioPaso(
        '7.1 ¿Cuántas hijas o hijos menores de edad tiene?',
        ['1 hija/o', '2 hijas/os', '3 hijas/os', 'Más de tres hijos'],
        q7_1HijosMenores,
        (v) => q7_1HijosMenores = v,
      ),
      _radioPaso(
        '7.2 ¿Alguno de sus hijos o hijas posee algún tipo de discapacidad?',
        ['Sí', 'No'],
        q7_2HijosDiscapacidad,
        (v) => q7_2HijosDiscapacidad = v,
      ),
      _radioPaso(
        '7.3 ¿Sus hijos menores de edad a cargo se encuentran escolarizados?',
        ['Sí', 'No'],
        q7_3HijosEscolarizados,
        (v) => q7_3HijosEscolarizados = v,
      ),
      _preguntaIngresosWidget(isLegacy: false),
      _preguntaViviendaWidget(isLegacy: false),
      _preguntaCuidadoWidget(isLegacy: false),
      _preguntaVacacionesWidget(isLegacy: false),
      _radioPaso(
        '12. Al finalizar sus vacaciones o licencia, ¿considera que logró recuperarse física y mentalmente del trabajo?',
        ['Totalmente', 'En gran medida', 'Moderadamente', 'Poco', 'Nada'],
        q12Recuperacion,
        (v) => q12Recuperacion = v,
      ),
      _preguntaObservaciones(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_preguntaActual > 0)
          TextButton.icon(
            onPressed: _preguntaAnterior,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Anterior'),
          ),
        preguntas[_preguntaActual],
      ],
    );
  }

  Widget _preguntaHogar() {
    const opciones = [
      'Vivo sola/solo',
      'Convivo con mi pareja',
      'Vivo sola/solo con mis hijos',
      'Vivo con pareja e hijos',
      'Vivo con pareja, hijos y otros familiares',
      'Vivo con otros familiares (no hijos/as)',
    ];

    return _buildRadioQuestion(
      '7. ¿Cómo está conformado su hogar?',
      opciones,
      q7Hogar,
      (respuesta) {
        setState(() {
          q7Hogar = respuesta;
          _preguntaActual = _hogarSinHijos(respuesta) ? 10 : 7;
        });
      },
    );
  }

  bool _hogarSinHijos(String? respuesta) =>
      respuesta == 'Vivo sola/solo' ||
      respuesta == 'Convivo con mi pareja' ||
      respuesta == 'Vivo con otros familiares (no hijos/as)';

  Widget _preguntaIdentidadGeneroWidget({required bool isLegacy}) {
    final opciones = [
      'Mujer',
      'Varón',
      'Mujer Trans',
      'Varón Trans',
      'No binario',
      'Prefiero no decirlo',
      'Otro/a',
    ];

    final bool esOtro =
        q2IdentidadGenero != null &&
        !opciones.sublist(0, opciones.length - 1).contains(q2IdentidadGenero);
    final String? valorRadio = esOtro ? 'Otro/a' : q2IdentidadGenero;

    if (esOtro && _otroGeneroController.text != q2IdentidadGenero) {
      _otroGeneroController.text = q2IdentidadGenero!;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRadioQuestion(
          isLegacy
              ? '2. De acuerdo a la identidad de genero, se considera...'
              : '2. De acuerdo a la identidad de género, se considera...',
          opciones,
          valorRadio,
          (respuesta) {
            setState(() {
              if (respuesta == 'Otro/a') {
                _otroGeneroController.clear();
                q2IdentidadGenero = '';
              } else {
                q2IdentidadGenero = respuesta;
                if (!isLegacy && _preguntaActual < _totalPreguntas - 1) {
                  _preguntaActual++;
                }
              }
            });
          },
        ),
        if (valorRadio == 'Otro/a') ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _otroGeneroController,
              decoration: const InputDecoration(
                labelText: 'Especifique su identidad de género',
                hintText: 'Escriba aquí...',
                border: OutlineInputBorder(),
              ),
              onChanged: (text) {
                setState(() {
                  q2IdentidadGenero = text.trim();
                });
              },
            ),
          ),
          if (!isLegacy) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (q2IdentidadGenero == null ||
                        q2IdentidadGenero!.trim().isEmpty)
                    ? null
                    : _siguientePregunta,
                child: const Text('CONTINUAR'),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _preguntaDiscapacidadWidget({required bool isLegacy}) {
    final opciones3_1 = [
      'No, no requiero ninguna adaptacion o asistencia.',
      'Si, adaptaciones o asistencia para movilidad.',
      'Si, adaptaciones o asistencia sensorial (auditiva, visual, etc).',
      'Si, adaptaciones o asistencia cognitiva o intelectual.',
      'Si, adaptaciones o asistencia emocional o mental.',
      'Otra',
    ];

    final bool esOtra =
        q3_1DiscapacidadAdaptacion != null &&
        q3_1DiscapacidadAdaptacion !=
            'No, no requiero ninguna adaptacion o asistencia.' &&
        q3_1DiscapacidadAdaptacion !=
            'Si, adaptaciones o asistencia para movilidad.' &&
        q3_1DiscapacidadAdaptacion !=
            'Si, adaptaciones o asistencia sensorial (auditiva, visual, etc).' &&
        q3_1DiscapacidadAdaptacion !=
            'Si, adaptaciones o asistencia cognitiva o intelectual.' &&
        q3_1DiscapacidadAdaptacion !=
            'Si, adaptaciones o asistencia emocional o mental.';

    final String? valorRadio3_1 = esOtra ? 'Otra' : q3_1DiscapacidadAdaptacion;

    if (esOtra &&
        _otraAdaptacionController.text != q3_1DiscapacidadAdaptacion) {
      _otraAdaptacionController.text = q3_1DiscapacidadAdaptacion!;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRadioQuestion(
          isLegacy
              ? '3. Posee algun tipo de discapacidad?'
              : '3. ¿Posee algún tipo de discapacidad?',
          isLegacy ? ['Si', 'No'] : ['Sí', 'No'],
          q3Discapacidad,
          (respuesta) {
            setState(() {
              q3Discapacidad = respuesta;
              if (respuesta == 'No' || respuesta == 'No') {
                q3_1DiscapacidadAdaptacion = null;
                _otraAdaptacionController.clear();
                if (!isLegacy && _preguntaActual < _totalPreguntas - 1) {
                  _preguntaActual++;
                }
              }
            });
          },
        ),
        if (q3Discapacidad == 'Sí' || q3Discapacidad == 'Si') ...[
          const Divider(),
          _buildRadioQuestion(
            '3.1 Requiere alguna adaptacion o asistencia debido a una condicion de salud o discapacidad?',
            opciones3_1,
            valorRadio3_1,
            (respuesta) {
              setState(() {
                if (respuesta == 'Otra') {
                  _otraAdaptacionController.clear();
                  q3_1DiscapacidadAdaptacion = '';
                } else {
                  q3_1DiscapacidadAdaptacion = respuesta;
                  if (!isLegacy && _preguntaActual < _totalPreguntas - 1) {
                    _preguntaActual++;
                  }
                }
              });
            },
          ),
          if (valorRadio3_1 == 'Otra') ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _otraAdaptacionController,
                decoration: const InputDecoration(
                  labelText: 'Otra adaptacion o asistencia',
                  hintText: 'Escriba aquí...',
                  border: OutlineInputBorder(),
                ),
                onChanged: (text) {
                  setState(() {
                    q3_1DiscapacidadAdaptacion = text.trim();
                  });
                },
              ),
            ),
            if (!isLegacy) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (q3_1DiscapacidadAdaptacion == null ||
                          q3_1DiscapacidadAdaptacion!.trim().isEmpty)
                      ? null
                      : _siguientePregunta,
                  child: const Text('CONTINUAR'),
                ),
              ),
            ],
          ],
        ],
      ],
    );
  }

  Widget _preguntaEstadoCivilWidget({required bool isLegacy}) {
    final opciones = [
      'Soltero/a',
      'Casado/a',
      'Unión de hecho',
      'Separado/a',
      'Divorciado/a',
      'Viudo/a',
    ];

    final bool esCasado = q6EstadoCivil == 'Casado/a';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRadioQuestion(
          isLegacy
              ? '6. Cual es su estado civil?'
              : '6. ¿Cuál es su estado civil?',
          opciones,
          q6EstadoCivil,
          (respuesta) {
            setState(() {
              q6EstadoCivil = respuesta;
              if (respuesta != 'Casado/a') {
                _dniConyugeController.clear();
                _nombreConyugeController.clear();
                if (!isLegacy && _preguntaActual < _totalPreguntas - 1) {
                  _preguntaActual++;
                }
              }
            });
          },
        ),
        if (esCasado) ...[
          const SizedBox(height: 12),
          const Text(
            '6.1 Datos del cónyuge',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF284b72),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dniConyugeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'DNI del cónyuge',
              prefixIcon: Icon(Icons.badge),
              border: OutlineInputBorder(),
            ),
            onChanged: (val) {
              setState(() {});
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nombreConyugeController,
            decoration: const InputDecoration(
              labelText: 'Nombre y apellido del cónyuge',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            onChanged: (val) {
              setState(() {});
            },
          ),
          if (!isLegacy) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (_dniConyugeController.text.trim().isEmpty ||
                        _nombreConyugeController.text.trim().isEmpty)
                    ? null
                    : _siguientePregunta,
                child: const Text('CONTINUAR'),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _preguntaIngresosWidget({required bool isLegacy}) {
    final opciones = [
      'Yo',
      'El progenitor/a de mis hijos',
      'Alguno de mis hijos',
      'Un familiar mío',
      'Un familiar del progenitor/a de mis hijos',
      'Mi pareja',
      'No sabe / no contesta',
      'Otro',
    ];

    final opcionesLegacy = [
      'Yo',
      'El progenitor/a de mis hijos',
      'Alguno de mis hijos',
      'Un familiar mio',
      'Un familiar del progenitor/a de mis hijos',
      'Mi pareja',
      'No sabe / no contesta',
      'Otro',
    ];

    final List<String> opcionesLista = isLegacy ? opcionesLegacy : opciones;

    final bool esOtro =
        q8Ingresos != null &&
        !opcionesLista
            .sublist(0, opcionesLista.length - 1)
            .contains(q8Ingresos);
    final String? valorRadio = esOtro ? 'Otro' : q8Ingresos;

    if (esOtro && _otroIngresosController.text != q8Ingresos) {
      _otroIngresosController.text = q8Ingresos!;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRadioQuestion(
          isLegacy
              ? '8. Quien aporta mayores ingresos en el hogar?'
              : '8. ¿Quién aporta mayores ingresos en el hogar?',
          opcionesLista,
          valorRadio,
          (respuesta) {
            setState(() {
              if (respuesta == 'Otro') {
                _otroIngresosController.clear();
                q8Ingresos = '';
              } else {
                q8Ingresos = respuesta;
                if (!isLegacy && _preguntaActual < _totalPreguntas - 1) {
                  _preguntaActual++;
                }
              }
            });
          },
        ),
        if (valorRadio == 'Otro') ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _otroIngresosController,
              decoration: const InputDecoration(
                labelText: 'Especifique quién aporta mayores ingresos',
                hintText: 'Escriba aquí...',
                border: OutlineInputBorder(),
              ),
              onChanged: (text) {
                setState(() {
                  q8Ingresos = text.trim();
                });
              },
            ),
          ),
          if (!isLegacy) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (q8Ingresos == null || q8Ingresos!.trim().isEmpty)
                    ? null
                    : _siguientePregunta,
                child: const Text('CONTINUAR'),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _preguntaViviendaWidget({required bool isLegacy}) {
    final opciones = [
      'Propia',
      'Propia con hipoteca',
      'Alquilada',
      'Prestada',
      'Familiar',
      'La propiedad del padre/progenitor o madre/progenitor',
      'No sabe / no contesta',
      'Otro',
    ];

    final bool esOtro =
        q9Vivienda != null &&
        !opciones.sublist(0, opciones.length - 1).contains(q9Vivienda);
    final String? valorRadio = esOtro ? 'Otro' : q9Vivienda;

    if (esOtro && _otroViviendaController.text != q9Vivienda) {
      _otroViviendaController.text = q9Vivienda!;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRadioQuestion(
          isLegacy
              ? '9. Cual es su situación de vivienda actual?'
              : '9. ¿Cuál es su situación de vivienda actual?',
          opciones,
          valorRadio,
          (respuesta) {
            setState(() {
              if (respuesta == 'Otro') {
                _otroViviendaController.clear();
                q9Vivienda = '';
              } else {
                q9Vivienda = respuesta;
                if (!isLegacy && _preguntaActual < _totalPreguntas - 1) {
                  _preguntaActual++;
                }
              }
            });
          },
        ),
        if (valorRadio == 'Otro') ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _otroViviendaController,
              decoration: const InputDecoration(
                labelText: 'Especifique su situación de vivienda',
                hintText: 'Escriba aquí...',
                border: OutlineInputBorder(),
              ),
              onChanged: (text) {
                setState(() {
                  q9Vivienda = text.trim();
                });
              },
            ),
          ),
          if (!isLegacy) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (q9Vivienda == null || q9Vivienda!.trim().isEmpty)
                    ? null
                    : _siguientePregunta,
                child: const Text('CONTINUAR'),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _preguntaCuidadoWidget({required bool isLegacy}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRadioQuestion(
          isLegacy
              ? '10. Tiene a cargo el cuidado de otros familiares? (No incluye hijos)'
              : '10. ¿Tiene a cargo el cuidado de otros familiares? (No incluye hijos)',
          isLegacy ? ['Si', 'No'] : ['Sí', 'No'],
          q10Cuidado,
          (respuesta) {
            setState(() {
              q10Cuidado = respuesta;
              if (respuesta == 'No' || respuesta == 'No') {
                q10_1CuidadoDiscapacidad = null;
                if (!isLegacy && _preguntaActual < _totalPreguntas - 1) {
                  _preguntaActual++;
                }
              }
            });
          },
        ),
        if (q10Cuidado == 'Sí' || q10Cuidado == 'Si') ...[
          const Divider(),
          _buildRadioQuestion(
            isLegacy
                ? '10.1 La persona a su cargo tiene discapacidad o una limitacion permanente?'
                : '10.1 ¿La persona a su cargo tiene discapacidad o una limitación permanente?',
            isLegacy ? ['Si', 'No'] : ['Sí', 'No'],
            q10_1CuidadoDiscapacidad,
            (respuesta) {
              setState(() {
                q10_1CuidadoDiscapacidad = respuesta;
                if (!isLegacy && _preguntaActual < _totalPreguntas - 1) {
                  _preguntaActual++;
                }
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _preguntaVacacionesWidget({required bool isLegacy}) {
    final List<String> opcionesEstandar = [
      'Descanso en el hogar',
      'Viajes o turismo',
      'Actividades recreativas o deportivas',
      'Actividades familiares o sociales',
      'Estudios o capacitación',
      'Actividades laborales adicionales',
    ];

    final String customVal = q11Vacaciones.firstWhere(
      (e) => !opcionesEstandar.contains(e),
      orElse: () => '',
    );

    if (customVal.isNotEmpty && !_otroVacacionesChecked) {
      _otroVacacionesChecked = true;
      if (_otroVacacionesController.text != customVal) {
        _otroVacacionesController.text = customVal;
      }
    }

    final bool esValido =
        q11Vacaciones.isNotEmpty &&
        (!_otroVacacionesChecked ||
            _otroVacacionesController.text.trim().isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCheckboxQuestion(
          '11. Durante sus vacaciones o licencia ordinaria, ¿qué actividades realiza habitualmente?\nPuede marcar varias opciones.',
          [...opcionesEstandar, 'Otro'],
          [
            ...q11Vacaciones.where((e) => opcionesEstandar.contains(e)),
            if (_otroVacacionesChecked) 'Otro',
          ],
          (actividad, marcada) {
            setState(() {
              if (actividad == 'Otro') {
                _otroVacacionesChecked = marcada == true;
                if (!_otroVacacionesChecked) {
                  _otroVacacionesController.clear();
                  q11Vacaciones.removeWhere(
                    (e) => !opcionesEstandar.contains(e),
                  );
                } else if (_otroVacacionesController.text.trim().isNotEmpty) {
                  q11Vacaciones.add(_otroVacacionesController.text.trim());
                }
              } else {
                if (marcada == true) {
                  q11Vacaciones.add(actividad);
                } else {
                  q11Vacaciones.remove(actividad);
                }
              }
            });
          },
        ),
        if (_otroVacacionesChecked) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _otroVacacionesController,
              decoration: const InputDecoration(
                labelText: 'Especifique otra actividad',
                hintText: 'Escriba aquí...',
                border: OutlineInputBorder(),
              ),
              onChanged: (text) {
                setState(() {
                  q11Vacaciones.removeWhere(
                    (e) => !opcionesEstandar.contains(e),
                  );
                  if (text.trim().isNotEmpty) {
                    q11Vacaciones.add(text.trim());
                  }
                });
              },
            ),
          ),
        ],
        if (!isLegacy) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: esValido ? _siguientePregunta : null,
              child: const Text('CONTINUAR'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _radioPaso(
    String pregunta,
    List<String> opciones,
    String? valor,
    void Function(String) guardar,
  ) {
    return _buildRadioQuestion(pregunta, opciones, valor, (respuesta) {
      setState(() {
        guardar(respuesta);
        if (_preguntaActual < _totalPreguntas - 1) _preguntaActual++;
      });
    });
  }

  Widget _preguntaObservaciones() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '13. Observaciones adicionales',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF284b72),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _observacionesController,
        maxLines: 5,
        decoration: const InputDecoration(
          hintText: 'Ingrese sus observaciones',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _enviarFormulario,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF658ebc),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'GUARDAR FORMULARIO',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ],
  );

  void _siguientePregunta() => setState(() => _preguntaActual++);

  void _preguntaAnterior() {
    setState(() {
      _preguntaActual = _preguntaActual == 10 && _hogarSinHijos(q7Hogar)
          ? 6
          : _preguntaActual - 1;
    });
  }

  Widget _buildPreguntasFormLegacy() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cuestionario',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF284b72),
              ),
            ),
            const SizedBox(height: 16),

            // Genero
            const Text(
              'Genero',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF284b72),
              ),
            ),
            _buildRadioQuestion(
              '1. Cual es el sexo según figura en el DNI?',
              ['Femenino', 'Masculino', 'X'],
              q1SexoDni,
              (v) => setState(() => q1SexoDni = v),
            ),
            _preguntaIdentidadGeneroWidget(isLegacy: true),
            const Divider(),

            // Discapacidad
            const Text(
              'Discapacidad',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF284b72),
              ),
            ),
            _preguntaDiscapacidadWidget(isLegacy: true),
            const Divider(),

            // Estudios
            const Text(
              'Estudios',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF284b72),
              ),
            ),
            _buildRadioQuestion(
              '4. Cual es su nivel de estudios alcanzado?',
              [
                'Primario Incompleto',
                'Primario Completo',
                'Secundario Incompleto',
                'Secundario Completo',
                'Terciario Incompleto',
                'Terciario Completo',
                'Universitario Incompleto',
                'Universitario Completo',
                'Sin Estudios',
              ],
              q4Estudios,
              (v) => setState(() => q4Estudios = v),
            ),
            const Divider(),

            // IOMA
            const Text(
              'IOMA',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF284b72),
              ),
            ),
            _buildRadioQuestion(
              '5. Sabe que siendo empleado municipal puede usar IOMA?',
              ['Si', 'No'],
              q5IOMA,
              (v) => setState(() => q5IOMA = v),
            ),
            const Divider(),

            // Estado Civil
            const Text(
              'Estado Civil',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF284b72),
              ),
            ),
            _preguntaEstadoCivilWidget(isLegacy: true),
            const Divider(),

            // Hogar
            const Text(
              'Hogar',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF284b72),
              ),
            ),
            _buildRadioQuestion(
              '7. Como esta conformado su hogar?',
              [
                'Vivo sola/solo',
                'Convivo con mi pareja',
                'Vivo sola/solo con mis hijos',
                'Vivo con pareja e hijos',
                'Vivo con pareja, hijos y otros familiares',
                'Vivo con otros familiares (no hijos/as)',
              ],
              q7Hogar,
              (v) => setState(() => q7Hogar = v),
            ),
            if (!_hogarSinHijos(q7Hogar)) ...[
              _buildRadioQuestion(
                '7.1 Cuantas hijas o hijos menores de edad tiene?',
                ['1 hija/o', '2 hijas/os', '3 hijas/os', 'Mas de tres hijos'],
                q7_1HijosMenores,
                (v) => setState(() => q7_1HijosMenores = v),
              ),
              _buildRadioQuestion(
                '7.2 Alguno de sus hijos o hijas posee algun tipo de discapacidad?',
                ['Si', 'No'],
                q7_2HijosDiscapacidad,
                (v) => setState(() => q7_2HijosDiscapacidad = v),
              ),
              _buildRadioQuestion(
                '7.3 Sus hijos menores de edad a cargo se encuentran escolarizados?',
                ['Si', 'No'],
                q7_3HijosEscolarizados,
                (v) => setState(() => q7_3HijosEscolarizados = v),
              ),
            ],
            _preguntaIngresosWidget(isLegacy: true),
            _preguntaViviendaWidget(isLegacy: true),
            const Divider(),

            // Familiares a cargo
            const Text(
              'Familiares a cargo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF284b72),
              ),
            ),
            _preguntaCuidadoWidget(isLegacy: true),
            const Divider(),

            // Uso del tiempo
            const Text(
              'Uso del tiempo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF284b72),
              ),
            ),
            _preguntaVacacionesWidget(isLegacy: true),
            _buildRadioQuestion(
              '12. Al finalizar sus vacaciones o licencia, considera que logro recuperarse fisica y mentalmente del trabajo?',
              ['Totalmente', 'En gran medida', 'Moderadamente', 'Poco', 'Nada'],
              q12Recuperacion,
              (v) => setState(() => q12Recuperacion = v),
            ),
            const Divider(),

            // Observaciones
            const Text(
              'Observaciones',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF284b72),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '13. Observaciones adicionales',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF284b72),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _observacionesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Ingrese sus observaciones',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enviarFormulario,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF658ebc,
                  ), // Matching the button color in the screenshot
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: const Text(
                  'GUARDAR FORMULARIO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioQuestion(
    String question,
    List<String> options,
    String? groupValue,
    Function(String) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF284b72),
            ),
          ),
          const SizedBox(height: 8),
          ...options
              .map(
                (opt) => RadioListTile<String>(
                  title: Text(opt),
                  value: opt,
                  groupValue: groupValue,
                  onChanged: (val) {
                    if (val != null) onChanged(val);
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF40A5DD),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _buildCheckboxQuestion(
    String question,
    List<String> options,
    List<String> groupValues,
    Function(String, bool?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF284b72),
            ),
          ),
          const SizedBox(height: 8),
          ...options
              .map(
                (opt) => CheckboxListTile(
                  title: Text(opt),
                  value: groupValues.contains(opt),
                  onChanged: (val) => onChanged(opt, val),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: const Color(0xFF40A5DD),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Future<void> _enviarFormulario() async {
    Map<String, dynamic> payload = {
      "legajo": _legajoController.text,
      "celular_prefijo": _prefijoController.text,
      "celular_numero": _celularController.text,
      "fk_localidad": selectedLocalidad ?? '',
      "fk_calle": selectedCalle ?? '',
      "numero_calle": _numeroCalleController.text,
      "fk_secretaria": datosPersonales?['secretaria']?.toString() ?? '',
      "lugar_trabajo": _nombreLugarTrabajo(datosPersonales, const [
        'nombre_dependencia',
        'dependencia_nombre',
        'nombre_lugar_trabajo',
        'lugar_trabajo',
        'dependencia',
      ], _dependenciasPorCodigo),
      "fk_genero_nacer": q1SexoDni,
      "fk_genero_identidad": q2IdentidadGenero,
      "genero_identidad_otro": _otroGeneroController.text,
      "tiene_discapacidad": q3Discapacidad,
      "fk_requiere_adaptacion": q3_1DiscapacidadAdaptacion,
      "adaptacion_detalle": _otraAdaptacionController.text,
      "fk_nivel_educacional": q4Estudios,
      "fk_estado_civil": q6EstadoCivil,
      "conoce_ioma": q5IOMA,
      "fk_conformacion_hogar": q7Hogar,
      "fk_situacion_habitacional": null,
      "conyuge_dni": q6EstadoCivil == 'Casado/a'
          ? _dniConyugeController.text
          : null,
      "conyuge_apellido_nombre": q6EstadoCivil == 'Casado/a'
          ? _nombreConyugeController.text
          : null,
      "fk_cantidad_hijos_menores": q7_1HijosMenores,
      "hijos_con_discapacidad": q7_2HijosDiscapacidad,
      "hijos_escolarizados": q7_3HijosEscolarizados,
      "fk_participacion_progenitor_cuidado": null,
      "fk_situacion_cuota_alimentaria": null,
      "fk_definicion_cuota_alimentaria": null,
      "fk_mayor_aporte_ingresos_hogar": q8Ingresos,
      "mayor_aporte_ingresos_hogar_otro": _otroIngresosController.text,
      "fk_situacion_vivienda_actual": q9Vivienda,
      "situacion_vivienda_otro": _otroViviendaController.text,
      "cuida_otros_familiares": q10Cuidado,
      "familiar_a_cargo_discapacidad": q10_1CuidadoDiscapacidad,
      "fk_recuperacion_post_licencia": q12Recuperacion,
      "vac_otro": _otroVacacionesController.text,
      "observaciones": _observacionesController.text,
      "actividades_vacaciones_habituales": q11Vacaciones,
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    bool success = await guardarRelevamiento(context, payload, _imageFile);
    Navigator.of(context).pop(); // Ocultar loader

    if (success) {
      await _mostrarGuardadoExitoso();
      if (!mounted) return;
      _limpiarDatos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error al guardar el formulario',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _mostrarGuardadoExitoso() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 34,
                backgroundColor: Color(0xFFE0F2E4),
                child: Icon(Icons.check, size: 46, color: Colors.green),
              ),
              const SizedBox(height: 20),
              const Text(
                'Información guardada con éxito',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF284B72),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF658EBC),
                  ),
                  child: const Text(
                    'ACEPTAR',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
