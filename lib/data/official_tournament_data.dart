import '../models/enums.dart';

/// عنصر بيانات فريق/منتخب جاهز داخل مكتبة التطبيق
class OfficialTeamData {
  final String name;
  final String colorHex;
  const OfficialTeamData(this.name, this.colorHex);
}

/// مكتبة الفرق والمنتخبات الرسمية المدمجة داخل التطبيق (الفصل 2.4 / 3.4)
/// لا تحتاج إلى إنترنت أبدًا — كل القوائم مكتوبة مباشرة هنا.
///
/// ملاحظة تقنية: القوائم هنا تحتوي على الاسم واللون المميز فقط (بدل شعارات
/// PNG حقيقية غير متوفرة في هذه البيئة). عند إضافة الشعارات الحقيقية لاحقًا،
/// يكفي إضافة حقل `assetPath` هنا وربطه بمسار الصورة داخل assets/logos/.
class OfficialTournamentData {
  // 🌍 كأس العالم — أشهر 32 منتخبًا
  static const List<OfficialTeamData> worldCupNations = [
    OfficialTeamData('البرازيل', '#FFDF00'),
    OfficialTeamData('الأرجنتين', '#75AADB'),
    OfficialTeamData('فرنسا', '#0055A4'),
    OfficialTeamData('ألمانيا', '#1C1C1C'),
    OfficialTeamData('إسبانيا', '#C60B1E'),
    OfficialTeamData('إنجلترا', '#CF081F'),
    OfficialTeamData('البرتغال', '#046A38'),
    OfficialTeamData('هولندا', '#FF6600'),
    OfficialTeamData('بلجيكا', '#ED2939'),
    OfficialTeamData('إيطاليا', '#0066CC'),
    OfficialTeamData('المغرب', '#C1272D'),
    OfficialTeamData('كرواتيا', '#FF0000'),
    OfficialTeamData('اليابان', '#BC002D'),
    OfficialTeamData('كوريا الجنوبية', '#C60C30'),
    OfficialTeamData('السعودية', '#006C35'),
    OfficialTeamData('المكسيك', '#006847'),
    OfficialTeamData('الولايات المتحدة', '#3C3B6E'),
    OfficialTeamData('أستراليا', '#FFCD00'),
    OfficialTeamData('سويسرا', '#FF0000'),
    OfficialTeamData('الدنمارك', '#C60C30'),
    OfficialTeamData('السنغال', '#00853F'),
    OfficialTeamData('غانا', '#CE1126'),
    OfficialTeamData('تونس', '#E70013'),
    OfficialTeamData('الجزائر', '#006233'),
    OfficialTeamData('مصر', '#C8102E'),
    OfficialTeamData('نيجيريا', '#008751'),
    OfficialTeamData('كولومبيا', '#FCD116'),
    OfficialTeamData('الأوروغواي', '#7CB9E8'),
    OfficialTeamData('تشيلي', '#D52B1E'),
    OfficialTeamData('بولندا', '#DC143C'),
    OfficialTeamData('صربيا', '#C6363C'),
    OfficialTeamData('كندا', '#FF0000'),
  ];

  // 🌍 كأس أمم إفريقيا
  static const List<OfficialTeamData> africaCupNations = [
    OfficialTeamData('المغرب', '#C1272D'),
    OfficialTeamData('مصر', '#C8102E'),
    OfficialTeamData('الجزائر', '#006233'),
    OfficialTeamData('تونس', '#E70013'),
    OfficialTeamData('السنغال', '#00853F'),
    OfficialTeamData('نيجيريا', '#008751'),
    OfficialTeamData('الكاميرون', '#007A5E'),
    OfficialTeamData('غانا', '#CE1126'),
    OfficialTeamData('ساحل العاج', '#F77F00'),
    OfficialTeamData('مالي', '#14B53A'),
    OfficialTeamData('جنوب إفريقيا', '#007A4D'),
    OfficialTeamData('كينيا', '#BB0000'),
  ];

  // 🌍 كأس أمم أوروبا
  static const List<OfficialTeamData> europeCupNations = [
    OfficialTeamData('فرنسا', '#0055A4'),
    OfficialTeamData('ألمانيا', '#1C1C1C'),
    OfficialTeamData('إسبانيا', '#C60B1E'),
    OfficialTeamData('إنجلترا', '#CF081F'),
    OfficialTeamData('البرتغال', '#046A38'),
    OfficialTeamData('هولندا', '#FF6600'),
    OfficialTeamData('بلجيكا', '#ED2939'),
    OfficialTeamData('إيطاليا', '#0066CC'),
    OfficialTeamData('كرواتيا', '#FF0000'),
    OfficialTeamData('سويسرا', '#FF0000'),
    OfficialTeamData('الدنمارك', '#C60C30'),
    OfficialTeamData('بولندا', '#DC143C'),
  ];

