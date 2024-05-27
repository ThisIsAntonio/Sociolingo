import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/screens/login_screen.dart'; // Asegúrate de que esta ruta sea correcta

void main() {
  testWidgets('Login Screen Test', (WidgetTester tester) async {
    // Construye la aplicación y dispara un frame.
    await tester.pumpWidget(MaterialApp(home: LoginScreen()));

    // Realiza aquí tus verificaciones y acciones de prueba.
    // Por ejemplo, puedes buscar botones o campos de texto y simular interacciones.

    // Verifica si ciertos widgets están presentes en la pantalla.
    // Como ejemplo, verifica la presencia de un campo de texto para el email.
    expect(find.byType(TextFormField), findsWidgets);

    // Aquí puedes agregar más verificaciones o interacciones,
    // como enviar toques en botones o ingresar texto en campos de texto.
  });

  //this doesnt work for me
  
}
