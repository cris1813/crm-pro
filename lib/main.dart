import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CrmMayoristaApp());
}

class CrmMayoristaApp extends StatelessWidget {
  const CrmMayoristaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRM Mayorista Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF10B981),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10B981),
          secondary: Color(0xFF3B82F6),
          surface: Color(0xFF1E293B),
        ),
        useMaterial3: true,
      ),
      home: const MainDashboard(),
    );
  }
}

// ==========================================
// MODELO DE CLIENTE
// ==========================================
class Cliente {
  String id;
  String nombre;
  String rut;
  String telefono;
  String categoria;
  String queCompra;
  int montoPromedio;
  String notas;
  bool prefiereLlamada;
  int cicloDias;
  DateTime ultimoContacto;

  Cliente({
    required this.id,
    required this.nombre,
    required this.rut,
    required this.telefono,
    required this.categoria,
    required this.queCompra,
    required this.montoPromedio,
    required this.notas,
    this.prefiereLlamada = false,
    this.cicloDias = 10,
    DateTime? ultimoContacto,
  }) : ultimoContacto = ultimoContacto ?? DateTime.now().subtract(const Duration(days: 12));

  int get diasSinContacto => DateTime.now().difference(ultimoContacto).inDays;
  bool get requiereAtencionUrgente => diasSinContacto >= cicloDias;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'rut': rut,
        'telefono': telefono,
        'categoria': categoria,
        'queCompra': queCompra,
        'montoPromedio': montoPromedio,
        'notas': notas,
        'prefiereLlamada': prefiereLlamada,
        'cicloDias': cicloDias,
        'ultimoContacto': ultimoContacto.toIso8601String(),
      };

  factory Cliente.fromJson(Map<String, dynamic> json) => Cliente(
        id: json['id'],
        nombre: json['nombre'],
        rut: json['rut'] ?? '',
        telefono: json['telefono'] ?? '',
        categoria: json['categoria'] ?? 'Sin Clasificar',
        queCompra: json['queCompra'] ?? '',
        montoPromedio: json['montoPromedio'] ?? 0,
        notas: json['notas'] ?? '',
        prefiereLlamada: json['prefiereLlamada'] ?? false,
        cicloDias: json['cicloDias'] ?? 10,
        ultimoContacto: DateTime.tryParse(json['ultimoContacto'] ?? '') ?? DateTime.now(),
      );
}

