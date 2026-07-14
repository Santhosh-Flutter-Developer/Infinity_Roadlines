import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_sheet_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter username and password.')),
      );
      return;
    }

    final success = await ref.read(authNotifierProvider.notifier).login(username, password);
    if (!mounted) return;

    if (success) {
      ref.read(tripSheetsProvider.notifier).fetchTripSheets();
    } else {
      final error = ref.read(authNotifierProvider).error;
      final errorMsg = error != null 
          ? error.toString().replaceAll('Exception: ', '') 
          : 'Invalid username or password.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    }
  }

  void _usePreset(String username) {
    _usernameController.text = username;
    _passwordController.text = 'password';
    _handleLogin();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AnimatedTruckWithParcel(
                        color: Theme.of(context).colorScheme.primary,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Trip Sheet Tracker',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      Text(
                        'Logistics & GPS Tracking',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscureText = !_obscureText),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _handleLogin(),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: authState.isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: authState.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Login', style: TextStyle(fontSize: 16)),
                      ),
                      // const SizedBox(height: 32),
                      // const Divider(),
                      // const SizedBox(height: 16),
                      // Text(
                      //   'Quick Sign In (Demo Users)',
                      //   style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                      //   textAlign: TextAlign.center,
                      // ),
                      // const SizedBox(height: 8),
                      // Wrap(
                      //   spacing: 12.0,
                      //   runSpacing: 12.0,
                      //   alignment: WrapAlignment.center,
                      //   children: [
                      //     OutlinedButton(
                      //       onPressed: () => _usePreset('kumar'),
                      //       child: const Text('Kumar (Driver)'),
                      //     ),
                      //     OutlinedButton(
                      //       onPressed: () => _usePreset('admin'),
                      //       child: const Text('Vinayagam (Admin)'),
                      //     ),
                      //   ],
                      // ),
                    ],
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

class AnimatedTruckWithParcel extends StatefulWidget {
  final Color color;
  final double size;

  const AnimatedTruckWithParcel({
    super.key,
    required this.color,
    required this.size,
  });

  @override
  State<AnimatedTruckWithParcel> createState() => _AnimatedTruckWithParcelState();
}

class _AnimatedTruckWithParcelState extends State<AnimatedTruckWithParcel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _lerp(double start, double end, double t) {
    return start + (end - start) * t;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final val = _controller.value;

        // 1. Truck Position Offset
        Offset truckOffset;
        if (val < 0.25) {
          // Slide in from left (-2.5) to center (0.0)
          final t = val / 0.25;
          final double curve = Curves.fastOutSlowIn.transform(t);
          truckOffset = Offset(_lerp(-2.5, 0.0, curve), 0.0);
        } else if (val < 0.70) {
          // Shake at center (0.0)
          final t = (val - 0.25) / 0.45; // 0.0 to 1.0
          // Wobble using Sine wave
          final shake = math.sin(t * 8 * math.pi) * 0.08;
          truckOffset = Offset(shake, 0.0);
        } else {
          // Slide out to right (2.5)
          final t = (val - 0.70) / 0.30;
          final double curve = Curves.fastOutSlowIn.transform(t);
          truckOffset = Offset(_lerp(0.0, 2.5, curve), 0.0);
        }

        // 2. Parcel Drop Details
        bool showParcel = val >= 0.35 && val <= 0.65;
        double parcelOpacity = 0.0;
        double parcelYTranslate = 0.0;
        if (showParcel) {
          final t = (val - 0.35) / 0.30; // 0.0 to 1.0
          // Drop down by 25 pixels
          parcelYTranslate = t * 25.0;
          // Fade in at start, fade out at end
          if (t < 0.2) {
            parcelOpacity = t / 0.2;
          } else {
            parcelOpacity = (1.0 - (t - 0.2) / 0.8).clamp(0.0, 1.0);
          }
        }

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Container for consistent layout bounds
            const SizedBox(height: 90, width: double.infinity),

            // Truck icon
            FractionalTranslation(
              translation: truckOffset,
              child: Icon(
                Icons.local_shipping,
                size: widget.size,
                color: widget.color,
              ),
            ),

            // Parcel dropped container
            if (showParcel)
              Positioned(
                top: 40 + parcelYTranslate,
                child: Opacity(
                  opacity: parcelOpacity,
                  child: Icon(
                    Icons.inventory_2,
                    size: widget.size * 0.35,
                    color: widget.color.withOpacity(0.85),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
