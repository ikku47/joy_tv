import 'package:flutter/material.dart';
import '../../models/iptv_channel.dart';
import '../../theme/app_theme.dart';

class PlaylistPickerSheet extends StatelessWidget {
  final List<IPTVPlaylistSource> sources;
  final String? selectedId;
  final ValueChanged<IPTVPlaylistSource> onSelect;

  const PlaylistPickerSheet({
    super.key,
    required this.sources,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Playlists',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: sources.length,
                itemBuilder: (context, index) {
                  final source = sources[index];
                  final selected = source.id == selectedId;
                  return ListTile(
                    dense: true,
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primaryColor.withOpacity(0.15)
                            : Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.playlist_play_rounded,
                        size: 18,
                        color: selected ? AppTheme.primaryColor : Colors.white.withOpacity(0.5),
                      ),
                    ),
                    title: Text(
                      source.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected ? AppTheme.primaryColor : Colors.white.withOpacity(0.85),
                      ),
                    ),
                    trailing: selected
                        ? Icon(Icons.check_rounded, size: 16, color: AppTheme.primaryColor)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      onSelect(source);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
