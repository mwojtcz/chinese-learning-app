import 'dart:async';
import 'dart:ui' as ui;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_language.dart';
import '../models/classroom_lesson.dart';
import '../models/word.dart';
import '../providers/word_provider.dart';
import '../services/classroom_store.dart';
import '../services/lesson_dictionary.dart';
import '../services/portable_file.dart';
import '../widgets/classroom/notebook_canvas.dart';
import '../widgets/classroom/notebook_editing_controller.dart';

class ClassroomScreen extends StatefulWidget {
  final AppLanguage language;
  final String profileId;
  final String studentName;
  final bool teacherMode;

  const ClassroomScreen({
    super.key,
    required this.language,
    required this.profileId,
    required this.studentName,
    required this.teacherMode,
  });

  @override
  State<ClassroomScreen> createState() => _ClassroomScreenState();
}

class _ClassroomScreenState extends State<ClassroomScreen> {
  ClassroomStore? _store;
  String? _selectedId;
  bool _loading = true;
  bool _loadFailed = false;
  bool _busy = false;
  bool _board = false;
  bool _pinyin = true;
  bool _translations = true;
  final _editing = NotebookEditingController();
  int _loadEpoch = 0;
  final _title = TextEditingController();
  List<Word>? _dictionaryWords;
  int _dictionaryWordCount = -1;
  LessonDictionary _dictionary = LessonDictionary([]);

