import 'dart:convert';

import 'package:animetn/core/anime/downloader/downloadManager.dart';
import 'package:animetn/core/anime/providers/types.dart';
import 'package:animetn/core/app/logging.dart';
import 'package:animetn/core/app/runtimeDatas.dart';
import 'package:animetn/ui/models/providers/infoProvider.dart';
import 'package:animetn/ui/models/snackBar.dart';
import 'package:animetn/ui/models/sources.dart';
import 'package:flutter/material.dart';

/// Bottom sheet for selecting multiple episodes and downloading them in batch.
class BatchDownloadSheet extends StatefulWidget {
  final InfoProvider provider;

  const BatchDownloadSheet({super.key, required this.provider});

  @override
  State<BatchDownloadSheet> createState() => _BatchDownloadSheetState();
}

class _BatchDownloadSheetState extends State<BatchDownloadSheet> {
  /// Set of selected episode indices (realIndex from epLinks)
  final Set<int> _selectedEpisodes = {};

  /// Whether batch download is in progress
  bool _isDownloading = false;

  /// Current episode being processed during batch download
  int _currentProcessingIndex = -1;

  /// Total episodes to process
  int _totalToProcess = 0;

  /// Number of episodes processed so far
  int _processedCount = 0;

  /// Range picker controllers
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  /// Preferred quality setting
  String _preferredQuality = "auto"; // "auto" = first available, or specific like "1080p", "720p", etc.

  final List<String> _qualityOptions = ["auto", "1080p", "720p", "480p", "360p"];

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _selectAll() {
    setState(() {
      for (int i = 0; i < widget.provider.epLinks.length; i++) {
        _selectedEpisodes.add(i);
      }
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedEpisodes.clear();
    });
  }

  void _selectRange() {
    final from = int.tryParse(_fromController.text);
    final to = int.tryParse(_toController.text);
    if (from == null || to == null || from < 1 || to < from) {
      floatingSnackBar("Invalid range! Enter valid episode numbers.");
      return;
    }
    setState(() {
      for (int i = from - 1; i < to && i < widget.provider.epLinks.length; i++) {
        _selectedEpisodes.add(i);
      }
    });
    floatingSnackBar("Selected EP $from–$to");
  }

  void _invertSelection() {
    setState(() {
      final allIndices = List.generate(widget.provider.epLinks.length, (i) => i).toSet();
      final inverted = allIndices.difference(_selectedEpisodes);
      _selectedEpisodes.clear();
      _selectedEpisodes.addAll(inverted);
    });
  }

