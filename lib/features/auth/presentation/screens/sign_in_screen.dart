import 'package:flutter/material.dart';
import 'package:goldfish/core/auth/auth_exceptions.dart';
import 'package:goldfish/core/auth/auth_notifier.dart';
import 'package:goldfish/core/logging/app_logger.dart';
import 'package:goldfish/features/auth/presentation/widgets/google_sign_in_button.dart';

/// Screen for user authentication via Google Sign-In.
///
/// Displays a sign-in button and handles authentication state.
class SignInScreen extends StatefulWidget {
  /// Creates a new [SignInScreen].
  const SignInScreen({super.key, required this.authNotifier});

  /// The authentication notifier for managing auth state.
  final AuthNotifier authNotifier;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  String? _errorMessage;

  Future<void> _handleSignIn() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final response = await widget.authNotifier.signInWithGoogle();
      if (response.authState == AuthState.unauthenticated) {
        // User cancelled - log and don't show error
        AppLogger.info({
          'event': 'sign_in_cancelled',
          'provider': response.provider,
        });
        setState(() {
          _errorMessage = null;
        });
      } else if (response.authState == AuthState.authenticated) {
        // Sign-in succeeded - log success
        AppLogger.info({
          'event': 'google_sign_in_success',
          'uid': response.uid,
        });
      }
      // Navigation will be handled by the router based on auth state
    } on AuthenticationException catch (e) {
      // Log authentication errors with diagnostic information
      final logData = <String, dynamic>{
        'event': e.eventName,
        'provider': e.provider,
      };
      if (e.code != null) {
        logData['code'] = e.code;
      }
      if (e.userId != null) {
        logData['uid'] = e.userId;
      }
      AppLogger.error(logData);

      setState(() {
        _errorMessage = e.displayMessage;
      });
    } on AuthException catch (e) {
      // Log other auth exceptions
      AppLogger.error({'event': e.eventName, 'provider': e.provider});
      setState(() {
        _errorMessage = e.displayMessage;
      });
    } on Exception {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App logo/branding
                Icon(
                  Icons.pets,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 32),
                Text(
                  'Goldfish',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                // Sign-in button
                ListenableBuilder(
                  listenable: widget.authNotifier,
                  builder: (context, _) {
                    final isLoading = widget.authNotifier.isLoading;
                    return GoogleSignInButton(
                      onPressed: isLoading ? null : _handleSignIn,
                      isLoading: isLoading,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
