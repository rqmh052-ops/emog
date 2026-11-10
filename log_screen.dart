import 'package:material_ui/material_ui.dart';
import 'log_output_widget.dart';
import 'root_controller.dart';
import 'strings.dart';
import 'theme.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});
  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final _controller = RootController.instance;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _onChanged() {
    if (mounted) setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (!mounted || !_scroll.hasClients) return;
    _scroll.jumpTo(_scroll.position.maxScrollExtent);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logs = _controller.logs;
    return Scaffold(
      appBar: AppBar(
        title: Text(S.logs),
        actions: [
          IconButton(tooltip: S.copy, onPressed: logs.isEmpty ? null : () => copyLogs(context, logs), icon: const Icon(Icons.copy_rounded)),
          IconButton(
            tooltip: S.clear,
            onPressed: logs.isEmpty ? null : _controller.clearLogs,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: logs.isEmpty
          ? Center(child: Text(S.noLogsYet, style: const TextStyle(color: AppTheme.appMuted)))
          : ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: logs.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  logs[index],
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.5, color: logColor(logs[index])),
                ),
              ),
            ),
    );
  }
}
