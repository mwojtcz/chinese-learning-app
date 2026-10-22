import 'package:flutter/material.dart';
import '../../models/app_language.dart';
import '../../models/classroom_lesson.dart';
import '../../services/lesson_dictionary.dart';
import 'lesson_preview.dart';
import 'annotated_text_controller.dart';
import 'notebook_editing_controller.dart';
import 'paper_dictionary_overlay.dart';

class LessonBlockCard extends StatefulWidget {
  final LessonBlock block;
  final AppLanguage language;
  final LessonDictionary dictionary;
  final bool editable;
  final bool presentation;
  final bool showPinyin;
  final ValueChanged<LessonBlock> onChanged;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final bool paper;
  final bool autofocus;
  final bool showTranslations;
  final NotebookEditingController? editingController;

  const LessonBlockCard({
    super.key,
    required this.block,
    required this.language,
    required this.dictionary,
    required this.editable,
    required this.presentation,
    required this.showPinyin,
    required this.onChanged,
    required this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
    this.paper = false,
    this.autofocus = false,
    this.showTranslations = true,
    this.editingController,
  });

  @override
  State<LessonBlockCard> createState() => _LessonBlockCardState();
}

class _LessonBlockCardState extends State<LessonBlockCard> {
  late final _controller = AnnotatedTextController(
      text: widget.block.text, annotations: widget.block.annotations);
  late double _imageWidth = widget.block.imageWidth;
  final _focus = FocusNode();
  bool _writing = false;
  String t(String pl, String zh, [String? hant]) =>
      widget.language.text(pl, zh, hant);

  @override
  void initState() {
    super.initState();
    _writing = widget.autofocus;
    _controller.addListener(_selectionChanged);
    _focus.addListener(_focusChanged);
  }

  void _focusChanged() {
    if (_focus.hasFocus) {
      if (widget.paper && !_writing) setState(() => _writing = true);
      _selectionChanged();
    }
  }

