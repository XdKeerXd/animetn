import 'package:animetn/core/app/runtimeDatas.dart';
import 'package:flutter/material.dart';

/// A shimmer/skeleton loading effect widget that replaces plain CircularProgressIndicator
/// with a premium-looking animated placeholder.
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                appTheme.backgroundSubColor,
                appTheme.backgroundSubColor.withAlpha(100),
                appTheme.backgroundSubColor,
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
              begin: Alignment(-1.0, -0.3),
              end: Alignment(1.0, 0.3),
            ).createShader(bounds);
          },
          child: child!,
        );
      },
      child: widget.child,
    );
  }
}

/// Skeleton card that mimics the AnimeCard shape while loading
class SkeletonAnimeCard extends StatelessWidget {
  final bool isMobile;

  const SkeletonAnimeCard({super.key, this.isMobile = true});

  @override
  Widget build(BuildContext context) {
    final width = isMobile ? 110.0 : 155.0;
    final height = isMobile ? 160.0 : 200.0;

    return Container(
      width: width,
      margin: EdgeInsets.only(left: 5, right: 5),
      child: ShimmerEffect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: height,
              width: width,
              decoration: BoxDecoration(
                color: appTheme.backgroundSubColor,
                borderRadius: BorderRadius.circular(isMobile ? 20 : 10),
              ),
            ),
            SizedBox(height: 10),
            Container(
              height: 12,
              width: width * 0.8,
              decoration: BoxDecoration(
                color: appTheme.backgroundSubColor,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            SizedBox(height: 6),
            Container(
              height: 12,
              width: width * 0.5,
              decoration: BoxDecoration(
                color: appTheme.backgroundSubColor,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton card for extended anime card (continue watching style)
class SkeletonAnimeCardExtended extends StatelessWidget {
  const SkeletonAnimeCardExtended({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 305,
      height: 150,
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: appTheme.backgroundSubColor,
      ),
      child: ShimmerEffect(
        child: Row(
          children: [
            Container(
              width: 100,
              height: 130,
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: appTheme.backgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 8, top: 16, right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 140,
                      decoration: BoxDecoration(
                        color: appTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: 100,
                      decoration: BoxDecoration(
                        color: appTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    Spacer(),
                    Container(
                      height: 24,
                      width: 60,
                      margin: EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: appTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for episode tiles
class SkeletonEpisodeTile extends StatelessWidget {
  const SkeletonEpisodeTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      margin: EdgeInsets.only(top: 10, left: 10, right: 10),
      decoration: BoxDecoration(
        color: appTheme.backgroundSubColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ShimmerEffect(
        child: Row(
          children: [
            Container(
              width: 140,
              height: 100,
              decoration: BoxDecoration(
                color: appTheme.backgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 14,
                      width: 120,
                      decoration: BoxDecoration(
                        color: appTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: 60,
                      decoration: BoxDecoration(
                        color: appTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
