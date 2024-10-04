import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';

import '../components/grid.dart';

class UserProfile extends StatefulWidget {
  final String? id;

  const UserProfile({super.key, required this.id});

  @override
  State<UserProfile> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfile> {
  bool isLoading = true;
  RecordModel? user;
  late PocketBase pb;

  @override
  void initState() {
    super.initState();
    pb = Provider.of<PocketBase>(context, listen: false);
    getUser(pb);
  }

  void getUser(PocketBase pb) async {
    if (widget.id == null) return;
    var data =
        await pb.collection("users").getOne(widget.id!, expand: "watchfaces");
    print(data);
    inspect(data);
    setState(() {
      user = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: buildScaffold(context),
    );
  }

  String getHeaderText() {
    var wf = user;
    if (isLoading) {
      return "Loading...";
    } else if (wf == null) {
      return "Not found";
    } else {
      return wf.getStringValue("name");
    }
  }

  Widget buildScaffold(BuildContext context) {
    var theme = Theme.of(context);
    var wfs = user;
    return Scaffold(
        appBar: AppBar(
          title: Text(getHeaderText()),
          leading: InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const Icon(Symbols.arrow_back_rounded),
          ),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: buildBody(context, theme, wfs),
        ));
  }

  Widget buildBody(BuildContext context, ThemeData theme, RecordModel? user) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [CircularProgressIndicator(strokeCap: StrokeCap.round)],
        ),
      );
    } else if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Not found",
              style: theme.textTheme.titleLarge,
            ),
            Text(
              "We couldn't find what you were looking for.",
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    } else {
      var faces = user.expand['watchfaces'];
      var isVerified = user?.getStringValue("devId", null) != null;

      return CustomScrollView(
        slivers: [
          // Sliver for the top element (Header)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: buildUserInfo(theme, user),
            ),
          ),

          // Sliver for the Grid below
          WatchFaceGrid(faces),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "${faces?.length} watch faces",
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget buildUserInfo(ThemeData theme, RecordModel user) {
    final isVerified = user?.getStringValue("devId", null) != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
              color: theme.colorScheme
                  .surfaceContainerLowest, // Set your desired background color here
              shape: BoxShape.circle,
              border: Border.all(
                  color: theme.colorScheme.surfaceContainerHighest,
                  width: 1.5)),
          child: ClipOval(child: getUserImage(user, 80)),
        ),
        const SizedBox(
          width: 20,
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  user.getStringValue("displayName"),
                  style: theme.textTheme.displaySmall,
                ),
                if (isVerified) const SizedBox(width: 7),
                if (isVerified)
                  const Icon(
                    Symbols.verified_rounded,
                    size: 30,
                  ),
              ],
            ),
            if (isVerified)
              SizedBox(
                width: MediaQuery.of(context).size.width *
                    0.55, // Adjust as needed
                child: Text(
                  "This user has verified their Play Store account",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.9),
                  ),
                  overflow: TextOverflow.visible,
                  maxLines: 2,
                ),
              )
          ],
        )
      ],
    );
  }

  Widget getUserImage(RecordModel user, double size) {
    var avatarURL = user?.getStringValue("avatarURL", null);
    var isPrivate = user.getBoolValue("private", false);
    if (avatarURL != null && !isPrivate) {
      return Image.network(
        avatarURL,
        width: size,
        height:
            size, // Ensure the height matches the width for a circular shape
        fit: BoxFit.cover, // This will ensure the image covers the entire area
      );
    } else if (isPrivate) {
      return Icon(
        Symbols.lock_rounded,
        size: size,
      );
    } else {
      return Icon(
        Symbols.no_accounts_rounded,
        size: size,
      );
    }
  }

  Widget buildTags(ThemeData theme, RecordModel wf) {
    return Padding(
      padding:
          const EdgeInsets.all(15.0), // Outer padding for the entire section
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Tags',
            style: theme
                .textTheme.labelLarge, // Use theme's text style for the label
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10), // Add some space between label and tags
          Wrap(
            spacing: 10, // Horizontal space between tags
            runSpacing: 10, // Vertical space between lines
            children: wf.expand['tags']!.map((tag) {
              return Chip(
                label: Text(tag.getStringValue("name")),
                avatar: const Icon(Symbols.tag_rounded),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
