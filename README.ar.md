<div dir="rtl">

# Flutter AI Skills

مجموعة **guardrails** لـ Claude Code وCursor بتخلّي الكود اللي الـ AI بيكتبه في Flutter ماشي على الـ **stack** والـ **versions** والـ **architecture** بتاعة مشروعك. ومحدش يعلن إن الـ task خلصت قبل ما الـ **analyzer** يعدّي.

الفكرة مستوحاة من [andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills)، بس مخصوصة لـ Flutter. الفرق الأساسي إن القواعد هنا مش مجرد كلام في prompt، لأن فيه **hooks بتعمل enforce ليها** وقت التنفيذ.

[English](./README.md) | العربية

## المشكلة

الـ LLMs وهي بتكتب Flutter بتقع في نفس الأخطاء كل مرة:

- **APIs من major version غلط:** الـ training data فيها freezed 2 و3، وbloc من 7 لـ 9، وgo_router من 6 لـ 17، وdio 4 و5، كلهم مع بعض.
- **Dependencies ملهاش لازمة:** تلاقي HTTP client تاني، أو state management solution تاني، أو version number مش موجود أصلًا.
- **تجاهل الـ architecture:** المشروع ماشي بـ Cubit وget_it وrepository layer، والموديل يكتب `ChangeNotifier` جواه `http.get` مباشرة.
- **Deprecated APIs:** زي `withOpacity` و`WillPopScope` و`MaterialStateProperty` و`DioError`.
- **Runtime crashes:** `BuildContext` بيتستخدم بعد `await`، وcontrollers مبتعملش dispose، وkey ناقص في `Info.plist` يوقّع التطبيق على iOS.
- **Generated files:** يعدّل `*.g.dart` بإيده، أو ينسى يشغّل `build_runner`.
- **Hardcoded strings وLTR-only layouts** في تطبيقات بتدعم العربي.
- **يقول "Done"** من غير ما يشغّل `flutter analyze`.

## الـ Components

