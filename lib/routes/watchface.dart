import 'dart:developer';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wear_store/components/navigation.dart';

import '../components/dialog/confirm.dart';

class WatchFace extends StatefulWidget {
  final String? id;

  const WatchFace({super.key, required this.id});

  @override
  State<WatchFace> createState() => _WatchFacePageState();
}

class _WatchFacePageState extends State<WatchFace> {
  bool isLoading = true;
  RecordModel? face;
  late PocketBase pb;

  @override
  void initState() {
    super.initState();
    pb = Provider.of<PocketBase>(context, listen: false);
    getFaces(pb);
  }

  void getFaces(PocketBase pb) async {
    if (widget.id == null) return;
    var data =
        await pb.collection("faces").getOne(widget.id!, expand: "owner,tags");
    print(data);
    inspect(data);
    setState(() {
      face = data;
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
    var wf = face;
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
    var wf = face;
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
          child: buildBody(context, theme, wf),
        ));
  }

  Widget buildBody(BuildContext context, ThemeData theme, RecordModel? wf) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [CircularProgressIndicator(strokeCap: StrokeCap.round)],
        ),
      );
    } else if (wf == null) {
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
      return Column(
        children: [
          Stack(
            alignment: Alignment.center, // Aligns both images to the center
            children: [
              Container(
                decoration: const BoxDecoration(
                    color: Colors.black, shape: BoxShape.circle),
                height: 180,
              ),
              Image.network(
                pb.files
                    .getUrl(
                      wf,
                      wf.getListValue<String>('image')[0],
                      thumb: '100x250',
                    )
                    .toString(),
                width: 149,
                //height: 100,
              ),
              // Overlay image (Local Asset Image)
              Image.asset(
                'assets/pixel-watch.png',
                width: 220, // Size for the overlay image
                height: 220,
              ),
            ],
          ),
          const SizedBox(height: 15),
          buildUserInfo(theme, wf),
          const SizedBox(height: 10),
          Text(
            wf.getStringValue("name"),
            style: theme.textTheme.displayMedium,
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              wf.getStringValue("description"),
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 5),
          if (wf.getListValue("tags", List.empty()).isNotEmpty)
            buildTags(theme, wf),
          const SizedBox(height: 5),
          IntrinsicWidth(
            child: FilledButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) => ConfirmDialog(
                          isDestructive: false,
                          icon: Icons.open_in_browser_rounded,
                          title: "Open external link in browser?",
                          description:
                              "Are you sure you want to visit **${wf.getStringValue("url")}**?",
                          onConfirm: () async {
                            launchUrl(Uri.parse(wf.getStringValue("url")));
                            Navigator.of(context).pop();
                          },
                        ),
                    useSafeArea: false);
              },
              child: const Row(
                children: [
                  Icon(Symbols.travel_explore_rounded),
                  SizedBox(width: 10),
                  Text("Download"),
                ],
              ),
            ),
          )
        ],
      );
    }
  }

  Widget buildUserInfo(ThemeData theme, RecordModel wf) {
    final isVerified =
        wf.expand['owner']!.first?.getStringValue("devId", null) != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RawChip(
          onPressed: () {
            context.push("/user/${wf.getStringValue("owner")}");
          },
          label: Row(
            children: [
              Text(
                wf.expand['owner']!.first.getStringValue("displayName"),
                //style: theme.textTheme.titleLarge,
              ),
              if (isVerified)
                const SizedBox(
                  width: 7,
                ),
              if (isVerified)
                Icon(
                  Symbols.verified_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
          avatar: ClipOval(child: getUserImage(wf)),
        )
        // Container(
        //   decoration: BoxDecoration(
        //     color: theme.colorScheme
        //         .surfaceContainerLowest, // Set your desired background color here
        //     shape: BoxShape.circle, // Make the background circular
        //   ),
        //   child: ClipOval(child: getUserImage(wf)),
        // ),
        // const SizedBox(
        //   width: 10,
        // ),
        // Text(
        //   wf.expand['owner']!.first.getStringValue("displayName"),
        //   style: theme.textTheme.titleLarge,
        // ),
        // if (isVerified)
        //   const SizedBox(
        //     width: 7,
        //   ),
        // if (isVerified)
        //   const Icon(
        //     Symbols.verified_rounded,
        //     size: 23,
        //   ),
      ],
    );
  }

  Widget getUserImage(RecordModel wf) {
    var avatarURL =
        wf.expand['owner']!.first?.getStringValue("avatarURL", null);
    var isPrivate = wf.expand['owner']!.first.getBoolValue("private", false);
    final size = 100.toDouble();
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
              return RawChip(
                onPressed: () {
                  context.push(
                      Uri(path: '/search', queryParameters: {'tags': tag.id})
                          .toString());
                },
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
