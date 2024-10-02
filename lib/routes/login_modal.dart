import 'package:flutter/material.dart';
import 'package:flutter_advanced_avatar/flutter_advanced_avatar.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:wear_store/constants.dart';

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
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.waving_hand_rounded,
                      size: 45,
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Text(
                      "Join $appName",
                      style: theme.textTheme.displaySmall,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 15,
                ),
                Text(
                  "How it works",
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(
                  height: 15,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: Map.of({
                        "Publish your watch faces":
                            Icons.published_with_changes_rounded,
                        "Save watch faces": Icons.star_rounded,
                        "Save giveaway codes": Icons.redeem_rounded,
                        "Support a growing open-source platform":
                            Symbols.globe_rounded
                      }).entries.map<Widget>((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center, // Center the row
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                entry.value,
                                size: 28,
                              ),
                              const SizedBox(
                                  width: 15), // Spacing between icon and text
                              Expanded(
                                // Ensures text takes remaining space
                                child: Text(
                                  entry.key,
                                  style: Theme.of(context).textTheme.titleLarge,
                                  textAlign:
                                      TextAlign.left, // Left-align the text
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                )
              ],
            )));
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
