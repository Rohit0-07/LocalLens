import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/win.dart';

class WinCard extends StatefulWidget {
  final WinItem win;

  const WinCard({
    super.key,
    required this.win,
  });

  @override
  State<WinCard> createState() => _WinCardState();
}

class _WinCardState extends State<WinCard> {
  double _sliderValue = 0.5;

  void _shareWin(BuildContext context) {
    final deepLink = 'locallens://issue/${widget.win.issueId}';
    Clipboard.setData(ClipboardData(text: deepLink));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deep link copied: $deepLink'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final win = widget.win;
    final theme = Theme.of(context);

    return Card(
      key: Key('winCard_${win.id}'),
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF059669).withValues(alpha: 0.15),
              theme.colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'COMMUNITY WIN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 20),
                  tooltip: 'Share',
                  onPressed: () => _shareWin(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              win.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (win.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                win.description,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),

            // Before / After slider widget
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.black12,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Row(
                            children: [
                              Expanded(
                                flex: (_sliderValue * 100).toInt(),
                                child: Container(
                                  color: Colors.amber.shade900.withValues(alpha: 0.3),
                                  child: Center(
                                    child: win.beforeImageUrl != null
                                        ? Image.network(win.beforeImageUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => _buildPlaceholder('BEFORE'))
                                        : _buildPlaceholder('BEFORE'),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: ((1 - _sliderValue) * 100).toInt(),
                                child: Container(
                                  color: const Color(0xFF059669).withValues(alpha: 0.3),
                                  child: Center(
                                    child: win.afterImageUrl != null
                                        ? Image.network(win.afterImageUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => _buildPlaceholder('AFTER'))
                                        : _buildPlaceholder('AFTER'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: _buildLabel('BEFORE', Colors.amber.shade800),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: _buildLabel('AFTER', const Color(0xFF059669)),
                        ),
                      ],
                    ),
                  ),
                ),
                Slider(
                  value: _sliderValue,
                  onChanged: (val) => setState(() => _sliderValue = val),
                  activeColor: const Color(0xFF059669),
                  inactiveColor: Colors.amber.shade600,
                ),
              ],
            ),

            if (win.contributorCredits.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: win.contributorCredits.map((credit) {
                  return Chip(
                    avatar: const Icon(Icons.person_pin, size: 14),
                    label: Text(
                      credit,
                      style: const TextStyle(fontSize: 11),
                    ),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          label == 'BEFORE' ? Icons.history : Icons.check_circle,
          size: 32,
          color: Colors.grey.shade700,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
