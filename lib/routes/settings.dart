import 'package:flutter/material.dart';
import 'package:flutter_advanced_avatar/flutter_advanced_avatar.dart';
import 'package:flutter_wear_os_connectivity/flutter_wear_os_connectivity.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:wear_store/routes/login_modal.dart';
import '../components/dialog/confirm.dart';
import '../components/loader.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? username;
  late PocketBase pb;

  final FlutterWearOsConnectivity _flutterWearOsConnectivity =
      FlutterWearOsConnectivity();

  @override
  initState() {
    super.initState();
    pb = Provider.of<PocketBase>(context, listen: false);

    if (pb.authStore.isValid) {
      username = (pb.authStore.model as RecordModel)
          .getStringValue("username", "unknown");

      subscribe();
    }
  }

  void subscribe() {
    pb.collection("users").subscribe(pb.authStore.model.id, (value) {
      if (value.record != null) {
        setState(() {
          username = value.record!.getStringValue("username");
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    pb.collection("users").unsubscribe();
  }

  @override
  Widget build(BuildContext context) {
    final pb = Provider.of<PocketBase>(context, listen: false);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Column(
        children: [
          buildCard(
            [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (username != null)
                    AdvancedAvatar(
                      name: pb.authStore.model?.getStringValue("username"),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: theme.colorScheme.onPrimary),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      size: 50,
                    ),
                  if (username != null)
                    const SizedBox(
                      width: 20,
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        username == null
                            ? "Not logged in"
                            : "Logged in as $username",
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          FilledButton.tonal(
                            onPressed: _requestLogoutConfirmation,
                            child: Text(username == null ? "Login" : "Logout"),
                          ),
                          const SizedBox(width: 4),
                          if (username != null)
                            IconButton.filledTonal(
                                onPressed: username != null
                                    ? _openProfileEditor
                                    : null,
                                tooltip: "Edit Profile",
                                icon: Icon(
                                  Symbols.edit_rounded,
                                  color: theme.colorScheme.onPrimaryContainer,
                                )),
                          // IconButton.filledTonal(
                          //     onPressed: _openProfileEditor,
                          //     tooltip: "Delete Account",
                          //     icon: Icon(
                          //       Symbols.delete_forever_rounded,
                          //       color: theme.colorScheme.onPrimaryContainer,
                          //     ))
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  double getWidth(BoxConstraints constraints) {
    if (constraints.maxWidth < 500) {
      return constraints.maxWidth - 10; // Fill the width on phones with margin
    } else {
      return 500; // Limit to ~200 on larger devices
    }
  }

  Widget buildCard(List<Widget> children) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = getWidth(constraints);

      return Center(
          child: SizedBox(
        width: width,
        child: Card.outlined(
          //clipBehavior: Clip.hardEdge,
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children,
            ),
          ),
        ),
      ));
    });
  }

  void _openProfileEditor() {
    context.go("/edit-profile");
    // showDialog(
    //         context: context,
    //         builder: (context) => ProfileDialog(pb: pb),
    //         useSafeArea: false)
    //     .then((_) => {
    //           setState(() {
    //             username = (pb.authStore.model as RecordModel)
    //                 .getStringValue("username");
    //           })
    //         });
  }

  void _requestLogoutConfirmation() {
    if (username == null) {
      showDialog(
          context: context,
          builder: (context) => LoginDialog(),
          useSafeArea: true);
    } else {
      final pb = Provider.of<PocketBase>(context, listen: false);
      showDialog(
          context: context,
          builder: (context) => ConfirmDialog(
                isDestructive: true,
                icon: Icons.logout,
                title: "Logout",
                description: "Are you sure you want to logout?",
                onConfirm: () async {
                  pb.authStore.clear();
                  context.go("/login");
                },
              ),
          useSafeArea: false);
    }
  }
}
