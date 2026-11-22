import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../provider_dashboard/presentation/screens/provider_home_screen.dart';
import '../../receiver_dashboard/presentation/screens/receiver_home_screen.dart';
import '../data/models/user_model.dart';
import '../controllers/auth_controller.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  UserRole _selectedRole = UserRole.provider;
  final _nameController = TextEditingController();
  final _orgNameController = TextEditingController();
  String _selectedOrgType = 'Restaurant';

  final List<String> _providerOrgTypes = [
    'Hotel',
    'Hostel / Canteen',
    'Restaurant',
    'Bakery & Cafe',
    'Supermarket / Local Shop',
    'Event Caterer'
  ];

  final List<String> _receiverOrgTypes = [
    'Neighbor / Individual',
    'Orphanage',
    'Homeless Shelter',
    'Registered NGO',
    'Community Kitchen'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _orgNameController.dispose();
    super.dispose();
  }

  void _onRoleChanged(UserRole role) {
    setState(() {
      _selectedRole = role;
      _selectedOrgType = role == UserRole.provider
          ? _providerOrgTypes.first
          : _receiverOrgTypes.first;
    });
  }

  Future<void> _submitProfile() async {
    if (_nameController.text.trim().isEmpty ||
        _orgNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).completeOnboarding(
          role: _selectedRole,
          name: _nameController.text.trim(),
          orgName: _orgNameController.text.trim(),
          orgType: _selectedOrgType,
        );

    if (success && mounted) {
      if (_selectedRole == UserRole.provider) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProviderHomeScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ReceiverHomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final orgTypes = _selectedRole == UserRole.provider
        ? _providerOrgTypes
        : _receiverOrgTypes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Rescue Role'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How will you participate in food rescue?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select your account profile. You can list surplus food or claim food ready for rescue.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Role Selection Cards
              Row(
                children: [
                  Expanded(
                    child: _buildRoleCard(
                      role: UserRole.provider,
                      title: 'Food Provider',
                      subtitle: 'Hotels, Hostels, Bakeries & Shops',
                      icon: Icons.storefront_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildRoleCard(
                      role: UserRole.receiver,
                      title: 'Food Receiver',
                      subtitle: 'Neighbors, Shelters & NGOs',
                      icon: Icons.volunteer_activism_rounded,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Form Details
              Text(
                _selectedRole == UserRole.provider
                    ? 'Provider Details'
                    : 'Recipient Details',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Your Contact Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _orgNameController,
                decoration: InputDecoration(
                  labelText: _selectedRole == UserRole.provider
                      ? 'Business / Establishment Name'
                      : 'Organization / Household Name',
                  prefixIcon: const Icon(Icons.business_outlined),
                ),
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: orgTypes.contains(_selectedOrgType)
                    ? _selectedOrgType
                    : orgTypes.first,
                decoration: const InputDecoration(
                  labelText: 'Organization Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: orgTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedOrgType = val);
                },
              ),
              const SizedBox(height: 32),

              if (authState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    authState.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              ElevatedButton(
                onPressed: authState.isLoading ? null : _submitProfile,
                child: authState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Complete Registration & Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () => _onRoleChanged(role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2.2 : 1,
          ),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: isSelected ? color : Colors.grey.shade100,
              child: Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade700, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isSelected ? color : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
