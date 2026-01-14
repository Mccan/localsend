import 'dart:io';

import 'package:common/model/device.dart';
import 'package:common/model/session_status.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/persistence/receive_history_entry.dart';
import 'package:localsend_app/pages/receive_session_page.dart';
import 'package:localsend_app/provider/receive_history_provider.dart';
import 'package:localsend_app/theme/linkdrop_theme.dart';
import 'package:localsend_app/util/file_size_helper.dart';
import 'package:localsend_app/util/native/open_file.dart';
import 'package:localsend_app/util/native/open_folder.dart';
import 'package:localsend_app/widget/dialogs/file_info_dialog.dart';
import 'package:localsend_app/widget/dialogs/history_clear_dialog.dart';
import 'package:localsend_app/widget/file_thumbnail.dart';
import 'package:path/path.dart' as path;
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

/// 接收历史页面
///
/// 显示已接收文件的完整历史记录
/// 支持打开文件、查看文件夹、查看文件信息和从历史记录中删除
class ReceiveHistoryPage extends StatelessWidget {
  const ReceiveHistoryPage({super.key});

  Future<void> _openFile(
    BuildContext context,
    ReceiveHistoryEntry entry,
    Dispatcher<ReceiveHistoryService, List<ReceiveHistoryEntry>> dispatcher,
  ) async {
    if (entry.path != null) {
      await openFile(
        context,
        entry.fileType,
        entry.path!,
        onDeleteTap: () => dispatcher.dispatchAsync(RemoveHistoryEntryAction(entry.id)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = context.watch(receiveHistoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(32, MediaQuery.of(context).padding.top + 16, 32, 16),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: isDark ? Colors.white : LinkDropColors.zinc900,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    t.receiveHistoryPage.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : LinkDropColors.zinc900,
                    ),
                  ),
                ),
                if (entries.isNotEmpty)
                  IconButton(
                    onPressed: () async {
                      final result = await showDialog(
                        context: context,
                        builder: (_) => const HistoryClearDialog(),
                      );

                      if (result == true) {
                        await context.redux(receiveHistoryProvider).dispatchAsync(RemoveAllHistoryEntriesAction());
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: t.receiveHistoryPage.deleteHistory,
                    color: LinkDropColors.red500,
                  ),
              ],
            ),
          ),

          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 64,
                          color: LinkDropColors.zinc500,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          t.receiveHistoryPage.empty,
                          style: TextStyle(
                            fontSize: 18,
                            color: LinkDropColors.zinc500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return _HistoryEntryCard(
                        entry: entry,
                        isDark: isDark,
                        onTap: entry.path != null || entry.isMessage
                            ? () async {
                                if (entry.isMessage) {
                                  final vm = ViewProvider((ref) {
                                    return ReceivePageVm(
                                      status: SessionStatus.waiting,
                                      sender: Device(
                                        signalingId: null,
                                        ip: '0.0.0.0',
                                        version: '1.0.0',
                                        port: 8080,
                                        https: false,
                                        fingerprint: 'fingerprint',
                                        alias: entry.senderAlias,
                                        deviceModel: 'deviceModel',
                                        deviceType: DeviceType.web,
                                        download: true,
                                        discoveryMethods: const {},
                                      ),
                                      showSenderInfo: false,
                                      files: [],
                                      message: entry.fileName,
                                      onAccept: () {},
                                      onDecline: () {},
                                      onClose: () {},
                                    );
                                  });

                                  context.push(() => ReceiveSessionPage(vm));
                                  return;
                                }

                                await _openFile(context, entry, context.redux(receiveHistoryProvider));
                              }
                            : null,
                        onOpen: entry.path != null ? () => _openFile(context, entry, context.redux(receiveHistoryProvider)) : null,
                        onShowInFolder: entry.path != null
                            ? () => openFolder(
                                folderPath: File(entry.path!).parent.path,
                                fileName: path.basename(entry.path!),
                              )
                            : null,
                        onInfo: () => showDialog(
                          context: context,
                          builder: (_) => FileInfoDialog(entry: entry),
                        ),
                        onDelete: () => context.redux(receiveHistoryProvider).dispatchAsync(RemoveHistoryEntryAction(entry.id)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// 历史记录条目卡片组件
///
/// 显示单个历史记录条目的详细信息
class _HistoryEntryCard extends StatelessWidget {
  final ReceiveHistoryEntry entry;
  final bool isDark;
  final VoidCallback? onTap;
  final VoidCallback? onOpen;
  final VoidCallback? onShowInFolder;
  final VoidCallback? onInfo;
  final VoidCallback onDelete;

  const _HistoryEntryCard({
    required this.entry,
    required this.isDark,
    required this.onTap,
    required this.onOpen,
    required this.onShowInFolder,
    required this.onInfo,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? LinkDropColors.zinc900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilePathThumbnail(
            path: entry.path,
            fileType: entry.fileType,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.fileName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : LinkDropColors.zinc900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.timestampString} - ${entry.fileSize.asReadableFileSize} - ${entry.senderAlias}',
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 13,
                    color: LinkDropColors.zinc500,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<_EntryOption>(
            onSelected: (_EntryOption item) async {
              switch (item) {
                case _EntryOption.open:
                  onOpen?.call();
                  break;
                case _EntryOption.showInFolder:
                  onShowInFolder?.call();
                  break;
                case _EntryOption.info:
                  onInfo?.call();
                  break;
                case _EntryOption.delete:
                  onDelete.call();
                  break;
              }
            },
            icon: Icon(
              Icons.more_vert_rounded,
              color: LinkDropColors.zinc500,
            ),
            itemBuilder: (BuildContext context) {
              return (entry.path != null ? _EntryOption.values : [_EntryOption.info, _EntryOption.delete]).map((e) {
                return PopupMenuItem<_EntryOption>(
                  value: e,
                  child: Row(
                    children: [
                      Icon(
                        e.icon,
                        size: 20,
                        color: e == _EntryOption.delete ? LinkDropColors.red500 : null,
                      ),
                      const SizedBox(width: 12),
                      Text(e.label),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
    );
  }
}

enum _EntryOption {
  open,
  showInFolder,
  info,
  delete;

  String get label {
    return switch (this) {
      _EntryOption.open => t.receiveHistoryPage.entryActions.open,
      _EntryOption.showInFolder => t.receiveHistoryPage.entryActions.showInFolder,
      _EntryOption.info => t.receiveHistoryPage.entryActions.info,
      _EntryOption.delete => t.receiveHistoryPage.entryActions.deleteFromHistory,
    };
  }

  IconData get icon {
    return switch (this) {
      _EntryOption.open => Icons.open_in_new_rounded,
      _EntryOption.showInFolder => Icons.folder_open_rounded,
      _EntryOption.info => Icons.info_outline_rounded,
      _EntryOption.delete => Icons.delete_outline_rounded,
    };
  }
}
