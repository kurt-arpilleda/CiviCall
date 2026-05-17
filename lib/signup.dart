import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:civicall/theme/app_theme.dart';
import 'options.dart';

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

  String? _selectedCampus;
  String? _selectedUserCategory;
  String? _selectedGender;
  DateTime? _selectedDateOfBirth;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _campuses = AppOptions.campuses;
  final List<String> _userCategories = AppOptions.userCategories;
  final List<String> _genders = AppOptions.genders;

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

  void _submit() {
    if (_formKey.currentState!.validate()) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign Up UI demo — no backend call'),
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
                                  decoration: InputDecoration(
                                    hintText: '09XXXXXXXXX',
                                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
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
                                _buildDropdown(
                                  value: _selectedCampus,
                                  hint: 'Select your campus',
                                  icon: Icons.school_outlined,
                                  items: _campuses,
                                  onChanged: (v) => setState(() => _selectedCampus = v),
                                  validator: (v) => v == null ? 'Please select a campus' : null,
                                ),
                                const SizedBox(height: 18),
                                _buildLabel('User Category'),
                                const SizedBox(height: 8),
                                _buildDropdown(
                                  value: _selectedUserCategory,
                                  hint: 'Select category',
                                  icon: Icons.badge_outlined,
                                  items: _userCategories,
                                  onChanged: (v) => setState(() => _selectedUserCategory = v),
                                  validator: (v) => v == null ? 'Please select a user category' : null,
                                ),
                              ]),
                              const SizedBox(height: 16),
                              _buildSectionCard([
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildLabel('Date of Birth'),
                                          const SizedBox(height: 8),
                                          GestureDetector(
                                            onTap: _pickDateOfBirth,
                                            child: AbsorbPointer(
                                              child: TextFormField(
                                                readOnly: true,
                                                decoration: InputDecoration(
                                                  hintText: 'MM / DD / YYYY',
                                                  prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                                                ),
                                                controller: TextEditingController(
                                                  text: _selectedDateOfBirth != null
                                                      ? '${_selectedDateOfBirth!.month.toString().padLeft(2, '0')} / ${_selectedDateOfBirth!.day.toString().padLeft(2, '0')} / ${_selectedDateOfBirth!.year}'
                                                      : '',
                                                ),
                                                validator: (_) => _selectedDateOfBirth == null ? 'Required' : null,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildLabel('Gender'),
                                          const SizedBox(height: 8),
                                          _buildDropdown(
                                            value: _selectedGender,
                                            hint: 'Select',
                                            icon: Icons.wc_outlined,
                                            items: _genders,
                                            onChanged: (v) => setState(() => _selectedGender = v),
                                            validator: (v) => v == null ? 'Required' : null,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Password is required';
                                    if (v.length < 8) return 'Password must be at least 8 characters long';
                                    return null;
                                  },
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
                style: TextStyle(
                  color: AppTheme.redPink,
                ),
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
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.darkGray,
          ),
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
          child: GestureDetector(
            onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
            child: RichText(
              text: TextSpan(
                text: 'I have read and agree to ',
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppTheme.darkGray.withOpacity(0.65),
                  height: 1.5,
                ),
                children: const [
                  TextSpan(
                    text: 'Terms and Conditions',
                    style: TextStyle(
                      color: AppTheme.redPink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: AppTheme.redPink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
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
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.redPink,
          foregroundColor: AppTheme.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
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