  Future<void> _startBatchDownload() async {
    if (_selectedEpisodes.isEmpty) {
      floatingSnackBar("Select at least one episode!");
      return;
    }

    if (!widget.provider.selectedSource.supportDownloads) {
      floatingSnackBar("This source doesn't support downloading!");
      return;
    }

    setState(() {
      _isDownloading = true;
      _totalToProcess = _selectedEpisodes.length;
      _processedCount = 0;
    });

    final sortedEpisodes = _selectedEpisodes.toList()..sort();
    final titles = widget.provider.data.title;
    final defaultTitle = titles['english'] ?? titles['romaji'] ?? "";
    final title = (currentUserSettings?.nativeTitle ?? false) 
        ? titles['native'] ?? defaultTitle 
        : defaultTitle;
    final src = SourceManager.instance;

    for (final episodeIndex in sortedEpisodes) {
      if (!mounted) return;

      setState(() {
        _currentProcessingIndex = episodeIndex;
        _processedCount++;
      });

      try {
        final epLink = widget.provider.epLinks[episodeIndex];
        List<VideoStream> streams = [];
        List<Map<String, String>> qualities = [];
        bool fetchDone = false;

        // Try download sources first, fallback to regular streams
        try {
          await src.getDownloadSources(
            widget.provider.selectedSource.identifier,
            epLink.episodeLink,
            dub: widget.provider.preferDubs,
            metadata: epLink.metadata,
            (list, finished) {
              streams = streams + list;
              for (final element in list) {
                qualities.add({
                  'url': element.url,
                  'server': "${element.server}  ${element.backup ? "- backup" : ""}",
                  'quality': "${element.quality}",
                  'headers': jsonEncode(element.customHeaders ?? {}),
                  'subtitle': element.subtitle ?? "",
                });
              }
              if (finished) fetchDone = true;
            },
          );
        } catch (err) {
          if (err is UnimplementedError) {
            // Fallback to regular streams
            await src.getStreams(
              widget.provider.selectedSource.identifier,
              epLink.episodeLink,
              dub: widget.provider.preferDubs,
              metadata: epLink.metadata,
              (list, finished) {
                streams = streams + list;
                for (final element in list) {
                  if (element.quality == "multi-quality" || element.quality == "auto") {
                    // For multi-quality, we'll just use the URL directly
                    qualities.add({
                      'url': element.url,
                      'server': "${element.server} ${element.backup ? "- backup" : ""}",
                      'quality': element.quality,
                      'headers': jsonEncode(element.customHeaders ?? {}),
                      'subtitle': element.subtitle ?? "",
                    });
                  } else {
                    qualities.add({
                      'url': element.url,
                      'server': "${element.server} ${element.backup ? "- backup" : ""}",
                      'quality': "${element.quality}",
                      'headers': jsonEncode(element.customHeaders ?? {}),
                      'subtitle': element.subtitle ?? "",
                    });
                  }
                }
                if (finished) fetchDone = true;
              },
            );
          } else {
            Logs.downloader.log("Batch download: Failed to get streams for EP ${episodeIndex + 1}: $err");
            continue; // Skip this episode
          }
        }

        // Wait briefly for async callbacks to complete
        int waitCount = 0;
        while (!fetchDone && waitCount < 30) {
          await Future.delayed(Duration(milliseconds: 500));
          waitCount++;
        }

        if (qualities.isEmpty) {
          Logs.downloader.log("Batch download: No qualities found for EP ${episodeIndex + 1}");
          continue;
        }

        // Pick the best matching quality
        final selectedQuality = _pickBestQuality(qualities);
        if (selectedQuality == null) {
          Logs.downloader.log("Batch download: Could not pick quality for EP ${episodeIndex + 1}");
          continue;
        }

        String? subs = selectedQuality['subtitle'];
        subs = (subs?.isEmpty ?? true) ? null : subs;
        final mapped = jsonDecode(selectedQuality['headers'] ?? "{}");
        Map<String, String> headers = Map.from(mapped).cast();

        final episodeNum = "${episodeIndex + 1}";
        final fileName = "$title EP ${episodeNum.padLeft(2, '0')}";
        final streamLink = selectedQuality['url']!;

        await DownloadManager().addDownloadTask(
          streamLink,
          fileName,
          customHeaders: headers,
          subtitleUrl: subs,
        ).onError((err, st) {
          Logs.downloader.log("Batch download error for EP ${episodeIndex + 1}: $err");
        });

        // Small delay between downloads to avoid overwhelming the system
        await Future.delayed(Duration(milliseconds: 300));
      } catch (err) {
        Logs.downloader.log("Batch download: Error processing EP ${episodeIndex + 1}: $err");
        continue;
      }
    }

    if (mounted) {
      setState(() {
        _isDownloading = false;
      });
      floatingSnackBar("Batch download started for ${sortedEpisodes.length} episodes!");
      Navigator.of(context).pop();
    }
  }

  Map<String, String>? _pickBestQuality(List<Map<String, String>> qualities) {
    if (qualities.isEmpty) return null;
    if (_preferredQuality == "auto") return qualities.first;

    // Try to find matching quality
    for (final q in qualities) {
      final qStr = (q['quality'] ?? "").toLowerCase();
      if (qStr.contains(_preferredQuality.toLowerCase())) {
        return q;
      }
    }

    // Fallback to first available
    return qualities.first;
  }

