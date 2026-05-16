import 'dart:io';

import 'package:animetn/core/app/runtimeDatas.dart';
import 'package:animetn/core/commons/enums.dart';
import 'package:animetn/core/database/handler/syncHandler.dart';
import 'package:animetn/ui/models/snackBar.dart';
import 'package:animetn/ui/models/widgets/ContextMenu.dart';
import 'dart:ui';
import 'package:animetn/ui/pages/info.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:animetn/ui/models/transitions.dart';
import 'package:animetn/ui/models/widgets/shimmerCard.dart';

class AnimeCard extends StatefulWidget {
  final int id;
  final String title;
  final String imageUrl;
  final bool ongoing;
  final bool shouldNavigate;
  final bool isAnime;
  final bool isMobile;
  final String? subText;
  final double? rating;
  final void Function()? afterNavigation;

  const AnimeCard({
    super.key,
    required this.id,
    required this.title,
    required this.afterNavigation,
    required this.imageUrl,
    this.isAnime = true,
    this.ongoing = false,
    this.rating = null,
    this.shouldNavigate = true,
    this.subText = null,
    this.isMobile = true,
  });

  @override
  State<AnimeCard> createState() => _AnimeCardState();
}

class _AnimeCardState extends State<AnimeCard> {
  bool isFocused = false;
  bool isPressed = false;
  double width = Platform.isWindows || Platform.isLinux ? 150 : 110;
  double height = Platform.isWindows || Platform.isLinux ? 200 : 160;

  void updateFocus(bool val) {
    return setState(() {
      isFocused = val;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.isMobile ? width : width + 5,
      margin: EdgeInsets.only(left: 5, right: 5),
      child: InkWell(
        onHover: updateFocus,
        onFocusChange: updateFocus,
        onHighlightChanged: (val) {
          setState(() {
            isPressed = val;
          });
        },
        splashFactory: NoSplash.splashFactory,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        overlayColor: WidgetStatePropertyAll(Colors.transparent),
        onTap: () {
          if (!widget.isAnime) return floatingSnackBar("Manga or Novels aren't supported");
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
              widget.afterNavigation?.call();
            });
        },
        child: ContextMenu(
          menuItems: [
            ContextMenuItem(
              icon: Icons.movie_outlined,
              label: "Add to Watching",
              onClick: () {
                SyncHandler()
                    .mutateAnimeList(id: widget.id, status: MediaStatus.CURRENT)
                    .then((_) => floatingSnackBar("Added to watching!"));
              },
            ),
            ContextMenuItem(
              icon: Icons.calendar_today_outlined,
              label: "Add to Planned",
              onClick: () {
                SyncHandler()
                    .mutateAnimeList(id: widget.id, status: MediaStatus.PLANNING)
                    .then((_) => floatingSnackBar("Added to planned!"));
              },
            ),
            ContextMenuItem(
              icon: Icons.done,
              label: "Add to Completed",
              onClick: () {
                SyncHandler()
                    .mutateAnimeList(id: widget.id, status: MediaStatus.COMPLETED)
                    .then((_) => floatingSnackBar("Added to completed!"));
              },
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedScale(
                scale: isPressed ? 0.95 : 1.0,
                duration: Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                child: Stack(
                  children: [
                    AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      curve: Curves.linear,
                      height: widget.isMobile
                          ? height
                          : isFocused
                              ? height * 1.03
                              : height,
                      width: widget.isMobile
                          ? width
                          : isFocused
                              ? width * 1.03
                              : width,
                      margin: EdgeInsets.only(bottom: 10, top: widget.isMobile ? 0 : 5),
                      decoration: BoxDecoration(
                        border: isFocused
                            ? Border.all(
                                color: appTheme.accentColor,
                                strokeAlign: BorderSide.strokeAlignOutside,
                                width: 2,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(isFocused ? 5 : 10),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Hero(
                            tag: 'anime_cover_${widget.id}',
                            child: CachedNetworkImage(
                              imageUrl: widget.imageUrl,
                              fadeInDuration: Duration(milliseconds: 200),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => SkeletonAnimeCard(isMobile: widget.isMobile),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.transparent,
                                  Colors.black.withAlpha(80),
                                ],
                                stops: [0.0, 0.7, 1.0],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 10,
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            bottomRight: Radius.circular(widget.isMobile
                                ? 15
                                : isFocused
                                    ? 4
                                    : 9)),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: appTheme.accentColor.withAlpha(200),
                            ),
                      width: width / 2,
                      padding: EdgeInsets.only(left: 5, right: 5, top: 2, bottom: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star,
                            color: appTheme.onAccent,
                            size: 13,
                          ),
                          Text(
                            " ${widget.rating ?? '??'}",
                            style: TextStyle(
                              fontSize: 14,
                              color: appTheme.onAccent,
                              fontFamily: "NotoSans",
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Text(
                widget.title,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontFamily: "NotoSans",
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isFocused ? appTheme.accentColor : appTheme.textMainColor),
              ),
              if (widget.subText != null)
                Text(
                  widget.subText!,
                  style: TextStyle(fontFamily: "NunitoSans", color: appTheme.textSubColor),
                )
            ],
          ),
        ),
      ),
    );
  }
}
