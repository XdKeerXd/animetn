import 'dart:ui';

import 'package:animetn/ui/models/transitions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:animetn/core/app/runtimeDatas.dart';
import 'package:animetn/ui/models/snackBar.dart';
import 'package:animetn/ui/pages/info.dart';

class AnimeCardExtended extends StatefulWidget {
  final int id;
  final String title;
  final String imageUrl;
  final double rating;
  final bool shouldNavigate;
  final bool isAnime;
  final void Function()? afterNavigation;
  final int? watchedEpisodeCount;
  final int? totalEpisodes;
  final String? bannerImageUrl;
  final Color? surfaceColor;
  final double? customWidth;
  final double? lastWatchDuration;

  const AnimeCardExtended({
    super.key,
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.rating,
    this.shouldNavigate = true,
    this.isAnime = true,
    this.afterNavigation,
    this.watchedEpisodeCount,
    this.totalEpisodes,
    this.bannerImageUrl,
    this.customWidth,
    this.surfaceColor,
    this.lastWatchDuration,
  });

  @override
  State<AnimeCardExtended> createState() => _AnimeCardExtendedState();
}

class _AnimeCardExtendedState extends State<AnimeCardExtended> {
  bool isPressed = false;
  bool isFocused = false;

  void updateFocus(bool val) {
    setState(() {
      isFocused = val;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isPressed ? 0.96 : 1.0,
      duration: Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: appTheme.backgroundColor,
        border: isFocused
            ? Border.all(
                color: appTheme.accentColor,
                width: 2,
              )
            : null,
      ),
      clipBehavior: Clip.hardEdge,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          focusColor: Colors.transparent,
          onHover: updateFocus,
          onFocusChange: updateFocus,
          onHighlightChanged: (val) {
            setState(() {
              isPressed = val;
            });
          },
          onTap: () async {
            if (!widget.isAnime) return floatingSnackBar("Mangas/Novels arent supported");
            if (widget.shouldNavigate)
              Navigator.of(context)
                  .push(
                FadeScaleRoute(
                  page: Info(
                    id: widget.id,
                  ),
                ),
              )
                  .then((val) {
                if (widget.afterNavigation != null) widget.afterNavigation?.call();
              });
          },
          child: Container(
            width: widget.customWidth ?? 305,
            height: 150,
            color: widget.surfaceColor,
            child: Stack(
              children: [
                if (widget.bannerImageUrl != null)
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: Opacity(
                      opacity: 0.5,
                      child: CachedNetworkImage(
                        imageUrl: widget.bannerImageUrl!,
                        errorWidget: (context, url, error) {
                          return Image.asset("lib/assets/images/broken_heart.png");
                        },
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                Container(
                  padding: EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(50),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            )
                          ],
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Hero(
                          tag: 'anime_cover_${widget.id}',
                          child: CachedNetworkImage(
                            imageUrl: widget.imageUrl,
                          fit: BoxFit.cover,
                          fadeInDuration: Duration(milliseconds: 200),
                          fadeInCurve: Curves.easeIn,
                          width: 100,
                          height: 130,
                          errorWidget: (context, url, error) {
                          return Image.asset("lib/assets/images/broken_heart.png");
                        },
                        ),
                      ),
                      ),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.only(left: 15, top: 10),
                          // width: 175,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: TextStyle(
                                  color: appTheme.textMainColor,
                                  fontFamily: "NotoSans",
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                              Container(
                                margin: EdgeInsets.only(bottom: 15),
                                child: Row(
                                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                        child: Container(
                                          width: 52,
                                          padding: EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                              color: appTheme.accentColor.withValues(alpha: 0.6),
                                              borderRadius: BorderRadius.circular(10)),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.star,
                                                color: appTheme.onAccent,
                                                // (currentUserSettings?.darkMode ?? true) ? appTheme.backgroundColor : appTheme.textMainColor,
                                                size: 15,
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(left: 3),
                                                child: Text(
                                                  "${widget.rating}",
                                                  style: TextStyle(
                                                    color: appTheme.onAccent,
                                                    //  (currentUserSettings?.darkMode ?? true) ? appTheme.backgroundColor : appTheme.textMainColor,
                                                    fontFamily: "NotoSans",
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 2,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // if (widget.totalEpisodes != null || widget.watchedEpisodeCount != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 13, right: 13),
                                      child: Text(
                                        '•',
                                        style: TextStyle(fontSize: 17, color: Theme.of(context).colorScheme.secondary),
                                      ),
                                    ),
                                    Container(
                                      child: Row(
                                        children: [
                                          Text(
                                            "${widget.watchedEpisodeCount ?? "~"} ",
                                            style: TextStyle(
                                              fontFamily: "NunitoSans",
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                          Text(
                                            "/ ${widget.totalEpisodes ?? "??"}",
                                            style: TextStyle(
                                              fontFamily: "NunitoSans",
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                if (widget.lastWatchDuration != null && widget.lastWatchDuration! > 0)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: widget.lastWatchDuration,
                      color: appTheme.accentColor,
                      backgroundColor: Colors.transparent,
                      minHeight: 3,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