| Component | الـ Responsibility |
|---|---|
| `CLAUDE.md` | الـ core rules في file واحد، تقدر تحطه في أي Flutter project |
| `skills/flutter-guidelines` | نفس الـ core rules بس كـ skill، وبيتعملها load أي وقت Claude يكتب Dart |
| `skills/flutter-packages` | workflow عام بيشتغل مع **أي** package: يقرا `pubspec.lock`، ويعمل verify للـ API من الـ source الحقيقي في `~/.pub-cache`، ويمشي على الـ package اللي المشروع مستخدمها أصلًا. ومعاه reference notes لـ bloc وprovider وriverpod وgetx وget_it وinjectable وdio وretrofit وhttp وfreezed وjson_serializable وequatable وgo_router وauto_route وshared_preferences وhive / hive_ce وisar وdrift وFirebase والـ native plugins وscreenutil وdartz / fpdart. وبيتعمل load بس للـ references الخاصة بالـ packages اللي في مشروعك |
| `skills/flutter-ui` | screens تبقى polished ومتسقة مع باقي التطبيق. الأول بيدوّر على الـ design system الموجود (theme وtokens وshared widgets وأقرب screen شبهها) ويعمله reuse، ولو فيه Figma design بيلتزم بيه بالظبط. وبيفرض إن كل screen يبقى ليها loading وempty وerror وsuccess states، وبيعمل check على الـ thumb zone والـ accessibility والـ keyboard والـ safe area والـ text scaling والـ dark mode والـ RTL. ومعاه code جاهز للـ tokens (`ThemeExtension`) والـ skeletons والـ empty/error views، وwidget test بيفشل لو حصل overflow على عرض 320px مع text scale 2× وRTL. الـ design principles متاخدة (adapted) من [ceorkm/mobile-app-ui-design](https://github.com/ceorkm/mobile-app-ui-design) |
| `skills/flutter-testing` | الـ verification loop، والـ bug fix بيبدأ بـ failing test، وbloc / widget / golden tests بالـ tooling الموجود في المشروع |
| `skills/flutter-l10n-rtl` | easy_localization وgen-l10n وslang، وRTL-safe layout، وformatting للأرقام والتواريخ والفلوس |
| `hooks/session-context.sh` | **SessionStart:** بيطبع الـ Flutter version (وبيقرا FVM)، وكل direct dependency بالـ locked version بالظبط، متقسمين حسب الـ responsibility. ولو فيه أكتر من package بتعمل نفس الوظيفة بيطلّع warning |
| `hooks/dart-check.sh` | **PostToolUse:** بعد أي edit في file بامتداد `.dart`، بيشغّل `dart format` و`dart analyze` بالـ SDK بتاع المشروع نفسه. الـ errors والـ warnings بترجع لـ Claude على طول يعملها fix. وبيفكّره بـ `build_runner` لو الـ generated `part` file بقى stale |
| `.cursor/rules/` | الـ core rules كـ Cursor project rule |
| `EXAMPLES.md` | أمثلة before/after لكل rule |

### الـ Output في أول الـ Session (من project حقيقي)

<div dir="ltr">

```
## Flutter project stack (from pubspec.lock — trust these versions over memory)
Flutter (FVM): 3.44.4  → use `fvm flutter` / `fvm dart`
  State:             flutter_bloc 9.1.1
  DI:                get_it 8.3.0, injectable 2.7.1+4
  Network:           dio 5.9.2, retrofit 4.9.2
  Models:            freezed 3.2.5, freezed_annotation 3.1.0, json_serializable 6.11.4
  Storage:           shared_preferences 2.5.5, hive_ce 2.19.3
  Localization:      easy_localization 3.0.8
⚠ Multiple packages for the same job: routing, http+dio. Follow whichever the code you're editing already uses.
```

</div>

## الـ Installation

**Option A: Claude Code plugin (الأفضل، وفيه الـ hooks)**

<div dir="ltr">

```
/plugin marketplace add moustafadev/flutter-ai-skills
/plugin install flutter-ai-skills@flutter-ai-skills
```

</div>

ولو عندك local clone: `/plugin marketplace add /path/to/flutter-ai-skills`

**Option B: `CLAUDE.md` بس (لكل project لوحده، ومن غير hooks)**

<div dir="ltr">

```bash
curl -o CLAUDE.md https://raw.githubusercontent.com/moustafadev/flutter-ai-skills/main/CLAUDE.md
# or append to an existing one
curl https://raw.githubusercontent.com/moustafadev/flutter-ai-skills/main/CLAUDE.md >> CLAUDE.md
```

</div>

**Cursor:** انسخ `.cursor/rules/flutter-guidelines.mdc` جوه `.cursor/rules/` في مشروعك.

### الـ Requirements بتاعة الـ hooks
- `bash`، ومعاه `jq` أو `python3` عشان يعمل parse للـ hook input.
- Dart SDK. الـ hooks بتدوّر عليه بالترتيب ده: `.fvm/flutter_sdk`، بعدين `~/fvm/versions/<version from .fvmrc>`، وفي الآخر `dart` اللي على الـ `PATH`.
- لو ملقتش SDK، أو الـ session مش جوه Flutter project، الـ hooks بتعمل no-op ومبتعملش حاجة.

## الـ Customization

ضيف الـ project-specific rules تحت الـ rules الأساسية:

<div dir="ltr">

```markdown
## Project-specific
- Feature folders: lib/features/<name>/{data,domain,presentation}
- All repositories return Either<Failure, T>
- Colors only from AppColors, text styles only from AppTextStyles
```

</div>

الـ single source of truth هو `CLAUDE.md`. عدّل فيه، وبعدها شغّل `./scripts/sync.sh` عشان يعمل regenerate للـ skill وللـ Cursor rule.

## إزاي تعرف إنه شغال

- مفيش analyzer warnings جديدة بعد الـ edits بتاعة Claude.
- مفيش dependencies غريبة ظهرت فجأة في `pubspec.yaml`.
- الـ features الجديدة شبه القديمة: نفس الـ folder structure، ونفس الـ state classes، ونفس الـ error flow.
- الـ generated files بتتعمل regenerate، ومحدش بيعدّلها بإيده.
- الـ screens بالعربي وبالـ RTL مش محتاجة round تاني من التصليح.
- كل screen جديدة فيها loading وempty وerror states، ومبيحصلهاش overflow لما الخط يكبر.

## الـ Tradeoff

الـ rules دي بتقدّم الـ correctness على الـ speed. في الـ one-line fixes، الموديل المفروض يقدّر الموقف ويستخدم الـ judgment بتاعه.
والـ analyze hook بيزوّد كام ثانية على كل Dart file بيتعمله edit.

## الـ License

MIT

</div>
