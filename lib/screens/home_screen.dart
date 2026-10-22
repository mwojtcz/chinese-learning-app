import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, kReleaseMode, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_identity.dart';
import '../models/app_language.dart';
import '../models/learner_profile.dart';
import '../models/learning_target.dart';
import '../providers/appearance_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/word_provider.dart';
import '../services/windows_updater.dart';
import '../services/portable_file.dart';
import '../services/classroom_store.dart';
import '../widgets/study_atmosphere.dart';
import 'chengyu_screen.dart';
import 'classroom_screen.dart';
import 'learning_tabs.dart';
import 'practice_tab.dart';

final emojiEnabledNotifier = ValueNotifier<bool>(false);
final traditionalChineseNotifier = ValueNotifier<bool>(false);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  AppLanguage _language = AppLanguage.polish;
  LearningTarget _learningTarget = LearningTarget.chinese;
  String? _studentId;
  bool _switching = false;
  bool _restoringWorkspace = false;
  static const _maxBackupBytes = 32 * 1024 * 1024;
  int _workspaceGeneration = 0;

  void navigateToScreen(int index) {
    if (mounted) setState(() => _selectedIndex = index.clamp(0, 7).toInt());
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _checkForWindowsUpdate());
  }

  Future<void> _loadPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    final language =
        appLanguageFromCode(preferences.getString('interface_language'));
    if (!mounted) return;
    setState(() {
      _language = language;
      _learningTarget = learningTargetFromCode(
        preferences.getString('learning_target'),
        language,
      );
    });
    traditionalChineseNotifier.value = language.isTraditional;
  }

  Future<void> _setLanguage(AppLanguage language) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('interface_language', language.code);
    await preferences.setBool('traditional_chinese', language.isTraditional);
    if (!mounted) return;
    setState(() => _language = language);
    traditionalChineseNotifier.value = language.isTraditional;
  }

  Future<void> _setLearningTarget(LearningTarget target) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('learning_target', target.code);
    if (mounted) setState(() => _learningTarget = target);
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
      _language.text('Nie udało się zapisać lub otworzyć danych: $error',
          '无法保存或打开数据：$error', '無法儲存或開啟資料：$error'),
    )));
  }

  Future<void> _switchProfile(String id, {bool student = false}) async {
    if (_switching) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _switching = true);
    final profiles = context.read<ProfileProvider>();
    final words = context.read<WordProvider>();
    final previousId = _studentId ?? profiles.activeProfile.id;
    try {
      await words.flush();
      await ClassroomStore.flushAll();
      await words.setProfile(id);
      if (!student) await profiles.selectProfile(id);
      if (!mounted) return;
      setState(() {
        _studentId = student ? id : null;
        if (student) _selectedIndex = 5;
      });
    } catch (error) {
      try {
        await words.setProfile(previousId);
      } catch (restoreError) {
        _showError('$error; could not reload previous profile: $restoreError');
        return;
      }
      _showError(error);
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  Future<void> _createProfile() async {
    final controller = TextEditingController();
    var teacher = false;
    final create = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(_language.text('Nowy profil', '新建档案', '新增檔案')),
          content: SizedBox(
            width: 360,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 80,
                decoration: InputDecoration(
                  labelText:
                      _language.text('Imię lub pseudonim', '姓名或昵称', '姓名或暱稱'),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_language.text('Tryb nauczyciela', '教师模式', '教師模式')),
                value: teacher,
                onChanged: (value) => setDialogState(() => teacher = value),
              ),
              Text(
                  _language.text(
                    'Profile są lokalne. Nie mają hasła i nie chronią dostępu do danych.',
                    '档案仅保存在本机，无密码保护。',
                    '檔案僅儲存在本機，無密碼保護。',
                  ),
                  style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(_language.text('Anuluj', '取消', '取消'))),
            FilledButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty)
                    Navigator.pop(context, true);
                },
                child: Text(_language.text('Utwórz', '创建', '建立'))),
          ],
        ),
      ),
    );
    final name = controller.text.trim();
    controller.dispose();
    if (create != true || !mounted) return;
    try {
      await context
          .read<ProfileProvider>()
          .createProfile(name, isTeacher: teacher);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _prepareUpdate() async {
    await ClassroomStore.flushAll();
    if (!mounted) return;
    await context.read<WordProvider>().flush();
    if (!mounted) return;
    final profiles = context.read<ProfileProvider>();
    await profiles.flush();
    await profiles.createBackup(reason: 'pre-update');
  }

  Future<void> _installUpdate(
    WindowsUpdate update, {
    ValueChanged<double>? onProgress,
  }) async {
    if (_switching)
      throw StateError('A data operation is already in progress.');
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _switching = true);
    try {
      await _prepareUpdate();
      await WindowsUpdater.downloadAndInstall(update, onProgress: onProgress);
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  Future<void> _checkForWindowsUpdate() async {
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.windows ||
        !kReleaseMode) return;
    try {
      final update = await WindowsUpdater.checkForUpdate();
      if (update == null || !mounted) return;
      final preferences = await SharedPreferences.getInstance();
      if (!mounted ||
          preferences.getInt('dismissed_windows_update') == update.buildNumber)
        return;
      final install = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title:
              Text(_language.text('Dostępna aktualizacja', '发现新版本', '發現新版本')),
          content: Text(_language.text(
            'Wersja ${update.version}. Przed instalacją zapiszemy kopię danych. Aplikacja uruchomi się ponownie.',
            '版本 ${update.version}。安装前将备份数据，随后重启应用。',
            '版本 ${update.version}。安裝前將備份資料，隨後重新啟動應用程式。',
          )),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(_language.text('Później', '稍后', '稍後'))),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(_language.text('Aktualizuj', '更新', '更新'))),
          ],
        ),
      );
      if (install != true) {
        await preferences.setInt(
            'dismissed_windows_update', update.buildNumber);
        return;
      }
      await _installUpdate(update);
    } catch (error) {
      _showError(error);
    }
  }

  List<String> get _labels => [
        _language.text('Talia', '词卡', '詞卡'),
        _language.text('HSK', 'HSK 词库', 'HSK 詞庫'),
        _language.text('Ćwiczenia', '练习', '練習'),
        _language.text('Gramatyka', '语法', '語法'),
        _language.text('Zapisane', '收藏', '收藏'),
        _language.text('Zeszyt i tablica', '笔记与白板', '筆記與白板'),
        _language.text('Chengyu', '成语', '成語'),
        _language.text('Ustawienia', '设置', '設定'),
      ];

  static const _icons = [
    Icons.style_outlined,
    Icons.menu_book_outlined,
    Icons.edit_note_rounded,
    Icons.translate_rounded,
    Icons.bookmark_border_rounded,
    Icons.co_present_outlined,
    Icons.auto_stories_outlined,
    Icons.tune_rounded,
  ];

  Widget _pages(LearnerProfile active, List<LearnerProfile> profiles) {
    final selected = profiles.where((profile) => profile.id == _studentId);
    final learner =
        active.isTeacher && selected.isNotEmpty ? selected.first : active;
    return KeyedSubtree(
      key: ValueKey('${active.id}:${learner.id}:$_workspaceGeneration'),
      child: IndexedStack(index: _selectedIndex, children: [
        StudyDeckTab(
            language: _language,
            target: _learningTarget,
            isActive: _selectedIndex == 0),
        HskLibraryTab(language: _language),
        PracticeTab(language: _language, target: _learningTarget),
        GrammarTab(language: _language),
        SavedWordsTab(language: _language),
        active.isTeacher && learner.isTeacher
            ? ListView(
                padding: const EdgeInsets.all(28),
                children: [
                  Text(_language.text('Twoi uczniowie', '学生名单', '學生名單'),
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 12),
                  Text(_language.text(
                    'Wybierz ucznia, aby otworzyć jego zeszyt lekcji i postępy.',
                    '选择学生以打开课堂笔记和学习进度。',
                    '選擇學生以開啟課堂筆記和學習進度。',
                  )),
                  const SizedBox(height: 20),
                  for (final student
                      in profiles.where((profile) => !profile.isTeacher))
                    Card(
                        child: ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(student.name),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () => _switchProfile(student.id, student: true),
                    )),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: _createProfile,
                      icon: const Icon(Icons.person_add_alt_1),
                      label:
                          Text(_language.text('Dodaj profil', '添加档案', '新增檔案')),
                    ),
                  ),
                ],
              )
            : ClassroomScreen(
                language: _language,
                profileId: learner.id,
                studentName: learner.name,
                teacherMode: active.isTeacher,
              ),
        ChengyuScreen(language: _language),
        _settings(),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profiles = context.watch<ProfileProvider>();
    final active = profiles.activeProfile;
    final colors = Theme.of(context).colorScheme;
    final wide = MediaQuery.sizeOf(context).width >= 1100;
    final navigation = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          child: Text(appDisplayName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  )),
        ),
        for (var i = 0; i < _labels.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              leading: Icon(_icons[i]),
              title: Text(_labels[i]),
              selected: _selectedIndex == i,
              selectedTileColor: colors.primaryContainer,
              selectedColor: colors.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              onTap: () {
                navigateToScreen(i);
                if (!wide) Navigator.pop(context);
              },
            ),
          ),
        const SizedBox(height: 24),
        StudyEncouragement(language: _language),
      ],
    );
    return Scaffold(
      drawer: wide ? null : Drawer(child: navigation),
      appBar: wide ? null : AppBar(title: Text(appDisplayName)),
      body: SafeArea(
          child: Row(children: [
        if (wide) ...[
          SizedBox(width: 238, child: navigation),
          const VerticalDivider(width: 1),
        ],
        Expanded(
            child: Column(children: [
          Material(
            color: colors.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                      width: 230,
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: active.id,
                        onChanged: _switching
                            ? null
                            : (id) {
                                if (id != null) _switchProfile(id);
                              },
                        items: [
                          for (final profile in profiles.profiles)
                            DropdownMenuItem(
                                value: profile.id,
                                child: Text(
                                  '${profile.isTeacher ? _language.text("Nauczyciel", "教师", "教師") : _language.text("Uczeń", "学生", "學生")}: ${profile.name}',
                                  overflow: TextOverflow.ellipsis,
                                )),
                        ],
                      )),
                  IconButton(
                    tooltip: _language.text('Dodaj profil', '添加档案', '新增檔案'),
                    onPressed: _switching ? null : _createProfile,
                    icon: const Icon(Icons.person_add_alt_1),
                  ),
                  if (active.isTeacher)
                    SizedBox(
                        width: 210,
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: Text(
                              _language.text('Wybierz ucznia', '选择学生', '選擇學生')),
                          value: _studentId,
                          onChanged: _switching
                              ? null
                              : (id) {
                                  if (id != null)
                                    _switchProfile(id, student: true);
                                },
                          items: [
                            for (final student
                                in profiles.profiles.where((p) => !p.isTeacher))
                              DropdownMenuItem(
                                  value: student.id,
                                  child: Text(student.name,
                                      overflow: TextOverflow.ellipsis)),
                          ],
                        )),
                  SegmentedButton<LearningTarget>(
                    showSelectedIcon: false,
                    segments: [
                      for (final target in LearningTarget.values)
                        ButtonSegment(
                            value: target,
                            label: Text(target.label(_language))),
                    ],
                    selected: {_learningTarget},
                    onSelectionChanged: (value) =>
                        _setLearningTarget(value.first),
                  ),
                  _languageControl(),
                  Consumer<WordProvider>(
                    builder: (context, words, _) => Text(
                      _language.text(
                        'Opanowane: ${words.learnedWordsCount} · Do nauki: ${words.savedForStudyCount}',
                        '已掌握：${words.learnedWordsCount} · 待学习：${words.savedForStudyCount}',
                        '已掌握：${words.learnedWordsCount} · 待學習：${words.savedForStudyCount}',
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  if (wide)
                    Tooltip(
                      message: _language.text(
                        'Jedno nowe słowo to już postęp.',
                        '学会一个新词，就是进步。',
                        '學會一個新詞，就是進步。',
                      ),
                      child: const ExcludeSemantics(
                        child: Text('🌱', style: TextStyle(fontSize: 26)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          if (_switching) const LinearProgressIndicator(),
          Expanded(
              child: AbsorbPointer(
            absorbing: _switching,
            child: FocusScope(
              canRequestFocus: !_switching,
              child: StudyAtmosphere(
                  child: _restoringWorkspace
                      ? const Center(child: CircularProgressIndicator())
                      : _pages(active, profiles.profiles)),
            ),
          )),
        ])),
      ])),
    );
  }

  Widget _languageControl() => SegmentedButton<AppLanguage>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(
              value: AppLanguage.polish, label: Text('PL'), tooltip: 'Polski'),
          ButtonSegment(
              value: AppLanguage.simplifiedChinese,
              label: Text('简'),
              tooltip: '简体中文'),
          ButtonSegment(
              value: AppLanguage.traditionalChinese,
              label: Text('繁'),
              tooltip: '繁體中文'),
        ],
        selected: {_language},
        onSelectionChanged: (value) => _setLanguage(value.first),
      );

  Widget _settings() {
    final appearance = context.watch<AppearanceProvider>();
    final profiles = context.watch<ProfileProvider>();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(_language.text('Twoja przestrzeń do nauki.', '学习偏好。', '學習偏好。'),
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),
        _SettingsCard(
          title: _language.text('Motyw i czytelność', '主题与阅读', '主題與閱讀'),
          description: _language.text('Wygląd zapisujemy na tym urządzeniu.',
              '外观设置保存在本机。', '外觀設定儲存在本機。'),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, children: [
              for (final value in AppAppearance.values)
                ChoiceChip(
                  label: Text(switch (value) {
                    AppAppearance.paper => _language.text('Papier', '纸色', '紙色'),
                    AppAppearance.jade => _language.text('Jadeit', '翡翠', '翡翠'),
                    AppAppearance.midnight => _language.text('Noc', '夜间', '夜間'),
                  }),
                  selected: appearance.appearance == value,
                  onSelected: (_) async {
                    try {
                      await appearance.setAppearance(value);
                    } catch (error) {
                      _showError(error);
                    }
                  },
                ),
            ]),
            Text(_language.text('Rozmiar tekstu', '文字大小', '文字大小')),
            Slider(
              min: 1,
              max: 1.3,
              divisions: 3,
              value: appearance.textScale,
              label: '${(appearance.textScale * 100).round()}%',
              onChanged: (value) async {
                try {
                  await appearance.setTextScale(value);
                } catch (error) {
                  _showError(error);
                }
              },
            ),
          ]),
        ),
        _SettingsCard(
          title: _language.text('Język interfejsu', '界面语言', '介面語言'),
          description: _language.text('Wybierz polski lub zapis chiński.',
              '选择波兰语或中文书写形式。', '選擇波蘭語或中文書寫形式。'),
          child: _languageControl(),
        ),
        _SettingsCard(
          title: _language.text('Dane i kopia zapasowa', '数据与备份', '資料與備份'),
          description: _language.text(
            'Postępy są przypisane do profilu i przechowywane poza plikami aplikacji. '
                'Pełna kopia może zawierać prywatne dane uczniów. Nie wysyłaj jej zamiast pakietu lekcji.',
            '进度按档案保存在应用文件之外。完整备份可能包含学生隐私，请勿将其当作课堂包分享。',
            '進度按檔案儲存在應用檔案之外。完整備份可能包含學生隱私，請勿將其當作課堂包分享。',
          ),
          child: Wrap(spacing: 12, runSpacing: 8, children: [
            OutlinedButton.icon(
              onPressed: _exportBackup,
              icon: const Icon(Icons.download),
              label: Text(_language.text('Eksport kopii', '导出备份', '匯出備份')),
            ),
            OutlinedButton.icon(
              onPressed: _importBackup,
              icon: const Icon(Icons.upload),
              label: Text(_language.text('Przywróć kopię', '恢复备份', '還原備份')),
            ),
            if (profiles.backups.isNotEmpty)
              OutlinedButton.icon(
                onPressed: _restoreLocalBackup,
                icon: const Icon(Icons.restore),
                label: Text(_language.text(
                    'Lokalne punkty odzyskiwania', '本机恢复点', '本機還原點')),
              ),
          ]),
        ),
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows)
          _WindowsUpdatesCard(
            language: _language,
            installUpdate: (update, onProgress) =>
                _installUpdate(update, onProgress: onProgress),
          ),
        _SettingsCard(
          title: appDisplayName,
          description: _language.text(
            '11 105 haseł HSK 2025. Lokalne profile, lekcje i nauka w obu kierunkach. '
                'Profile nie są kontami i nie zapewniają kontroli dostępu.',
            '11,105 个 HSK 2025 词条。本地档案、课堂与双向学习。档案不是账户，不提供访问保护。',
            '11,105 個 HSK 2025 詞條。本地檔案、課堂與雙向學習。檔案不是帳戶，不提供存取保護。',
          ),
        ),
      ],
    );
  }

  Future<void> _exportBackup() async {
    try {
      await ClassroomStore.flushAll();
      if (!mounted) return;
      await context.read<WordProvider>().flush();
      if (!mounted) return;
      final json = await context.read<ProfileProvider>().exportBackup();
      final bytes = utf8.encode(json);
      if (bytes.length > _maxBackupBytes) {
        throw FormatException(_language.text(
          'Pełna kopia przekracza limit 32 MB. Nie zapisano pliku, którego nie można przywrócić. Wyeksportuj lekcje ze zdjęciami osobno.',
          '完整备份超过 32 MB，未保存无法恢复的文件。请将含图片的课堂单独导出。',
          '完整備份超過 32 MB，未儲存無法還原的檔案。請將含圖片的課堂單獨匯出。',
        ));
      }
      await savePortableFile(
        suggestedName: 'polski-chinese-backup.json',
        bytes: bytes,
      );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _importBackup() async {
    var restoring = false;
    try {
      final file = await openFile(acceptedTypeGroups: [
        const XTypeGroup(label: 'Backup JSON', extensions: ['json']),
      ]);
      if (file == null || !mounted) return;
      if (await file.length() > _maxBackupBytes) {
        throw const FormatException('Backup exceeds 32 MB.');
      }
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_language.text('Przywrócić kopię?', '恢复备份？', '還原備份？')),
          content: Text(_language.text(
            'Ta operacja zastąpi lokalne profile i postępy danymi z kopii. Najpierw wyeksportuj bieżące dane.',
            '此操作将用备份替换本机档案和进度。请先导出当前数据。',
            '此操作將用備份取代本機檔案和進度。請先匯出目前資料。',
          )),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(_language.text('Anuluj', '取消', '取消'))),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(_language.text('Przywróć', '恢复', '還原'))),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      if (_switching) return;
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() {
        _switching = true;
        _restoringWorkspace = true;
        _studentId = null;
      });
      restoring = true;
      final profiles = context.read<ProfileProvider>();
      final words = context.read<WordProvider>();
      await WidgetsBinding.instance.endOfFrame;
      await words.flush();
      await ClassroomStore.flushAll();
      await profiles.importBackup(await file.readAsString());
      if (mounted)
        setState(() {
          _studentId = null;
          _workspaceGeneration++;
        });
    } catch (error) {
      _showError(error);
    } finally {
      if (restoring && mounted) {
        try {
          await context.read<WordProvider>().setProfile(
                context.read<ProfileProvider>().activeProfile.id,
              );
        } catch (error) {
          _showError(error);
        }
        if (mounted)
          setState(() {
            _switching = false;
            _restoringWorkspace = false;
          });
      }
    }
  }

  Future<void> _restoreLocalBackup() async {
    final profiles = context.read<ProfileProvider>();
    final selected = await showDialog<DateTime>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(
            _language.text('Przywrócić stan z kopii?', '恢复到备份状态？', '還原至備份狀態？')),
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(_language.text(
              'Przywrócenie zastąpi obecne profile, lekcje i postępy. Bieżący stan zostanie najpierw zapisany.',
              '恢复将替换当前档案、课堂和进度。操作前会先保存当前状态。',
              '還原將取代目前檔案、課堂和進度。操作前會先儲存目前狀態。',
            )),
          ),
          for (final backup in profiles.backups)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, backup.createdAt),
              child: Text(
                  '${backup.createdAt.toLocal()} · ${backup.profileCount} '
                  '${_language.text("profili", "个档案", "個檔案")} · ${backup.reason}'),
            ),
        ],
      ),
    );
    if (selected == null || !mounted) return;
    if (_switching) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _switching = true;
      _restoringWorkspace = true;
      _studentId = null;
    });
    try {
      final words = context.read<WordProvider>();
      await WidgetsBinding.instance.endOfFrame;
      await words.flush();
      await ClassroomStore.flushAll();
      await profiles.restoreBackupSnapshot(selected);
      if (mounted)
        setState(() {
          _studentId = null;
          _workspaceGeneration++;
        });
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        try {
          await context
              .read<WordProvider>()
              .setProfile(profiles.activeProfile.id);
        } catch (error) {
          _showError(error);
        }
        if (mounted)
          setState(() {
            _switching = false;
            _restoringWorkspace = false;
          });
      }
    }
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard(
      {required this.title, required this.description, this.child});
  final String title;
  final String description;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(description),
            if (child != null) ...[const SizedBox(height: 16), child!],
          ]),
        ),
      );
}

