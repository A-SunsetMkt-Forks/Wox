import 'dart:convert';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:uuid/v4.dart';
import 'package:wox/api/wox_api.dart';
import 'package:wox/components/wox_image_view.dart';
import 'package:wox/components/wox_tooltip_view.dart';
import 'package:wox/entity/setting/wox_plugin_setting_select.dart';
import 'package:wox/entity/setting/wox_plugin_setting_table.dart';
import 'package:wox/entity/wox_ai.dart';
import 'package:wox/entity/wox_image.dart';
import 'package:flutter/material.dart' as material;

import 'wox_setting_plugin_item_view.dart';
import 'wox_setting_plugin_table_update_view.dart';

class WoxSettingPluginTable extends WoxSettingPluginItem {
  final PluginSettingValueTable item;
  static const String rowUniqueIdKey = "wox_table_row_id";
  final double tableWidth;
  final operationWidth = 75.0;
  final columnSpacing = 10.0;
  final columnTooltipWidth = 20.0;
  final bool readonly;
  final Future<String?> Function(Map<String, dynamic> rowValues)? onUpdateValidate;

  const WoxSettingPluginTable({
    super.key,
    required this.item,
    required super.value,
    required super.onUpdate,
    this.tableWidth = 760.0,
    this.readonly = false,
    this.onUpdateValidate,
  });

  double calculateColumnWidthForZeroWidth(PluginSettingValueTableColumn column) {
    // if there are multiple columns which have width set to 0, we will set the max width to 100 for each column
    // if there is only one column which has width set to 0, we will set the max width to 600 - (other columns width)
    // if all columns have width set to 0, we will set the max width to 100 for each column
    var zeroWidthColumnCount = 0;
    var totalWidth = 0.0;
    var totalColumnTooltipWidth = 0.0;
    for (var element in item.columns) {
      if (element.hideInTable) {
        continue;
      }

      totalWidth += element.width + columnSpacing;
      if (element.width == 0) {
        zeroWidthColumnCount++;
      }
      if (element.tooltip.isNotEmpty) {
        totalColumnTooltipWidth += columnTooltipWidth;
      }
    }
    if (zeroWidthColumnCount == 1) {
      return tableWidth - totalWidth - (operationWidth + columnSpacing) - totalColumnTooltipWidth;
    }

    return 100.0;
  }

  Widget columnWidth({required PluginSettingValueTableColumn column, required bool isHeader, required bool isOperation, required Widget child}) {
    var width = column.width;
    if (isOperation) {
      width = operationWidth.toInt();
    }
    if (width == 0) {
      width = calculateColumnWidthForZeroWidth(column).toInt();
    }
    if (column.tooltip.isNotEmpty) {
      width += columnTooltipWidth.toInt();
    }

    return SizedBox(
      width: width.toDouble(),
      child: child,
    );
  }

