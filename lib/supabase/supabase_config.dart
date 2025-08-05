import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://azqdywochojufjswqxqx.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF6cWR5d29jaG9qdWZqc3dxeHF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM1MzkxMjIsImV4cCI6MjA2OTExNTEyMn0.i7F1BlIB640ch_-9SMagVwGxyhRQFJkAa6CIz39E-ng';
  
  static SupabaseClient get client => Supabase.instance.client;
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: anonKey,
    );
  }
  
  // Authentication helpers
  static Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }
  
  static Future<AuthResponse> signUpWithEmail(String email, String password) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }
  
  static Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      throw _handleAuthError(e);
    }
  }
  
  static Future<void> resetPassword(String email) async {
    try {
      await client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }
  
  static User? get currentUser => client.auth.currentUser;
  
  static bool get isAuthenticated => currentUser != null;
  
  static Stream<AuthState> get authStateStream => client.auth.onAuthStateChange;
  
  // Database helpers
  static SupabaseQueryBuilder from(String table) => client.from(table);
  
  // Error handling
  static Exception _handleAuthError(dynamic error) {
    if (error is AuthException) {
      switch (error.message) {
        case 'Invalid login credentials':
          return Exception('Email ou mot de passe incorrect');
        case 'Email not confirmed':
          return Exception('Veuillez confirmer votre email');
        case 'User already registered':
          return Exception('Un compte existe déjà avec cet email');
        case 'Signup not allowed for this instance':
          return Exception('L\'inscription n\'est pas autorisée');
        default:
          return Exception('Erreur d\'authentification: ${error.message}');
      }
    } else if (error is PostgrestException) {
      return Exception('Erreur de base de données: ${error.message}');
    } else {
      return Exception('Erreur réseau. Vérifiez votre connexion.');
    }
  }
}