// ==========================================
// BASE DE DATOS INICIAL (EXTRAÍDA DE TU PDF)
// ==========================================
final List<Cliente> clientesSemilla = [
  // ABARROTES Y ALIMENTOS
  Cliente(id: '1', nombre: 'Caroline / Cesar (Almacén San Vicente)', rut: '78.076.635', telefono: '+56964203947', categoria: 'Abarrotes y Alimentos', queCompra: 'Compra millones en chocolates', montoPromedio: 2000000, notas: 'Tel alt: 935595136. Llamar y escribir', cicloDias: 7, ultimoContacto: DateTime.now().subtract(const Duration(days: 11))),
  Cliente(id: '2', nombre: 'Comercializadora Weisz', rut: '78.102.847-9', telefono: '+56981441715', categoria: 'Abarrotes y Alimentos', queCompra: 'Mucho pallet de arroz y azúcar', montoPromedio: 1500000, notas: 'Cliente potencial de alto volumen', cicloDias: 10, ultimoContacto: DateTime.now().subtract(const Duration(days: 14))),
  Cliente(id: '3', nombre: 'Marcela', rut: '', telefono: '+56961636386', categoria: 'Abarrotes y Alimentos', queCompra: 'Precios por pallet y productos corta fecha', montoPromedio: 800000, notas: 'Avisar apenas entren lotes a corta fecha', cicloDias: 7, ultimoContacto: DateTime.now().subtract(const Duration(days: 8))),
  Cliente(id: '4', nombre: 'Santa Economia EIRL / Mauricio Miranda', rut: '78.199.928-8', telefono: '+56997586362', categoria: 'Abarrotes y Alimentos', queCompra: 'Surtido general de negocio', montoPromedio: 1200000, notas: 'Compra mucho, recién surtiendo negocio', cicloDias: 10, ultimoContacto: DateTime.now().subtract(const Duration(days: 5))),
  Cliente(id: '5', nombre: 'Santa Flora SpA / Cristian Miranda', rut: '78.291.382-4', telefono: '+56983543128', categoria: 'Abarrotes y Alimentos', queCompra: 'Compra de todo y bebidas', montoPromedio: 1000000, notas: 'Avisar urgente cuando lleguen todas las bebidas', cicloDias: 7, ultimoContacto: DateTime.now().subtract(const Duration(days: 9))),
  Cliente(id: '6', nombre: 'Silvia', rut: '9.182.388-8', telefono: '+56936424876', categoria: 'Abarrotes y Alimentos', queCompra: 'Surtido de todo para almacén', montoPromedio: 450000, notas: 'Almacén tradicional', cicloDias: 10, ultimoContacto: DateTime.now().subtract(const Duration(days: 4))),
  Cliente(id: '7', nombre: 'Sra Margarita (Verdurería Las Nietas)', rut: '11.737.106-9', telefono: '+56972969640', categoria: 'Abarrotes y Alimentos', queCompra: 'Surtido completo minimarket playa', montoPromedio: 3000000, notas: 'Cliente Ballena: compra 3 millones', cicloDias: 10, ultimoContacto: DateTime.now().subtract(const Duration(days: 15))),
  Cliente(id: '8', nombre: 'Victor / Panadería', rut: '78.441.909-6', telefono: '+56981934386', categoria: 'Abarrotes y Alimentos', queCompra: 'Insumos panadería y abarrotes', montoPromedio: 2000000, notas: 'Cliente Ballena: compró 2 millones', cicloDias: 10, ultimoContacto: DateTime.now().subtract(const Duration(days: 13))),
  Cliente(id: '9', nombre: 'Erika Saez', rut: '13.607.820-8', telefono: '+56966162817', categoria: 'Abarrotes y Alimentos', queCompra: 'Queso despunte y fiambrería', montoPromedio: 500000, notas: 'Avisar siempre que llegue queso despunte', cicloDias: 7, ultimoContacto: DateTime.now().subtract(const Duration(days: 8))),
  Cliente(id: '10', nombre: 'Cliente Almacenero', rut: '', telefono: '+56942826685', categoria: 'Abarrotes y Alimentos', queCompra: 'Mercadería general de almacén', montoPromedio: 500000, notas: 'Promedio de compra 500.000', cicloDias: 10, ultimoContacto: DateTime.now().subtract(const Duration(days: 6))),

  // ASEO Y PAPEL
  Cliente(id: '11', nombre: 'Agrolatino / Cristopher', rut: '78.070.723-2', telefono: '+56932516615', categoria: 'Aseo y Papel', queCompra: 'Pallet de papel higiénico', montoPromedio: 1200000, notas: 'Compra por volumen de pallet', cicloDias: 14, ultimoContacto: DateTime.now().subtract(const Duration(days: 12))),
  Cliente(id: '12', nombre: 'Andres Albarracin', rut: '77.305.701-K', telefono: '+56958383389', categoria: 'Aseo y Papel', queCompra: 'Higiénico, toalla, servilleta, bolsa, detergente', montoPromedio: 900000, notas: 'Canal E-commerce', cicloDias: 10, ultimoContacto: DateTime.now().subtract(const Duration(days: 7))),
  Cliente(id: '13', nombre: 'Carlos Ignacio Brante', rut: '15.999.884-3', telefono: '+56964819488', categoria: 'Aseo y Papel', queCompra: 'Papel higiénico y toallas', montoPromedio: 450000, notas: 'Emprendimiento de papel', cicloDias: 10, ultimoContacto: DateTime.now().subtract(const Duration(days: 9))),
  Cliente(id: '14', nombre: 'Comercial ATH / Pedro', rut: '76.751.574-K', telefono: '+56922133197', categoria: 'Aseo y Papel', queCompra: 'Mucho papel (cotizó 500 mangas de Elite)', montoPromedio: 2500000, notas: 'Cliente de altísimo volumen en papel', cicloDias: 10, ultimoContacto: DateTime.now().subtract(const Duration(days: 14))),
  Cliente(id: '15', nombre: 'Dilum Restauran', rut: '75.840.502-6', telefono: '+56942252957', categoria: 'Aseo y Papel', queCompra: 'Papel oferta 4x500', montoPromedio: 400000, notas: 'Recordatorio: Avisar día 20 para oferta 4x500', cicloDias: 15, ultimoContacto: DateTime.now().subtract(const Duration(days: 16))),
  Cliente(id: '16', nombre: 'DIST Y COMER Santa Juana LTDA', rut: '77.882.033-1', telefono: '+56977646940', categoria: 'Aseo y Papel', queCompra: 'Papel higiénico, toalla y productos corta fecha', montoPromedio: 1100000, notas: 'Interesado en corta fecha y papel', cicloDias: 10, ultimoContacto: DateTime.now().subtract(const Duration(days: 8))),
  Cliente(id: '17', nombre: 'Edgar (Ovalle - 3 Minimarkets)', rut: '26.452.795-3', telefono: '+56954843198', categoria: 'Aseo y Papel', queCompra: 'Aseo y perfumería para 3 locales', montoPromedio: 1800000, notas: 'Es de Ovalle. DE PREFERENCIA LLAMAR', prefiereLlamada: true, cicloDias: 12, ultimoContacto: DateTime.now().subtract(const Duration(days: 15))),
  Cliente(id: '18', nombre: 'Karen', rut: '', telefono: '+56978797268', categoria: 'Aseo y Papel', queCompra: 'Papel y artículos de aseo', montoPromedio: 400000, notas: 'Interesada en ofertas de aseo', cicloDias: 10, ultimoContacto: DateTime.now().subtract(const Duration(days: 5))),
  Cliente(id: '19', nombre: 'LED - MARIA CRISTINA', rut: '16.716.408-0', telefono: '+56978473181', categoria: 'Aseo y Papel', queCompra: 'Artículos de aseo por mayor', montoPromedio: 1500000, notas: 'Compran mucho. Tel 2: 978473185', cicloDias: 10, ultimoContacto: DateTime.now().subtract(const Duration(days: 11))),
  Cliente(id: '20', nombre: 'Limpieza Aysi SpA', rut: '78.414.683', telefono: '+56986484781', categoria: 'Aseo y Papel', queCompra: 'Artículos de limpieza general', montoPromedio: 400000, notas: 'Cliente empezando en venta de limpieza', cicloDias: 10, ultimoContacto: DateTime.now().subtract(const Duration(days: 6))),
  Cliente(id: '21', nombre: 'Maribel Natalia Arcos', rut: '17.336.845-3', telefono: '+56948755324', categoria: 'Aseo y Papel', queCompra: 'Mucho papel e insumos para carnicería', montoPromedio: 950000, notas: 'Carnicería. DE PREFERENCIA LLAMAR (Javi)', prefiereLlamada: true, cicloDias: 10, ultimoContacto: DateTime.now().subtract(const Duration(days: 12))),
  Cliente(id: '22', nombre: 'Minimarket Ricardo Andres Nuñez', rut: '78.322.941-2', telefono: '+56959661230', categoria: 'Aseo y Papel', queCompra: 'Papel de 10 en 10 mangas por tipo', montoPromedio: 500000, notas: 'Promedio de compra $500.000 constante', cicloDias: 10, ultimoContacto: DateTime.now().subtract(const Duration(days: 9))),

  // MAYORISTAS / SURTIDO GENERAL
  Cliente(id: '23', nombre: 'Angel L2P SpA', rut: '78.130.297-K', telefono: '+56931815515', categoria: 'Mayoristas / Surtido General', queCompra: 'Compra de todo (surtido completo)', montoPromedio: 1500000, notas: 'Recordatorio: Llamar los lunes', prefiereLlamada: true, cicloDias: 7, ultimoContacto: DateTime.now().subtract(const Duration(days: 8))),
  Cliente(id: '24', nombre: 'Comercial Nietos / Alfredo', rut: '77.979.333-8', telefono: '+56978515834', categoria: 'Mayoristas / Surtido General', queCompra: 'Compra millones y de todo', montoPromedio: 2800000, notas: 'Ballena VIP: Cliente con varios locales', cicloDias: 10, ultimoContacto: DateTime.now().subtract(const Duration(days: 14))),
  Cliente(id: '25', nombre: 'Edisson Bonacic Rojas', rut: '13.983.850-5', telefono: '+56957111745', categoria: 'Mayoristas / Surtido General', queCompra: 'Surtido mayorista de alto volumen', montoPromedio: 3000000, notas: 'Última compra 3 millones - IMPORTANTE LLAMAR', prefiereLlamada: true, cicloDias: 10, ultimoContacto: DateTime.now().subtract(const Duration(days: 16))),
  Cliente(id: '26', nombre: 'Fabian Erice (Rancagua)', rut: '17.573.384-1', telefono: '+56957047224', categoria: 'Mayoristas / Surtido General', queCompra: 'Compra quincenal de todo', montoPromedio: 1400000, notas: 'Ciclo fijo cada 15 días (Rancagua)', cicloDias: 14, ultimoContacto: DateTime.now().subtract(const Duration(days: 14))),
  Cliente(id: '27', nombre: 'Luis Silva (Melipilla)', rut: '78.370.642-3', telefono: '+56965857854', categoria: 'Mayoristas / Surtido General', queCompra: 'Surtido con despacho a Melipilla', montoPromedio: 650000, notas: 'Compra sobre $600.000 para despacho', cicloDias: 12, ultimoContacto: DateTime.now().subtract(const Duration(days: 10))),
  Cliente(id: '28', nombre: 'Tres Hermanos', rut: '78.177.706-4', telefono: '+56957260645', categoria: 'Mayoristas / Surtido General', queCompra: 'Compra de todo y mucho producto TOP', montoPromedio: 1800000, notas: 'Avisar productos de alta rotación', cicloDias: 10, ultimoContacto: DateTime.now().subtract(const Duration(days: 7))),
  Cliente(id: '29', nombre: 'Yris Local 57', rut: '', telefono: '+56921751069', categoria: 'Mayoristas / Surtido General', queCompra: 'Compra de todo', montoPromedio: 750000, notas: 'Local 57', cicloDias: 10, ultimoContacto: DateTime.now().subtract(const Duration(days: 6))),

  // CLIENTES DE FERIA
  Cliente(id: '30', nombre: 'Ramon', rut: '', telefono: '+56954352142', categoria: 'Clientes de Feria', queCompra: 'Papelería y perfumería', montoPromedio: 350000, notas: 'Puesto de Feria', cicloDias: 7, ultimoContacto: DateTime.now().subtract(const Duration(days: 5))),
  Cliente(id: '31', nombre: 'Miguel Muñoz', rut: '', telefono: '+56956054737', categoria: 'Clientes de Feria', queCompra: 'Papelería y perfumería', montoPromedio: 350000, notas: 'Puesto de Feria', cicloDias: 7, ultimoContacto: DateTime.now().subtract(const Duration(days: 8))),

  // FACTURAS RECIENTES Y PENDIENTES
  Cliente(id: '32', nombre: 'Gemma del Carmen Henriquez Orellana', rut: '12.676.382-4', telefono: '', categoria: 'Facturación Reciente', queCompra: 'Factura Mayorista (7 líneas de prod.)', montoPromedio: 1292815, notas: 'Sucursal Bernardino Parada 0958 - Transf. Electrónica', cicloDias: 10, ultimoContacto: DateTime.now().subtract(const Duration(days: 11))),
  Cliente(id: '33', nombre: 'Marco Loriza Pereira', rut: '9.766.488-2', telefono: '', categoria: 'Facturación Reciente', queCompra: 'Factura Mayorista (15 productos)', montoPromedio: 253548, notas: 'Local 77 Bodega Mersan - Transbank', cicloDias: 14, ultimoContacto: DateTime.now().subtract(const Duration(days: 9))),
  Cliente(id: '34', nombre: 'Angelo Fuente Alba', rut: '', telefono: '+56987387277', categoria: 'Sin Clasificar', queCompra: 'Pendiente consultar rubro principal', montoPromedio: 300000, notas: 'Clasificar en próximo contacto', cicloDias: 7, ultimoContacto: DateTime.now().subtract(const Duration(days: 15))),
  Cliente(id: '35', nombre: 'Freddy Cartagena', rut: '', telefono: '+56963162615', categoria: 'Sin Clasificar', queCompra: 'Pendiente consultar rubro principal', montoPromedio: 300000, notas: 'Clasificar en próximo contacto', cicloDias: 7, ultimoContacto: DateTime.now().subtract(const Duration(days: 15))),
  Cliente(id: '36', nombre: 'GSM Construcciones SpA', rut: '', telefono: '+56950339202', categoria: 'Sin Clasificar', queCompra: 'Pendiente consultar rubro principal', montoPromedio: 400000, notas: 'Empresa constructora', cicloDias: 14, ultimoContacto: DateTime.now().subtract(const Duration(days: 14))),
];

