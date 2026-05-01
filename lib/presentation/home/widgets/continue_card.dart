import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/media_item.dart';
import '../../common/smart_network_image.dart';

class ContinueCard extends StatefulWidget {
  const ContinueCard({required this.item, required this.onTap, super.key});

  final MediaItem item;
  final VoidCallback onTap;

  @override
  State<ContinueCard> createState() => _ContinueCardState();
}

class _ContinueCardState extends State<ContinueCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final artworkUrl = widget.item.backdropUrl ?? widget.item.posterUrl;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: _hovered ? 1.025 : 1,
          child: Container(
            width: 260,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _hovered ? AppColors.gold : Colors.white10,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (artworkUrl != null)
                  SmartNetworkImage(
                    imageUrl: artworkUrl,
                    fit: BoxFit.cover,
                    fallback: _ContinueFallback(item: widget.item),
                  )
                else
                  _ContinueFallback(item: widget.item),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xEE000000), Color(0x33000000)],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'SYNC',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.item.seasonEpisodeLabel ?? 'Resume playback',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(widget.item.progress.clamp(0.0, 1.0) * 100).round()}%',
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: widget.item.progress.clamp(0.0, 1.0),
                          minHeight: 3,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContinueFallback extends StatelessWidget {
  const _ContinueFallback({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    final colors = [
      const [Color(0xFF3A1A2E), Color(0xFF111111)],
      const [Color(0xFF123D3A), Color(0xFF0A0A0B)],
      const [Color(0xFF451313), Color(0xFF111827)],
      const [Color(0xFF172554), Color(0xFF09090B)],
    ][item.tmdbId.abs() % 4];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(
            item.title.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.text.withValues(alpha: 0.42),
              fontSize: 22,
              height: 0.96,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
