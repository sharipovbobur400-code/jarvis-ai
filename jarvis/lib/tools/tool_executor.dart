import 'application_tool.dart';
import 'browser_tool.dart';
import 'file_tool.dart';
import 'terminal_tool.dart';
import 'media_tool.dart';
import 'system_tool.dart';
import 'tool_result.dart';

/// Central tool registry + executor. The AI brain dispatches a JSON action
/// here; each tool returns a ToolResult (section 28).
class ToolExecutor {
  final application = ApplicationTool();
  final browser = BrowserTool();
  final files = FileTool();
  final terminal = TerminalTool();
  final media = MediaTool();
  final system = SystemTool();

  Future<ToolResult> execute(
      String action, Map<String, dynamic> args,
      {required bool confirmed}) async {
    switch (action) {
      case 'open_application':
        return application.openApplication(args['application'] ?? args['app'] ?? '');
      case 'close_application':
        return application.closeApplication(args['application'] ?? '');
      case 'open_browser':
        return browser.openBrowser(args['url']);
      case 'open_url':
        return browser.openUrl(args['url'] ?? '');
      case 'search_web':
        return browser.searchWeb(args['query'] ?? '');
      case 'open_youtube':
        return browser.openYoutube();
      case 'play_youtube':
        return browser.playYoutube(args['query'] ?? args['song'] ?? '');
      case 'open_vscode':
        return browser.openVsCode(args['path']);
      case 'create_file':
        return files.createFile(args['path'] ?? '', content: args['content'] ?? '');
      case 'write_file':
        return files.writeFile(args['path'] ?? '', args['content'] ?? '');
      case 'read_file':
        return files.readFile(args['path'] ?? '');
      case 'create_folder':
        return files.createFolder(args['path'] ?? '');
      case 'open_folder':
        return files.openPath(args['path'] ?? '');
      case 'list_directory':
        return files.listDirectory(args['path'] ?? '.');
      case 'delete_path':
        if (!confirmed) return _needConfirm('delete_path');
        return files.deletePath(args['path'] ?? '');
      case 'create_project':
        final r = files.createProject(args['name'] ?? 'project',
            parent: args['parent'] ?? '');
        if (r.success && (args['open_vscode'] == true)) {
          browser.openVsCode(r.data['path']);
        }
        return r;
      case 'run_terminal_command':
        final needs = terminal.requiresConfirmation(args['command'] ?? '');
        if (needs && !confirmed) return _needConfirm('run_terminal_command');
        return terminal.run(args['command'] ?? '', confirmed: confirmed);
      case 'pause_media':
        return media.pause();
      case 'resume_media':
        return media.resume();
      case 'stop_media':
        return media.stop();
      case 'next_track':
        return media.next();
      case 'previous_track':
        return media.previous();
      case 'volume_up':
        return media.volumeUp();
      case 'volume_down':
        return media.volumeDown();
      case 'mute':
        return media.mute();
      case 'change_volume':
        return system.changeVolume(
            int.tryParse('${args['percent'] ?? 50}') ?? 50);
      case 'get_system_info':
        return system.getSystemInfo();
      case 'get_cpu_usage':
        return system.getCpuUsage();
      case 'get_ram_usage':
        return system.getRamUsage();
      case 'get_network_status':
        return system.getNetworkStatus();
      case 'get_time':
        return system.getTime();
      default:
        return ToolResult.fail(action, 'Unknown tool: $action');
    }
  }

  ToolResult _needConfirm(String tool) => ToolResult(
        success: false,
        tool: tool,
        error: 'confirmation_required',
        message:
            "Bu amal tizimga ta'sir qilishi mumkin. Davom etaymi?",
      );

  /// JSON catalog injected into the AI prompt (section 27).
  String get toolCatalog => '''
- open_application {application: string}
- close_application {application: string}
- open_browser {url?: string}
- open_url {url: string}
- search_web {query: string}
- open_youtube {}
- play_youtube {query: string}   // search & play a song on YouTube
- open_vscode {path?: string}
- create_file {path: string, content: string}
- write_file {path: string, content: string}
- read_file {path: string}
- create_folder {path: string}
- open_folder {path: string}
- list_directory {path: string}
- delete_path {path: string}     // DESTRUCTIVE
- create_project {name: string, parent?: string, open_vscode?: bool}
- run_terminal_command {command: string}   // destructive commands need confirmation
- pause_media / resume_media / stop_media / next_track / previous_track {}
- volume_up / volume_down / mute {}
- change_volume {percent: int}
- get_system_info {} / get_cpu_usage {} / get_ram_usage {} / get_network_status {} / get_time {}
''';
}
