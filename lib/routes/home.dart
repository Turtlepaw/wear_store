import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:wear_store/components/navigation.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomePageState();
}

class _HomePageState extends State<Home> {
  bool isLoading = false;
  List<RecordModel>? faces;
  late PocketBase pb;

  @override
  @override
  void initState() {
    super.initState();
    pb = Provider.of<PocketBase>(context, listen: false);
    getFaces(pb);
  }

  void getFaces(PocketBase pb) async {
    var data = await pb.collection("faces").getFullList(expand: "owner");
    setState(() {
      faces = data;
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
          )
        ],
      ),
      body: Center(
          child: GridView.builder(
        padding: EdgeInsets.only(top: 10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio:
              0.8, // Adjust this ratio to make the height more flexible
        ),
        itemCount: faces?.length ?? 0,
        itemBuilder: (context, index) {
          final face = faces![index];
          return Card.outlined(
              child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () {
              context.push("/watchface/${face.id}");
            },
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  Stack(
                    alignment:
                        Alignment.center, // Aligns both images to the center
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                            color: Colors.black, shape: BoxShape.circle),
                        height: 120,
                      ),
                      Image.network(
                        pb.files
                            .getUrl(
                              face,
                              face.getListValue<String>('image')[0],
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
                      if (face.expand['owner']!.first
                              ?.getStringValue("devId", null) !=
                          null)
                        const Icon(
                          Symbols.verified_rounded,
                          size: 22,
                        ),
                      if (face.expand['owner']!.first
                              ?.getStringValue("devId", null) !=
                          null)
                        const SizedBox(
                          width: 7,
                        ),
                      Text(
                        face.expand['owner']!.first
                            .getStringValue("displayName"),
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  Text(
                    face.getStringValue("name"),
                    style: theme.textTheme.headlineMedium,
                  )
                ],
              ),
            ),
          ));
        },
      )),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}
