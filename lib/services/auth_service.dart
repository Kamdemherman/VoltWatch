
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voltwatch/supabase/supabase_config.dart';
import 'package:voltwatch/models/user_model.dart';

class AuthService {
  static final SupabaseClient _client = SupabaseConfig.client;

  // Authentication methods
  static Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await SupabaseConfig.signInWithEmail(email, password);
  }

  static Future<AuthResponse> signUpWithEmail(String email, String password, {
    String? fullName,
    String? phone,
    String? eneoClientId,
    String? meterAddress,
  }) async {
    final response = await SupabaseConfig.signUpWithEmail(email, password);
    
    if (response.user != null) {
      // Create user profile after successful signup
      await _createUserProfile(
        userId: response.user!.id,
        email: email,
        fullName: fullName,
        phone: phone,
        eneoClientId: eneoClientId,
        meterAddress: meterAddress,
      );
    }
    
    return response;
  }

  static Future<void> signOut() async {
    return await SupabaseConfig.signOut();
  }

  static Future<void> resetPassword(String email) async {
    return await SupabaseConfig.resetPassword(email);
  }

  // User profile methods
  static Future<void> _createUserProfile({
    required String userId,
    required String email,
    String? fullName,
    String? phone,
    String? eneoClientId,
    String? meterAddress,
  }) async {
    try {
      await _client.from('users').insert({
        'id': userId,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'eneo_client_id': eneoClientId,
        'meter_address': meterAddress,
      });

      // Create default user preferences
      await _client.from('user_preferences').insert({
        'user_id': userId,
        'monthly_budget_fcfa': 100000.0,
        'consumption_alert_percentage': 20,
        'custom_threshold_fcfa': 50000.0,
        'enable_push_notifications': true,
        'enable_email_notifications': true,
        'enable_sms_notifications': false,
        'preferred_language': 'fr',
      });
    } catch (e) {
      throw Exception('Erreur lors de la création du profil: $e');
    }
  }

  static Future<UserModel?> getCurrentUserProfile() async {
    final user = SupabaseConfig.currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du profil: $e');
    }
  }

  static Future<UserModel> updateUserProfile({
    String? fullName,
    String? phone,
    String? eneoClientId,
    String? meterAddress,
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      final updateData = <String, dynamic>{};
      if (fullName != null) updateData['full_name'] = fullName;
      if (phone != null) updateData['phone'] = phone;
      if (eneoClientId != null) updateData['eneo_client_id'] = eneoClientId;
      if (meterAddress != null) updateData['meter_address'] = meterAddress;

      if (updateData.isNotEmpty) {
        updateData['updated_at'] = DateTime.now().toIso8601String();
      }

      final response = await _client
          .from('users')
          .update(updateData)
          .eq('id', user.id)
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du profil: $e');
    }
  }

  static Future<UserPreferences?> getUserPreferences() async {
    final user = SupabaseConfig.currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('user_preferences')
          .select()
          .eq('user_id', user.id)
          .single();

      return UserPreferences.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la récupération des préférences: $e');
    }
  }

  static Future<UserPreferences> updateUserPreferences({
    double? monthlyBudgetFcfa,
    int? consumptionAlertPercentage,
    double? customThresholdFcfa,
    bool? enablePushNotifications,
    bool? enableEmailNotifications,
    bool? enableSmsNotifications,
    String? preferredLanguage,
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      final updateData = <String, dynamic>{};
      if (monthlyBudgetFcfa != null) updateData['monthly_budget_fcfa'] = monthlyBudgetFcfa;
      if (consumptionAlertPercentage != null) updateData['consumption_alert_percentage'] = consumptionAlertPercentage;
      if (customThresholdFcfa != null) updateData['custom_threshold_fcfa'] = customThresholdFcfa;
      if (enablePushNotifications != null) updateData['enable_push_notifications'] = enablePushNotifications;
      if (enableEmailNotifications != null) updateData['enable_email_notifications'] = enableEmailNotifications;
      if (enableSmsNotifications != null) updateData['enable_sms_notifications'] = enableSmsNotifications;
      if (preferredLanguage != null) updateData['preferred_language'] = preferredLanguage;

      if (updateData.isNotEmpty) {
        updateData['updated_at'] = DateTime.now().toIso8601String();
      }

      final response = await _client
          .from('user_preferences')
          .update(updateData)
          .eq('user_id', user.id)
          .select()
          .single();

      return UserPreferences.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour des préférences: $e');
    }
  }

  // Auth state helpers
  static User? get currentUser => SupabaseConfig.currentUser;
  static bool get isAuthenticated => SupabaseConfig.isAuthenticated;
  static Stream<AuthState> get authStateStream => SupabaseConfig.authStateStream;

  // Utility methods
  static Future<bool> isEmailAvailable(String email) async {
    try {
      final response = await _client
          .from('users')
          .select('email')
          .eq('email', email)
          .maybeSingle();

      return response == null;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isEneoClientIdAvailable(String eneoClientId) async {
    try {
      final response = await _client
          .from('users')
          .select('eneo_client_id')
          .eq('eneo_client_id', eneoClientId)
          .maybeSingle();

      return response == null;
    } catch (e) {
      return false;
    }
  }

  static Future<void> deleteAccount() async {
    final user = SupabaseConfig.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      // Delete user profile (cascade will handle related data)
      await _client
          .from('users')
          .delete()
          .eq('id', user.id);

      // Sign out after deletion
      await signOut();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du compte: $e');
    }
  }
}