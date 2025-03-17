// presentation/screens/auth/profile_setup_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/user_provider.dart';

class ProfileSetupScreen extends StatefulWidget {
  @override
  _ProfileSetupScreenState createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _selectedDistrict = '';
  List<String> _selectedInterests = [];
  File? _profileImage;
  bool _isLoading = false;
  String _errorMessage = '';
  
  final List<String> _interestsList = [
    'Community Development',
    'Education',
    'Healthcare',
    'Agriculture',
    'Technology',
    'Arts & Culture',
    'Sports',
    'Environment',
    'Business',
    'Youth Empowerment',
    'Women Empowerment',
    'Social Justice'
  ];
  
  @override
  void initState() {
    super.initState();
    // Pre-fill with existing data if available
    _loadUserData();
  }
  
  @override
  void dispose() {
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.fetchCurrentUser();
    
    if (userProvider.currentUser != null) {
      setState(() {
        _bioController.text = userProvider.currentUser!.bio;
        _phoneController.text = userProvider.currentUser!.phone ?? '';
        _selectedDistrict = userProvider.currentUser!.district;
        _selectedInterests = List<String>.from(userProvider.currentUser!.interests);
      });
    }
  }
  
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedDistrict.isEmpty) {
      setState(() {
        _errorMessage = 'Please select your district';
      });
      return;
    }
    
    if (_selectedInterests.isEmpty) {
      setState(() {
        _errorMessage = 'Please select at least one interest';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      await userProvider.updateUserProfile(
        bio: _bioController.text.trim(),
        district: _selectedDistrict,
        interests: _selectedInterests,
        phone: _phoneController.text.trim(),
        profileImage: _profileImage,
      );
      
      // Navigate to home screen
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update profile. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text('Complete Your Profile'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          TextButton(
            onPressed: () {
              // Skip profile setup - navigate to home
              Navigator.of(context).pushReplacementNamed(AppRoutes.home);
            },
            child: Text(
              'Skip',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile image
                      Center(
                        child: Stack(
                          children: [
                            // Profile image
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey.shade300,
                              backgroundImage: _profileImage != null
                                  ? FileImage(_profileImage!)
                                  : (user?.photoURL != null
                                      ? NetworkImage(user!.photoURL!)
                                      : null) as ImageProvider?,
                              child: _profileImage == null && user?.photoURL == null
                                  ? Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.grey.shade600,
                                    )
                                  : null,
                            ),
                            
                            // Edit button
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(8),
                                child: InkWell(
                                  onTap: _pickImage,
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Error message
                      if (_errorMessage.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _errorMessage,
                            style: TextStyle(
                              color: AppTheme.errorColor,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      
                      if (_errorMessage.isNotEmpty)
                        const SizedBox(height: 24),
                      
                      // Display name
                      Text(
                        'Name: ${user?.displayName ?? "User"}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Email
                      Text(
                        'Email: ${user?.email ?? ""}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Phone number
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number (Optional)',
                          hintText: 'Enter your phone number',
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // District dropdown
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'District',
                          hintText: 'Select your district',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        value: _selectedDistrict.isNotEmpty ? _selectedDistrict : null,
                        items: AppConstants.rwandaDistricts.map((district) {
                          return DropdownMenuItem<String>(
                            value: district,
                            child: Text(district),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDistrict = value ?? '';
                          });
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Bio
                      TextFormField(
                        controller: _bioController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Bio',
                          hintText: 'Tell us a bit about yourself',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a short bio';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Interests
                      Text(
                        'Select Your Interests',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _interestsList.map((interest) {
                          final isSelected = _selectedInterests.contains(interest);
                          return FilterChip(
                            label: Text(interest),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedInterests.add(interest);
                                } else {
                                  _selectedInterests.remove(interest);
                                }
                              });
                            },
                            selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                            checkmarkColor: AppTheme.primaryColor,
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Save button
                      ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Save Profile & Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}