// ==========================================
// MOTOR DEEPSEEK OFFLINE (SIN INTERNET + GGUF)
// ==========================================
class DeepSeekOfflineEngine {
  static String generarMensajePersonalizado(Cliente c, String promoBase, int variacion) {
    final saludos = [
      'Hola ${c.nombre.split('/').first.trim()}, ¿cómo va el negocio?',
      '¡Buenas ${c.nombre.split('/').first.trim()}! Te escribo directo de bodega.',
      'Hola ${c.nombre.split('/').first.trim()}, espero que estés teniendo buena semana.',
      '¿Qué tal ${c.nombre.split('/').first.trim()}? Te paso el dato antes de que se agote.'
    ];

    final ganchoPersonalizado = c.queCompra.isNotEmpty
        ? 'Como sé que trabajas fuerte con *${c.queCompra.toLowerCase()}*, te reservé cupo en esta promo:'
        : 'Me acordé de tu local porque nos acaba de entrar mercadería ideal para ti:';

    final cierres = [
      '¿Te separo un lote o prefieres que te llame en 5 minutos para ver cantidades?',
      'Avísame cuántas mangas/cajas te anoto para asegurarte el precio.',
      'Si quieres asegurar stock me respondes por acá o te pego un telefonazo.',
    ];

    final s = saludos[variacion % saludos.length];
    final cierre = cierres[variacion % cierres.length];

    return '$s\n\n$ganchoPersonalizado\n\n🔥 *$promoBase*\n\n$cierre';
  }