  // 🌍 كوبا أمريكا
  static const List<OfficialTeamData> copaAmericaNations = [
    OfficialTeamData('البرازيل', '#FFDF00'),
    OfficialTeamData('الأرجنتين', '#75AADB'),
    OfficialTeamData('كولومبيا', '#FCD116'),
    OfficialTeamData('الأوروغواي', '#7CB9E8'),
    OfficialTeamData('تشيلي', '#D52B1E'),
    OfficialTeamData('الإكوادور', '#FFD100'),
    OfficialTeamData('بيرو', '#D91023'),
    OfficialTeamData('باراغواي', '#D52B1E'),
    OfficialTeamData('بوليفيا', '#D52B1E'),
    OfficialTeamData('فنزويلا', '#FFCC00'),
  ];

  // 🏆 الدوري الإسباني
  static const List<OfficialTeamData> laLigaClubs = [
    OfficialTeamData('برشلونة', '#A50044'),
    OfficialTeamData('ريال مدريد', '#FEBE10'),
    OfficialTeamData('أتلتيكو مدريد', '#CB3524'),
    OfficialTeamData('إشبيلية', '#D2001C'),
    OfficialTeamData('فالنسيا', '#F68A21'),
    OfficialTeamData('ريال سوسيداد', '#0067B1'),
    OfficialTeamData('فياريال', '#FFE667'),
    OfficialTeamData('أتلتيك بيلباو', '#EE2523'),
    OfficialTeamData('ريال بيتيس', '#00954C'),
    OfficialTeamData('خيتافي', '#005CA9'),
    OfficialTeamData('أوساسونا', '#D2001C'),
    OfficialTeamData('سيلتا فيغو', '#8AC3EE'),
    OfficialTeamData('رايو فاليكانو', '#E2231A'),
    OfficialTeamData('مايوركا', '#E20613'),
    OfficialTeamData('جيرونا', '#CB3524'),
    OfficialTeamData('ألافيس', '#0F47AF'),
    OfficialTeamData('إلتشي', '#005CA9'),
    OfficialTeamData('ليفانتي', '#0F47AF'),
    OfficialTeamData('إسبانيول', '#0F47AF'),
    OfficialTeamData('فالد هيبد', '#F7941D'),
  ];

  // 🏆 الدوري الإنجليزي
  static const List<OfficialTeamData> premierLeagueClubs = [
    OfficialTeamData('مانشستر سيتي', '#6CABDD'),
    OfficialTeamData('ليفربول', '#C8102E'),
    OfficialTeamData('آرسنال', '#EF0107'),
    OfficialTeamData('تشيلسي', '#034694'),
    OfficialTeamData('مانشستر يونايتد', '#DA291C'),
    OfficialTeamData('توتنهام', '#132257'),
    OfficialTeamData('نيوكاسل يونايتد', '#241F20'),
    OfficialTeamData('استون فيلا', '#670E36'),
    OfficialTeamData('برايتون', '#0057B8'),
    OfficialTeamData('وست هام', '#7A263A'),
    OfficialTeamData('وولفرهامبتون', '#FDB913'),
    OfficialTeamData('كريستال بالاس', '#1B458F'),
    OfficialTeamData('فولهام', '#FFFFFF'),
    OfficialTeamData('برينتفورد', '#E30613'),
    OfficialTeamData('إيفرتون', '#003399'),
    OfficialTeamData('ليستر سيتي', '#003090'),
    OfficialTeamData('ساوثهامبتون', '#D71920'),
    OfficialTeamData('ايبسويتش تاون', '#0044A9'),
    OfficialTeamData('بورنموث', '#DA291C'),
    OfficialTeamData('نوتنغهام فورست', '#DD0000'),
  ];

  // 🏆 الدوري الإيطالي
  static const List<OfficialTeamData> serieAClubs = [
    OfficialTeamData('يوفنتوس', '#000000'),
    OfficialTeamData('إنتر ميلان', '#0068A8'),
    OfficialTeamData('ميلان', '#FB090B'),
    OfficialTeamData('نابولي', '#12A0D7'),
    OfficialTeamData('روما', '#8E1F2F'),
    OfficialTeamData('لاتسيو', '#87D8F7'),
    OfficialTeamData('أتالانتا', '#1E71B8'),
    OfficialTeamData('فيورنتينا', '#57267A'),
    OfficialTeamData('بولونيا', '#8C0000'),
    OfficialTeamData('توري نو', '#8B1E3F'),
    OfficialTeamData('أودينيزي', '#000000'),
    OfficialTeamData('ساسولو', '#00A650'),
    OfficialTeamData('إمبولي', '#005CA9'),
    OfficialTeamData('كالياري', '#00317F'),
    OfficialTeamData('فيرونا', '#FFCC00'),
    OfficialTeamData('جنوى', '#0A2240'),
    OfficialTeamData('ليتشي', '#FFD500'),
    OfficialTeamData('موناتزا', '#D0021B'),
    OfficialTeamData('بارما', '#FFDE00'),
    OfficialTeamData('كومو', '#003D7C'),
  ];

