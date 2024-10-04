import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:wear_store/components/loader.dart';
import 'package:wear_store/components/navigation.dart';

class Search extends StatefulWidget {
  final String? text;
  final String? tags;

  const Search({super.key, this.text, this.tags});

  @override
  State<Search> createState() => _SearchPageState();
}

class _SearchPageState extends State<Search> {
  bool isLoading = false;
  List<RecordModel>? faces;
  late PocketBase pb;
  String? textFilter;
  List<String>? tagFilter;
  List<RecordModel> tags = List.empty(growable: true);
  bool isTagsLoading = true;

  @override
  void initState() {
    super.initState();
    pb = Provider.of<PocketBase>(context, listen: false);
    runSearch(pb);
  }

  void runSearch(PocketBase pb) async {
    var filters = List.empty(growable: true);
    var text = textFilter ?? widget.text;
    var tags = tagFilter ?? widget.tags?.split(",");
    if (text != null && text.trim().isNotEmpty) {
      filters.add("(name~\"$text\")");
    }

    if (tags != null && tags.isNotEmpty) {
      filters.add("(tags?~'${tags.join(",")}')");
    }

    print(filters.join("||"));
    print(filters);

    var data = await pb.collection("faces").getFullList(
          filter: filters.isEmpty ? null : "(${filters.join('||')})",
          expand: "owner",
        );
    setState(() {
      faces = data;
      tagFilter = tags;
      textFilter = text;
    });

    await getTags(pb, tags);
  }

  Future<void> getTags(PocketBase pb, List<String>? filterTags) async {
    // Get tags
    const max = 6;
    var fillers = await pb.collection("tags").getFullList(batch: 5);
    if (filterTags != null && filterTags.isNotEmpty) {
      var tagsFiltered = await Future.wait(filterTags
          .map((tag) async => await pb.collection("tags").getOne(tag)));
      if (filterTags.length < max) {
        int fillersNeeded = max - filterTags.length;

        // Add filler tags to make up the difference
        for (int i = 0; i < fillersNeeded; i++) {
          var element = fillers.elementAtOrNull(i);
          if (element != null) {
            tagsFiltered.add(element); // Add custom filler tags
          }
        }
      }

      Map<String, RecordModel> uniqueTags = {
        for (var tag in tagsFiltered) tag.id: tag
      };

      setState(() {
        tags = uniqueTags.values.toList();
        isTagsLoading = false;
      });
    } else {
      setState(() {
        tags = fillers.length >= 5 ? fillers.sublist(0, 5) : fillers;
        isTagsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Scaffold(
        appBar: AppBar(
          title: const Text("Search"),
          leading: InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const Icon(Symbols.arrow_back_rounded),
          ),
        ),
        body: CustomScrollView(
          slivers: [
            // Sliver for the top element (Header)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Search',
                      icon: Icon(Symbols.search_rounded)),
                  onChanged: (text) {
                    setState(() {
                      textFilter = text;
                    });
                    runSearch(pb);
                  },
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: buildTags(theme),
              ),
            ),

            // Sliver for the Grid below
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio:
                    0.85, // Adjust this ratio to make the height more flexible
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
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
                              alignment: Alignment
                                  .center, // Aligns both images to the center
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
                                        face.getListValue<String>('image')[0],
                                        thumb: '100x250',
                                      )
                                      .toString(),
                                  width: 101,
                                ),
                                Image.asset(
                                  'assets/pixel-watch.png',
                                  width: 150, // Size for the overlay image
                                  height: 150,
                                ),
                              ],
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
                  );
                },
                childCount: faces?.length ?? 0,
              ),
            ),
          ],
        ));
  }

  Widget buildTags(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(0), // Outer padding for the entire section
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 100),
            child: Wrap(
              spacing: 10, // Horizontal space between tags
              runSpacing: 10, // Vertical space between lines
              children: isTagsLoading
                  ? List.filled(5, null)
                      .map((e) => LoadingBox(width: 90, height: 40))
                      .toList()
                  : tags!.map((tag) {
                      return RawChip(
                        showCheckmark: true,
                        onPressed: () {
                          setState(() {
                            if (tagFilter != null &&
                                tagFilter!.contains(tag.id)) {
                              tagFilter!.removeWhere((e) => e == tag.id);
                            } else if (tagFilter != null) {
                              tagFilter!.add(tag.id);
                            } else {
                              tagFilter = List.of([tag.id]);
                            }
                          });
                          runSearch(pb);
                        },
                        label: Text(tag.getStringValue("name")),
                        avatar: (tagFilter?.contains(tag.id) ?? false)
                            ? const Icon(Symbols.check_rounded)
                            : const Icon(Symbols.tag_rounded),
                      );
                    }).toList(),
            ),
          )
        ],
      ),
    );
  }
}
