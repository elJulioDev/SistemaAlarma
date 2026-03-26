import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

// 1. Esta función DEBE estar fuera de cualquier clase. 
// Se encarga de escuchar cuando la app está cerrada o en segundo plano.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Aseguramos que Firebase esté inicializado en este "hilo" aislado
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  print("🚨 ¡EMERGENCIA RECIBIDA EN SEGUNDO PLANO!");
  print("Datos: ${message.data}");
  // Aquí es donde pondremos el código para hacer sonar la alarma ruidosa
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Le decimos a Firebase qué función ejecutar cuando llegue un mensaje en segundo plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const AlarmaApp());
}

class AlarmaApp extends StatelessWidget {
  const AlarmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sistema de Alarma',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const PantallaPrincipal(),
    );
  }
}

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  String _tokenDispositivo = "Obteniendo token...";

  @override
  void initState() {
    super.initState();
    _configurarNotificaciones();
  }

  Future<void> _configurarNotificaciones() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 3. Pedimos permiso al usuario (muy importante en iOS y Android 13+)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Permisos de notificación concedidos.');
      
      // 4. Obtenemos el "Token" de este celular. 
      // Esta es la "dirección" única a la que el panel web enviará la alarma.
      String? token = await messaging.getToken();
      setState(() {
        _tokenDispositivo = token ?? "No se pudo obtener el token";
      });
      print("Token del dispositivo: $_tokenDispositivo");

      // 5. Escuchamos los mensajes si la app está abierta en pantalla
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("🚨 ¡EMERGENCIA RECIBIDA CON LA APP ABIERTA!");
        print("Datos: ${message.data}");
        
        // Mostrar un aviso en pantalla
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ALERTA: ${message.data['emergencia'] ?? 'Emergencia recibida'}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispositivo Activo', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.security, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'Sistema esperando alertas...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            const Text(
              'Tu Token de identificación (Cópialo en la terminal para pruebas):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SelectableText(
              _tokenDispositivo,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}