  // 🏆 الدوري الألماني
  static const List<OfficialTeamData> bundesligaClubs = [
    OfficialTeamData('بايرن ميونخ', '#DC052D'),
    OfficialTeamData('بوروسيا دورتموند', '#FDE100'),
    OfficialTeamData('لايبزيغ', '#DD0741'),
    OfficialTeamData('باير ليفركوزن', '#E32219'),
    OfficialTeamData('اونيون برلين', '#EB1923'),
    OfficialTeamData('فرايبورغ', '#000000'),
    OfficialTeamData('فولفسبورغ', '#65B32E'),
    OfficialTeamData('آينتراخت فرانكفورت', '#E1000F'),
    OfficialTeamData('بوروسيا مونشنغلادباخ', '#000000'),
    OfficialTeamData('هوفنهايم', '#1961B5'),
    OfficialTeamData('ماينتس 05', '#C7093D'),
    OfficialTeamData('فيردر بريمن', '#1A9E46'),
    OfficialTeamData('اوغسبورغ', '#BA3733'),
    OfficialTeamData('اشتوتغارت', '#DA151B'),
    OfficialTeamData('بوخوم', '#005CA9'),
    OfficialTeamData('هايدنهايم', '#DA151B'),
    OfficialTeamData('سانت باولي', '#5B3625'),
    OfficialTeamData('هولشتاين كيل', '#005CA9'),
  ];

  // 🏆 الدوري الفرنسي
  static const List<OfficialTeamData> ligue1Clubs = [
    OfficialTeamData('باريس سان جيرمان', '#004170'),
    OfficialTeamData('موناكو', '#E4022D'),
    OfficialTeamData('مارسيليا', '#2FAEE0'),
    OfficialTeamData('ليل', '#E2001A'),
    OfficialTeamData('ليون', '#004A9C'),
    OfficialTeamData('نيس', '#E2011A'),
    OfficialTeamData('رين', '#E2011A'),
    OfficialTeamData('لانس', '#FFD200'),
    OfficialTeamData('ستراسبورغ', '#0055A4'),
    OfficialTeamData('نانت', '#FFD200'),
    OfficialTeamData('تولوز', '#6A0DAD'),
    OfficialTeamData('رانس', '#E2011A'),
    OfficialTeamData('بريست', '#E2011A'),
    OfficialTeamData('مونبلييه', '#F58220'),
    OfficialTeamData('لوهافر', '#0055A4'),
    OfficialTeamData('أنجيه', '#000000'),
    OfficialTeamData('أوكسير', '#0055A4'),
    OfficialTeamData('سانت إتيان', '#3AAA35'),
  ];

  /// دوري أبطال أوروبا (القديم والجديد) — نفس مجموعة الأندية الأوروبية الكبرى
  static List<OfficialTeamData> get uclClubs => [
        ...laLigaClubs.take(4),
        ...premierLeagueClubs.take(5),
        ...serieAClubs.take(4),
        ...bundesligaClubs.take(4),
        ...ligue1Clubs.take(2),
        const OfficialTeamData('بورتو', '#003c78'),
        const OfficialTeamData('بنفيكا', '#E30613'),
        const OfficialTeamData('سبورتينغ لشبونة', '#00944D'),
        const OfficialTeamData('أياكس', '#D2122E'),
        const OfficialTeamData('بي إس في أيندهوفن', '#ED1C24'),
        const OfficialTeamData('سيلتيك', '#018749'),
        const OfficialTeamData('غلطة سراي', '#A6192E'),
        const OfficialTeamData('شاختار دونيتسك', '#F58220'),
        const OfficialTeamData('سالزبورغ', '#D4022A'),
        const OfficialTeamData('يونغ بويز', '#FFD100'),
      ];

  /// يُرجع قائمة الفرق/المنتخبات الرسمية المرتبطة بنوع بطولة معيّن
  static List<OfficialTeamData> teamsFor(TournamentType type) {
    switch (type) {
      case TournamentType.worldCup:
        return worldCupNations;
      case TournamentType.africaCup:
        return africaCupNations;
      case TournamentType.europeCup:
        return europeCupNations;
      case TournamentType.copaAmerica:
        return copaAmericaNations;
      case TournamentType.uclOldFormat:
      case TournamentType.uclNewFormat:
        return uclClubs;
      case TournamentType.laLiga:
        return laLigaClubs;
      case TournamentType.premierLeague:
        return premierLeagueClubs;
      case TournamentType.serieA:
        return serieAClubs;
      case TournamentType.bundesliga:
        return bundesligaClubs;
      case TournamentType.ligue1:
        return ligue1Clubs;
      case TournamentType.customLeague:
      case TournamentType.customCup:
      case TournamentType.customGroupsKnockout:
        return [];
    }
  }

  /// كل الفرق مجمّعة حسب الفئة — تُستخدم في نافذة اختيار شعار اللاعب (الفصل 2.5)
  static Map<String, List<OfficialTeamData>> get allByCategory => {
        'المنتخبات (كأس العالم)': worldCupNations,
        'الدوري الإسباني': laLigaClubs,
        'الدوري الإنجليزي': premierLeagueClubs,
        'الدوري الإيطالي': serieAClubs,
        'الدوري الألماني': bundesligaClubs,
        'الدوري الفرنسي': ligue1Clubs,
      };
}