  Widget buildHeaderCell(PluginSettingValueTableColumn column) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          tr(column.label),
          style: const TextStyle(
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (column.tooltip != "")
          WoxTooltipView(
            tooltip: tr(column.tooltip),
            paddingRight: 0,
          ),
      ],
    );
  }

  Widget buildRowCell(PluginSettingValueTableColumn column, Map<String, dynamic> row) {
    var value = row[column.key] ?? "";

    if (column.type == PluginSettingValueType.pluginSettingValueTableColumnTypeText) {
      return columnWidth(
        column: column,
        isHeader: false,
        isOperation: false,
        child: Text(
          value,
          style: const TextStyle(
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }
    if (column.type == PluginSettingValueType.pluginSettingValueTableColumnTypeDirPath) {
      return columnWidth(
        column: column,
        isHeader: false,
        isOperation: false,
        child: Text(
          value,
          style: const TextStyle(
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }
    if (column.type == PluginSettingValueType.pluginSettingValueTableColumnTypeHotkey) {
      return columnWidth(
        column: column,
        isHeader: false,
        isOperation: false,
        child: Text(
          value,
          style: const TextStyle(
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }
    if (column.type == PluginSettingValueType.pluginSettingValueTableColumnTypeCheckbox) {
      var isChecked = false;
      if (value is bool) {
        isChecked = value;
      } else if (value is String) {
        isChecked = value == "true";
      }
      return Row(
        children: [
          isChecked ? const Icon(material.Icons.check_box) : const Icon(material.Icons.check_box_outline_blank),
        ],
      );
    }
    if (column.type == PluginSettingValueType.pluginSettingValueTableColumnTypeTextList) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var txt in value)
            columnWidth(
              column: column,
              isHeader: false,
              isOperation: false,
              child: Text(
                "${(value as List<dynamic>).length == 1 ? "" : "-"} $txt",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      );
    }
    if (column.type == PluginSettingValueType.pluginSettingValueTableColumnTypeWoxImage) {
      if (value == "") {
        return const SizedBox.shrink();
      }

      final woxImage = WoxImage.fromJson(value);
      return Row(
        children: [
          WoxImageView(woxImage: woxImage, width: 24, height: 24),
        ],
      );
    }
    if (column.type == PluginSettingValueType.pluginSettingValueTableColumnTypeSelect) {
      var selectOption = column.selectOptions.firstWhere((element) => element.value == value, orElse: () => PluginSettingValueSelectOption.fromJson(<String, dynamic>{}));
      return columnWidth(
        column: column,
        isHeader: false,
        isOperation: false,
        child: Text(
          selectOption.label,
          style: const TextStyle(
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }
    if (column.type == PluginSettingValueType.pluginSettingValueTableColumnTypeSelectAIModel) {
      var model = AIModel.fromJson(json.decode(value));
      return columnWidth(
        column: column,
        isHeader: false,
        isOperation: false,
        child: Text(
          "${model.provider} - ${model.name}",
          style: const TextStyle(
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }
    if (column.type == PluginSettingValueType.pluginSettingValueTableColumnTypeAIModelStatus) {
      var providerName = row["Name"] ?? "";
      var modelName = row["ApiKey"] ?? "";
      var host = row["Host"] ?? "";
      
      return FutureBuilder<String>(
        future: WoxApi.instance.pingAIModel(providerName, modelName, host),
        builder: (context, snapshot) {
          return columnWidth(
            column: column,
            isHeader: false,
            isOperation: false,
            child: snapshot.connectionState == ConnectionState.waiting
                ? const Icon(material.Icons.circle, color: material.Colors.grey)
                : snapshot.error != null
                    ? material.Tooltip(
                        message: snapshot.error?.toString() ?? "",
                        child: const Icon(material.Icons.circle, color: material.Colors.red),
                      )
                    : const Icon(material.Icons.circle, color: material.Colors.green),
          );
        },
      );
    }

    return Text("Unknown column type: ${column.type}");
  }

  material.DataCell buildOperationCell(context, row, rows) {
    return material.DataCell(
      SizedBox(
        width: operationWidth,
        child: Row(
          children: [
            HyperlinkButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return WoxSettingPluginTableUpdate(
                        item: item,
                        row: row,
                        onUpdateValidate: onUpdateValidate,
                        onUpdate: (key, value) async {
                          var rowsJson = getSetting(key);
                          if (rowsJson == "") {
                            rowsJson = "[]";
                          }
                          for (var i = 0; i < rows.length; i++) {
                            if (rows[i][rowUniqueIdKey] == value[rowUniqueIdKey]) {
                              rows[i] = value;
                              break;
                            }
                          }

                          //remove the unique key
                          rows.forEach((element) {
                            element.remove(rowUniqueIdKey);
                          });

                          updateConfig(key, json.encode(rows));
                        },
                      );
                    });
              },
              child: const Icon(material.Icons.edit),
            ),
            HyperlinkButton(
              onPressed: () {
                //confirm delete
                showDialog(
                    context: context,
                    builder: (context) {
                      return ContentDialog(
                        content: Text(tr("ui_delete_row_confirm")),
                        actions: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Button(
                                child: Text(tr("ui_cancel")),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const SizedBox(width: 16),
                              FilledButton(
                                child: Text(tr("ui_delete")),
                                onPressed: () {
                                  Navigator.pop(context);

                                  var rowsJson = getSetting(item.key);
                                  if (rowsJson == "") {
                                    rowsJson = "[]";
                                  }
                                  rows.removeWhere((element) => element[rowUniqueIdKey] == row[rowUniqueIdKey]);

                                  //remove the unique key
                                  rows.forEach((element) {
                                    element.remove(rowUniqueIdKey);
                                  });
                                  updateConfig(item.key, json.encode(rows));
                                },
                              ),
                            ],
                          )
                        ],
                      );
                    });
              },
              child: const Icon(material.Icons.delete),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildEmptyTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        material.DataTable(
          columnSpacing: columnSpacing,
          horizontalMargin: 5,
          clipBehavior: Clip.hardEdge,
          headingRowHeight: 40,
          headingRowColor: material.MaterialStateProperty.resolveWith((states) => material.Colors.grey[200]),
          border: TableBorder.all(color: material.Colors.grey[300]!),
          columns: [
            for (var column in item.columns)
              material.DataColumn(
                label: columnWidth(
                  column: column,
                  isHeader: false,
                  isOperation: false,
                  child: Text(
                    column.label,
                    style: const TextStyle(
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            material.DataColumn(
              label: columnWidth(
                column: PluginSettingValueTableColumn.fromJson(<String, dynamic>{
                  "Key": "Operation",
                  "Label": tr("operation"),
                  "Tooltip": "",
                  "Width": operationWidth.toInt(),
                  "Type": PluginSettingValueType.pluginSettingValueTableColumnTypeText,
                  "TextMaxLines": 1,
                }),
                isHeader: false,
                isOperation: true,
                child: Text(
                  tr("operation"),
                  style: const TextStyle(
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
          rows: const [],
        ),
        const Center(
          child: Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text("No data"),
          ),
        ),
      ],
    );
  }

  Widget buildTable(BuildContext context) {
    var rowsJson = getSetting(item.key);
    if (rowsJson == "") {
      return buildEmptyTable();
    }
    var rows = json.decode(rowsJson);
    if (rows == null || rows.isEmpty) {
      return buildEmptyTable();
    }

    //give each row a unique key
    for (var row in rows) {
      row[rowUniqueIdKey] = const UuidV4().generate();
    }

    //sort the rows if needed
    if (item.sortColumnKey.isNotEmpty) {
      rows.sort((a, b) {
        var aValue = a[item.sortColumnKey] ?? "";
        var bValue = b[item.sortColumnKey] ?? "";
        if (item.sortOrder == "asc") {
          return aValue.toString().compareTo(bValue.toString());
        } else {
          return bValue.toString().compareTo(aValue.toString());
        }
      });
    }

    return material.DataTable(
      columnSpacing: columnSpacing,
      horizontalMargin: 5,
      headingRowHeight: 40,
      headingRowColor: material.MaterialStateProperty.resolveWith((states) => material.Colors.grey[200]),
      border: TableBorder.all(color: material.Colors.grey[300]!),
      columns: [
        for (var column in item.columns)
          if (!column.hideInTable)
            material.DataColumn(
              label: columnWidth(
                column: column,
                isHeader: true,
                isOperation: false,
                child: buildHeaderCell(column),
              ),
            ),
        if (!readonly)
          material.DataColumn(
            label: columnWidth(
              column: PluginSettingValueTableColumn.fromJson(<String, dynamic>{
                "Key": "Operation",
                "Label": tr("ui_operation"),
                "Tooltip": "",
                "Width": operationWidth.toInt(),
                "Type": PluginSettingValueType.pluginSettingValueTableColumnTypeText,
                "TextMaxLines": 1,
              }),
              isHeader: true,
              isOperation: true,
              child: Text(
                tr("ui_operation"),
                style: const TextStyle(
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
      ],
      rows: [
        for (var row in rows)
          material.DataRow(
            cells: [
              for (var column in item.columns)
                if (!column.hideInTable)
                  material.DataCell(
                    buildRowCell(column, row),
                  ),
              if (!readonly)
                // operation cell
                buildOperationCell(context, row, rows),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: SizedBox(
        width: tableWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Text(
                        item.title,
                      ),
                      if (item.tooltip != "") WoxTooltipView(tooltip: item.tooltip),
                    ],
                  ),
                ),
                if (!readonly)
                  HyperlinkButton(
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return WoxSettingPluginTableUpdate(
                                item: item,
                                row: const {},
                                onUpdate: (key, row) {
                                  var rowsJson = getSetting(key);
                                  if (rowsJson == "") {
                                    rowsJson = "[]";
                                  }
                                  var rows = json.decode(rowsJson);
                                  rows.add(row);
                                  //remove the unique key
                                  rows.forEach((element) {
                                    element.remove(rowUniqueIdKey);
                                  });

                                  updateConfig(key, json.encode(rows));
                                },
                              );
                            });
                      },
                      child: Row(
                        children: [
                          const Icon(material.Icons.add),
                          Text(tr("ui_add")),
                        ],
                      )),
              ],
            ),
            buildTable(context),
          ],
        ),
      ),
    );
  }
}
