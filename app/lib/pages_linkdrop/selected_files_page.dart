import 'dart:convert';

import 'package:common/model/file_type.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/cross_file.dart';
import 'package:localsend_app/provider/selection/selected_sending_files_provider.dart';
import 'package:localsend_app/theme/linkdrop_theme.dart';
import 'package:localsend_app/util/file_size_helper.dart';
import 'package:localsend_app/util/native/open_file.dart';
import 'package:localsend_app/widget/dialogs/message_input_dialog.dart';
import 'package:localsend_app/widget/file_thumbnail.dart';
import 'package:refena_flutter/refena_flutter.dart';

/// 已选文件页面
///
/// 显示用户选择的待发送文件列表
/// 支持编辑文本消息、删除单个文件或清空所有文件
class SelectedFilesPage extends StatelessWidget {
  const SelectedFilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ref = context.ref;
    final selectedFiles = ref.watch(selectedSendingFilesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.sendTab.selection.title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : LinkDropColors.zinc900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.sendTab.selection.size(size: selectedFiles.fold(0, (prev, curr) => prev + curr.size).asReadableFileSize),
                        style: TextStyle(
                          color: LinkDropColors.zinc500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selectedFiles.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.redux(selectedSendingFilesProvider).dispatch(ClearSelectionAction());
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(t.selectedFilesPage.deleteAll),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LinkDropColors.red500,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: selectedFiles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 64,
                          color: LinkDropColors.zinc500,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          t.sendTab.selection.files(files: 0),
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
                    itemCount: selectedFiles.length,
                    itemBuilder: (context, index) {
                      final file = selectedFiles[index];

                      final String? message;
                      if (file.fileType == FileType.text && file.bytes != null) {
                        message = utf8.decode(file.bytes!);
                      } else {
                        message = null;
                      }

                      return _FileCard(
                        file: file,
                        message: message,
                        isDark: isDark,
                        onTap: file.path != null ? () async => openFile(context, file.fileType, file.path!) : null,
                        onEdit: file.fileType == FileType.text && file.bytes != null
                            ? () async {
                                final result = await showDialog<String>(
                                  context: context,
                                  builder: (_) => MessageInputDialog(initialText: message),
                                );
                                if (result != null) {
                                  ref.redux(selectedSendingFilesProvider).dispatch(UpdateMessageAction(message: result, index: index));
                                }
                              }
                            : null,
                        onDelete: () {
                          final currCount = ref.read(selectedSendingFilesProvider).length;
                          ref.redux(selectedSendingFilesProvider).dispatch(RemoveSelectedFileAction(index));
                          if (currCount == 1) {
                            Navigator.of(context).pop();
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// 文件卡片组件
///
/// 显示单个文件的缩略图、名称、大小和操作按钮
class _FileCard extends StatelessWidget {
  final CrossFile file;
  final String? message;
  final bool isDark;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;

  const _FileCard({
    required this.file,
    required this.message,
    required this.isDark,
    required this.onTap,
    required this.onEdit,
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
        children: [
          SmartFileThumbnail.fromCrossFile(file),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message != null ? '"${message!.replaceAll('\n', ' ')}"' : file.name,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : LinkDropColors.zinc900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  file.size.asReadableFileSize,
                  style: TextStyle(
                    fontSize: 13,
                    color: LinkDropColors.zinc500,
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded),
              color: LinkDropColors.zinc500,
            ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            color: LinkDropColors.red500,
          ),
        ],
      ),
    );
  }
}
