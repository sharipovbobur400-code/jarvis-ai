import 'system_tool.dart';
import 'tool_result.dart';

/// Media control via system media keys (works with Spotify, Chrome YouTube,
/// Windows player). All play/pause/next/prev/volume commands (section 11).
class MediaTool {
  final SystemTool _system = SystemTool();

  ToolResult play() => _press('play_pause');
  ToolResult pause() => _press('play_pause');
  ToolResult resume() => _press('play_pause');
  ToolResult stop() => _press('stop');
  ToolResult next() => _press('next');
  ToolResult previous() => _press('previous');
  ToolResult volumeUp() => _press('volume_up');
  ToolResult volumeDown() => _press('volume_down');
  ToolResult mute() => _press('mute');

  ToolResult _press(String key) {
    final r = _system.sendMediaKey(key);
    return r.success
        ? ToolResult.ok('media_control', 'Media: $key')
        : r;
  }
}
