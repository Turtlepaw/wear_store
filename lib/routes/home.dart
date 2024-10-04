import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:wear_store/components/grid.dart';
import 'package:wear_store/routes/watchface.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomePageState();
}

class _HomePageState extends State<Home> {
  bool isLoading = false;
  List<RecordModel>? faces;
  List<RecordModel>? collections;
  late PocketBase pb;

  @override
  void initState() {
    super.initState();
    pb = Provider.of<PocketBase>(context, listen: false);
    getFaces(pb);
  }

  void getFaces(PocketBase pb) async {
    var data = await pb.collection("faces").getFullList(expand: "owner");
    var collectionsData =
        await pb.collection("collections").getFullList(expand: "watchfaces");
    setState(() {
      faces = data;
      collections = collectionsData;
    });
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Browse Watch Faces"),
        actions: [
          Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Tooltip(
                message: "Search",
                child: InkWell(
                  borderRadius: BorderRadius.circular(100),
                  onTap: () {
                    context.push("/search");
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(Symbols.search_rounded),
                  ),
                ),
              ))
        ],
      ),
      body: Center(
        child: CustomScrollView(
          slivers: [
            ...(collections ?? List.empty()).map((c) => SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 20, bottom: 10, top: 10),
                        child: Text(
                          c.getStringValue("name"),
                          style: theme.textTheme.headlineMedium,
                        ),
                      ),
                      SizedBox(
                        height: 250, // Height for the carousel
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal, // No snapping
                          itemCount: c.expand['watchfaces']!.length,
                          itemBuilder: (context, index) {
                            var face = c.expand['watchfaces']![index];
                            return Container(
                              width: 200, // Fixed width for each card
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              child: Card.outlined(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(5),
                                  onTap: () {
                                    context.push("/watchface/${face.id}");
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(15),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        SizedBox(
                                          height:
                                              150, // Fixed height for the image area
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Container(
                                                decoration: const BoxDecoration(
                                                  color: Colors.black,
                                                  shape: BoxShape.circle,
                                                ),
                                                height: 120,
                                              ),
                                              Image.network(
                                                pb.files
                                                    .getUrl(
                                                      face,
                                                      face.getListValue<String>(
                                                          'image')[0],
                                                      thumb: '100x250',
                                                    )
                                                    .toString(),
                                                width: 101,
                                              ),
                                              Image.asset(
                                                'assets/pixel-watch.png',
                                                width: 150,
                                                height: 150,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 15),
                                        Text(
                                          face.getStringValue("name"),
                                          style: theme.textTheme.headlineMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                )),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "All Watch Faces",
                  style: theme.textTheme.headlineLarge,
                ),
              ),
            ),
            WatchFaceGrid(faces),
          ],
        ),
      ),
    );
  }
}
