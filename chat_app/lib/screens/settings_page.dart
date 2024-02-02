import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('Settings'),
          ElevatedButton(
            onPressed: () {
              // Aquí podrías implementar la lógica para cerrar sesión,
              // como borrar datos de usuario guardados y navegar de vuelta a la pantalla de login.
              Navigator.pop(context);
            },
            child: Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
