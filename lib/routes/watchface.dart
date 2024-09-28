import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
    var data = await pb.collection("faces").getOne(widget.id!, expand: "owner");
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
          leading: GestureDetector(
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
                height: 120,
              ),
              Image.network(
                pb.files
                    .getUrl(
                      wf,
                      wf.getListValue<String>('image')[0],
                      thumb: '100x250',
                    )
                    .toString(),
                width: 101,
                //height: 100,
              ),
              // Overlay image (Local Asset Image)
              Image.asset(
                'assets/pixel-watch.png',
                width: 150, // Size for the overlay image
                height: 150,
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (wf.expand['owner']!.first?.getStringValue("devId", null) !=
                  null)
                const Icon(
                  Symbols.verified_rounded,
                  size: 25,
                ),
              if (wf.expand['owner']!.first?.getStringValue("devId", null) !=
                  null)
                const SizedBox(
                  width: 7,
                ),
              Text(
                wf.expand['owner']!.first.getStringValue("displayName"),
                style: theme.textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            wf.getStringValue("name"),
            style: theme.textTheme.displayMedium,
          ),
          const SizedBox(height: 10),
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
}
