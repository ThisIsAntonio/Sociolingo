import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  final String
      userEmail; // Suponiendo que pasas el email como identificador del usuario

  const MainScreen({Key? key, required this.userEmail}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Índice de la pestaña actual

  // Lista de widgets para cada pestaña
  List<Widget> _widgetOptions = <Widget>[
    Text(
        'User Information'), // Aquí iría el widget real de información del usuario
    Text('Friend Suggestions'),
    Text('Friend Requests'),
    Text('Chat'),
    Text('Settings'), // Aquí podrías incluir la opción de cerrar sesión
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Main Screen'),
      ),
      body: Center(
        // Muestra el widget correspondiente a la pestaña activa
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Suggestions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mail),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
