import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:wear_store/components/navigation.dart';
import 'package:wear_store/constants.dart';
import 'package:wear_store/routes/login.dart';

class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});

  @override
  _LoginDialogState createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  // bool _isDialogLoading = true;
  // bool _isHealthAvailable = true;
  bool _isUpdating = false;
  late PocketBase pb;
  int page = 0;

  @override
  void initState() {
    super.initState();

    pb = Provider.of<PocketBase>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Dialog.fullscreen(
        child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back_rounded),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: page == 0
            ? buildGetStartedPage(theme)
            : SignIn(
                onSignIn: () {
                  context.pop();
                },
                onBack: () {
                  setState(() {
                    page = 0;
                  });
                },
              ),
      ),
    ));
  }

  Widget buildGetStartedPage(ThemeData theme) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.waving_hand_rounded,
                    size: 35,
                  ),
                  const SizedBox(
                    width: 15,
                  ),
                  Text(
                    "Join $appName",
                    style: theme.textTheme.headlineMedium,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                "How it works",
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: Map.of({
                    "Publish your watch faces":
                        Icons.published_with_changes_rounded,
                    "Save watch faces": Icons.star_rounded,
                    "Keep giveaway codes": Icons.redeem_rounded,
                    "Support a growing open-source platform": Icons.public
                  }).entries.map<Widget>((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            entry.value,
                            size: 28,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        // Button at the bottom right
        Positioned(
          bottom: 16, // Adjust as needed
          right: 16, // Adjust as needed
          child: FilledButton(
            onPressed: () {
              setState(() {
                page = 1;
              });
            },
            child: Text('Get Started'),
          ),
        ),
      ],
    );
  }

  void _handleEdit() async {
    setState(() {
      _isUpdating = true;
    });
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged in'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (error, stackTrace) {
      print('Error updating profile: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to login"),
          ),
        );
      }
      setState(() {
        _isUpdating = false;
      });
    }
  }
}
