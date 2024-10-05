import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';

class WatchFaceGrid extends StatelessWidget {
  final List<RecordModel>? faces;
  const WatchFaceGrid(this.faces);

  @override
  Widget build(BuildContext context) {
    var pb = Provider.of<PocketBase>(context);
    var theme = Theme.of(context);
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
            _getCrossAxisCount(context), // Responsive cross-axis count
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio:
            _getChildAspectRatio(context), // Responsive aspect ratio
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final face = faces![index];
          var isVerified = face.expand.containsKey("owner")
              ? (face.expand['owner']!.first?.getStringValue("devId", null) !=
                  null)
              : false;
          return Center(
              child: Card.outlined(
                  child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () {
              context.push("/watchface/${face.id}");
            },
            child: Padding(
                padding: const EdgeInsets.all(15),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 150, // Set fixed height for image area
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
                                    face.getListValue<String>('image')[0],
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
                      if (face.expand.containsKey("owner"))
                        const SizedBox(height: 15),
                      if (face.expand.containsKey("owner"))
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              face.expand['owner']!.first
                                  .getStringValue("displayName", "Unknown"),
                              style: theme.textTheme.titleMedium,
                            ),
                            if (isVerified) const SizedBox(width: 7),
                            if (isVerified)
                              const Tooltip(
                                message: "Verified Account",
                                child: Icon(
                                  Symbols.verified_rounded,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 5),
                      Text(
                        face.getStringValue("name"),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                )),
          )));
        },
        childCount: faces?.length ?? 0,
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) {
      return 6; // For larger screens
    } else if (screenWidth > 800) {
      return 3; // For medium screens (e.g. tablets)
    } else {
      return 2; // For smaller screens (e.g. phones)
    }
  }

  double _getChildAspectRatio(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) {
      return 1.1; // Aspect ratio for larger screens
    } else if (screenWidth > 800) {
      return 0.9; // Aspect ratio for medium screens
    } else {
      return 0.80; // Aspect ratio for smaller screens
    }
  }
}