  String t(String pl, String zh, [String? hant]) =>
      widget.language.text(pl, zh, hant);
  ClassroomLesson? get _lesson =>
      _store?.lessons.where((l) => l.id == _selectedId).firstOrNull;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant ClassroomScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileId != widget.profileId) {
      _board = false;
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final epoch = ++_loadEpoch;
    final profile = widget.profileId;
    final previous = _store;
    previous?.removeListener(_changed);
    _store = null;
    _selectedId = null;
    _title.clear();
    setState(() {
      _loading = true;
      _loadFailed = false;
      _busy = false;
    });
    try {
      await previous?.flush();
    } catch (_) {
      // Parent navigation uses flushAll as a guard. If the widget is forcibly
      // recreated, the learner-bound unsaved snapshot still survives in memory.
    }
    previous?.dispose();
    ClassroomStore? store;
    try {
      final preferences = await SharedPreferences.getInstance();
      store = ClassroomStore(profileId: profile, preferences: preferences);
      await store.load();
      if (!mounted || epoch != _loadEpoch) {
        store.dispose();
        return;
      }
      _store = store..addListener(_changed);
      if (store.lessons.isEmpty && widget.teacherMode) {
        store.put(ClassroomLesson(
          title: t('Strona 1', '第 1 页', '第 1 頁'),
          blocks: [LessonBlock(y: 90 / 1123)],
        ));
      }
      _select(store.lessons.firstOrNull?.id);
      setState(() => _loading = false);
    } catch (_) {
      store?.dispose();
      if (mounted && epoch == _loadEpoch) {
        setState(() {
          _loading = false;
          _loadFailed = true;
        });
      }
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _select(String? id) {
    setState(() {
      _selectedId = id;
      _title.text = _lesson?.title ?? '';
    });
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  void _edit({String? title, List<LessonBlock>? blocks, String? paperStyle}) {
    final lesson = _lesson;
    if (lesson == null || !widget.teacherMode) return;
    _store!
        .put(lesson.edit(title: title, blocks: blocks, paperStyle: paperStyle));
  }

  void _replaceBlock(LessonBlock block) {
    final blocks = _lesson?.blocks;
    if (blocks == null) return;
    _edit(blocks: blocks.map((b) => b.id == block.id ? block : b).toList());
  }

  Future<void> _image() async {
    final store = _store;
    final lessonId = _selectedId;
    final epoch = _loadEpoch;
    setState(() => _busy = true);
    try {
      final file = await openFile(acceptedTypeGroups: [
        const XTypeGroup(
            label: 'PNG / JPEG',
            extensions: ['png', 'jpg', 'jpeg'],
            mimeTypes: ['image/png', 'image/jpeg'],
            uniformTypeIdentifiers: ['public.png', 'public.jpeg']),
      ]);
      if (file == null) return;
      if (await file.length() > ClassroomPackage.maxImageBytes) {
        throw const FormatException('image-size');
      }
      final bytes = await file.readAsBytes();
      final mime =
          bytes.isNotEmpty && bytes[0] == 137 ? 'image/png' : 'image/jpeg';
      ClassroomPackage.validateImage(bytes, mime);
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 1600);
      try {
        final frame = await codec.getNextFrame();
        frame.image.dispose();
      } finally {
        codec.dispose();
      }
      if (!mounted ||
          !identical(store, _store) ||
          _selectedId != lessonId ||
          !widget.teacherMode) {
        return;
      }
      if (_lesson!.blocks.length >= 200) {
        throw const FormatException('block-limit');
      }
      _edit(blocks: [
        ..._lesson!.blocks,
        LessonBlock(
            kind: LessonBlockKind.image, imageBytes: bytes, imageMime: mime)
      ]);
    } catch (_) {
      if (mounted && epoch == _loadEpoch) {
        _message(t(
            'Nie udało się dodać obrazu. PNG/JPEG: do 4 MB, 8192 px i 16 mln pikseli.',
            '无法添加图片。PNG/JPEG：不超过 4 MB、8192 像素及 1600 万像素。',
            '無法新增圖片。PNG/JPEG：不超過 4 MB、8192 像素及 1600 萬像素。'));
      }
    } finally {
      if (mounted && epoch == _loadEpoch) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final store = _store;
    final epoch = _loadEpoch;
    setState(() => _busy = true);
    try {
      final file = await openFile(acceptedTypeGroups: [
        XTypeGroup(
            label: t('Pakiet lekcji (.cika)', '课程文件 (.cika)', '課程檔案 (.cika)'),
            extensions: const ['cika'],
            mimeTypes: const ['application/json'],
            uniformTypeIdentifiers: const ['public.json']),
      ]);
      if (file == null) return;
      if (await file.length() > ClassroomPackage.maxFileBytes) {
        throw const FormatException('package-size');
      }
      final package = ClassroomPackage.decode(await file.readAsBytes());
      if (!mounted || !identical(store, _store)) return;
      final result = store!.importPackage(package);
      _select(package.lessons.first.id);
      await store.flush();
      if (!mounted || !identical(store, _store)) return;
      if (store.error != null) return;
      _message(result == LessonImportResult.unchanged
          ? t('Ta wersja lekcji już istnieje.', '此版本的课程已存在。', '此版本的課程已存在。')
          : t('Zaimportowano lekcję. Notatki i postępy ucznia pozostają bez zmian.',
              '课程已导入。学生笔记和学习进度保持不变。', '課程已匯入。學生筆記和學習進度保持不變。'));
    } catch (error) {
      if (!mounted || epoch != _loadEpoch) return;
      final code = error is FormatException ? error.message : '';
      _message(switch (code) {
        'older-revision' =>
          t('Odrzucono starszą wersję lekcji.', '已拒绝旧版本课程。', '已拒絕舊版本課程。'),
        'revision-conflict' => t(
            'Konflikt: ten sam numer wersji ma inną treść.',
            '冲突：相同版本号的内容不同。',
            '衝突：相同版本號的內容不同。'),
        'unsupported-schema' => t('Nieobsługiwana wersja pakietu lekcji .cika.',
            '不支持此 .cika 课程文件版本。', '不支援此 .cika 課程檔案版本。'),
        _ => t(
            'Nie można importować pliku. Sprawdź format .cika i limit 20 MB.',
            '无法导入文件。请检查 .cika 格式及 20 MB 大小限制。',
            '無法匯入檔案。請檢查 .cika 格式及 20 MB 大小限制。'),
      });
    } finally {
      if (mounted && epoch == _loadEpoch) setState(() => _busy = false);
    }
  }

  Future<void> _export() async {
    final lesson = _lesson;
    if (lesson == null) return;
    final epoch = _loadEpoch;
    setState(() => _busy = true);
    try {
      final bytes = ClassroomPackage(_store!.lessons).encode();
      await savePortableFile(
        suggestedName: 'lesson-${lesson.id}-r${lesson.revision}.cika',
        bytes: bytes,
      );
    } catch (_) {
      if (mounted && epoch == _loadEpoch) {
        _message(t('Eksport nie powiódł się. Limit pakietu: 20 MB.',
            '导出失败。文件大小上限为 20 MB。', '匯出失敗。檔案大小上限為 20 MB。'));
      }
    } finally {
      if (mounted && epoch == _loadEpoch) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _editing.dispose();
    ++_loadEpoch;
    _store?.removeListener(_changed);
    _store?.dispose();
    _title.dispose();
    super.dispose();
  }

  Widget _notes(ClassroomLesson lesson) {
    final teacher = widget.teacherMode;
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.lock_outline),
            const SizedBox(width: 10),
            Expanded(
                child: Text(
                    teacher
                        ? t('Prywatne notatki nauczyciela', '教师私人笔记', '教師私人筆記')
                        : t('Moje osobiste notatki', '我的个人笔记', '我的個人筆記'),
                    style: Theme.of(context).textTheme.titleMedium)),
          ]),
          const SizedBox(height: 8),
          Text(t('Tylko na tym urządzeniu. Nigdy nie trafiają do pliku .cika.',
              '仅保存在本设备上，绝不导出到 .cika 文件。', '僅儲存在本裝置上，絕不匯出到 .cika 檔案。')),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey('${widget.profileId}:${lesson.id}:$teacher'),
            initialValue: teacher
                ? _store!.teacherNote(lesson.id)
                : _store!.pupilNote(lesson.id),
            minLines: 3,
            maxLines: 8,
            maxLength: 20000,
            decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: t('Notatki', '笔记', '筆記')),
            onChanged: (value) => teacher
                ? _store!.setTeacherNote(lesson.id, value)
                : _store!.setPupilNote(lesson.id, value),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = context.watch<WordProvider>().allWords;
    if (!identical(words, _dictionaryWords) ||
        _dictionaryWordCount != words.length) {
      _dictionaryWords = words;
      _dictionaryWordCount = words.length;
      _dictionary = LessonDictionary(words);
    }
    final colors = Theme.of(context).colorScheme;
    final lesson = _lesson;
    final editable = widget.teacherMode && !_board;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text(_board
            ? t('Tablica', '课堂展示', '課堂展示')
            : t('Notatnik · ${widget.studentName}',
                '笔记本 · ${widget.studentName}', '筆記本 · ${widget.studentName}')),
        actions: [
          if (lesson != null)
            IconButton(
                onPressed: () => setState(() => _board = !_board),
                tooltip: _board
                    ? t('Zakończ prezentację', '退出展示', '退出展示')
                    : t('Tryb tablicy', '课堂展示模式', '課堂展示模式'),
                icon: Icon(_board
                    ? Icons.close_fullscreen
                    : Icons.cast_for_education)),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadFailed
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(t(
                            'Nie można odczytać notatnika. Dane nie zostały nadpisane.',
                            '无法读取笔记本。原有数据未被覆盖。',
                            '無法讀取筆記本。原有資料未被覆蓋。')),
                        TextButton(
                            onPressed: _load,
                            child: Text(t('Spróbuj ponownie', '重试', '重試'))),
                      ])))
              : Column(children: [
                  if (_store?.error != null)
                    MaterialBanner(
                      content: Text(t(
                          'Zapis nie powiódł się — pamięć urządzenia może być pełna. Zmiany pozostają w pamięci tej sesji. Nie zamykaj aplikacji: wyeksportuj lekcję .cika, usuń zbędny obraz lub ponów zapis.',
                          '保存失败，设备存储空间可能已满。更改保留在当前会话内存中。请勿关闭应用：导出 .cika 课程、删除不需要的图片或重试保存。',
                          '儲存失敗，裝置儲存空間可能已滿。變更保留在目前工作階段記憶體中。請勿關閉應用程式：匯出 .cika 課程、刪除不需要的圖片或重試儲存。')),
                      actions: [
                        TextButton(
                            onPressed: _store!.retry,
                            child: Text(t('Ponów zapis', '重新保存', '重新儲存')))
                      ],
                    ),
                  if (_busy) const LinearProgressIndicator(),
                  if (lesson != null) _formattingToolbar(editable),
                  Expanded(
                      child: LayoutBuilder(builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 1050 && !_board;
                    final notebook = _notebook(lesson, editable);
                    if (!wide) {
                      return Column(children: [
                        if (!_board)
                          SizedBox(
                              height: 142, child: _pageStrip(horizontal: true)),
                        Expanded(child: notebook),
                      ]);
                    }
                    return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(width: 156, child: _pageStrip()),
                          VerticalDivider(
                              width: 1, color: colors.outlineVariant),
                          Expanded(child: notebook),
                        ]);
                  })),
                ]),
    );
  }

  void _newPage() {
    if (_store!.lessons.length >= 100) {
      _message(t(
          'Notatnik może mieć do 100 stron.', '笔记本最多 100 页。', '筆記本最多 100 頁。'));
      return;
    }

    final page = ClassroomLesson(
      title: t(
          'Strona ${_store!.lessons.length + 1}',
          '第 ${_store!.lessons.length + 1} 页',
          '第 ${_store!.lessons.length + 1} 頁'),
      blocks: [LessonBlock(y: 90 / 1123)],
    );
    _store!.put(page);
    _select(page.id);
  }

  Widget _formattingToolbar(bool editable) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: ListenableBuilder(
          listenable: _editing,
          builder: (context, _) => Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (editable)
                for (final item in [
                  (
                    NotebookFormat.bold,
                    Icons.format_bold,
                    t('Pogrubienie', '加粗', '粗體')
                  ),
                  (
                    NotebookFormat.italic,
                    Icons.format_italic,
                    t('Kursywa', '斜体', '斜體')
                  ),
                  (
                    NotebookFormat.underline,
                    Icons.format_underlined,
                    t('Podkreśl', '下划线', '底線')
                  ),
                  (
                    NotebookFormat.highlight,
                    Icons.highlight,
                    t('Wyróżnij', '高亮', '螢光標示')
                  ),
                  (
                    NotebookFormat.showPinyin,
                    Icons.visibility,
                    t('Pokaż pinyin zaznaczenia', '显示所选拼音', '顯示所選拼音')
                  ),
                  (
                    NotebookFormat.hidePinyin,
                    Icons.visibility_off,
                    t('Ukryj pinyin zaznaczenia', '隐藏所选拼音', '隱藏所選拼音')
                  ),
                  (
                    NotebookFormat.showTranslation,
                    Icons.translate,
                    t('Pokaż tłumaczenie zaznaczenia', '显示所选翻译', '顯示所選翻譯')
                  ),
                  (
                    NotebookFormat.hideTranslation,
                    Icons.subtitles_off_outlined,
                    t('Ukryj tłumaczenie zaznaczenia', '隐藏所选翻译', '隱藏所選翻譯')
                  ),
                  (
                    NotebookFormat.clear,
                    Icons.format_clear,
                    t('Wyczyść oznaczenia', '清除标记', '清除標記')
                  ),
                ])
                  IconButton(
                    tooltip: item.$3,
                    onPressed: _editing.hasSelection
                        ? () => _editing.apply(item.$1)
                        : null,
                    icon: Icon(item.$2),
                  ),
              FilterChip(
                  selected: _pinyin,
                  onSelected: (value) => setState(() => _pinyin = value),
                  label: Text(t('Pinyin', '拼音'))),
              FilterChip(
                  selected: _translations,
                  onSelected: (value) => setState(() => _translations = value),
                  label: Text(t('Tłumaczenia', '翻译', '翻譯'))),
              if (editable)
                Text(t('Zaznacz tekst, aby go sformatować.', '选择文字以设置格式。',
                    '選取文字以設定格式。')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pageStrip({bool horizontal = false}) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      scrollDirection: horizontal ? Axis.horizontal : Axis.vertical,
      padding: const EdgeInsets.all(12),
      children: [
        for (var i = 0; i < _store!.lessons.length; i++)
          Padding(
            padding: const EdgeInsets.all(4),
            child: Semantics(
              selected: _store!.lessons[i].id == _selectedId,
              button: true,
              child: InkWell(
                onTap: () => _select(_store!.lessons[i].id),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: horizontal ? 88 : 120,
                  height: horizontal ? 108 : 150,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _store!.lessons[i].id == _selectedId
                          ? colors.primary
                          : colors.outlineVariant,
                      width: _store!.lessons[i].id == _selectedId ? 2 : 1,
                    ),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            t('Strona ${i + 1}', '第 ${i + 1} 页',
                                '第 ${i + 1} 頁'),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: colors.primary)),
                        const SizedBox(height: 6),
                        Text(_store!.lessons[i].title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall),
                        const SizedBox(height: 4),
                        Expanded(
                            child: Text(
                                _store!.lessons[i].blocks
                                    .map((b) => b.kind == LessonBlockKind.image
                                        ? '▧ ${b.text}'
                                        : b.text)
                                    .join('\n'),
                                overflow: TextOverflow.fade,
                                style: TextStyle(
                                    fontSize: 9,
                                    color: colors.onSurfaceVariant))),
                      ]),
                ),
              ),
            ),
          ),
        if (widget.teacherMode)
          SizedBox(
              width: horizontal ? 88 : null,
              height: horizontal ? 108 : 80,
              child: IconButton(
                  onPressed: _busy ? null : _newPage,
                  tooltip: t('Dodaj stronę', '添加页面', '新增頁面'),
                  icon: const Icon(Icons.note_add_outlined))),
      ],
    );
  }

  Widget _notebook(ClassroomLesson? lesson, bool editable) {
    final colors = Theme.of(context).colorScheme;
    final pageIndex =
        _store!.lessons.indexWhere((page) => page.id == _selectedId);
    return ListView(
      key: ValueKey('paper-scroll:$_selectedId:$_board'),
      padding: EdgeInsets.symmetric(horizontal: _board ? 24 : 12, vertical: 16),
      children: [
        Center(
            child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _board ? 1120 : 794),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (!_board) ...[
              Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (widget.teacherMode)
                      FilledButton.icon(
                          onPressed: _busy
                              ? null
                              : () {
                                  _newPage();
                                },
                          icon: const Icon(Icons.add),
                          label: Text(t('Dodaj stronę', '添加页面', '新增頁面'))),
                    OutlinedButton.icon(
                        onPressed: _busy ? null : _import,
                        icon: const Icon(Icons.file_open_outlined),
                        label:
                            Text(t('Importuj .cika', '导入 .cika', '匯入 .cika'))),
                    OutlinedButton.icon(
                        onPressed: _busy || lesson == null ? null : _export,
                        icon: const Icon(Icons.ios_share),
                        label:
                            Text(t('Eksportuj .cika', '导出 .cika', '匯出 .cika'))),
                    Text(
                        _store!.saving
                            ? t('Zapisywanie…', '保存中…', '儲存中…')
                            : _store!.error != null
                                ? t('Niezapisane zmiany', '有未保存的更改', '有未儲存的變更')
                                : t('Zapisano lokalnie', '已本地保存', '已在本機儲存'),
                        style: Theme.of(context).textTheme.labelMedium),
                  ]),
              const SizedBox(height: 12),
            ],
            if (lesson != null)
              Row(children: [
                IconButton(
                  tooltip: t('Poprzednia strona', '上一页', '上一頁'),
                  onPressed: pageIndex > 0
                      ? () => _select(_store!.lessons[pageIndex - 1].id)
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                    child: Text(
                        t(
                            'Strona ${pageIndex + 1} z ${_store!.lessons.length}',
                            '第 ${pageIndex + 1} / ${_store!.lessons.length} 页',
                            '第 ${pageIndex + 1} / ${_store!.lessons.length} 頁'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge)),
                IconButton(
                  tooltip: t('Następna strona', '下一页', '下一頁'),
                  onPressed: pageIndex + 1 < _store!.lessons.length
                      ? () => _select(_store!.lessons[pageIndex + 1].id)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ]),
            if (lesson == null)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 64),
                  child: Column(children: [
                    Icon(Icons.auto_stories_outlined,
                        size: 64, color: colors.primary),
                    const SizedBox(height: 20),
                    Text(
                        t('Ten notatnik nie ma jeszcze stron.', '笔记本尚无页面。',
                            '筆記本尚無頁面。'),
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(
                        t('Nauczyciel może dodać stronę. Możesz też zaimportować plik .cika.',
                            '教师可以添加页面，也可导入 .cika 文件。', '教師可以新增頁面，也可匯入 .cika 檔案。'),
                        textAlign: TextAlign.center),
                  ])),
            if (lesson != null) ...[
              if (editable)
                TextField(
                    controller: _title,
                    maxLength: 200,
                    decoration: InputDecoration(
                        labelText: t('Tytuł strony', '页面标题', '頁面標題'),
                        counterText: '',
                        border: InputBorder.none,
                        filled: false),
                    onChanged: (value) => _edit(title: value)),
              Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (editable) ...[
                      for (final style in ['blank', 'lined', 'grid'])
                        ChoiceChip(
                            selected: lesson.paperStyle == style,
                            label: Text(switch (style) {
                              'lined' => t('Linie', '横线', '橫線'),
                              'grid' => t('Kratka', '方格'),
                              _ => t('Gładki', '空白'),
                            }),
                            onSelected: (_) => _edit(paperStyle: style)),
                    ],
                  ]),
              const SizedBox(height: 12),
              Container(
                key: const ValueKey('a4-notebook-paper'),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLowest,
                  border: Border.all(color: colors.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                        color: colors.shadow.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 5))
                  ],
                ),
                child: NotebookCanvas(
                    key: ValueKey('${widget.profileId}:${lesson.id}'),
                    page: lesson,
                    language: widget.language,
                    dictionary: _dictionary,
                    editable: editable,
                    showPinyin: _pinyin,
                    showTranslations: _translations,
                    editingController: _editing,
                    onInsert: (block) {
                      if (_lesson!.blocks.length >= 200) {
                        _message(t('Limit: 200 fragmentów na stronę.',
                            '每页最多 200 段。', '每頁最多 200 段。'));
                        return;
                      }
                      _edit(blocks: [..._lesson!.blocks, block]);
                    },
                    onChanged: _replaceBlock,
                    onDelete: (id) => _edit(
                        blocks:
                            _lesson!.blocks.where((b) => b.id != id).toList())),
              ),
              const SizedBox(height: 12),
              if (editable) ...[
                Wrap(spacing: 8, runSpacing: 8, children: [
                  Text(t('Kliknij linię na kartce i zacznij pisać.',
                      '点击页面上的一行即可书写。', '點擊頁面上的一行即可書寫。')),
                  OutlinedButton.icon(
                      onPressed: _busy ? null : _image,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: Text(
                          t('Obraz PNG/JPEG', 'PNG/JPEG 图片', 'PNG/JPEG 圖片'))),
                ]),
                const SizedBox(height: 24),
              ],
              const SizedBox(height: 20),
              if (!_board)
                ExpansionTile(
                  title: Text(widget.teacherMode
                      ? t('Prywatne notatki nauczyciela', '教师私人笔记', '教師私人筆記')
                      : t('Moje osobiste notatki', '我的个人笔记', '我的個人筆記')),
                  leading: const Icon(Icons.lock_outline),
                  children: [_notes(lesson)],
                ),
            ],
          ]),
        )),
      ],
    );
  }
}
