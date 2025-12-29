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
import '../../core/providers/app_provider.dart';
import '../../core/utils/role_access.dart';
import '../../core/models/user_model.dart';
import 'auth_routes.dart';
import 'auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final appState = AppProvider.of(context);
        final username = _emailController.text.trim();
        final password = _passwordController.text;
        
        // Authenticate user
        final user = await appState.login(username, password);
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          if (user != null) {
            // Navigate to the appropriate dashboard based on role
            final route = _getRouteForRole(user.role);
            Navigator.pushNamedAndRemoveUntil(
              context,
              route,
              (route) => false,
            );
          } else {
            // Show error for invalid credentials
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Invalid username or password'),
                backgroundColor: context.colors.danger,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: RadiusTokens.button,
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: context.colors.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: RadiusTokens.button,
              ),
            ),
          );
        }
      }
    }
  }

  String _getRouteForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
      case UserRole.principal:
        return '/principal';
      case UserRole.teacher:
        return '/teacher';
      case UserRole.student:
        return '/student';
    }
  }

  void _navigateToSignup() {
    Navigator.pushNamed(
      context,
      AuthRoutes.signup,
    ).then((_) {
      // Reset form when returning from signup
      _emailController.clear();
      _passwordController.clear();
    });
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
                          'Welcome Back',
                          role: TypographyRole.headline,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: SpacingTokens.space4),
                        DSText(
                          'Sign in to continue',
                          role: TypographyRole.body,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: SpacingTokens.space24),

                        // Email Field
                        _AuthTextField(
                          controller: _emailController,
                          label: 'Email or Username',
                          hint: 'Enter your email or username',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email or username';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: SpacingTokens.space16),

                        // Password Field
                        _AuthTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Enter your password',
                          icon: Icons.lock_outlined,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
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
                              return 'Please enter your password';
                            }
                            if (!AuthState.isValidPassword(value)) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _handleLogin(),
                        ),
                        const SizedBox(height: SpacingTokens.space24),

                        // Login Button
                        DSButton(
                          label: _isLoading ? 'Signing in...' : 'Sign In',
                          onPressed: _isLoading ? null : _handleLogin,
                          icon: _isLoading ? null : Icons.login_rounded,
                        ),
                        const SizedBox(height: SpacingTokens.space16),

                        // Signup Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            DSText(
                              "Don't have an account? ",
                              role: TypographyRole.body,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            GestureDetector(
                              onTap: _navigateToSignup,
                              child: DSText(
                                'Sign Up',
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
                        const SizedBox(height: SpacingTokens.space8),
                        
                        // Compact Test Credentials Hint
                        DSText(
                          'Test: admin/admin123, principal/principal123, teacher/teacher123, student/student123',
                          role: TypographyRole.caption,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.textSecondary.withOpacity(0.6),
                            fontSize: 10,
                          ),
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
              color: colors.accentPrimary.withOpacity(0.1),
              borderRadius: RadiusTokens.card,
            ),
            child: Icon(
              Icons.school_rounded,
              color: colors.accentPrimary,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}

