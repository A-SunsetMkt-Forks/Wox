import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:from_css_color/from_css_color.dart';
import 'package:get/get.dart';
import 'package:uuid/v4.dart';
import 'package:wox/components/wox_list_item_view.dart';
import 'package:wox/controllers/wox_list_controller.dart';
import 'package:wox/entity/wox_hotkey.dart';
import 'package:wox/entity/wox_list_item.dart';
import 'package:wox/enums/wox_direction_enum.dart';
import 'package:wox/enums/wox_list_view_type_enum.dart';
import 'package:wox/utils/log.dart';
import 'package:wox/utils/wox_theme_util.dart';

class WoxListView extends StatelessWidget {
  final WoxListController controller;
  final WoxListViewType listViewType;
  final bool showFilter;
  final double maxHeight;

  const WoxListView({
    super.key,
    required this.controller,
    required this.listViewType,
    this.showFilter = true,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: maxHeight,
          ),
          child: Scrollbar(
            thumbVisibility: true,
            controller: controller.scrollController,
            child: Listener(
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) {
                  controller.updateActiveIndexByDirection(
                    const UuidV4().generate(),
                    event.scrollDelta.dy > 0 ? WoxDirectionEnum.WOX_DIRECTION_DOWN.code : WoxDirectionEnum.WOX_DIRECTION_UP.code,
                  );
                }
              },
              child: ListView.builder(
                shrinkWrap: true,
                controller: controller.scrollController,
                physics: const ClampingScrollPhysics(),
                itemCount: controller.items.length,
                itemExtent: WoxThemeUtil.instance.getResultListViewHeightByCount(1),
                itemBuilder: (context, index) {
                  WoxListItem item = controller.items[index];
                  return MouseRegion(
                    onEnter: (_) {
                      if (controller.isMouseMoved && !item.isGroup) {
                        Logger.instance.info(const UuidV4().generate(), "MOUSE: onenter, is mouse moved: ${controller.isMouseMoved}, is group: ${item.isGroup}");
                        controller.updateHoveredIndex(index);
                      }
                    },
                    onHover: (_) {
                      if (!controller.isMouseMoved && !item.isGroup) {
                        Logger.instance.info(const UuidV4().generate(), "MOUSE: onHover, is mouse moved: ${controller.isMouseMoved}, is group: ${item.isGroup}");
                        controller.isMouseMoved = true;
                        controller.updateHoveredIndex(index);
                      }
                    },
                    onExit: (_) {
                      if (!item.isGroup && controller.hoveredIndex.value == index) {
                        controller.clearHoveredResult();
                      }
                    },
                    child: GestureDetector(
                      onTap: () {
                        if (!item.isGroup) {
                          controller.updateActiveIndex(const UuidV4().generate(), index);
                          controller.onItemActive?.call(item);
                        }
                      },
                      onDoubleTap: () {
                        if (!item.isGroup) {
                          controller.onItemExecuted?.call(item);
                        }
                      },
                      child: Obx(
                        () => WoxListItemView(
                          item: item,
                          woxTheme: WoxThemeUtil.instance.currentTheme.value,
                          isActive: controller.activeIndex.value == index,
                          isHovered: controller.hoveredIndex.value == index,
                          listViewType: listViewType,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (showFilter)
          Focus(
            onKeyEvent: (FocusNode node, KeyEvent event) {
              var isAnyModifierPressed = WoxHotkey.isAnyModifierPressed();
              if (!isAnyModifierPressed) {
                if (event is KeyDownEvent) {
                  switch (event.logicalKey) {
                    case LogicalKeyboardKey.escape:
                      controller.onFilterEscPressed?.call();
                      return KeyEventResult.handled;
                    case LogicalKeyboardKey.arrowDown:
                      controller.updateActiveIndexByDirection(
                        const UuidV4().generate(),
                        WoxDirectionEnum.WOX_DIRECTION_DOWN.code,
                      );
                      return KeyEventResult.handled;
                    case LogicalKeyboardKey.arrowUp:
                      controller.updateActiveIndexByDirection(
                        const UuidV4().generate(),
                        WoxDirectionEnum.WOX_DIRECTION_UP.code,
                      );
                      return KeyEventResult.handled;
                    case LogicalKeyboardKey.enter:
                      if (controller.items.isNotEmpty && controller.activeIndex.value < controller.items.length) {
                        controller.onItemExecuted?.call(controller.items[controller.activeIndex.value]);
                      }
                      return KeyEventResult.handled;
                  }
                }

                if (event is KeyRepeatEvent) {
                  switch (event.logicalKey) {
                    case LogicalKeyboardKey.arrowDown:
                      controller.updateActiveIndexByDirection(
                        const UuidV4().generate(),
                        WoxDirectionEnum.WOX_DIRECTION_DOWN.code,
                      );
                      return KeyEventResult.handled;
                    case LogicalKeyboardKey.arrowUp:
                      controller.updateActiveIndexByDirection(
                        const UuidV4().generate(),
                        WoxDirectionEnum.WOX_DIRECTION_UP.code,
                      );
                      return KeyEventResult.handled;
                  }
                }
              }

              var pressedHotkey = WoxHotkey.parseNormalHotkeyFromEvent(event);
              if (pressedHotkey == null) {
                return KeyEventResult.ignored;
              }

              WoxListItem? itemMatchedHotkey = controller.items.firstWhereOrNull((element) {
                if (element.hotkey == null || element.hotkey!.isEmpty) {
                  return false;
                }

                var elementHotkey = WoxHotkey.parseHotkeyFromString(element.hotkey!);
                if (elementHotkey != null && WoxHotkey.equals(elementHotkey.normalHotkey, pressedHotkey)) {
                  return true;
                }

                return false;
              });

              if (itemMatchedHotkey == null) {
                return KeyEventResult.ignored;
              } else {
                controller.onItemExecuted?.call(itemMatchedHotkey);
                return KeyEventResult.handled;
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: SizedBox(
                height: 40.0,
                child: TextField(
                  style: TextStyle(
                    fontSize: 14.0,
                    color: fromCssColor(WoxThemeUtil.instance.currentTheme.value.actionQueryBoxFontColor),
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.only(
                      left: 8,
                      right: 8,
                      top: 20,
                      bottom: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(WoxThemeUtil.instance.currentTheme.value.actionQueryBoxBorderRadius.toDouble()),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: fromCssColor(WoxThemeUtil.instance.currentTheme.value.actionQueryBoxBackgroundColor),
                    hoverColor: Colors.transparent,
                  ),
                  cursorColor: fromCssColor(WoxThemeUtil.instance.currentTheme.value.queryBoxCursorColor),
                  focusNode: controller.filterBoxFocusNode,
                  controller: controller.filterBoxController,
                  onChanged: (value) {
                    controller.updateActiveIndex(const UuidV4().generate(), 0);
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}