  void _beginWriting() {
    setState(() => _writing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _selectionChanged() {
    if (_focus.hasFocus) {
      widget.editingController?.attach(this, _controller.selection, _format);
    }
  }

  Future<void> _format(NotebookFormat format) async {
    if (format == NotebookFormat.clear) {
      final selection = _controller.selection;
      final annotations = <LessonAnnotation>[];
      for (final annotation in widget.block.annotations) {
        if (annotation.end <= selection.start ||
            annotation.start >= selection.end) {
          annotations.add(annotation);
        } else {
          if (annotation.start < selection.start) {
            annotations.add(LessonAnnotation.fromJson(
                {...annotation.toJson(), 'end': selection.start},
                widget.block.text.length));
          }
          if (annotation.end > selection.end) {
            annotations.add(LessonAnnotation.fromJson(
                {...annotation.toJson(), 'start': selection.end},
                widget.block.text.length));
          }
        }
      }
      setState(() => _controller.annotations = annotations);
      widget.onChanged(widget.block.withAnnotations(annotations));
      return;
    }
    await _annotate(
        bold: format == NotebookFormat.bold,
        italic: format == NotebookFormat.italic,
        underline: format == NotebookFormat.underline,
        highlight: format == NotebookFormat.highlight,
        pinyin: switch (format) {
          NotebookFormat.showPinyin => true,
          NotebookFormat.hidePinyin => false,
          _ => null,
        },
        translation: switch (format) {
          NotebookFormat.showTranslation => true,
          NotebookFormat.hideTranslation => false,
          _ => null,
        });
  }

  @override
  void didUpdateWidget(covariant LessonBlockCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != widget.block.text) {
      _controller.text = widget.block.text;
    }
    _controller.annotations = widget.block.annotations;
    if (oldWidget.block.imageWidth != widget.block.imageWidth) {
      _imageWidth = widget.block.imageWidth;
    }
  }

  @override
  void dispose() {
    widget.editingController?.detach(this);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _annotate(
      {bool underline = false,
      bool highlight = false,
      bool bold = false,
      bool italic = false,
      bool? pinyin,
      bool? translation,
      bool correction = false}) async {
    final selection = _controller.selection;
    if (!selection.isValid || selection.isCollapsed) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t('Najpierw zaznacz fragment w edytorze.',
              '请先在编辑框中选择文字。', '請先在編輯框中選擇文字。'))));
      return;
    }
    var note = '';
    final originalText = widget.block.text;
    if (correction) {
      final input = TextEditingController();
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(t('Korekta / uwaga nauczyciela', '教师修正／说明', '教師修正／說明')),
          content: TextField(
              controller: input, autofocus: true, maxLength: 2000, maxLines: 4),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t('Anuluj', '取消'))),
            FilledButton(
                onPressed: () => Navigator.pop(context, input.text),
                child: Text(t('Zastosuj', '应用', '套用'))),
          ],
        ),
      );
      // A dialog route can still be animating out while its field is mounted.
      Future.delayed(const Duration(seconds: 1), input.dispose);
      if (!mounted || result == null || widget.block.text != originalText) {
        return;
      }
      note = result;
    }
    if (widget.block.annotations.length >= 500) return;
    final annotations = [
      ...widget.block.annotations,
      LessonAnnotation(
          start: selection.start,
          end: selection.end,
          underline: underline,
          highlight: highlight,
          bold: bold,
          italic: italic,
          pinyinVisible: pinyin,
          translationVisible: translation,
          note: note),
    ];
    setState(() => _controller.annotations = annotations);
    widget.onChanged(widget.block.withAnnotations(annotations));
  }

  @override
  Widget build(BuildContext context) {
    final block = widget.block;
    final colors = Theme.of(context).colorScheme;
    if (widget.paper && !_writing && block.text.isNotEmpty) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _beginWriting,
        child: LessonPreview(
            block: block,
            dictionary: widget.dictionary,
            language: widget.language,
            showPinyin: widget.showPinyin,
            onEdit: _beginWriting,
            showTranslations: widget.showTranslations),
      );
    }
    final label = switch (block.kind) {
      LessonBlockKind.text => t('Notatka', '笔记', '筆記'),
      LessonBlockKind.question => t('Pytanie', '问题', '問題'),
      LessonBlockKind.sentence => t('Zdanie', '例句'),
      LessonBlockKind.image => t('Obraz', '图片', '圖片'),
    };
    return Padding(
      padding: EdgeInsets.symmetric(vertical: widget.paper ? 0 : 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (widget.editable &&
            (widget.onMoveUp != null || widget.onMoveDown != null))
          Row(children: [
            Expanded(
                child: Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: colors.primary))),
            if (widget.editable) ...[
              IconButton(
                  onPressed: widget.onMoveUp,
                  tooltip: t('Przesuń w górę', '上移'),
                  icon: const Icon(Icons.arrow_upward, size: 18)),
              IconButton(
                  onPressed: widget.onMoveDown,
                  tooltip: t('Przesuń w dół', '下移'),
                  icon: const Icon(Icons.arrow_downward, size: 18)),
              IconButton(
                  onPressed: widget.onDelete,
                  tooltip: t('Usuń blok', '删除内容块', '刪除內容區塊'),
                  icon: const Icon(Icons.delete_outline, size: 20)),
            ],
          ]),
        if (widget.editable && !widget.paper) const SizedBox(height: 4),
        if (block.kind == LessonBlockKind.image) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(block.imageBytes!,
                  width: _imageWidth,
                  cacheWidth: 1600,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Text(
                      t('Nie można odczytać obrazu.', '无法读取图片。', '無法讀取圖片。'))),
            ),
          ),
          if (widget.editable)
            Row(children: [
              const Icon(Icons.photo_size_select_large_outlined),
              Expanded(
                  child: Slider(
                      value: _imageWidth,
                      min: 160,
                      max: 1200,
                      label: '${_imageWidth.round()} px',
                      onChanged: (value) => setState(() => _imageWidth = value),
                      onChangeEnd: (value) =>
                          widget.onChanged(block.withWidth(value)))),
              Text('${_imageWidth.round()} px'),
            ]),
        ],
        if (widget.editable) ...[
          _paperEditor(TextField(
            controller: _controller,
            focusNode: _focus,
            autofocus: widget.autofocus,
            minLines:
                widget.paper || block.kind == LessonBlockKind.image ? 1 : 3,
            maxLines: null,
            maxLength: 20000,
            style: Theme.of(context).textTheme.bodyLarge!.merge(TextStyle(
                fontSize: widget.paper
                    ? 20
                    : widget.presentation
                        ? 30
                        : 21,
                height: widget.paper ? 3 : 1.8)),
            strutStyle: widget.paper ? PaperDictionaryOverlay.strut : null,
            contextMenuBuilder: (context, state) {
              final selection = state.textEditingValue.selection;
              final selected = selection.isValid && !selection.isCollapsed;
              return AdaptiveTextSelectionToolbar.buttonItems(
                anchors: state.contextMenuAnchors,
                buttonItems: [
                  ...state.contextMenuButtonItems,
                  if (selected && block.kind != LessonBlockKind.image) ...[
                    ContextMenuButtonItem(
                        label: t('Pogrubienie', '加粗', '粗體'),
                        onPressed: () {
                          state.hideToolbar();
                          _annotate(bold: true);
                        }),
                    ContextMenuButtonItem(
                        label: t('Kursywa', '斜体', '斜體'),
                        onPressed: () {
                          state.hideToolbar();
                          _annotate(italic: true);
                        }),
                    ContextMenuButtonItem(
                        label: t('Podkreśl', '下划线', '底線'),
                        onPressed: () {
                          state.hideToolbar();
                          _annotate(underline: true);
                        }),
                    ContextMenuButtonItem(
                        label: t('Wyróżnij', '高亮', '螢光標示'),
                        onPressed: () {
                          state.hideToolbar();
                          _annotate(highlight: true);
                        }),
                    ContextMenuButtonItem(
                        label: t('Pokaż pinyin', '显示拼音', '顯示拼音'),
                        onPressed: () {
                          state.hideToolbar();
                          _annotate(pinyin: true);
                        }),
                    ContextMenuButtonItem(
                        label: t('Ukryj pinyin', '隐藏拼音', '隱藏拼音'),
                        onPressed: () {
                          state.hideToolbar();
                          _annotate(pinyin: false);
                        }),
                  ],
                ],
              );
            },
            decoration: InputDecoration(
              hintText: block.kind == LessonBlockKind.image
                  ? t('Podpis obrazu', '图片说明', '圖片說明')
                  : widget.paper
                      ? null
                      : t('Pisz tutaj…', '在此输入…', '在此輸入…'),
              counterText: '',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              isDense: widget.paper,
              contentPadding:
                  EdgeInsets.symmetric(vertical: widget.paper ? 0 : 8),
            ),
            onChanged: (value) {
              final updated = block.withText(value);
              _controller.annotations = updated.annotations;
              widget.onChanged(updated);
            },
          )),
          if (widget.paper && block.text.isNotEmpty) ...[
            if (widget.dictionary.lookup(block.text).isEmpty &&
                (widget.showPinyin || widget.showTranslations))
              Text(
                  t('Brak jednoznacznych dopasowań w słowniku.', '词典中没有明确匹配。',
                      '詞典中沒有明確匹配。'),
                  style: Theme.of(context).textTheme.labelSmall),
          ],
          if (block.kind != LessonBlockKind.image && !widget.paper)
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) {
                if (!value.selection.isValid || value.selection.isCollapsed) {
                  return const SizedBox.shrink();
                }
                return Wrap(spacing: 4, runSpacing: 4, children: [
                  TextButton.icon(
                      onPressed: () => _annotate(bold: true),
                      icon: const Icon(Icons.format_bold),
                      label: Text(t('Pogrubienie', '加粗', '粗體'))),
                  TextButton.icon(
                      onPressed: () => _annotate(italic: true),
                      icon: const Icon(Icons.format_italic),
                      label: Text(t('Kursywa', '斜体', '斜體'))),
                  TextButton.icon(
                      onPressed: () => _annotate(underline: true),
                      icon: const Icon(Icons.format_underlined),
                      label: Text(t('Podkreśl', '下划线', '底線'))),
                  TextButton.icon(
                      onPressed: () => _annotate(highlight: true),
                      icon: const Icon(Icons.highlight),
                      label: Text(t('Wyróżnij', '高亮', '螢光標示'))),
                  TextButton.icon(
                      onPressed: () => _annotate(pinyin: true),
                      icon: const Icon(Icons.visibility_outlined),
                      label: Text(t('Pokaż pinyin', '显示拼音', '顯示拼音'))),
                  TextButton.icon(
                      onPressed: () => _annotate(pinyin: false),
                      icon: const Icon(Icons.visibility_off_outlined),
                      label: Text(t('Ukryj pinyin', '隐藏拼音', '隱藏拼音'))),
                  TextButton.icon(
                      onPressed: () => _annotate(correction: true),
                      icon: const Icon(Icons.edit_note),
                      label: Text(t('Korekta', '修正'))),
                  if (block.annotations.isNotEmpty)
                    TextButton(
                        onPressed: () =>
                            widget.onChanged(block.withAnnotations([])),
                        child: Text(t('Wyczyść oznaczenia', '清除标记', '清除標記'))),
                ]);
              },
            ),
        ],
        if (block.text.isNotEmpty && !widget.editable)
          LessonPreview(
              block: block,
              dictionary: widget.dictionary,
              language: widget.language,
              showPinyin: widget.showPinyin,
              presentation: widget.presentation),
      ]),
    );
  }

  Widget _paperEditor(Widget field) {
    if (!widget.paper) return field;
    return ValueListenableBuilder<TextEditingValue>(
        valueListenable: _controller,
        builder: (context, _, __) => PaperDictionaryOverlay(
            controller: _controller,
            dictionary: widget.dictionary,
            language: widget.language,
            showPinyin: widget.showPinyin,
            showTranslations: widget.showTranslations,
            child: Stack(clipBehavior: Clip.none, children: [
              field,
              if (widget.block.text.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                      tooltip: t('Gotowe', '完成'),
                      onPressed: () {
                        _focus.unfocus();
                        widget.editingController?.detach(this);
                        setState(() => _writing = false);
                      },
                      icon: const Icon(Icons.check, size: 18)),
                ),
            ])));
  }
}
