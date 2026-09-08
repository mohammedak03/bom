import '../models/question.dart';
import '../models/question_package.dart';

/// Topic catalog. Access is checked before its question bank enters a game.
final questionPackages = <QuestionPackage>[
  QuestionPackage(
    id: 'general',
    name: 'خلطة عامة',
    emoji: '✨',
    description: 'من كل موضوع سؤال... الكل إله فرصة.',
    isFree: true,
    questions: <Question>[
      Question(
        text: 'ما اسم الرياضة التي اشتهر بها مايكل جوردان؟',
        category: 'خلطة عامة',
        packageId: 'general',
      ),
      Question(
        text: 'من رسم لوحة الموناليزا؟',
        category: 'خلطة عامة',
        packageId: 'general',
      ),
      Question(
        text: 'ما اسم الآلة الموسيقية ذات المفاتيح البيضاء والسوداء؟',
        category: 'خلطة عامة',
        packageId: 'general',
      ),
      Question(
        text: 'كم ضلعًا للشكل السداسي؟',
        category: 'خلطة عامة',
        packageId: 'general',
      ),
      Question(
        text: 'كم دقيقة في ساعة ونصف؟',
        category: 'خلطة عامة',
        packageId: 'general',
      ),
      Question(
        text: 'ما اسم صغير الأسد؟',
        category: 'خلطة عامة',
        packageId: 'general',
      ),
      Question(
        text: 'ما الحيوان الذي يُلقّب بسفينة الصحراء؟',
        category: 'خلطة عامة',
        packageId: 'general',
      ),
      Question(
        text: 'ما الحشرة التي تنتج العسل؟',
        category: 'خلطة عامة',
        packageId: 'general',
      ),
      Question(
        text: 'ما الأداة المستخدمة لقياس درجة الحرارة؟',
        category: 'خلطة عامة',
        packageId: 'general',
      ),
      Question(
        text: 'ما اسم الكتاب الذي يجمع معاني الكلمات؟',
        category: 'خلطة عامة',
        packageId: 'general',
      ),
      Question(
        text: 'كم شهرًا في السنة الميلادية؟',
        category: 'خلطة عامة',
        packageId: 'general',
      ),
      Question(
        text: 'ما الشهر الميلادي الذي يأتي بعد سبتمبر؟',
        category: 'خلطة عامة',
        packageId: 'general',
      ),
      Question(
        text: 'أي قطعة في الشطرنج تتحرك على شكل حرف L؟',
        category: 'خلطة عامة',
        packageId: 'general',
      ),
      Question(
        text: 'ما الرياضة التي يستخدم لاعبوها مضربًا وريشة؟',
        category: 'خلطة عامة',
        packageId: 'general',
      ),
      Question(
        text: 'ما اسم السباق الذي تبلغ مسافته نحو 42 كيلومترًا؟',
        category: 'خلطة عامة',
        packageId: 'general',
      ),
      Question(
        text: 'أي لون ينتج عادة من مزج طلاء أحمر وأصفر؟',
        category: 'خلطة عامة',
        packageId: 'general',
      ),
      Question(
        text: 'كم عدد ألوان قوس قزح المتعارف عليها؟',
        category: 'خلطة عامة',
        packageId: 'general',
      ),
      Question(
        text: 'ما اسم فن طي الورق الياباني؟',
        category: 'خلطة عامة',
        packageId: 'general',
      ),
      Question(
        text: 'ما اللغة التي كُتبت بها مسرحيات شكسبير؟',
        category: 'خلطة عامة',
        packageId: 'general',
      ),
      Question(
        text: 'من ألّف رواية «البؤساء»؟',
        category: 'خلطة عامة',
        packageId: 'general',
      ),
      Question(
        text: 'ما اسم الحرفة التي تعتمد على تشكيل الأواني من الطين وحرقها؟',
        category: 'خلطة عامة',
        packageId: 'general',
      ),
      Question(
        text: 'كم يساوي ربع العدد مئة؟',
        category: 'خلطة عامة',
        packageId: 'general',
      ),
      Question(
        text: 'ما اسم الأداة التي تحدد الجهات باستخدام إبرة مغناطيسية؟',
        category: 'خلطة عامة',
        packageId: 'general',
      ),
      Question(
        text: 'أي طائر يرتبط تقليديًا بإيصال الرسائل؟',
        category: 'خلطة عامة',
        packageId: 'general',
      ),
    ],
  ),
  QuestionPackage(
    id: 'countries',
    name: 'دول وعواصم',
    emoji: '🌍',
    description: 'لفة حول العالم من غير تذكرة.',
    isFree: true,
    questions: <Question>[
      Question(
        text: 'ما عاصمة الأردن؟',
        category: 'دول وعواصم',
        packageId: 'countries',
      ),
      Question(
        text: 'ما عاصمة مصر؟',
        category: 'دول وعواصم',
        packageId: 'countries',
      ),
      Question(
        text: 'ما عاصمة فرنسا؟',
        category: 'دول وعواصم',
        packageId: 'countries',
      ),
      Question(
        text: 'ما عاصمة اليابان؟',
        category: 'دول وعواصم',
        packageId: 'countries',
      ),
      Question(
        text: 'ما عاصمة تركيا؟',
        category: 'دول وعواصم',
        packageId: 'countries',
      ),
      Question(
        text: 'ما عاصمة أستراليا؟',
        category: 'دول وعواصم',
        packageId: 'countries',
      ),
      Question(
        text: 'ما عاصمة كندا؟',
        category: 'دول وعواصم',
        packageId: 'countries',
      ),
      Question(
        text: 'ما عاصمة المغرب؟',
        category: 'دول وعواصم',
        packageId: 'countries',
      ),
      Question(
        text: 'ما عاصمة السعودية؟',
        category: 'دول وعواصم',
        packageId: 'countries',
      ),
      Question(
        text: 'ما عاصمة لبنان؟',
        category: 'دول وعواصم',
        packageId: 'countries',
      ),
      Question(
        text: 'ما عاصمة ألمانيا؟',
        category: 'دول وعواصم',
        packageId: 'countries',
      ),
      Question(
        text: 'ما عاصمة إيطاليا؟',
        category: 'دول وعواصم',
        packageId: 'countries',
      ),
      Question(
        text: 'في أي دولة تقع مدينة البتراء الأثرية؟',
        category: 'دول وعواصم',
        packageId: 'countries',
      ),
      Question(
        text: 'في أي دولة يقع تاج محل؟',
        category: 'دول وعواصم',
        packageId: 'countries',
      ),
      Question(
        text: 'في أي دولة يقع برج خليفة؟',
        category: 'دول وعواصم',
        packageId: 'countries',
      ),
      Question(
        text: 'في أي دولة تقع أهرامات الجيزة؟',
        category: 'دول وعواصم',
        packageId: 'countries',
      ),
      Question(
        text: 'في أي دولة تقع مدينة برشلونة؟',
        category: 'دول وعواصم',
        packageId: 'countries',
      ),
      Question(
        text: 'في أي دولة تقع مدينة البندقية؟',
        category: 'دول وعواصم',
        packageId: 'countries',
      ),
      Question(
        text: 'أي دولة تظهر على علمها ورقة القيقب؟',
        category: 'دول وعواصم',
        packageId: 'countries',
      ),
      Question(
        text: 'ما القارة التي تقع فيها البرازيل؟',
        category: 'دول وعواصم',
        packageId: 'countries',
      ),
      Question(
        text: 'ما القارة التي تقع فيها كينيا؟',
        category: 'دول وعواصم',
        packageId: 'countries',
      ),
      Question(
        text: 'ما المحيط الذي يحد المغرب من الغرب؟',
        category: 'دول وعواصم',
        packageId: 'countries',
      ),
      Question(
        text: 'ما اسم أكبر صحراء حارة في العالم؟',
        category: 'دول وعواصم',
        packageId: 'countries',
      ),
      Question(
        text: 'ما الدولة الأوروبية التي تشبه الحذاء على الخريطة؟',
        category: 'دول وعواصم',
        packageId: 'countries',
      ),
    ],
  ),
  QuestionPackage(
    id: 'football',
    name: 'عالم الكرة',
    emoji: '⚽',
    description: 'للّي حافظين الأهداف أكثر من الدروس.',
    isFree: false,
    questions: <Question>[
      Question(
        text: 'كم يبلغ العدد الكامل للاعبي فريق كرة القدم داخل الملعب؟',
        category: 'عالم الكرة',
        packageId: 'football',
      ),
      Question(
        text: 'كم دقيقة في شوط كرة القدم، دون الوقت بدل الضائع؟',
        category: 'عالم الكرة',
        packageId: 'football',
      ),
      Question(
        text: 'ما لون البطاقة التي تعني الطرد في كرة القدم؟',
        category: 'عالم الكرة',
        packageId: 'football',
      ),
      Question(
        text: 'ما لون البطاقة التي تعني الإنذار في كرة القدم؟',
        category: 'عالم الكرة',
        packageId: 'football',
      ),
      Question(
        text: 'ماذا يُسمى تسجيل لاعب ثلاثة أهداف في مباراة واحدة؟',
        category: 'عالم الكرة',
        packageId: 'football',
      ),
      Question(
        text: 'ما اسم اللاعب الذي يحمي مرمى فريقه؟',
        category: 'عالم الكرة',
        packageId: 'football',
      ),
      Question(
        text: 'أي منتخب فاز بكأس العالم للرجال عام 2022؟',
        category: 'عالم الكرة',
        packageId: 'football',
      ),
      Question(
        text: 'أي منتخب فاز بكأس العالم للرجال عام 2018؟',
        category: 'عالم الكرة',
        packageId: 'football',
      ),
      Question(
        text: 'أي منتخب فاز بكأس العالم للرجال عام 2014؟',
        category: 'عالم الكرة',
        packageId: 'football',
      ),
      Question(
        text: 'أي منتخب فاز بكأس العالم للرجال عام 2010؟',
        category: 'عالم الكرة',
        packageId: 'football',
      ),
      Question(
        text: 'في أي دولة أقيم كأس العالم للرجال عام 2022؟',
        category: 'عالم الكرة',
        packageId: 'football',
      ),
      Question(
        text: 'في أي دولة أقيم كأس العالم للرجال عام 2010؟',
        category: 'عالم الكرة',
        packageId: 'football',
      ),
      Question(
        text: 'في أي دولة أقيم كأس العالم للرجال عام 2006؟',
        category: 'عالم الكرة',
        packageId: 'football',
      ),
      Question(
        text: 'ما جنسية لاعب كرة القدم محمد صلاح؟',
        category: 'عالم الكرة',
        packageId: 'football',
      ),
      Question(
        text: 'ما جنسية لاعب كرة القدم كريستيانو رونالدو؟',
        category: 'عالم الكرة',
        packageId: 'football',
      ),
      Question(
        text: 'ما جنسية لاعب كرة القدم ليونيل ميسي؟',
        category: 'عالم الكرة',
        packageId: 'football',
      ),
      Question(
        text: 'ما جنسية أسطورة كرة القدم بيليه؟',
        category: 'عالم الكرة',
        packageId: 'football',
      ),
      Question(
        text: 'أي منتخب مثّله زين الدين زيدان؟',
        category: 'عالم الكرة',
        packageId: 'football',
      ),
      Question(
        text: 'أي منتخب مثّله دييغو مارادونا؟',
        category: 'عالم الكرة',
        packageId: 'football',
      ),
      Question(
        text: 'في أي مدينة إسبانية يقع نادي ريال مدريد؟',
        category: 'عالم الكرة',
        packageId: 'football',
      ),
      Question(
        text: 'في أي مدينة ألمانية يقع نادي بايرن ميونخ؟',
        category: 'عالم الكرة',
        packageId: 'football',
      ),
      Question(
        text: 'ما اسم ملعب نادي ليفربول التاريخي؟',
        category: 'عالم الكرة',
        packageId: 'football',
      ),
      Question(
        text: 'ما اسم البطولة الأوروبية للأندية المعروفة بالكأس ذات الأذنين؟',
        category: 'عالم الكرة',
        packageId: 'football',
      ),
      Question(
        text: 'ماذا تُسمى الركلة التي تُنفذ من زاوية الملعب؟',
        category: 'عالم الكرة',
        packageId: 'football',
      ),
    ],
  ),
  QuestionPackage(
    id: 'screen',
    name: 'أفلام ومسلسلات',
    emoji: '🎬',
    description: 'وجوه وحكايات من الشاشة الكبيرة والصغيرة.',
    isFree: false,
    questions: <Question>[
      Question(
        text: 'ما اسم شبل الأسد بطل فيلم «الأسد الملك»؟',
        category: 'أفلام ومسلسلات',
        packageId: 'screen',
      ),
      Question(
        text: 'ما اسم أخت إلسا في فيلم «فروزن»؟',
        category: 'أفلام ومسلسلات',
        packageId: 'screen',
      ),
      Question(
        text: 'ما اسم رجل الثلج في فيلم «فروزن»؟',
        category: 'أفلام ومسلسلات',
        packageId: 'screen',
      ),
      Question(
        text: 'ما اسم لعبة راعي البقر في «توي ستوري»؟',
        category: 'أفلام ومسلسلات',
        packageId: 'screen',
      ),
      Question(
        text: 'ما اسم السمكة الزرقاء كثيرة النسيان في «البحث عن نيمو»؟',
        category: 'أفلام ومسلسلات',
        packageId: 'screen',
      ),
      Question(
        text: 'ما لون شخصية شريك؟',
        category: 'أفلام ومسلسلات',
        packageId: 'screen',
      ),
      Question(
        text: 'ما نوع الحيوان الذي يمثله بو في «كونغ فو باندا»؟',
        category: 'أفلام ومسلسلات',
        packageId: 'screen',
      ),
      Question(
        text: 'ما اسم مدرسة السحر التي يدرس فيها هاري بوتر؟',
        category: 'أفلام ومسلسلات',
        packageId: 'screen',
      ),
      Question(
        text: 'ما شكل الندبة على جبين هاري بوتر؟',
        category: 'أفلام ومسلسلات',
        packageId: 'screen',
      ),
      Question(
        text: 'ما اسم صديقة هاري بوتر المقرّبة صاحبة الشعر البني؟',
        category: 'أفلام ومسلسلات',
        packageId: 'screen',
      ),
      Question(
        text: 'ما اسم المدينة الخيالية التي يحميها باتمان؟',
        category: 'أفلام ومسلسلات',
        packageId: 'screen',
      ),
      Question(
        text: 'ما الاسم الحقيقي لشخصية باتمان؟',
        category: 'أفلام ومسلسلات',
        packageId: 'screen',
      ),
      Question(
        text: 'ما اسم القرصان الذي يؤديه جوني ديب في «قراصنة الكاريبي»؟',
        category: 'أفلام ومسلسلات',
        packageId: 'screen',
      ),
      Question(
        text: 'من أخرج فيلم «تيتانيك» الصادر عام 1997؟',
        category: 'أفلام ومسلسلات',
        packageId: 'screen',
      ),
      Question(
        text: 'ما اسم الطفل بطل فيلم «وحدي في المنزل» الأول؟',
        category: 'أفلام ومسلسلات',
        packageId: 'screen',
      ),
      Question(
        text: 'ما نوع الحيوان الذي يمثله ريمي في فيلم «راتاتوي»؟',
        category: 'أفلام ومسلسلات',
        packageId: 'screen',
      ),
      Question(
        text: 'في أي مدينة سورية تدور أحداث مسلسل «باب الحارة»؟',
        category: 'أفلام ومسلسلات',
        packageId: 'screen',
      ),
      Question(
        text: 'ما البلد الذي ينتمي إليه مسلسل «طاش ما طاش»؟',
        category: 'أفلام ومسلسلات',
        packageId: 'screen',
      ),
      Question(
        text: 'من يؤدي شخصية الكبير في مسلسل «الكبير أوي»؟',
        category: 'أفلام ومسلسلات',
        packageId: 'screen',
      ),
      Question(
        text: 'في أي مدينة أمريكية تدور أحداث مسلسل «فريندز»؟',
        category: 'أفلام ومسلسلات',
        packageId: 'screen',
      ),
      Question(
        text: 'ما المادة التي يدرّسها والتر وايت في بداية «بريكينغ باد»؟',
        category: 'أفلام ومسلسلات',
        packageId: 'screen',
      ),
      Question(
        text: 'بأي لقب يُعرف مخطط السرقة في «لا كاسا دي بابيل»؟',
        category: 'أفلام ومسلسلات',
        packageId: 'screen',
      ),
      Question(
        text: 'ما الفاكهة التي يتخذها سبونج بوب منزلًا؟',
        category: 'أفلام ومسلسلات',
        packageId: 'screen',
      ),
      Question(
        text: 'ما نوع الحيوان الذي يمثله جيري في «توم وجيري»؟',
        category: 'أفلام ومسلسلات',
        packageId: 'screen',
      ),
    ],
  ),
  QuestionPackage(
    id: 'food',
    name: 'أكل ومذاق',
    emoji: '🍋',
    description: 'أسئلة تفتح النفس... وتختبر الذوق.',
    isFree: false,
    questions: <Question>[
      Question(
        text: 'ما البقول الذي يحمل طبق الحمص اسمه؟',
        category: 'أكل ومذاق',
        packageId: 'food',
      ),
      Question(
        text: 'من أي بذور تُصنع الطحينة؟',
        category: 'أكل ومذاق',
        packageId: 'food',
      ),
      Question(
        text: 'ما اسم اللبن المجفف المستخدم في المنسف الأردني؟',
        category: 'أكل ومذاق',
        packageId: 'food',
      ),
      Question(
        text: 'ما المكوّن الورقي الأساسي في التبولة التقليدية؟',
        category: 'أكل ومذاق',
        packageId: 'food',
      ),
      Question(
        text: 'ما اسم الحلوى النابلسية الشهيرة التي تحتوي على الجبن والقطر؟',
        category: 'أكل ومذاق',
        packageId: 'food',
      ),
      Question(
        text: 'ما اسم المشروب المصنوع من حبوب البن؟',
        category: 'أكل ومذاق',
        packageId: 'food',
      ),
      Question(
        text: 'ما الحبوب التي يُصنع من سميدها الكسكس التقليدي؟',
        category: 'أكل ومذاق',
        packageId: 'food',
      ),
      Question(
        text:
            'ما اسم الحلوى المصرية المصنوعة من رقائق العجين والحليب والمكسرات؟',
        category: 'أكل ومذاق',
        packageId: 'food',
      ),
      Question(
        text: 'ما المادة التي تساعد عجينة الخبز على الانتفاخ بالتخمير؟',
        category: 'أكل ومذاق',
        packageId: 'food',
      ),
      Question(
        text:
            'ما اسم الطبق الإيطالي الدائري المغطى غالبًا بالجبن وصلصة الطماطم؟',
        category: 'أكل ومذاق',
        packageId: 'food',
      ),
      Question(
        text: 'ما الجبن الأبيض المستخدم تقليديًا على البيتزا النابولية؟',
        category: 'أكل ومذاق',
        packageId: 'food',
      ),
      Question(
        text: 'ما الحبوب التي تُحمّص لتتحول إلى فشار؟',
        category: 'أكل ومذاق',
        packageId: 'food',
      ),
      Question(
        text: 'ما اسم ثمار النخيل التي تؤكل طازجة أو مجففة؟',
        category: 'أكل ومذاق',
        packageId: 'food',
      ),
      Question(
        text: 'ما التابل الذي يمنح الكاري لونًا أصفر غالبًا؟',
        category: 'أكل ومذاق',
        packageId: 'food',
      ),
      Question(
        text: 'ما اسم التابل الذي يُستخرج من مياسم زهرة بنفسجية؟',
        category: 'أكل ومذاق',
        packageId: 'food',
      ),
      Question(
        text: 'ما اسم الصلصة البيضاء التي تُحضّر من الزبدة والدقيق والحليب؟',
        category: 'أكل ومذاق',
        packageId: 'food',
      ),
      Question(
        text: 'ما العنصر الأساسي الذي يميز السوشي: الأرز المتبّل أم الخبز؟',
        category: 'أكل ومذاق',
        packageId: 'food',
      ),
      Question(
        text: 'ما العشب الأخضر الأساسي في صلصة البيستو الإيطالية التقليدية؟',
        category: 'أكل ومذاق',
        packageId: 'food',
      ),
      Question(
        text: 'ما البلد الذي تشتهر به حلوى التيراميسو؟',
        category: 'أكل ومذاق',
        packageId: 'food',
      ),
      Question(
        text: 'ما اسم حلوى الطحينة التي تُباع غالبًا على شكل قوالب؟',
        category: 'أكل ومذاق',
        packageId: 'food',
      ),
      Question(
        text: 'ما الفاكهة التي ينتج عن تجفيفها الزبيب؟',
        category: 'أكل ومذاق',
        packageId: 'food',
      ),
      Question(
        text: 'أي جزء من البيضة يُستخدم في المايونيز التقليدي؟',
        category: 'أكل ومذاق',
        packageId: 'food',
      ),
      Question(
        text: 'ما الطعم الغالب على الليمون: حلو أم حامض؟',
        category: 'أكل ومذاق',
        packageId: 'food',
      ),
      Question(
        text: 'ما المكوّن الأساسي في صلصة الغواكامولي؟',
        category: 'أكل ومذاق',
        packageId: 'food',
      ),
    ],
  ),
  QuestionPackage(
    id: 'science',
    name: 'علوم وعجائب',
    emoji: '🔭',
    description: 'فضول وتجارب وكم معلومة بتفاجئك.',
    isFree: false,
    questions: <Question>[
      Question(
        text: 'ما الكوكب المعروف بالكوكب الأحمر؟',
        category: 'علوم وعجائب',
        packageId: 'science',
      ),
      Question(
        text: 'ما أقرب كوكب إلى الشمس؟',
        category: 'علوم وعجائب',
        packageId: 'science',
      ),
      Question(
        text: 'ما أكبر كوكب في المجموعة الشمسية؟',
        category: 'علوم وعجائب',
        packageId: 'science',
      ),
      Question(
        text: 'ما ثاني أكبر كوكب في المجموعة الشمسية؟',
        category: 'علوم وعجائب',
        packageId: 'science',
      ),
      Question(
        text: 'كم كوكبًا تضم المجموعة الشمسية؟',
        category: 'علوم وعجائب',
        packageId: 'science',
      ),
      Question(
        text: 'ما الظاهرة الناتجة عن مرور القمر بين الأرض والشمس؟',
        category: 'علوم وعجائب',
        packageId: 'science',
      ),
      Question(
        text: 'ما النجم الأقرب إلى الأرض؟',
        category: 'علوم وعجائب',
        packageId: 'science',
      ),
      Question(
        text: 'ما الغاز الذي يحتاجه الإنسان للتنفس؟',
        category: 'علوم وعجائب',
        packageId: 'science',
      ),
      Question(
        text: 'ما الغاز الذي تمتصه النباتات أثناء البناء الضوئي؟',
        category: 'علوم وعجائب',
        packageId: 'science',
      ),
      Question(
        text: 'ما اسم العملية التي يصنع بها النبات غذاءه باستخدام الضوء؟',
        category: 'علوم وعجائب',
        packageId: 'science',
      ),
      Question(
        text: 'ما الرمز الكيميائي للماء؟',
        category: 'علوم وعجائب',
        packageId: 'science',
      ),
      Question(
        text: 'عند الضغط الجوي المعتاد، عند أي درجة مئوية يتجمد الماء النقي؟',
        category: 'علوم وعجائب',
        packageId: 'science',
      ),
      Question(
        text: 'ما اسم تحول الماء من سائل إلى غاز؟',
        category: 'علوم وعجائب',
        packageId: 'science',
      ),
      Question(
        text: 'ما اسم تحول بخار الماء إلى سائل؟',
        category: 'علوم وعجائب',
        packageId: 'science',
      ),
      Question(
        text: 'ما العضو الذي يضخ الدم في الجسم؟',
        category: 'علوم وعجائب',
        packageId: 'science',
      ),
      Question(
        text: 'ما أكبر عضو في جسم الإنسان من حيث المساحة؟',
        category: 'علوم وعجائب',
        packageId: 'science',
      ),
      Question(
        text: 'كم عظمة توجد عادة في الهيكل العظمي للإنسان البالغ؟',
        category: 'علوم وعجائب',
        packageId: 'science',
      ),
      Question(
        text: 'ما اسم القوة التي تجذب الأشياء نحو الأرض؟',
        category: 'علوم وعجائب',
        packageId: 'science',
      ),
      Question(
        text: 'أيهما يصلنا أولًا من العاصفة: ضوء البرق أم صوت الرعد؟',
        category: 'علوم وعجائب',
        packageId: 'science',
      ),
      Question(
        text: 'هل يستطيع الصوت الانتقال في الفراغ؟',
        category: 'علوم وعجائب',
        packageId: 'science',
      ),
      Question(
        text: 'ما اسم وحدة قياس شدة التيار الكهربائي؟',
        category: 'علوم وعجائب',
        packageId: 'science',
      ),
      Question(
        text: 'ما نوع الشحنة الكهربائية للإلكترون: موجبة أم سالبة؟',
        category: 'علوم وعجائب',
        packageId: 'science',
      ),
      Question(
        text: 'ما العنصر الكيميائي الذي رمزه Fe؟',
        category: 'علوم وعجائب',
        packageId: 'science',
      ),
      Question(
        text: 'ما العنصر الكيميائي الذي رمزه Au؟',
        category: 'علوم وعجائب',
        packageId: 'science',
      ),
    ],
  ),
];
