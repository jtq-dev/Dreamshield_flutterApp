import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/home.dart';
import 'screens/sessions.dart';
import 'screens/studio.dart';
import 'screens/explore_map.dart';
import 'screens/profile.dart';
import 'package:flutter/foundation.dart';



void main() async {print('Firebase project: ${DefaultFirebaseOptions.currentPlatform.projectId}');

WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
  runApp(const ProviderScope(child: DreamShieldApp()));
}

class DreamShieldApp extends StatefulWidget {
  const DreamShieldApp({super.key});

  @override
  State<DreamShieldApp> createState() => _DreamShieldAppState();
}

class _DreamShieldAppState extends State<DreamShieldApp> {
  int _index = 0;
  final _screens = const [
    HomeScreen(),
    SessionsScreen(),
    StudioScreen(),
    ExploreMapScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DreamShield Studio',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: Scaffold(
        body: _screens[_index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.today_outlined),
                selectedIcon: Icon(Icons.today),
                label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.list_alt_outlined),
                selectedIcon: Icon(Icons.list_alt),
                label: 'Sessions'),
            NavigationDestination(
                icon: Icon(Icons.graphic_eq_outlined),
                selectedIcon: Icon(Icons.graphic_eq),
                label: 'Studio'),
            NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'Explore'),
            NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
