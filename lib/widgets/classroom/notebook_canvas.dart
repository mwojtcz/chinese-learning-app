import 'package:flutter/material.dart';
import '../../models/app_language.dart';
import '../../models/classroom_lesson.dart';
import '../../services/lesson_dictionary.dart';
import 'lesson_block_card.dart';
import 'lesson_preview.dart';
import 'notebook_editing_controller.dart';

class NotebookCanvas extends StatefulWidget {
  final ClassroomLesson page;
  final AppLanguage language;
  final LessonDictionary dictionary;
  final bool editable;
  final bool showPinyin;
  final ValueChanged<LessonBlock> onChanged;
  final ValueChanged<String> onDelete;
  final ValueChanged<LessonBlock> onInsert;
  final NotebookEditingController? editingController;
  final bool showTranslations;
  const NotebookCanvas(
      {super.key,
      required this.page,
      required this.language,
      required this.dictionary,
      required this.editable,
      required this.showPinyin,
      required this.onChanged,
      required this.onDelete,
      required this.onInsert,
      this.showTranslations = true,
      this.editingController});
  @override
  State<NotebookCanvas> createState() => _NotebookCanvasState();
}

class _NotebookCanvasState extends State<NotebookCanvas> {
  String? selected;
  String? inserted;
  LessonBlock? draft;
  String t(String pl, String zh, [String? hant]) =>
      widget.language.text(pl, zh, hant);

  void _drag(LessonBlock block, Offset delta, {bool resize = false}) {
    final source = draft?.id == block.id ? draft! : block;
    setState(() => draft = source.placed(
          x: resize
              ? source.x
              : (source.x + delta.dx / 794).clamp(0.0, 1 - source.width),
          y: resize
              ? source.y
              : (source.y + delta.dy / 1123).clamp(0.0, 1 - source.height),
          width: resize
              ? (source.width + delta.dx / 794).clamp(0.08, 1 - source.x)
              : source.width,
          height: resize
              ? (source.height + delta.dy / 1123).clamp(0.04, 1 - source.y)
              : source.height,
        ));
  }

  void _commit() {
    if (draft != null) widget.onChanged(draft!);
    setState(() => draft = null);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, constraints) {
      final scale = constraints.maxWidth / 794;
      return SizedBox(
          height: 1123 * scale,
          child: FittedBox(
            alignment: Alignment.topLeft,
            fit: BoxFit.fill,
            child: SizedBox(
              width: 794,
              height: 1123,
              child: CustomPaint(
                painter: _PaperPainter(
                    widget.page.paperStyle, colors.outlineVariant),
                child: Stack(clipBehavior: Clip.hardEdge, children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: widget.editable
                          ? (details) {
                              final point = details.localPosition;
                              if (point.dy < 90 || point.dy > 1098) return;
                              final row = ((point.dy - 90) / 60).floor();
                              final block = LessonBlock(
                                  x: 0.07,
                                  y: (90 + row * 60) / 1123,
                                  width: 0.86,
                                  height: 0.04);
                              setState(() => inserted = block.id);
                              widget.onInsert(block);
                            }
                          : null,
                    ),
                  ),
                  Positioned(
                      left: 55,
                      top: 28,
                      right: 55,
                      child: Text(widget.page.title,
                          style: TextStyle(
                              fontSize: 23,
                              color: colors.onSurface,
                              fontWeight: FontWeight.w600))),
                  for (final original in widget.page.blocks)
                    _element(draft?.id == original.id ? draft! : original,
                        colors, scale),
                ]),
              ),
            ),
          ));
    });
  }

  Widget _element(LessonBlock block, ColorScheme colors, double scale) {
    if (block.kind != LessonBlockKind.image) {
      return Positioned(
          key: ValueKey(block.id),
          left: block.x * 794,
          top: block.y * 1123,
          width: block.width * 794,
          child: widget.editable
              ? LessonBlockCard(
                  key: ValueKey('text:${block.id}'),
                  block: block,
                  language: widget.language,
                  dictionary: widget.dictionary,
                  editable: true,
                  presentation: false,
                  showPinyin: widget.showPinyin,
                  paper: true,
                  autofocus: inserted == block.id,
                  editingController: widget.editingController,
                  showTranslations: widget.showTranslations,
                  onChanged: widget.onChanged,
                  onDelete: () => widget.onDelete(block.id))
              : LessonPreview(
                  block: block,
                  dictionary: widget.dictionary,
                  language: widget.language,
                  showPinyin: widget.showPinyin,
                  showTranslations: widget.showTranslations));
    }
    final active = widget.editable && selected == block.id;
    return Positioned(
      left: block.x * 794,
      top: block.y * 1123,
      width: block.width * 794,
      height: block.height * 1123,
      child: GestureDetector(
        onTap:
            widget.editable ? () => setState(() => selected = block.id) : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
              border: active ? Border.all(color: colors.primary) : null),
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(
                child: ClipRect(
              child: Image.memory(block.imageBytes!,
                  fit: BoxFit.contain,
                  cacheWidth: 1600,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image_outlined)),
            )),
            if (active) ...[
              Positioned(
                  top: 0,
                  left: 0,
                  child: GestureDetector(
                    onPanUpdate: (details) => _drag(block, details.delta),
                    onPanEnd: (_) => _commit(),
                    child: Tooltip(
                        message: t('Przeciągnij element', '拖动元素', '拖曳元素'),
                        child: MouseRegion(
                            cursor: SystemMouseCursors.move,
                            child: Container(
                                color: colors.primaryContainer,
                                width: 44,
                                height: 30,
                                child: Icon(Icons.open_with,
                                    size: 20,
                                    color: colors.onPrimaryContainer)))),
                  )),
              Positioned(
                  top: 0,
                  right: 0,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                        visualDensity: VisualDensity.compact,
                        iconSize: 18,
                        tooltip: t('Usuń element', '删除元素', '刪除元素'),
                        onPressed: () => widget.onDelete(block.id),
                        icon: const Icon(Icons.close)),
                  ])),
              Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onPanUpdate: (details) =>
                        _drag(block, details.delta, resize: true),
                    onPanEnd: (_) => _commit(),
                    child: Tooltip(
                        message: t('Zmień rozmiar', '调整大小', '調整大小'),
                        child: MouseRegion(
                            cursor: SystemMouseCursors.resizeUpLeftDownRight,
                            child: Container(
                                width: 30,
                                height: 30,
                                color: colors.primaryContainer,
                                child: Icon(Icons.south_east,
                                    size: 20,
                                    color: colors.onPrimaryContainer)))),
                  )),
            ],
          ]),
        ),
      ),
    );
  }
}

class _PaperPainter extends CustomPainter {
  final String style;
  final Color color;
  _PaperPainter(this.style, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    if (style == 'blank') return;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..strokeWidth = 0.6;
    for (double y = 136; y < size.height; y += 60) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    if (style == 'grid') {
      for (double x = 0; x < size.width; x += 28) {
        canvas.drawLine(Offset(x, 90), Offset(x, size.height), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PaperPainter oldDelegate) =>
      oldDelegate.style != style || oldDelegate.color != color;
}