  @override
  Widget build(BuildContext context) {
    final totalEpisodes = widget.provider.epLinks.length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: _isDownloading ? _buildProgressView() : _buildSelectionView(totalEpisodes),
    );
  }

  Widget _buildProgressView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 20),
        Icon(
          Icons.downloading_rounded,
          size: 48,
          color: appTheme.accentColor,
        ),
        SizedBox(height: 16),
        Text(
          "Processing Downloads...",
          style: TextStyle(
            fontFamily: "Rubik",
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: appTheme.textMainColor,
          ),
        ),
        SizedBox(height: 8),
        Text(
          "EP ${_currentProcessingIndex + 1} • $_processedCount / $_totalToProcess",
          style: TextStyle(
            fontFamily: "NotoSans",
            fontSize: 16,
            color: appTheme.textSubColor,
          ),
        ),
        SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: _totalToProcess > 0 ? _processedCount / _totalToProcess : 0,
            backgroundColor: appTheme.backgroundSubColor,
            color: appTheme.accentColor,
            minHeight: 8,
          ),
        ),
        SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSelectionView(int totalEpisodes) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          "Batch Download",
          style: TextStyle(
            color: appTheme.textMainColor,
            fontFamily: "Rubik",
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          "${_selectedEpisodes.length} of $totalEpisodes episodes selected",
          style: TextStyle(
            color: appTheme.textSubColor,
            fontFamily: "NotoSans",
            fontSize: 14,
          ),
        ),
        SizedBox(height: 16),

        // Range Picker
        _buildRangePicker(totalEpisodes),
        SizedBox(height: 12),

        // Quick Actions Row
        _buildQuickActions(),
        SizedBox(height: 12),

        // Quality Picker
        _buildQualityPicker(),
        SizedBox(height: 12),

        // Episode Grid (scrollable)
        Flexible(
          child: _buildEpisodeGrid(totalEpisodes),
        ),
        SizedBox(height: 16),

        // Download Button
        _buildDownloadButton(),
      ],
    );
  }

  Widget _buildRangePicker(int totalEpisodes) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appTheme.backgroundSubColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.swap_horiz_rounded, color: appTheme.accentColor, size: 20),
          SizedBox(width: 8),
          Text(
            "Range:",
            style: TextStyle(
              fontFamily: "Rubik",
              fontWeight: FontWeight.bold,
              color: appTheme.textMainColor,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: _fromController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: appTheme.textMainColor, fontFamily: "NotoSans", fontSize: 14),
                decoration: InputDecoration(
                  hintText: "1",
                  hintStyle: TextStyle(color: appTheme.textSubColor),
                  filled: true,
                  fillColor: appTheme.backgroundColor,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text("–", style: TextStyle(color: appTheme.textMainColor, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: _toController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: appTheme.textMainColor, fontFamily: "NotoSans", fontSize: 14),
                decoration: InputDecoration(
                  hintText: "$totalEpisodes",
                  hintStyle: TextStyle(color: appTheme.textSubColor),
                  filled: true,
                  fillColor: appTheme.backgroundColor,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: _selectRange,
              style: ElevatedButton.styleFrom(
                backgroundColor: appTheme.accentColor,
                foregroundColor: appTheme.onAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text("Select", style: TextStyle(fontFamily: "Rubik", fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _actionChip("Select All", Icons.select_all_rounded, _selectAll),
        SizedBox(width: 8),
        _actionChip("Deselect", Icons.deselect_rounded, _deselectAll),
        SizedBox(width: 8),
        _actionChip("Invert", Icons.flip_rounded, _invertSelection),
      ],
    );
  }

  Widget _actionChip(String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: appTheme.backgroundSubColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: appTheme.accentColor),
                SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: "NotoSans",
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: appTheme.textMainColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQualityPicker() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: appTheme.backgroundSubColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.high_quality_rounded, color: appTheme.accentColor, size: 20),
          SizedBox(width: 8),
          Text(
            "Quality:",
            style: TextStyle(
              fontFamily: "Rubik",
              fontWeight: FontWeight.bold,
              color: appTheme.textMainColor,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _qualityOptions.length,
                itemBuilder: (context, index) {
                  final option = _qualityOptions[index];
                  final isSelected = _preferredQuality == option;
                  return Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(
                        option,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: "NotoSans",
                          fontWeight: FontWeight.bold,
                          color: isSelected ? appTheme.onAccent : appTheme.textMainColor,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: appTheme.accentColor,
                      backgroundColor: appTheme.backgroundColor,
                      side: BorderSide.none,
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _preferredQuality = option);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeGrid(int totalEpisodes) {
    return Container(
      decoration: BoxDecoration(
        color: appTheme.backgroundSubColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(8),
      child: GridView.builder(
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).orientation == Orientation.portrait ? 6 : 10,
          childAspectRatio: 1.0,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: totalEpisodes,
        itemBuilder: (context, index) {
          final isSelected = _selectedEpisodes.contains(index);
          final isWatched = index < widget.provider.watched;
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedEpisodes.remove(index);
                } else {
                  _selectedEpisodes.add(index);
                }
              });
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected
                    ? appTheme.accentColor
                    : appTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? null
                    : Border.all(
                        color: appTheme.textSubColor.withAlpha(40),
                        width: 1,
                      ),
              ),
              alignment: Alignment.center,
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      "${index + 1}",
                      style: TextStyle(
                        fontFamily: "NotoSans",
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isSelected
                            ? appTheme.onAccent
                            : isWatched
                                ? appTheme.textSubColor
                                : appTheme.textMainColor,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 12,
                        color: appTheme.onAccent,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDownloadButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _selectedEpisodes.isEmpty ? null : _startBatchDownload,
        style: ElevatedButton.styleFrom(
          backgroundColor: appTheme.accentColor,
          foregroundColor: appTheme.onAccent,
          disabledBackgroundColor: appTheme.backgroundSubColor,
          disabledForegroundColor: appTheme.textSubColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        icon: Icon(Icons.download_rounded, size: 22),
        label: Text(
          _selectedEpisodes.isEmpty
              ? "Select Episodes"
              : "Download ${_selectedEpisodes.length} Episode${_selectedEpisodes.length > 1 ? 's' : ''}",
          style: TextStyle(
            fontFamily: "Rubik",
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
