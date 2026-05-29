import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:civicall/theme/app_theme.dart';
import 'options.dart';
import 'longText/termsConditions.dart';
import 'longText/privacyPolicy.dart';
import 'api_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int? _selectedCampusId;
  int? _selectedUserTypeId;
  String? _selectedGender;
  DateTime? _selectedDateOfBirth;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  bool _isSubmitting = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _genders = AppOptions.genders;

  List<Map<String, dynamic>> _campuses = [];
  List<Map<String, dynamic>> _userTypes = [];
  bool _isLoadingCampuses = true;
  bool _isLoadingUserTypes = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
    _fetchCampuses();
    _fetchUserTypes();
  }

  Future<void> _fetchCampuses() async {
    final ApiService api = ApiService();
    final result = await api.fetchCampus();
    if (result['success'] == true && result['campuses'] != null) {
      setState(() {
        _campuses = List<Map<String, dynamic>>.from(result['campuses']);
        _isLoadingCampuses = false;
      });
    } else {
      setState(() {
        _isLoadingCampuses = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load campuses'),
          backgroundColor: AppTheme.redPink,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _fetchUserTypes() async {
    final ApiService api = ApiService();
    final result = await api.fetchDropdowns();
    if (result['success'] == true && result['userTypes'] != null) {
      setState(() {
        _userTypes = List<Map<String, dynamic>>.from(result['userTypes']);
        _isLoadingUserTypes = false;
      });
    } else {
      setState(() {
        _isLoadingUserTypes = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load user types'),
          backgroundColor: AppTheme.redPink,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.redPink,
              onPrimary: AppTheme.white,
              onSurface: AppTheme.darkGray,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppTheme.redPink),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDateOfBirth = picked);
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    final passwordRegex = RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$');
    if (!passwordRegex.hasMatch(value)) {
      return 'Password must include uppercase, lowercase, number, and special character';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Date of birth is required.'),
          backgroundColor: AppTheme.redPink,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms and Conditions and Privacy Policy.'),
          backgroundColor: AppTheme.redPink,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final int genderValue = _selectedGender == 'Male' ? 0 : 1;
    final String birthDayFormatted =
        '${_selectedDateOfBirth!.year}-${_selectedDateOfBirth!.month.toString().padLeft(2, '0')}-${_selectedDateOfBirth!.day.toString().padLeft(2, '0')}';

    final ApiService api = ApiService();
    final result = await api.signUp(
      firstName: _firstNameController.text.trim(),
      middleName: _middleNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      address: _addressController.text.trim(),
      mobileNum: _mobileController.text.trim(),
      campusId: _selectedCampusId!,
      userTypeId: _selectedUserTypeId!,
      birthDay: birthDayFormatted,
      gender: genderValue,
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! You can now sign in.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Registration failed. Please try again.'),
          backgroundColor: AppTheme.redPink,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    _buildTopBar(context),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 28.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              _buildHeading(context),
                              const SizedBox(height: 28),
                              _buildSectionCard([
                                _buildLabel('First Name'),
                                const SizedBox(height: 8),
                                _buildTextFormField(
                                  controller: _firstNameController,
                                  hint: 'e.g. Juan',
                                  icon: Icons.person_outline,
                                  validator: (v) => v == null || v.trim().isEmpty ? 'First name is required' : null,
                                ),
                                const SizedBox(height: 18),
                                _buildLabel('Middle Name'),
                                const SizedBox(height: 8),
                                _buildTextFormField(
                                  controller: _middleNameController,
                                  hint: 'e.g. Dela',
                                  icon: Icons.person_outline,
                                ),
                                const SizedBox(height: 18),
                                _buildLabel('Last Name'),
                                const SizedBox(height: 8),
                                _buildTextFormField(
                                  controller: _lastNameController,
                                  hint: 'e.g. Cruz',
                                  icon: Icons.person_outline,
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Last name is required' : null,
                                ),
                              ]),
                              const SizedBox(height: 16),
                              _buildSectionCard([
                                _buildLabel('Address'),
                                const SizedBox(height: 8),
                                _buildTextFormField(
                                  controller: _addressController,
                                  hint: 'Street, Barangay, City',
                                  icon: Icons.location_on_outlined,
                                  maxLines: 2,
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Address is required' : null,
                                ),
                                const SizedBox(height: 18),
                                _buildLabel('Mobile Number'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _mobileController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 11,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: const InputDecoration(
                                    hintText: '09XXXXXXXXX',
                                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                                    counterText: '',
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Mobile number is required';
                                    if (v.length != 11) return 'Mobile number must be 11 digits';
                                    return null;
                                  },
                                ),
                              ]),
                              const SizedBox(height: 16),
                              _buildSectionCard([
                                _buildLabel('Campus'),
                                const SizedBox(height: 8),
                                _isLoadingCampuses
                                    ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Center(child: CircularProgressIndicator()),
                                )
                                    : _buildCampusDropdown(),
                                const SizedBox(height: 18),
                                _buildLabel('User Category'),
                                const SizedBox(height: 8),
                                _isLoadingUserTypes
                                    ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Center(child: CircularProgressIndicator()),
                                )
                                    : _buildUserTypeDropdown(),
                              ]),
                              const SizedBox(height: 16),
                              _buildSectionCard([
                                _buildLabel('Date of Birth'),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _pickDateOfBirth,
                                  child: AbsorbPointer(
                                    child: TextFormField(
                                      readOnly: true,
                                      decoration: const InputDecoration(
                                        hintText: 'MM / DD / YYYY',
                                        prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                                      ),
                                      controller: TextEditingController(
                                        text: _selectedDateOfBirth != null
                                            ? '${_selectedDateOfBirth!.month.toString().padLeft(2, '0')} / ${_selectedDateOfBirth!.day.toString().padLeft(2, '0')} / ${_selectedDateOfBirth!.year}'
                                            : '',
                                      ),
                                      validator: (_) => _selectedDateOfBirth == null ? 'Date of birth is required' : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _buildLabel('Gender'),
                                const SizedBox(height: 8),
                                _buildDropdown(
                                  value: _selectedGender,
                                  hint: 'Select gender',
                                  icon: Icons.wc_outlined,
                                  items: _genders,
                                  onChanged: (v) => setState(() => _selectedGender = v),
                                  validator: (v) => v == null ? 'Please select a gender' : null,
                                ),
                              ]),
                              const SizedBox(height: 16),
                              _buildSectionCard([
                                _buildLabel('Email Address'),
                                const SizedBox(height: 8),
                                _buildTextFormField(
                                  controller: _emailController,
                                  hint: 'you@example.com',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Email is required';
                                    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
                                    if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email address';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),
                                _buildLabel('Password'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    hintText: '••••••••',
                                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  validator: _validatePassword,
                                ),
                                const SizedBox(height: 18),
                                _buildLabel('Confirm Password'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  decoration: InputDecoration(
                                    hintText: '••••••••',
                                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Please confirm your password';
                                    if (v != _passwordController.text) return 'Passwords do not match';
                                    return null;
                                  },
                                ),
                              ]),
                              const SizedBox(height: 20),
                              _buildTermsCheckbox(),
                              const SizedBox(height: 24),
                              _buildRegisterButton(),
                              const SizedBox(height: 20),
                              _buildLoginRow(context),
                              const SizedBox(height: 36),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned(
      top: -80,
      right: -60,
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.redPink.withOpacity(0.07),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.redPink.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppTheme.redPink,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeading(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sign Up Now and',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppTheme.darkGray,
            letterSpacing: -0.5,
            height: 1.15,
          ),
        ),
        RichText(
          text: TextSpan(
            text: 'Be a Part of ',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkGray,
              letterSpacing: -0.5,
              height: 1.15,
            ),
            children: const [
              TextSpan(
                text: 'Change.',
                style: TextStyle(color: AppTheme.redPink),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Create your account to get started.',
          style: TextStyle(
            color: AppTheme.darkGray.withOpacity(0.5),
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkGray.withOpacity(0.07),
            blurRadius: 28,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: AppTheme.darkGray.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.darkGray.withOpacity(0.75),
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
      ),
      validator: validator,
    );
  }

  Widget _buildCampusDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedCampusId,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.darkGray),
      decoration: const InputDecoration(
        hintText: 'Select your campus',
        prefixIcon: Icon(Icons.school_outlined, size: 20),
      ),
      items: _campuses.map((campus) {
        return DropdownMenuItem<int>(
          value: campus['campusId'] as int,
          child: Text(
            campus['campusName'] as String,
            style: const TextStyle(fontSize: 14, color: AppTheme.darkGray),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedCampusId = value),
      validator: (value) => value == null ? 'Please select a campus' : null,
    );
  }

  Widget _buildUserTypeDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedUserTypeId,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.darkGray),
      decoration: const InputDecoration(
        hintText: 'Select category',
        prefixIcon: Icon(Icons.badge_outlined, size: 20),
      ),
      items: _userTypes.map((type) {
        return DropdownMenuItem<int>(
          value: type['id'] as int,
          child: Text(
            type['name'] as String,
            style: const TextStyle(fontSize: 14, color: AppTheme.darkGray),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedUserTypeId = value),
      validator: (value) => value == null ? 'Please select a user category' : null,
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.darkGray),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
      ),
      items: items
          .map((item) => DropdownMenuItem(
        value: item,
        child: Text(
          item,
          style: const TextStyle(fontSize: 14, color: AppTheme.darkGray),
          overflow: TextOverflow.ellipsis,
        ),
      ))
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreedToTerms,
            activeColor: AppTheme.redPink,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            children: [
              Text(
                'I have read and agree to ',
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppTheme.darkGray.withOpacity(0.65),
                  height: 1.5,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TermsConditionsScreen()),
                  );
                },
                child: const Text(
                  'Terms and Conditions',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppTheme.redPink,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ),
              Text(
                ' and ',
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppTheme.darkGray.withOpacity(0.65),
                  height: 1.5,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                  );
                },
                child: const Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppTheme.redPink,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.redPink,
          foregroundColor: AppTheme.white,
          disabledBackgroundColor: AppTheme.redPink.withOpacity(0.6),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
        )
            : const Text(
          'Register',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account?',
          style: TextStyle(
            color: AppTheme.darkGray.withOpacity(0.55),
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Sign In',
            style: TextStyle(
              color: AppTheme.redPink,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}