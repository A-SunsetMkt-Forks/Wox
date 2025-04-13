import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:from_css_color/from_css_color.dart';
import 'package:get/get.dart';
import 'package:uuid/v4.dart';
import 'package:wox/components/wox_image_view.dart';
import 'package:wox/components/wox_list_view.dart';
import 'package:wox/controllers/wox_ai_chat_controller.dart';
import 'package:wox/entity/wox_ai.dart';
import 'package:wox/entity/wox_hotkey.dart';
import 'package:wox/entity/wox_preview.dart';
import 'package:wox/entity/wox_theme.dart';
import 'package:wox/enums/wox_ai_conversation_role_enum.dart';
import 'package:wox/enums/wox_list_view_type_enum.dart';
import 'package:wox/utils/log.dart';
import 'package:wox/utils/wox_theme_util.dart';

class WoxAIChatView extends GetView<WoxAIChatController> {
  const WoxAIChatView({super.key});

  WoxTheme get woxTheme => WoxThemeUtil.instance.currentTheme.value;

  @override
  Widget build(BuildContext context) {
    if (LoggerSwitch.enablePaintLog) Logger.instance.debug(const UuidV4().generate(), "repaint: chat view");

    return Stack(
      children: [
        Column(
          children: [
            // AI Model Selection
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: InkWell(
                onTap: () {
                  controller.showModelsPanel();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: fromCssColor(woxTheme.queryBoxBackgroundColor),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: fromCssColor(woxTheme.previewPropertyTitleColor).withAlpha(25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.smart_toy_outlined,
                        size: 20,
                        color: fromCssColor(woxTheme.previewPropertyTitleColor),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Obx(() => Text(
                              controller.aiChatData.value.model.value.name.isEmpty ? "请选择模型" : controller.aiChatData.value.model.value.name,
                              style: TextStyle(
                                color: fromCssColor(woxTheme.previewPropertyTitleColor),
                                fontSize: 14,
                              ),
                            )),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: fromCssColor(woxTheme.previewPropertyTitleColor),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Messages list
            Expanded(
              child: SingleChildScrollView(
                controller: controller.aiChatScrollController,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Obx(() => Column(
                      children: controller.aiChatData.value.conversations.map((message) => _buildMessageItem(message)).toList(),
                    )),
              ),
            ),
            // Input box and controls area
            Focus(
              onKeyEvent: (FocusNode node, KeyEvent event) {
                if (event is KeyDownEvent) {
                  switch (event.logicalKey) {
                    case LogicalKeyboardKey.escape:
                      controller.launcherController.focusQueryBox();
                      return KeyEventResult.handled;
                    case LogicalKeyboardKey.enter:
                      controller.sendMessage();
                      return KeyEventResult.handled;
                  }
                }

                var pressedHotkey = WoxHotkey.parseNormalHotkeyFromEvent(event);
                if (pressedHotkey == null) {
                  return KeyEventResult.ignored;
                }

                // Show chat select panel on Cmd+J
                if (controller.launcherController.isActionHotkey(pressedHotkey)) {
                  controller.showChatSelectPanel();
                  return KeyEventResult.handled;
                }

                return KeyEventResult.ignored;
              },
              // Wrap the input area content in a Column to place the expandable section above
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  // New outer Column
                  mainAxisSize: MainAxisSize.min, // Important for Column height
                  children: [
                    const SizedBox.shrink(),
                    Container(
                      decoration: BoxDecoration(
                        color: fromCssColor(woxTheme.queryBoxBackgroundColor),
                        borderRadius: BorderRadius.circular(woxTheme.queryBoxBorderRadius.toDouble()),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: controller.textController,
                            focusNode: controller.aiChatFocusNode,
                            decoration: InputDecoration(
                              hintText: '在这里输入消息，按下 ← 发送',
                              hintStyle: TextStyle(color: fromCssColor(woxTheme.previewPropertyTitleColor)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            style: TextStyle(
                              fontSize: 14,
                              color: fromCssColor(woxTheme.queryBoxFontColor),
                            ),
                          ),
                          // Input Box Toolbar (Send button, Tool icon)
                          Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: fromCssColor(woxTheme.previewPropertyTitleColor).withAlpha(25),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Tool configuration button - opens chat select panel
                                Obx(() => IconButton(
                                      tooltip: 'Configure Tool Usage',
                                      icon: Icon(Icons.build,
                                          size: 18,
                                          color: controller.selectedTools.isNotEmpty
                                              ? Theme.of(context).colorScheme.primary
                                              : fromCssColor(woxTheme.previewPropertyTitleColor).withAlpha(128)),
                                      color: fromCssColor(woxTheme.previewPropertyTitleColor),
                                      onPressed: () {
                                        controller.showToolsPanel();
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                    )),
                                const Spacer(),
                                // Send button container (unchanged)
                                InkWell(
                                  onTap: () => controller.sendMessage(),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: fromCssColor(woxTheme.actionItemActiveBackgroundColor).withAlpha(25),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.keyboard_return,
                                          size: 14,
                                          color: fromCssColor(woxTheme.previewPropertyTitleColor),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '发送',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: fromCssColor(woxTheme.previewPropertyTitleColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Obx(() => controller.isShowChatSelectPanel.value ? _buildChatSelectPanel(context) : const SizedBox.shrink()),
      ],
    );
  }

  Widget _buildChatSelectPanel(BuildContext context) {
    return Positioned(
      right: 10,
      bottom: 10,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(woxTheme.actionQueryBoxBorderRadius.toDouble()),
        child: Container(
          padding: EdgeInsets.only(
            top: woxTheme.actionContainerPaddingTop.toDouble(),
            bottom: woxTheme.actionContainerPaddingBottom.toDouble(),
            left: woxTheme.actionContainerPaddingLeft.toDouble(),
            right: woxTheme.actionContainerPaddingRight.toDouble(),
          ),
          decoration: BoxDecoration(
            color: fromCssColor(woxTheme.actionContainerBackgroundColor),
            borderRadius: BorderRadius.circular(woxTheme.actionQueryBoxBorderRadius.toDouble()),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                      controller.currentChatSelectCategory.isEmpty ? "Chat Options" : (controller.currentChatSelectCategory.value == "models" ? "Select Model" : "Configure Tools"),
                      style: TextStyle(color: fromCssColor(woxTheme.actionContainerHeaderFontColor), fontSize: 16.0),
                    )),
                const Divider(),
                // List of items using WoxListView
                WoxListView<ChatSelectItem>(
                  controller: controller.chatSelectListController,
                  listViewType: WoxListViewTypeEnum.WOX_LIST_VIEW_TYPE_CHAT.code,
                  showFilter: true,
                  maxHeight: 350,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageItem(WoxPreviewChatConversation message) {
    final isUser = message.role == WoxAIChatConversationRoleEnum.WOX_AIChat_CONVERSATION_ROLE_USER.value;
    final backgroundColor = isUser ? fromCssColor(woxTheme.resultItemActiveBackgroundColor) : fromCssColor(woxTheme.actionContainerBackgroundColor);
    final alignment = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(message),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: alignment,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text content
                      MarkdownBody(
                        data: message.text,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            color: fromCssColor(
                                isUser ? WoxThemeUtil.instance.currentTheme.value.resultItemActiveTitleColor : WoxThemeUtil.instance.currentTheme.value.resultItemTitleColor),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      // Images if any
                      if (message.images.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: message.images
                              .map((image) => ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 200, // Consider making this adaptive
                                      child: WoxImageView(woxImage: image),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4),
                  child: Text(
                    controller.formatTimestamp(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: fromCssColor(WoxThemeUtil.instance.currentTheme.value.resultItemSubTitleColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isUser) _buildAvatar(message),
        ],
      ),
    );
  }

  Widget _buildAvatar(WoxPreviewChatConversation message) {
    final isUser = message.role == WoxAIChatConversationRoleEnum.WOX_AIChat_CONVERSATION_ROLE_USER.value;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: fromCssColor(isUser ? woxTheme.actionItemActiveBackgroundColor : woxTheme.resultItemActiveBackgroundColor),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          isUser ? 'U' : 'A', // Consider using user/model icons later
          style: TextStyle(
            color: fromCssColor(isUser ? woxTheme.actionItemActiveFontColor : woxTheme.resultItemActiveTitleColor),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
