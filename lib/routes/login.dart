import 'package:wear_store/components/loader.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:url_launcher/url_launcher.dart';

class AdaptiveBox extends StatelessWidget {
  final double? width;
  final double? height;
  final Widget child;

  const AdaptiveBox({super.key, required this.child, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    print(width);
    if (width != null) {
      return SizedBox(
        width: width,
        height: height,
        child: child,
      );
    } else {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: child,
        ),
      );
    }
  }
}

// Extract _buildUsernameForm into a StatefulWidget
class SignIn extends StatefulWidget {
  final Function() onSignIn;
  final Function() onBack;
  const SignIn({super.key, required this.onSignIn, required this.onBack});

  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  bool isLoading = false;
  late PocketBase pb;

  late Future<bool> _isNewAccountFuture;

  @override
  void initState() {
    super.initState();
    pb = Provider.of<PocketBase>(context, listen: false);
  }

  Future<void> login(String provider) async {
    setState(() {
      isLoading = true;
    });
    await pb.collection("users").authWithOAuth2(provider, (url) async {
      try {
        await launchUrl(url);
        await widget.onSignIn();
        setState(() {
          isLoading = false;
        });
      } catch (err) {
        print(err);
      }
    });
    setState(() {
      isLoading = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(15),
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeCap: StrokeCap.round,
                          strokeWidth: 3,
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.tonal(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  login("google");
                                },
                          child: isLoading
                              ? const SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    strokeCap: StrokeCap.round,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text("Sign in with Google"),
                        ),
                        FilledButton.tonal(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  login("github");
                                },
                          child: isLoading
                              ? const SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    strokeCap: StrokeCap.round,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [const Text("Sign in with GitHub")],
                                ),
                        ),
                        FilledButton.tonal(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  login("discord");
                                },
                          child: isLoading
                              ? const SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    strokeCap: StrokeCap.round,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text("Sign in with Discord"),
                        ),
                      ],
                    ),
            ),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(),
                children: [
                  const TextSpan(
                      text: 'By creating an account, you agree to our '),
                  TextSpan(
                    text: 'privacy policy',
                    style: const TextStyle(
                      color: Colors.blue,
                      //decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        var url = Uri.parse(
                            'https://gist.github.com/Turtlepaw/97976ff459a671e26ad6843d2562b439');
                        await launchUrl(url);
                      },
                  ),
                  const TextSpan(text: ' and our '),
                  TextSpan(
                    text: 'terms of service.',
                    style: const TextStyle(
                      color: Colors.blue,
                      //decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        var url = Uri.parse(
                            'https://gist.github.com/Turtlepaw/c2127d7551b5797df235358eeb76673a');
                        await launchUrl(url);
                      },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80), // Add space for the back button
          ],
        ),
        Positioned(
          bottom: 20, // Adjust position as needed
          left: 20, // Adjust position as needed
          child: FilledButton(
            onPressed: () {
              widget.onBack();
            },
            child: const Text("Back"),
          ),
        ),
      ],
    );
  }
}
