import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const datasets = [
    'assets/data/hsk2025_1_words.json',
    'assets/data/hsk2025_2_words.json',
    'assets/data/hsk2025_3_words.json',
    'assets/data/hsk2025_4_words.json',
    'assets/data/hsk2025_5_words.json',
    'assets/data/hsk2025_6_words.json',
    'assets/data/hsk2025_7_9_words.json',
  ];
  const corrections = <String, String>{
    'HSK-4|178': 'ustalać; określać; decydować; zamawiać; ustalony; stabilny',
    'HSK-4|455': 'pusty; powietrze; niebo; na próżno',
    'HSK-4|456': 'opróżniać; wolny; nieobsadzony; wolne miejsce; wolny czas',
    'HSK-4|549':
        'serce; najgłębsze uczucia i myśli; świat wewnętrzny; (geom.) środek okręgu wpisanego',
    'HSK-4|903': 'przyjazny; życzliwy; przyjaźń',
    'HSK-3|328': 'zamiatać; zamieść',
    'HSK-3|409': 'bagaż; rzeczy podróżne',
    'HSK-3|432': 'łącznie; w sumie; razem (ogółem)',
    'HSK-3|444': 'sądzić; uważać; myśleć (często błędnie)',
    'HSK-3|487': 'tylko; jedynie; mieć tylko; istnieć tylko',
    'HSK-2|36':
        'partykuła łącząca czasownik z określeniem rezultatu, stopnia lub możliwości',
    'HSK-2|52':
        'partykuła doświadczenia: wskazuje, że dana czynność miała miejsce wcześniej',
    'HSK-2|74': 'bliski; niedaleko; w pobliżu; około',
    'HSK-2|119': 'biegać; truchtać; (wojskowo) maszerować biegiem',
    'HSK-2|193': 'tak; w ten sposób; taki; tak dużo',
    'HSK-4|105': 'ponownie; powtarzać; warstwa',
    'HSK-5|209': 'miejsce; placówka; biuro; dział',
    'HSK-6|315':
        'dì dao: autentyczny; prawdziwy; idiomatyczny; dì dào: tunel; przejście podziemne',
    'HSK-7-9|897':
        'dì dao: autentyczny; prawdziwy; idiomatyczny; dì dào: tunel; przejście podziemne',
    'HSK-7-9|2798': 'oszukiwać; zgadywać na ślepo; być zdezorientowanym',
    'HSK-7-9|2800':
        'zasłaniać; pokrywać; nieświadomy; doznawać (nieszczęścia); otrzymywać (przysługę)',
    'HSK-6|1139': 'zatykać; wpychać; upychać; korek; zatyczka',
    'HSK-6|1810':
        'zuān: wiercić; przeciskać się; zgłębiać; zuàn: wiertło; diament',
    'HSK-4|751': 'badanie lekarskie; badanie kontrolne',
    'HSK-5|626': 'zapis; relacja pisemna; rekord (np. sportowy)',
    'HSK-7-9|447': 'mieszać; dodawać domieszkę; fałszować przez domieszanie',
    'HSK-7-9|652': 'prostolinijny; szczery; bezpretensjonalny',
    'HSK-7-9|852':
        'wyraźnie zadowolony z siebie; triumfujący; z miną pełną samozadowolenia',
    'HSK-7-9|2731': 'gadatliwy; rozwlekły; zrzędzić; uciążliwy',
    'HSK-7-9|2889':
        'hartować (charakter); doskonalić (umiejętności) przez ćwiczenie',
    'HSK-7-9|4345':
        'nie zasługiwać na surową krytykę; dać się usprawiedliwić w danych okolicznościach',
    'HSK-3|78': 'mniej więcej; około; prawdopodobnie; ogólny zarys',
    'HSK-3|190': 'spotkanie; zebranie; konferencja',
    'HSK-4|125': 'istnieć; przechowywać; zdeponować; zachować; przetrwać',
    'HSK-4|136': 'osiągnąć; dojść do; dotrzeć do',
    'HSK-4|205': 'wydać (rozkaz); wysłać; wyemitować; wydać (dźwięk)',
    'HSK-4|402': 'policja; policjant',
    'HSK-4|552': 'zdolność; umiejętność; możliwości',
    'HSK-4|577':
        'zepsuty; uszkodzony; zniszczyć; rozbić; złamać; pokonać; ujawnić',
    'HSK-4|601': 'sytuacja; okoliczności; stan rzeczy',
    'HSK-4|671': 'sprawiać; powodować; umożliwiać; używać; posyłać; kazać',
    'HSK-4|858': 'naciskać; przyciskać; dociskać; tłumić; presja',
    'HSK-4|874': 'aktor; aktorka; wykonawca',
    'HSK-4|941': 'odpowiedzialność; obowiązek; wina',
    'HSK-4|974': 'zawód; profesja; zawodowy',
    'HSK-4|1013': 'dzieło; utwór (artystyczny lub literacki)',
    'HSK-5|17':
        'wstawać; podnosić się; wyruszać; zaczynać; pojawiać się; zakładać; odbierać; od (czasu, miejsca lub ceny); klasyfikator zdarzeń i grup',
    'HSK-5|90': 'wskazywać; wykazywać; jasno stwierdzać',
    'HSK-5|200': 'być pełnym; przepełniać; roić się od; napełniać',
    'HSK-5|241': 'zajmować się; podejmować się; wykonywać',
    'HSK-5|313':
        'diào: przenosić służbowo; badać (调查); ton; melodia; tiáo: regulować; dostosowywać; przyprawiać',
    'HSK-5|371': 'zapobiegać; chronić przed; podejmować środki ostrożności',
    'HSK-5|375': 'zakres; zasięg; granice',
    'HSK-5|402': 'zaprzeczać; negować; nie uznawać',
    'HSK-5|448': 'narzędzie; przyrząd; instrument; środek',
    'HSK-5|636': 'duch; umysł; świadomość; psychika; istota; sedno',
    'HSK-5|772': 'powód; przyczyna; uzasadnienie; racja',
    'HSK-5|789': 'zaspokajać; spełniać (wymagania); być zadowolonym',
    'HSK-5|897': 'podkreślać; kłaść nacisk na',
    'HSK-5|941':
        'pewny; ustalony; określić; potwierdzić; upewnić się; przycisk „OK”',
    'HSK-5|960': 'ludzkość; rodzaj ludzki; ludzie',
    'HSK-5|1008': 'sprzęt; wyposażenie; urządzenia; instalacje',
    'HSK-5|1070': 'wdrażać; realizować; wprowadzać w życie; stosować',
    'HSK-5|1147': 'cecha charakterystyczna; wyróżnik; specyfika',
    'HSK-5|1156':
        'diào: przenosić służbowo; badać (调查); ton; melodia; tiáo: regulować; dostosowywać; przyprawiać',
    'HSK-5|1288': 'pokazywać; wyświetlać; przedstawiać; ukazywać; wskazywać',
    'HSK-5|1447': 'przewaga; atut; mocna strona; dominacja',
    'HSK-5|1589': 'prowadzić; kierować; przewodniczyć; prowadzić program',
    'HSK-6|5': 'mniej więcej; około; prawdopodobnie; ogólny zarys',
    'HSK-6|431': 'przekształcać; przebudowywać; reformować; przerabiać',
    'HSK-6|1345': 'grupa; organizacja; zespół',
    'HSK-7-9|878':
        'diào: przenosić służbowo; badać (调查); ton; melodia; tiáo: regulować; dostosowywać; przyprawiać',
    'HSK-7-9|2160': 'duch; umysł; świadomość; psychika; istota; sedno',
  };
  const reviewedSenses = <String, String>{
    '权': 'prawo; uprawnienie; władza',
    '吧': 'partykuła sugestii lub prośby',
    '词': 'słowo; wyraz; tekst piosenki',
    '鱼': 'ryba',
    '草': 'trawa',
    '船': 'statek; łódź',
    '加': 'dodawać; zwiększać',
    '戴': 'nosić (np. kapelusz, okulary, biżuterię)',
    '懂': 'rozumieć; pojmować',
    '交通': 'ruch uliczny; transport; komunikacja',
    '教师': 'nauczyciel; nauczycielka',
    '信用卡': 'karta kredytowa',
    '重点': 'główny punkt; sedno; priorytet',
    '全身': 'całe ciało',
    '自由': 'wolność; swoboda; wolny',
    '躺': 'leżeć; kłaść się',
    '承担': 'podejmować się; brać na siebie; ponosić (odpowiedzialność)',
    '承受': 'znosić; wytrzymywać; dźwigać (ciężar)',
    '简历': 'życiorys; CV',
    '利益': 'korzyść; interes; pożytek',
    '培训': 'szkolenie; szkolić',
    '手工': 'praca ręczna; rękodzieło; ręczny',
    '手术': 'operacja chirurgiczna; zabieg',
    '吸管': 'słomka do picia; pipeta; rurka',
    '字母': 'litera alfabetu',
    '遗传': 'dziedziczność; dziedziczenie cech; przekazywać genetycznie',
    '突破口': 'punkt przełomowy; wyłom; punkt wyjścia do przełomu',
  };
  const reviewedReadings = <String, String>{
    'HSK-4|92': 'chà (yì) diǎnr',
    'HSK-6|1810': 'zuān',
    'HSK-1|2': 'ba',
    'HSK-1|114': 'ma',
    'HSK-1|131': 'nà',
    'HSK-1|174': 'shàng',
    'HSK-4|40': 'bèi',
    'HSK-4|304': 'hàn',
    'HSK-5|528': 'huà',
    'HSK-7-9|1735': 'huǎng',
    'HSK-7-9|1736': 'huàng',
    'HSK-7-9|1862': 'jì',
    'HSK-7-9|2796': 'mēn',
    'HSK-7-9|2797': 'mèn',
    'HSK-7-9|2812': 'mí',
    'HSK-7-9|4388': 'xiā',
  };

  test('all HSK 2025 entries have Polish glosses and review notes', () async {
    var total = 0;
    var reviewNotes = 0;
    final entries = <String, Map<String, dynamic>>{};

    for (final path in datasets) {
      final source = await rootBundle.loadString(path);
      final words = jsonDecode(source) as List<dynamic>;
      total += words.length;

      for (final value in words) {
        final word = value as Map<String, dynamic>;
        final key = '${word['level']}|${word['frequency']}';
        expect(word['polish'], isA<String>());
        expect((word['polish'] as String).trim(), isNotEmpty, reason: key);
        final polish = word['polish'] as String;
        expect(polish.length, lessThanOrEqualTo(170), reason: key);
        expect(
          RegExp(r'^[\u3400-\u9fff\s]+$').hasMatch(polish),
          isFalse,
          reason: 'Untranslated Chinese gloss: $key',
        );
        expect(
          RegExp(r'[a-z]_[a-z]|m\.\s*\[|^Wersja \d|^Odmiana:|CL:')
              .hasMatch(polish),
          isFalse,
          reason: 'Machine translation artifact: $key',
        );
        final reviewed = reviewedSenses[word['hanzi']];
        if (reviewed != null) {
          expect(polish, reviewed, reason: key);
        }
        entries[key] = word;
        if ((word['notes'] as String? ?? '').contains('Review:')) {
          reviewNotes++;
        }
      }
    }

    expect(total, 11105);
    expect(reviewNotes, 23);
    for (final correction in corrections.entries) {
      expect(
        entries[correction.key]?['polish'],
        correction.value,
        reason: correction.key,
      );
    }
    for (final reading in reviewedReadings.entries) {
      expect(entries[reading.key]?['pinyin'], reading.value,
          reason: reading.key);
    }
    for (final key in ['HSK-1|5', 'HSK-5|933', 'HSK-7-9|18']) {
      expect(
        entries[key]?['english'],
        isNot(startsWith('surname ')),
        reason: 'Common-word sense must precede surname: $key',
      );
    }
    expect(entries['HSK-1|5']?['english'], contains('hundred'));
    expect(entries['HSK-1|2']?['english'], contains('particle'));
    for (final key in [
      'HSK-4|751',
      'HSK-5|626',
      'HSK-6|1418',
      'HSK-7-9|95',
      'HSK-7-9|248',
      'HSK-7-9|447',
      'HSK-7-9|652',
      'HSK-7-9|852',
      'HSK-7-9|2731',
      'HSK-7-9|2889',
      'HSK-7-9|4345',
      'HSK-7-9|4474',
      'HSK-7-9|4571',
      'HSK-7-9|4732',
      'HSK-7-9|4963',
      'HSK-7-9|5619',
    ]) {
      expect(
        RegExp(r'^(see |variant of|abbr\.)')
            .hasMatch(entries[key]!['english'] as String),
        isFalse,
        reason: 'Curated entry must explain its meaning directly: $key',
      );
    }
  });

  test('source shards and reviewed overrides match shipped vocabulary',
      () async {
    final words = <String, Map<String, dynamic>>{};
    for (final path in datasets) {
      final values = jsonDecode(await rootBundle.loadString(path)) as List;
      for (final value in values) {
        final word = value as Map<String, dynamic>;
        words['${word['level']}|${word['frequency']}'] = word;
      }
    }
    var sourceEntries = 0;
    final overrides = jsonDecode(
      File('assets/data/sources/hsk-2025/sense_overrides.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final file in Directory('assets/data').listSync().whereType<File>()) {
      if (!RegExp(r'hsk2025_polish_\d{4}_\d{4}\.json$').hasMatch(file.path)) {
        continue;
      }
      final shard = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      for (final entry in shard.entries) {
        sourceEntries++;
        final source = entry.value as Map<String, dynamic>;
        final override = overrides[entry.key] as Map<String, dynamic>?;
        for (final field in ['polish', 'pinyin', 'english']) {
          final expected = override?.containsKey(field) == true
              ? override![field]
              : source[field];
          if (expected != null) {
            expect(words[entry.key]?[field], expected, reason: entry.key);
          }
        }
      }
    }
    expect(sourceEntries, 8280);
    for (final entry in overrides.entries) {
      final source = entry.value as Map<String, dynamic>;
      for (final field in source.keys) {
        expect(words[entry.key]?[field], source[field],
            reason: '${entry.key}: reviewed $field');
      }
    }
  });

  test('curated beginner and erhua meanings retain their intended senses',
      () async {
    final words = <String, Map<String, dynamic>>{};
    for (final path in datasets) {
      for (final value
          in jsonDecode(await rootBundle.loadString(path)) as List) {
        final word = value as Map<String, dynamic>;
        words['${word['level']}|${word['frequency']}'] = word;
      }
    }
    final beginnerIds = words.keys.where((id) => id.startsWith('HSK-1|'));
    expect(beginnerIds.toSet(), {
      for (var frequency = 1; frequency <= 300; frequency++) 'HSK-1|$frequency'
    });
    expect(words['HSK-1|157']?['pinyin'], 'pián yi');
    expect(words['HSK-1|157']?['english'], 'cheap; inexpensive; a bargain');
    expect(words['HSK-1|230']?['english'], 'Mr.; sir; gentleman; husband');
    expect(words['HSK-1|268']?['polish'],
        'juan (jednostka waluty); podstawowy; pierwotny');
    expect(words['HSK-1|218']?['polish'], 'halo (przy odbieraniu telefonu)');
    expect(words['HSK-1|10']?['polish'], 'klasyfikator książek i zeszytów');
    expect(
        words['HSK-1|58']?['polish'], 'ogólny klasyfikator osób i przedmiotów');
    const erhuaDefinitions = {
      'HSK-1|126': 'noodles (erhua form)',
      'HSK-1|256': 'a little; a bit; a small amount (erhua form)',
      'HSK-2|113': 'boy (erhua form)',
      'HSK-2|116': 'girl (erhua form)',
      'HSK-2|163': 'child; kid (erhua form)',
      'HSK-3|261': 'to chat; to have an informal conversation (erhua form)',
      'HSK-3|434': 'together; in the same place; one piece (erhua form)',
      'HSK-6|258': 'everyone; everybody; all of us or you (colloquial)',
      'HSK-7-9|743': 'to doze; to nod off; to take a short nap (erhua form)',
      'HSK-7-9|2509': "one's husband or wife in old age; elderly spouse",
      'HSK-7-9|2933':
          'to be puzzled; to wonder why; to be unable to understand (erhua form)',
      'HSK-7-9|3443':
          'popularity; rapport with other people; social appeal (erhua form)',
      'HSK-7-9|4240':
          'thing; object; toy; gadget; trick or act in a performance (colloquial)',
    };
    for (final entry in erhuaDefinitions.entries) {
      expect(words[entry.key]?['english'], entry.value, reason: entry.key);
    }
    expect(words['HSK-7-9|3443']?['polish'],
        'sympatia otoczenia; popularność wśród ludzi; dobre stosunki z ludźmi');
  });
}
