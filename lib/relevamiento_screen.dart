import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:relevamientomunicipal/servicios/guardado.dart';

class RelevamientoScreen extends StatefulWidget {
  const RelevamientoScreen({Key? key}) : super(key: key);

  @override
  _RelevamientoScreenState createState() => _RelevamientoScreenState();
}

class _RelevamientoScreenState extends State<RelevamientoScreen> {
  final TextEditingController _legajoController = TextEditingController();
  final TextEditingController _prefijoController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();
  final TextEditingController _numeroCalleController = TextEditingController();

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
  List<String> q11Vacaciones = [];
  String? q12Recuperacion;
  final TextEditingController _observacionesController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    localidades = await fetchLocalidades();
    calles = await fetchCalles();
    setState(() {});
  }

  Future<void> _buscarDatos() async {
    if (_legajoController.text.isEmpty) return;
    
    // Mostramos un indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    var datos = await buscarDatosLegajo(context, _legajoController.text);
    
    Navigator.of(context).pop(); // Ocultar carga

    if (datos != null && datos.isNotEmpty) {
      setState(() {
        datosPersonales = datos;
        
        // Asignamos datos a los controladores (ajustar las keys según el JSON real)
        _prefijoController.text = datos['prefijo']?.toString() ?? '';
        _celularController.text = datos['celular']?.toString() ?? '';
        _numeroCalleController.text = datos['numero_calle']?.toString() ?? '';
        
        String? locId = datos['id_localidad']?.toString() ?? datos['localidad']?.toString();
        if (localidades.any((e) => (e['id']?.toString() ?? e.toString()) == locId)) {
          selectedLocalidad = locId;
        } else {
          selectedLocalidad = null;
        }

        String? calleId = datos['id_calle']?.toString() ?? datos['calle']?.toString();
        if (calles.any((e) => (e['id']?.toString() ?? e.toString()) == calleId)) {
          selectedCalle = calleId;
        } else {
          selectedCalle = null;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontraron datos para ese legajo')),
      );
    }
  }

  void _limpiarDatos() {
    setState(() {
      _legajoController.clear();
      datosPersonales = null;
      _prefijoController.clear();
      _celularController.clear();
      _numeroCalleController.clear();
      selectedLocalidad = null;
      selectedCalle = null;
      _imageFile = null;

      q1SexoDni = null;
      q2IdentidadGenero = null;
      q3Discapacidad = null;
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
      q11Vacaciones.clear();
      q12Recuperacion = null;
      _observacionesController.clear();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relevamiento Municipal'),
        backgroundColor: const Color(0xFF40A5DD),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildIniciarRelevamientoCard(),
            const SizedBox(height: 16),
            if (datosPersonales != null) _buildDatosPersonalesCard(),
            const SizedBox(height: 16),
            if (datosPersonales != null) _buildLugarTrabajoCard(),
            const SizedBox(height: 16),
            if (datosPersonales != null) _buildPreguntasForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildIniciarRelevamientoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Iniciar relevamiento',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF284b72),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _legajoController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Numero de legajo',
                      prefixIcon: const Icon(Icons.badge, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _buscarDatos,
                  icon: const Icon(Icons.search, color: Colors.white),
                  label: const Text('BUSCAR DATOS', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFa4b9d6),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Datos personales',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF284b72),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _limpiarDatos,
                  icon: const Icon(Icons.refresh, color: Colors.red),
                  label: const Text('LIMPIAR', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildReadOnlyField('Numero de legajo', datosPersonales?['legajo']?.toString() ?? datosPersonales?['nro_legajo']?.toString() ?? '', Icons.badge),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildReadOnlyField('Nombre y apellido', datosPersonales?['nombre_completo']?.toString() ?? datosPersonales?['apellido_nombre']?.toString() ?? '', Icons.person_outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildReadOnlyField('DNI', datosPersonales?['dni']?.toString() ?? datosPersonales?['nro_documento']?.toString() ?? '', Icons.badge_outlined),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildReadOnlyField('Fecha de nacimiento', datosPersonales?['fecha_nacimiento']?.toString() ?? '', Icons.calendar_today),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: _prefijoController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Prefijo',
                                prefixIcon: Icon(Icons.phone, color: Colors.grey),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _celularController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Numero de celular',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Localidad',
                                prefixIcon: Icon(Icons.location_on, color: Colors.grey),
                                border: OutlineInputBorder(),
                              ),
                              value: selectedLocalidad,
                              isExpanded: true,
                              items: localidades.map((item) {
                                return DropdownMenuItem<String>(
                                  value: item['id']?.toString() ?? item.toString(),
                                  child: Text(item['nombre']?.toString() ?? item.toString()),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  selectedLocalidad = val;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Calle',
                                prefixIcon: Icon(Icons.add_road, color: Colors.grey),
                                border: OutlineInputBorder(),
                              ),
                              value: selectedCalle,
                              isExpanded: true,
                              items: calles.map((item) {
                                return DropdownMenuItem<String>(
                                  value: item['id']?.toString() ?? item.toString(),
                                  child: Text(item['nombre']?.toString() ?? item.toString()),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  selectedCalle = val;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _numeroCalleController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Numero',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4F8),
                          border: Border.all(color: const Color(0xFFB0C4DE), style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(_imageFile!, fit: BoxFit.cover),
                              )
                            : const Icon(Icons.person, size: 100, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _tomarFoto,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('TOMAR FOTO'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF284b72),
                            side: const BorderSide(color: Color(0xFF284b72)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
      child: Text(value.isEmpty ? '-' : value, style: const TextStyle(fontSize: 16, color: Colors.black)),
    );
  }

  Widget _buildLugarTrabajoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lugar de trabajo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF284b72),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildReadOnlyField(
                    'Secretaria',
                    datosPersonales?['secretaria']?.toString() ?? '',
                    Icons.business,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildReadOnlyField(
                    'Nombre del lugar de trabajo',
                    datosPersonales?['lugar_trabajo']?.toString() ?? '',
                    Icons.work,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreguntasForm() {
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
            const Text('Genero', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF284b72))),
            _buildRadioQuestion('1. Cual es el sexo según figura en el DNI?', ['Femenino', 'Masculino', 'X'], q1SexoDni, (v) => setState(() => q1SexoDni = v)),
            _buildRadioQuestion('2. De acuerdo a la identidad de genero, se considera...', ['Mujer', 'Varón', 'Mujer Trans', 'Varón Trans', 'No binario', 'Prefiero no decirlo', 'Otro/a'], q2IdentidadGenero, (v) => setState(() => q2IdentidadGenero = v)),
            const Divider(),

            // Discapacidad
            const Text('Discapacidad', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF284b72))),
            _buildRadioQuestion('3. Posee algun tipo de discapacidad?', ['Si', 'No'], q3Discapacidad, (v) => setState(() => q3Discapacidad = v)),
            const Divider(),

            // Estudios
            const Text('Estudios', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF284b72))),
            _buildRadioQuestion('4. Cual es su nivel de estudios alcanzado?', ['Primario Incompleto', 'Primario Completo', 'Secundario Incompleto', 'Secundario Completo', 'Terciario Incompleto', 'Terciario Completo', 'Universitario Incompleto', 'Universitario Completo', 'Sin Estudios'], q4Estudios, (v) => setState(() => q4Estudios = v)),
            const Divider(),

            // IOMA
            const Text('IOMA', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF284b72))),
            _buildRadioQuestion('5. Sabe que siendo empleado municipal puede usar IOMA?', ['Si', 'No'], q5IOMA, (v) => setState(() => q5IOMA = v)),
            const Divider(),

            // Estado Civil
            const Text('Estado Civil', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF284b72))),
            _buildRadioQuestion('6. Cual es su estado civil?', ['Soltero/a', 'Casado/a', 'Unión de hecho', 'Separado/a', 'Divorciado/a', 'Viudo/a'], q6EstadoCivil, (v) => setState(() => q6EstadoCivil = v)),
            const Divider(),

            // Hogar
            const Text('Hogar', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF284b72))),
            _buildRadioQuestion('7. Como esta conformado su hogar?', ['Vivo sola/solo', 'Convivo con mi pareja', 'Vivo sola/solo con mis hijos', 'Vivo con pareja e hijos', 'Vivo con pareja, hijos y otros familiares', 'Vivo con otros familiares (no hijos/as)'], q7Hogar, (v) => setState(() => q7Hogar = v)),
            _buildRadioQuestion('7.1 Cuantas hijas o hijos menores de edad tiene?', ['1 hija/o', '2 hijas/os', '3 hijas/os', 'Mas de tres hijos'], q7_1HijosMenores, (v) => setState(() => q7_1HijosMenores = v)),
            _buildRadioQuestion('7.2 Alguno de sus hijos o hijas posee algun tipo de discapacidad?', ['Si', 'No'], q7_2HijosDiscapacidad, (v) => setState(() => q7_2HijosDiscapacidad = v)),
            _buildRadioQuestion('7.3 Sus hijos menores de edad a cargo se encuentran escolarizados?', ['Si', 'No'], q7_3HijosEscolarizados, (v) => setState(() => q7_3HijosEscolarizados = v)),
            _buildRadioQuestion('8. Quien aporta mayores ingresos en el hogar?', ['Yo', 'El progenitor/a de mis hijos', 'Alguno de mis hijos', 'Un familiar mio', 'Un familiar del progenitor/a de mis hijos', 'Mi pareja', 'No sabe / no contesta', 'Otro'], q8Ingresos, (v) => setState(() => q8Ingresos = v)),
            _buildRadioQuestion('9. Cual es su situacion de vivienda actual?', ['Propia', 'Propia con hipoteca', 'Alquilada', 'Prestada', 'Familiar', 'La propiedad del padre/progenitor o madre/progenit', 'No sabe / no contesta', 'Otro'], q9Vivienda, (v) => setState(() => q9Vivienda = v)),
            const Divider(),

            // Familiares a cargo
            const Text('Familiares a cargo', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF284b72))),
            _buildRadioQuestion('10. Tiene a cargo el cuidado de otros familiares?', ['Si', 'No'], q10Cuidado, (v) => setState(() => q10Cuidado = v)),
            const Divider(),

            // Uso del tiempo
            const Text('Uso del tiempo', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF284b72))),
            _buildCheckboxQuestion('11. Durante sus vacaciones o licencia ordinaria, que actividades realiza habitualmente?\nPuede marcar varias opciones.', ['Descanso en el hogar', 'Viajes o turismo', 'Actividades recreativas o deportivas', 'Actividades familiares o sociales', 'Estudios o capacitacion', 'Actividades laborales adicionales', 'Otro'], q11Vacaciones, (v, checked) {
              setState(() {
                if (checked == true) {
                  q11Vacaciones.add(v);
                } else {
                  q11Vacaciones.remove(v);
                }
              });
            }),
            _buildRadioQuestion('12. Al finalizar sus vacaciones o licencia, considera que logro recuperarse fisica y mentalmente del trabajo?', ['Totalmente', 'En gran medida', 'Moderadamente', 'Poco', 'Nada'], q12Recuperacion, (v) => setState(() => q12Recuperacion = v)),
            const Divider(),

            // Observaciones
            const Text('Observaciones', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF284b72))),
            const SizedBox(height: 8),
            const Text('13. Observaciones adicionales', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF284b72))),
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
                  backgroundColor: const Color(0xFF658ebc), // Matching the button color in the screenshot
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                ),
                child: const Text('GUARDAR FORMULARIO', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioQuestion(String question, List<String> options, String? groupValue, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF284b72))),
          const SizedBox(height: 8),
          ...options.map((opt) => RadioListTile<String>(
            title: Text(opt),
            value: opt,
            groupValue: groupValue,
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
            dense: true,
            contentPadding: EdgeInsets.zero,
            activeColor: const Color(0xFF40A5DD),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildCheckboxQuestion(String question, List<String> options, List<String> groupValues, Function(String, bool?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF284b72))),
          const SizedBox(height: 8),
          ...options.map((opt) => CheckboxListTile(
            title: Text(opt),
            value: groupValues.contains(opt),
            onChanged: (val) => onChanged(opt, val),
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: const Color(0xFF40A5DD),
          )).toList(),
        ],
      ),
    );
  }

  Future<void> _enviarFormulario() async {
    Map<String, dynamic> payload = {
      "legajo": _legajoController.text,
      "prefijo": _prefijoController.text,
      "celular": _celularController.text,
      "id_localidad": selectedLocalidad,
      "id_calle": selectedCalle,
      "numero_calle": _numeroCalleController.text,
      "q1_sexo_dni": q1SexoDni,
      "q2_identidad_genero": q2IdentidadGenero,
      "q3_discapacidad": q3Discapacidad,
      "q4_estudios": q4Estudios,
      "q5_ioma": q5IOMA,
      "q6_estado_civil": q6EstadoCivil,
      "q7_hogar": q7Hogar,
      "q7_1_hijos_menores": q7_1HijosMenores,
      "q7_2_hijos_discapacidad": q7_2HijosDiscapacidad,
      "q7_3_hijos_escolarizados": q7_3HijosEscolarizados,
      "q8_ingresos": q8Ingresos,
      "q9_vivienda": q9Vivienda,
      "q10_cuidado": q10Cuidado,
      "q11_vacaciones": q11Vacaciones,
      "q12_recuperacion": q12Recuperacion,
      "q13_observaciones": _observacionesController.text,
    };
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    bool success = await guardarRelevamiento(context, payload, _imageFile);
    Navigator.of(context).pop(); // Ocultar loader
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Formulario guardado con éxito', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
      _limpiarDatos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar el formulario', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
    }
  }
}
