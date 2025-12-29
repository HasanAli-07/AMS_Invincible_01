import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../design_system/components/ds_glass_card.dart';
import '../../design_system/components/ds_button.dart';
import '../../design_system/components/ds_text.dart';
import '../../design_system/tokens/color_tokens.dart';
import '../../design_system/tokens/spacing_tokens.dart';
import '../../design_system/tokens/radius_tokens.dart';
import '../../design_system/tokens/typography_tokens.dart';
import '../../design_system/tokens/animation_tokens.dart';
import '../../design_system/tokens/opacity_tokens.dart';
import 'auth_routes.dart';
import 'auth_state.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AnimationTokens.durationScreenEntry,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AnimationCurves.screenEntry,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AnimationCurves.screenEntry,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignup() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Dummy validation - no backend
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          // Show success and navigate back to login
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Account created successfully!'),
              backgroundColor: context.colors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: RadiusTokens.button,
              ),
            ),
          );
          Navigator.pop(context);
        }
      });
    }
  }

  String? _validatePasswordMatch(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (!AuthState.passwordsMatch(_passwordController.text, value)) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(SpacingTokens.space24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: DSGlassCard(
                  padding: const EdgeInsets.all(SpacingTokens.space24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo Section
                        _AuthLogo(isDark: isDark),
                        const SizedBox(height: SpacingTokens.space20),
                        DSText(
                          'Create Account',
                          role: TypographyRole.headline,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: SpacingTokens.space4),
                        DSText(
                          'Sign up to get started',
                          role: TypographyRole.body,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: SpacingTokens.space24),

                        // Full Name Field
                        _AuthTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          hint: 'Enter your full name',
                          icon: Icons.person_outlined,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            if (value.trim().split(' ').length < 2) {
                              return 'Please enter your full name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: SpacingTokens.space16),

                        // Email Field
                        _AuthTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'Enter your email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!AuthState.isValidEmail(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: SpacingTokens.space16),

                        // Password Field
                        _AuthTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Create a password',
                          icon: Icons.lock_outlined,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: colors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (!AuthState.isValidPassword(value)) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: SpacingTokens.space16),

                        // Confirm Password Field
                        _AuthTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          hint: 'Re-enter your password',
                          icon: Icons.lock_outlined,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: colors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                          validator: _validatePasswordMatch,
                          onFieldSubmitted: (_) => _handleSignup(),
                        ),
                        const SizedBox(height: SpacingTokens.space24),

                        // Signup Button
                        DSButton(
                          label: _isLoading ? 'Creating Account...' : 'Create Account',
                          onPressed: _isLoading ? null : _handleSignup,
                          icon: _isLoading ? null : Icons.person_add_rounded,
                          variant: DSButtonVariant.success,
                        ),
                        const SizedBox(height: SpacingTokens.space16),

                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            DSText(
                              'Already have an account? ',
                              role: TypographyRole.body,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: DSText(
                                'Sign In',
                                role: TypographyRole.body,
                                style: TextStyle(
                                  color: colors.accentPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom text field for auth forms with design system styling.
class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final void Function(String)? onFieldSubmitted;

  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.suffixIcon,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DSText(
          label,
          role: TypographyRole.body,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: SpacingTokens.space8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: colors.textSecondary.withOpacity(OpacityTokens.opacityDisabled),
            ),
            prefixIcon: Icon(icon, color: colors.textSecondary),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: colors.backgroundSurface.withOpacity(
              OpacityTokens.glassBackgroundOpacity * 0.5,
            ),
            border: OutlineInputBorder(
              borderRadius: RadiusTokens.button,
              borderSide: BorderSide(
                color: colors.borderSubtle,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: RadiusTokens.button,
              borderSide: BorderSide(
                color: colors.borderSubtle,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: RadiusTokens.button,
              borderSide: BorderSide(
                color: colors.accentPrimary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: RadiusTokens.button,
              borderSide: BorderSide(
                color: colors.danger,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: RadiusTokens.button,
              borderSide: BorderSide(
                color: colors.danger,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.space16,
              vertical: SpacingTokens.space16,
            ),
          ),
        ),
      ],
    );
  }
}

/// Auth Logo Widget - Uses SVG logo from assets
class _AuthLogo extends StatelessWidget {
  final bool isDark;

  const _AuthLogo({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    // Use appropriate logo based on theme
    // For auth screens, we use primary logos since background is gradient
    final logoPath = isDark 
        ? 'Logos/Dark theme primary.svg'
        : 'Logos/light theme primary.svg';

    return Center(
      child: SizedBox(
        width: 80,
        height: 80,
        child: SvgPicture.asset(
          logoPath,
          fit: BoxFit.contain,
          placeholderBuilder: (context) => Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.accentSecondary.withOpacity(0.1),
              borderRadius: RadiusTokens.card,
            ),
            child: Icon(
              Icons.person_add_rounded,
              color: colors.accentSecondary,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}