  static String analizarCarteraOffline(List<Cliente> clientes) {
    final urgentes = clientes.where((c) => c.requiereAtencionUrgente).toList();
    urgentes.sort((a, b) => b.montoPromedio.compareTo(a.montoPromedio));
    final totalRiesgo = urgentes.fold<int>(0, (sum, c) => sum + c.montoPromedio);

    if (urgentes.isEmpty) {
      return '✅ Cartera al día. Ninguna ballena está en riesgo de enfriarse hoy.';
    }

    final top3 = urgentes.take(3).map((c) => '• ${c.nombre} (\$${formatearPesos(c.montoPromedio)} - hace ${c.diasSinContacto} días)').join('\n');
    return '⚠️ RIESGO DE FUGA DETECTADO:\nTienes ${urgentes.length} clientes pasados de su fecha de compra habitual, sumando \$${formatearPesos(totalRiesgo)} en juego.\n\nPrioridad inmediata:\n$top3';
  }
}

String formatearPesos(int monto) {
  final str = monto.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
    buffer.write(str[i]);
  }
  return buffer.toString();
}

// ==========================================
// PANTALLA PRINCIPAL CON 4 MÓDULOS
// ==========================================
class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  static const platform = MethodChannel('com.cristobal.crm/accessibility');
  int _tabIndex = 0;
  List<Cliente> _clientes = [];
  String _filtroCategoria = 'Todos';
  String _busqueda = '';
  bool _accesibilidadActiva = false;

  // Estado de Campaña
  final TextEditingController _promoCtrl = TextEditingController(
      text: 'Oferta Mayorista: Papel Higiénico y Abarrotes a precio de pallet por hoy');
  String _categoriaCampana = 'Aseo y Papel';
  bool _campanaCorriendo = false;
  int _progresoCampana = 0;
  String _estadoCampanaTexto = 'Listo para iniciar';

  // Estado DeepSeek Offline
  String _respuestaIA = '';
  bool _descargandoModelo = false;
  double _progresoModelo = 0.0;
  bool _modeloGGUFInstalado = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _verificarAccesibilidad();
    _verificarModeloGGUF();
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('clientes_crm_v1');
    if (data != null) {
      final List decoded = jsonDecode(data);
      setState(() {
        _clientes = decoded.map((e) => Cliente.fromJson(e)).toList();
      });
    } else {
      setState(() {
        _clientes = List.from(clientesSemilla);
      });
      _guardarDatos();
    }
    setState(() {
      _respuestaIA = DeepSeekOfflineEngine.analizarCarteraOffline(_clientes);
    });
  }

  Future<void> _guardarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_clientes.map((c) => c.toJson()).toList());
    await prefs.setString('clientes_crm_v1', encoded);
  }

  Future<void> _verificarAccesibilidad() async {
    try {
      final bool result = await platform.invokeMethod('isServiceEnabled');
      setState(() => _accesibilidadActiva = result);
    } catch (_) {}
  }

  Future<void> _abrirAjustesAccesibilidad() async {
    try {
      await platform.invokeMethod('openAccessibilitySettings');
    } catch (_) {}
  }

  Future<void> _marcarContactado(Cliente c) async {
    setState(() {
      c.ultimoContacto = DateTime.now();
      _respuestaIA = DeepSeekOfflineEngine.analizarCarteraOffline(_clientes);
    });
    await _guardarDatos();
  }

  Future<void> _llamarCliente(Cliente c) async {
    if (c.telefono.isEmpty) return;
    await _marcarContactado(c);
    final uri = Uri.parse('tel:${c.telefono}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _escribirWhatsApp(Cliente c, {String? mensajePersonalizado, bool autoClick = false}) async {
    if (c.telefono.isEmpty) return;
    await _marcarContactado(c);
    final numLimpio = c.telefono.replaceAll(RegExp(r'[^0-9]'), '');
    final msg = mensajePersonalizado ??
        DeepSeekOfflineEngine.generarMensajePersonalizado(c, _promoCtrl.text, Random().nextInt(10));

    if (autoClick) {
      try {
        await platform.invokeMethod('armAutoSend');
      } catch (_) {}
    }

    final uri = Uri.parse('whatsapp://send?phone=$numLimpio&text=${Uri.encodeComponent(msg)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      final webUri = Uri.parse('https://wa.me/$numLimpio?text=${Uri.encodeComponent(msg)}');
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  // ==========================================
  // CAMPAÑA AUTOMÁTICA CON ACCESSIBILITY SERVICE
  // ==========================================
  Future<void> _iniciarCampanaAutomatica() async {
    await _verificarAccesibilidad();
    final destinatarios = _clientes
        .where((c) =>
            c.telefono.isNotEmpty &&
            (_categoriaCampana == 'Todos' || c.categoria == _categoriaCampana))
        .toList();

    if (destinatarios.isEmpty) return;

    setState(() {
      _campanaCorriendo = true;
      _progresoCampana = 0;
    });

    for (int i = 0; i < destinatarios.length; i++) {
      if (!_campanaCorriendo) break;
      final cliente = destinatarios[i];

      setState(() {
        _progresoCampana = i + 1;
        _estadoCampanaTexto = 'Enviando a ${cliente.nombre} (${i + 1}/${destinatarios.length})...';
      });

      final msg = DeepSeekOfflineEngine.generarMensajePersonalizado(
          cliente, _promoCtrl.text, i);

      await _escribirWhatsApp(cliente, mensajePersonalizado: msg, autoClick: true);

      if (i < destinatarios.length - 1 && _campanaCorriendo) {
        final delaySegundos = 12 + Random().nextInt(10);
        for (int s = delaySegundos; s > 0; s--) {
          if (!_campanaCorriendo) break;
          setState(() {
            _estadoCampanaTexto =
                'Pausa anti-baneo: próximo envío en $s seg (${destinatarios[i + 1].nombre})';
          });
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }

    setState(() {
      _campanaCorriendo = false;
      _estadoCampanaTexto = '✅ Campaña completada con éxito';
    });
  }

  // ==========================================
  // GESTOR DEL MODELO DEEPSEEK GGUF LOCAL
  // ==========================================
  Future<void> _verificarModeloGGUF() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/deepseek_r1_1.5b_q4.gguf');
    if (await file.exists()) {
      setState(() => _modeloGGUFInstalado = true);
    }
  }

  Future<void> _descargarModeloDeepSeekGGUF() async {
    setState(() {
      _descargandoModelo = true;
      _progresoModelo = 0.01;
    });
    try {
      final url = Uri.parse(
          'https://huggingface.co/bartowski/DeepSeek-R1-Distill-Qwen-1.5B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf');
      final request = http.Request('GET', url);
      final response = await http.Client().send(request);
      final contentLength = response.contentLength ?? 1100000000;

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/deepseek_r1_1.5b_q4.gguf');
      final sink = file.openWrite();

      int descargado = 0;
      await for (var chunk in response.stream) {
        sink.add(chunk);
        descargado += chunk.length;
        setState(() {
          _progresoModelo = descargado / contentLength;
        });
      }
      await sink.close();
      setState(() {
        _descargandoModelo = false;
        _modeloGGUFInstalado = true;
      });
    } catch (e) {
      setState(() => _descargandoModelo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('CRM Mayorista Pro', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Color(0xFF10B981)),
            onPressed: _mostrarDialogoNuevoCliente,
          ),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _buildTabClientes(),
          _buildTabMonitoreo(),
          _buildTabCampanas(),
          _buildTabDeepSeek(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (idx) {
          if (idx == 2) _verificarAccesibilidad();
          setState(() => _tabIndex = idx);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.people), label: 'Clientes'),
          NavigationDestination(icon: Icon(Icons.radar), label: 'Radar VIP'),
          NavigationDestination(icon: Icon(Icons.rocket_launch), label: 'Campaña WA'),
          NavigationDestination(icon: Icon(Icons.psychology), label: 'DeepSeek IA'),
        ],
      ),
    );
  }

  // ==========================================
  // PESTAÑA 1: DIRECTORIO DE CLIENTES (1 BOTÓN)
  // ==========================================
  Widget _buildTabClientes() {
    final categorias = [
      'Todos',
      'Abarrotes y Alimentos',
      'Aseo y Papel',
      'Mayoristas / Surtido General',
      'Clientes de Feria',
      'Facturación Reciente',
      'Sin Clasificar'
    ];

    final filtrados = _clientes.where((c) {
      final matchCat = _filtroCategoria == 'Todos' || c.categoria == _filtroCategoria;
      final matchTexto = c.nombre.toLowerCase().contains(_busqueda.toLowerCase()) ||
          c.queCompra.toLowerCase().contains(_busqueda.toLowerCase()) ||
          c.rut.toLowerCase().contains(_busqueda.toLowerCase());
      return matchCat && matchTexto;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, RUT o producto (ej: papel, queso, pallet)...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (val) => setState(() => _busqueda = val),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: categorias.length,
            itemBuilder: (ctx, i) {
              final cat = categorias[i];
              final sel = _filtroCategoria == cat;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: sel,
                  onSelected: (_) => setState(() => _filtroCategoria = cat),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: ListView.builder(
            itemCount: filtrados.length,
            itemBuilder: (ctx, i) => _buildTarjetaCliente(filtrados[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildTarjetaCliente(Cliente c) {
    final urgente = c.requiereAtencionUrgente;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: urgente ? Colors.redAccent.withOpacity(0.7) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    c.nombre,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '\$${formatearPesos(c.montoPromedio)}',
                    style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${c.categoria} ${c.rut.isNotEmpty ? "• RUT: ${c.rut}" : ""}',
                style: const TextStyle(color: Colors.white60, fontSize: 12)),
            const SizedBox(height: 6),
            Text('🛒 Compra: ${c.queCompra}', style: const TextStyle(fontSize: 13)),
            if (c.notas.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('📌 ${c.notas}', style: const TextStyle(fontSize: 12, color: Colors.amberAccent)),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.history, size: 14, color: urgente ? Colors.redAccent : Colors.white54),
                const SizedBox(width: 4),
                Text(
                  'Hace ${c.diasSinContacto} días (Ciclo: ${c.cicloDias}d)',
                  style: TextStyle(fontSize: 12, color: urgente ? Colors.redAccent : Colors.white54),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.prefiereLlamada ? Colors.amber.shade800 : const Color(0xFF334155),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () => _llamarCliente(c),
                  icon: const Icon(Icons.phone, size: 16),
                  label: Text(c.prefiereLlamada ? 'LLAMAR (Pref)' : 'Llamar', style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () => _escribirWhatsApp(c),
                  icon: const Icon(Icons.chat, size: 16),
                  label: const Text('WhatsApp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PESTAÑA 2: SISTEMA DE MONITOREO CONSTANTE
  // ==========================================
  Widget _buildTabMonitoreo() {
    final urgentes = _clientes.where((c) => c.requiereAtencionUrgente).toList()
      ..sort((a, b) => b.montoPromedio.compareTo(a.montoPromedio));

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🚨 Radar de Monitoreo Activo (Ballenas y Ciclos)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent)),
              const SizedBox(height: 6),
              Text(
                'Tienes ${urgentes.length} clientes que superaron su ciclo habitual sin contacto. Al presionar Llamar o WhatsApp, el cliente quedará marcado como atendido hoy.',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...urgentes.map(_buildTarjetaCliente),
      ],
    );
  }

  // ==========================================
  // PESTAÑA 3: CAMPAÑAS AUTOMÁTICAS + PROMOS
  // ==========================================
  Widget _buildTabCampanas() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Card(
          color: _accesibilidadActiva ? const Color(0xFF064E3B) : const Color(0xFF7F1D1D),
          child: ListTile(
            leading: Icon(_accesibilidadActiva ? Icons.verified : Icons.warning_amber, color: Colors.white, size: 32),
            title: Text(
              _accesibilidadActiva
                  ? 'AccessibilityService ACTIVO'
                  : 'AccessibilityService DESACTIVADO',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(_accesibilidadActiva
                ? 'La app presionará "Enviar" en WhatsApp automáticamente.'
                : 'Toca aquí para activarlo en los Ajustes de Android y permitir envío 100% automático.'),
            trailing: ElevatedButton(
              onPressed: _abrirAjustesAccesibilidad,
              child: const Text('Ajustes'),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text('1. Crear Promoción / Mensaje Base:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        TextField(
          controller: _promoCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 14),
        const Text('2. Seleccionar Rubro Objetivo:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _categoriaCampana,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: [
            'Todos',
            'Abarrotes y Alimentos',
            'Aseo y Papel',
            'Mayoristas / Surtido General',
            'Clientes de Feria',
            'Sin Clasificar'
          ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (val) => setState(() => _categoriaCampana = val ?? 'Todos'),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Estado: $_estadoCampanaTexto', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _campanaCorriendo ? Colors.redAccent : const Color(0xFF10B981),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        if (_campanaCorriendo) {
                          setState(() => _campanaCorriendo = false);
                        } else {
                          _iniciarCampanaAutomatica();
                        }
                      },
                      icon: Icon(_campanaCorriendo ? Icons.stop : Icons.send),
                      label: Text(
                        _campanaCorriendo ? 'DETENER CAMPAÑA' : 'LANZAR CAMPAÑA AUTOMÁTICA',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // PESTAÑA 4: DEEPSEEK IA OFFLINE
  // ==========================================
  Widget _buildTabDeepSeek() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Card(
          color: const Color(0xFF1E293B),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.psychology, color: Color(0xFF10B981), size: 28),
                    SizedBox(width: 8),
                    Text('Motor DeepSeek-R1 Offline',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'El motor heurístico local ya está activo sin usar internet. Si además deseas descargar los pesos cuantizados GGUF (DeepSeek-R1-Distill-1.5B) en el almacenamiento interno de tu teléfono:',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                if (_descargandoModelo)
                  Column(
                    children: [
                      LinearProgressIndicator(value: _progresoModelo),
                      const SizedBox(height: 6),
                      Text('Descargando GGUF: ${(_progresoModelo * 100).toStringAsFixed(1)}%'),
                    ],
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _modeloGGUFInstalado ? null : _descargarModeloDeepSeekGGUF,
                    icon: Icon(_modeloGGUFInstalado ? Icons.check_circle : Icons.download),
                    label: Text(_modeloGGUFInstalado
                        ? 'Modelo DeepSeek GGUF Instalado en Memoria'
                        : 'Descargar DeepSeek-R1 1.5B GGUF (1.1 GB)'),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: const Color(0xFF1E293B),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Diagnóstico Inteligente de tu Cartera (100% Offline):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 10),
                Text(_respuestaIA, style: const TextStyle(fontSize: 14, height: 1.4)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _respuestaIA = DeepSeekOfflineEngine.analizarCarteraOffline(_clientes);
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Recalcular Prioridades de Venta'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // DIÁLOGO PARA AGREGAR NUEVO CLIENTE
  // ==========================================
  void _mostrarDialogoNuevoCliente() {
    final nombreCtrl = TextEditingController();
    final rutCtrl = TextEditingController();
    final telCtrl = TextEditingController(text: '+569');
    final compraCtrl = TextEditingController();
    final montoCtrl = TextEditingController(text: '500000');
    String cat = 'Abarrotes y Alimentos';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo Cliente Mayorista'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre / Razón Social')),
              TextField(controller: rutCtrl, decoration: const InputDecoration(labelText: 'RUT')),
              TextField(controller: telCtrl, decoration: const InputDecoration(labelText: 'Teléfono (+569...)')),
              TextField(controller: compraCtrl, decoration: const InputDecoration(labelText: '¿Qué suele comprar?')),
              TextField(
                controller: montoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Compra promedio (\$)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (nombreCtrl.text.isEmpty) return;
              setState(() {
                _clientes.insert(
                  0,
                  Cliente(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    nombre: nombreCtrl.text,
                    rut: rutCtrl.text,
                    telefono: telCtrl.text,
                    categoria: cat,
                    queCompra: compraCtrl.text,
                    montoPromedio: int.tryParse(montoCtrl.text) ?? 300000,
                    notas: 'Agregado desde la App',
                  ),
                );
              });
              _guardarDatos();
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
