import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unified_calendar_app/providers/auth_provider.dart';
import 'package:unified_calendar_app/providers/calendar_provider.dart';
import 'package:unified_calendar_app/screens/login_screen.dart';
import 'package:unified_calendar_app/screens/home_screen.dart';
import 'package:unified_calendar_app/screens/signup_screen.dart';
import 'package:unified_calendar_app/screens/connect_calendar_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
            title: 'Unified Calendar App',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
                primarySwatch: Colors.deepPurple, // Main theme color
                primaryColor: Colors.deepPurple,
                colorScheme: ColorScheme.dark(
                  primary: Colors.deepPurple,
                  secondary: Colors.tealAccent,
                  surface: Colors.grey[850]!, // Card and other surface elements
                  background: Colors.grey[900]!, // General app background
                  error: Colors.redAccent,
                  onPrimary: Colors.white,
                  onSecondary: Colors.black,
                  onSurface: Colors.white,
                  onBackground: Colors.white,
                  onError: Colors.white,
                ),
                scaffoldBackgroundColor: Colors.grey[900], // Background for Scaffold
                appBarTheme: AppBarTheme(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  centerTitle: true,
                  elevation: 0,
                ),
                floatingActionButtonTheme: FloatingActionButtonThemeData(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.deepPurpleAccent, width: 2),
                  ),
                  labelStyle: TextStyle(color: Colors.white70),
                  hintStyle: TextStyle(color: Colors.white54),
                  prefixIconColor: Colors.white70,
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.tealAccent,
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
                cardTheme: CardTheme(
                  color: Colors.grey[850],
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  // Removed the problematic 'margin' parameter from here
                ),
                listTileTheme: ListTileThemeData(
                  iconColor: Colors.white70,
                  textColor: Colors.white,
                  // Removed the problematic 'tileColor' parameter from here
                ),
                dialogTheme: DialogTheme(
                  backgroundColor: Colors.grey[800],
                  titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  contentTextStyle: TextStyle(color: Colors.white70),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                snackBarTheme: SnackBarThemeData(
                  backgroundColor: Colors.deepPurple,
                  contentTextStyle: TextStyle(color: Colors.white),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  //margin: EdgeInsets.all(10),
                )
            ),
            home: authProvider.token == null ? const LoginScreen() : const HomeScreen(),
            routes: {
              '/signup': (context) => const SignupScreen(),
              '/connect-calendars': (context) => const ConnectCalendarScreen(),
            },
          );
        },
      ),
    );
  }
}