class _WindowsUpdatesCard extends StatefulWidget {
  const _WindowsUpdatesCard(
      {required this.language, required this.installUpdate});
  final AppLanguage language;
  final Future<void> Function(WindowsUpdate, ValueChanged<double>)
      installUpdate;

  @override
  State<_WindowsUpdatesCard> createState() => _WindowsUpdatesCardState();
}

class _WindowsUpdatesCardState extends State<_WindowsUpdatesCard> {
  WindowsUpdate? _update;
  bool _busy = false;
  bool _checked = false;
  double? _progress;
  String? _error;

  Future<void> _run({bool install = false}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (install) {
        final update = _update;
        if (update == null) throw StateError('Check for an update first.');
        await widget.installUpdate(update, (value) {
          if (mounted) setState(() => _progress = value);
        });
      } else {
        final update = await WindowsUpdater.checkForUpdate();
        if (mounted)
          setState(() {
            _update = update;
            _checked = true;
          });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted)
        setState(() {
          _busy = false;
          _progress = null;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = widget.language;
    return _SettingsCard(
      title: language.text('Aktualizacje aplikacji', '应用更新', '應用程式更新'),
      description: _error ??
          (_update != null
              ? language.text('Dostępna wersja ${_update!.version}.',
                  '新版本 ${_update!.version}。', '新版本 ${_update!.version}。')
              : _checked
                  ? language.text('Masz aktualną wersję ($appVersion).',
                      '已是最新版本（$appVersion）。', '已是最新版本（$appVersion）。')
                  : language.text(
                      'Bieżąca wersja: $appVersion. Dane zapisujemy przed aktualizacją.',
                      '当前版本：$appVersion。更新前会保存数据。',
                      '目前版本：$appVersion。更新前會儲存資料。')),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_busy) ...[
          LinearProgressIndicator(value: _progress),
          const SizedBox(height: 12)
        ],
        Wrap(spacing: 12, runSpacing: 8, children: [
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _run(),
            icon: const Icon(Icons.refresh),
            label: Text(language.text('Sprawdź aktualizacje', '检查更新', '檢查更新')),
          ),
          if (_update != null)
            FilledButton.icon(
              onPressed: _busy ? null : () => _run(install: true),
              icon: const Icon(Icons.download),
              label: Text(language.text(
                  'Pobierz i uruchom ponownie', '下载并重启', '下載並重新啟動')),
            ),
        ]),
      ]),
    );
  }
}
