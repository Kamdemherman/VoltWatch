import 'package:flutter/material.dart';
import 'package:voltwatch/services/auth_service.dart';
import 'package:voltwatch/models/user_model.dart';
import 'package:voltwatch/screens/auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  UserPreferences? _preferences;
  bool _isLoading = true;
  bool _isEditing = false;

  // Form controllers
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _eneoClientIdController = TextEditingController();
  final _meterAddressController = TextEditingController();
  final _monthlyBudgetController = TextEditingController();
  final _customThresholdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _eneoClientIdController.dispose();
    _meterAddressController.dispose();
    _monthlyBudgetController.dispose();
    _customThresholdController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);

      final results = await Future.wait([
        AuthService.getCurrentUserProfile(),
        AuthService.getUserPreferences(),
      ]);

      setState(() {
        _user = results[0] as UserModel?;
        _preferences = results[1] as UserPreferences?;
        
        // Populate form controllers
        _fullNameController.text = _user?.fullName ?? '';
        _phoneController.text = _user?.phone ?? '';
        _eneoClientIdController.text = _user?.eneoClientId ?? '';
        _meterAddressController.text = _user?.meterAddress ?? '';
        _monthlyBudgetController.text = _preferences?.monthlyBudgetFcfa?.toStringAsFixed(0) ?? '';
        _customThresholdController.text = _preferences?.customThresholdFcfa?.toStringAsFixed(0) ?? '';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateProfile() async {
    try {
      setState(() => _isLoading = true);

      // Update user profile
      await AuthService.updateUserProfile(
        fullName: _fullNameController.text.trim().isNotEmpty 
            ? _fullNameController.text.trim() 
            : null,
        phone: _phoneController.text.trim().isNotEmpty 
            ? _phoneController.text.trim() 
            : null,
        eneoClientId: _eneoClientIdController.text.trim().isNotEmpty 
            ? _eneoClientIdController.text.trim() 
            : null,
        meterAddress: _meterAddressController.text.trim().isNotEmpty 
            ? _meterAddressController.text.trim() 
            : null,
      );

      // Update preferences
      await AuthService.updateUserPreferences(
        monthlyBudgetFcfa: _monthlyBudgetController.text.trim().isNotEmpty
            ? double.tryParse(_monthlyBudgetController.text.trim())
            : null,
        customThresholdFcfa: _customThresholdController.text.trim().isNotEmpty
            ? double.tryParse(_customThresholdController.text.trim())
            : null,
      );

      setState(() => _isEditing = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      _loadUserData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AuthService.signOut();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la déconnexion: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        automaticallyImplyLeading: false,
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit),
              tooltip: 'Modifier',
            ),
          if (_isEditing) ...[
            TextButton(
              onPressed: () {
                setState(() => _isEditing = false);
                _loadUserData(); // Reset form
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: _updateProfile,
              child: const Text('Sauvegarder'),
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile header
                  _buildProfileHeader(),
                  const SizedBox(height: 32),

                  // User information section
                  _buildSection(
                    'Informations personnelles',
                    [
                      _buildTextField(
                        controller: _fullNameController,
                        label: 'Nom complet',
                        icon: Icons.person,
                        enabled: _isEditing,
                      ),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Téléphone',
                        icon: Icons.phone,
                        enabled: _isEditing,
                        keyboardType: TextInputType.phone,
                      ),
                      _buildTextField(
                        controller: TextEditingController(text: _user?.email ?? ''),
                        label: 'Email',
                        icon: Icons.email,
                        enabled: false, // Email cannot be changed
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ENEO information section
                  _buildSection(
                    'Informations ENEO',
                    [
                      _buildTextField(
                        controller: _eneoClientIdController,
                        label: 'Numéro client ENEO',
                        icon: Icons.badge,
                        enabled: _isEditing,
                      ),
                      _buildTextField(
                        controller: _meterAddressController,
                        label: 'Adresse du compteur',
                        icon: Icons.location_on,
                        enabled: _isEditing,
                        maxLines: 2,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Preferences section
                  _buildSection(
                    'Préférences',
                    [
                      _buildTextField(
                        controller: _monthlyBudgetController,
                        label: 'Budget mensuel (FCFA)',
                        icon: Icons.account_balance_wallet,
                        enabled: _isEditing,
                        keyboardType: TextInputType.number,
                      ),
                      _buildTextField(
                        controller: _customThresholdController,
                        label: 'Seuil d\'alerte personnalisé (FCFA)',
                        icon: Icons.warning,
                        enabled: _isEditing,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Notification preferences
                  if (_preferences != null) _buildNotificationPreferences(),

                  const SizedBox(height: 32),

                  // Action buttons
                  _buildActionButtons(),

                  const SizedBox(height: 100), // Space for bottom nav
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                _user?.fullName?.isNotEmpty == true
                    ? _user!.fullName![0].toUpperCase()
                    : _user?.email[0].toUpperCase() ?? 'U',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _user?.fullName ?? 'Utilisateur',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _user?.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  if (_user?.eneoClientId != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Client ENEO: ${_user!.eneoClientId}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
    int? maxLines,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        maxLines: maxLines ?? 1,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: !enabled,
          fillColor: !enabled 
              ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
              : null,
        ),
      ),
    );
  }

  Widget _buildNotificationPreferences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notifications',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Notifications push'),
                  subtitle: const Text('Alertes et rappels sur votre appareil'),
                  value: _preferences!.enablePushNotifications,
                  onChanged: _isEditing ? (value) {
                    // Update preferences immediately
                    AuthService.updateUserPreferences(
                      enablePushNotifications: value,
                    ).then((_) => _loadUserData());
                  } : null,
                ),
                SwitchListTile(
                  title: const Text('Notifications email'),
                  subtitle: const Text('Alertes et rappels par email'),
                  value: _preferences!.enableEmailNotifications,
                  onChanged: _isEditing ? (value) {
                    AuthService.updateUserPreferences(
                      enableEmailNotifications: value,
                    ).then((_) => _loadUserData());
                  } : null,
                ),
                SwitchListTile(
                  title: const Text('Notifications SMS'),
                  subtitle: const Text('Alertes et rappels par SMS'),
                  value: _preferences!.enableSmsNotifications,
                  onChanged: _isEditing ? (value) {
                    AuthService.updateUserPreferences(
                      enableSmsNotifications: value,
                    ).then((_) => _loadUserData());
                  } : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Sign out button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              'Se déconnecter',
              style: TextStyle(color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Delete account button
        TextButton.icon(
          onPressed: _showDeleteAccountDialog,
          icon: const Icon(Icons.delete_forever, color: Colors.red),
          label: const Text(
            'Supprimer mon compte',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: const Text(
          'Cette action est irréversible. Toutes vos données seront définitivement supprimées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AuthService.deleteAccount();
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}