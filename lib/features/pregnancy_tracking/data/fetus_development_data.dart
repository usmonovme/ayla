class FetusDevelopmentInfo {
  final int week;
  final String size;
  final String description;
  final String height;
  final String weight;
  final String weeklyTip;
  final List<String> checklist;
  final String? babyGrowthDetailed;
  final String? motherChangesDetailed;
  final String? scientificInsight;
  final String? medicalNote;

  const FetusDevelopmentInfo({
    required this.week,
    required this.size,
    required this.description,
    required this.height,
    required this.weight,
    required this.weeklyTip,
    required this.checklist,
    this.babyGrowthDetailed,
    this.motherChangesDetailed,
    this.scientificInsight,
    this.medicalNote,
  });

  String get assetPath => 'assets/images/fetus_size/week_$week.svg';
}

class FetusDevelopmentData {
  static const Map<int, FetusDevelopmentInfo> weeklyData = {
    1: FetusDevelopmentInfo(
      week: 1,
      size: 'Microscopic',
      description:
          'You are not technically pregnant yet. This is the first week of your cycle. Your body is preparing for ovulation.',
      height: '-',
      weight: '-',
      weeklyTip:
          'Start taking prenatal vitamins with folic acid if you haven\'t already.',
      checklist: [
        'Start taking prenatal vitamins',
        'Stop smoking and drinking alcohol',
        'Track your period',
      ],
    ),
    2: FetusDevelopmentInfo(
      week: 2,
      size: 'Microscopic',
      description:
          'Ovulation occurs and your egg is released, waiting to be fertilized.',
      height: '-',
      weight: '-',
      weeklyTip: 'Track your ovulation to identify your most fertile days.',
      checklist: [
        'Have intercourse during fertile window',
        'Eat a balanced diet',
        'Stay hydrated',
      ],
    ),
    3: FetusDevelopmentInfo(
      week: 3,
      size: 'Poppy Seed',
      description:
          'Fertilization has occurred! The blastocyst is traveling down the fallopian tube to implant in the uterus.',
      height: '0.1 mm',
      weight: '< 1g',
      weeklyTip:
          'You might experience some light spotting (implantation bleeding).',
      checklist: [
        'Continue prenatal vitamins',
        'Limit caffeine intake',
        'Avoid raw or undercooked foods',
      ],
    ),
    4: FetusDevelopmentInfo(
      week: 4,
      size: 'Poppy Seed',
      description:
          'The embryo is forming layers that will become organs. The placenta is also beginning to form.',
      height: '1 mm',
      weight: '< 1g',
      weeklyTip:
          'This is when you might get a positive result on a home pregnancy test.',
      checklist: [
        'Take a home pregnancy test',
        'Schedule your first prenatal appointment',
        'Review current medications with your doctor',
      ],
    ),
    5: FetusDevelopmentInfo(
      week: 5,
      size: 'Sesame Seed',
      description:
          'The heart starts beating and the neural tube closes. Vital organs are beginning to develop.',
      height: '2 mm',
      weight: '< 1g',
      weeklyTip:
          'Morning sickness might start kicking in. Try eating small, frequent meals.',
      checklist: [
        'Avoid cat litter (toxoplasmosis risk)',
        'Rest when you feel tired',
        'Start a pregnancy journal',
      ],
    ),
    6: FetusDevelopmentInfo(
      week: 6,
      size: 'Lentil',
      description:
          'Facial features like eyes and nostrils are beginning to form. Arm and leg buds appear.',
      height: '5 mm',
      weight: '< 1g',
      weeklyTip: 'Ginger tea or candies can help with nausea.',
      checklist: [
        'Check insurance coverage for pregnancy',
        'Avoid hot tubs and saunas',
        'Eat foods rich in iron',
      ],
    ),

    7: FetusDevelopmentInfo(
      week: 7,
      size: 'Blueberry',
      description:
          'Arms and legs are growing longer. The baby is doubling in size.',
      height: '1.3 cm',
      weight: '< 1g',
      weeklyTip: 'Your uterus has doubled in size!',
      checklist: [
        'Prepare questions for your first doctor visit',
        'Look into pregnancy-safe skincare',
        'Stay active with gentle walks',
      ],
    ),
    8: FetusDevelopmentInfo(
      week: 8,
      size: 'Raspberry',
      description:
          'Fingers and toes are forming, though they are still webbed. Taste buds are developing.',
      height: '1.6 cm',
      weight: '1 g',
      weeklyTip: 'Invest in a supportive bra as your breasts may be growing.',
      checklist: [
        'Attend first prenatal checkup (usually around week 8-10)',
        'Discuss genetic screening options',
        'Check your workplace maternity leave policy',
      ],
    ),
    9: FetusDevelopmentInfo(
      week: 9,
      size: 'Grape',
      description:
          'Muscles are forming and the baby can move, though you can\'t feel it yet.',
      height: '2.3 cm',
      weight: '2 g',
      weeklyTip: ' mood swings are common due to hormonal changes.',
      checklist: [
        'Research foods to avoid during pregnancy',
        'Moisturize to prevent stretch marks',
        'Connect with your partner',
      ],
    ),
    10: FetusDevelopmentInfo(
      week: 10,
      size: 'Kumquat',
      description:
          'Vital organs are functioning. The baby is now officially a fetus, not an embryo.',
      height: '3.1 cm',
      weight: '4 g',
      weeklyTip:
          'Consider non-invasive prenatal testing (NIPT) if recommended.',
      checklist: [
        'Shop for maternity clothes (or stretchy pants)',
        'Plan a budget for baby expenses',
        'Visit the dentist (gum health is important)',
      ],
    ),
    11: FetusDevelopmentInfo(
      week: 11,
      size: 'Fig',
      description: 'Bones are starting to harden. Hair follicles are forming.',
      height: '4.1 cm',
      weight: '7 g',
      weeklyTip: 'You might notice your hair and nails growing faster.',
      checklist: [
        'Schedule your 12-week ultrasound (nuchal translucency)',
        'Start sleeping on your side',
        'Plan a "babymoon" if desired',
      ],
    ),
    12: FetusDevelopmentInfo(
      week: 12,
      size: 'Lime',
      description:
          'Reflexes are developing. The baby can open and close its fingers.',
      height: '5.4 cm',
      weight: '14 g',
      weeklyTip:
          'Your risk of miscarriage drops significantly after this week.',
      checklist: [
        'Announce pregnancy to family/friends (if ready)',
        'Start doing Kegel exercises',
        'Look into childbirth classes',
      ],
    ),
    13: FetusDevelopmentInfo(
      week: 13,
      size: 'Lemon',
      description:
          'Fingerprints are forming. You are entering the second trimester!',
      height: '7.4 cm',
      weight: '23 g',
      weeklyTip: 'Energy levels often return in the second trimester.',
      checklist: [
        'Share the news with your employer',
        'Research pediatricians',
        'Start moisturizing your belly daily',
      ],
    ),
    14: FetusDevelopmentInfo(
      week: 14,
      size: 'Peach',
      description:
          'You can now find out the gender via ultrasound. The baby can make facial expressions.',
      height: '8.7 cm',
      weight: '43 g',
      weeklyTip:
          'Welcome to the second trimester! The "golden period" of pregnancy.',
      checklist: [
        'Take a bump photo',
        'Sign up for prenatal yoga',
        'Discuss baby names',
      ],
    ),
    15: FetusDevelopmentInfo(
      week: 15,
      size: 'Apple',
      description:
          'The baby can sense light even though eyes are fused shut. Legs are growing longer than arms.',
      height: '10.1 cm',
      weight: '70 g',
      weeklyTip: 'You might experience "pregnancy brain" or forgetfulness.',
      checklist: [
        'Schedule a dental checkup if you haven\'t',
        'Look into childcare options',
        'Update your wardrobe',
      ],
    ),
    16: FetusDevelopmentInfo(
      week: 16,
      size: 'Avocado',
      description:
          'The baby is pumping blood. You might feel the first flutters of movement (quickening).',
      height: '11.6 cm',
      weight: '100 g',
      weeklyTip: 'Back pain might start; watch your posture.',
      checklist: [
        'Schedule your anatomy scan (usually week 18-20)',
        'Start a baby registry',
        'Talk to your partner about parenting styles',
      ],
    ),
    17: FetusDevelopmentInfo(
      week: 17,
      size: 'Turnip',
      description:
          'The baby is practicing swallowing and sucking. Fat stores are beginning to develop.',
      height: '13 cm',
      weight: '140 g',
      weeklyTip: 'Vivid dreams are common due to hormones.',
      checklist: [
        'Research hospital or birth center tours',
        'Look for a supportive pregnancy pillow',
        'Stay hydrated to prevent headaches',
      ],
    ),
    18: FetusDevelopmentInfo(
      week: 18,
      size: 'Bell Pepper',
      description:
          'Ears are in position and the baby can hear sounds like your heartbeat.',
      height: '14.2 cm',
      weight: '190 g',
      weeklyTip: 'Talk or sing to your baby; they can hear you!',
      checklist: [
        'Anatomy scan might be this week',
        'Research cord blood banking',
        'Plan the nursery theme',
      ],
    ),
    19: FetusDevelopmentInfo(
      week: 19,
      size: 'Heirloom Tomato',
      description:
          'A protective coating called vernix caseosa forms on the baby\'s skin.',
      height: '15.3 cm',
      weight: '240 g',
      weeklyTip: 'You might feel round ligament pain as your belly stretches.',
      checklist: [
        'Sign up for breastfeeding classes',
        'Choose a crib and mattress',
        'Date night with partner',
      ],
    ),
    20: FetusDevelopmentInfo(
      week: 20,
      size: 'Banana',
      description:
          'Halfway there! The baby is swallowing amniotic fluid to practice digestion.',
      height: '16.4 cm',
      weight: '300 g',
      weeklyTip: 'Congratulations on reaching the halfway mark!',
      checklist: [
        'Celebrate the halfway milestone',
        'Finalize baby registry',
        'Review birth plan options',
      ],
    ),
    21: FetusDevelopmentInfo(
      week: 21,
      size: 'Carrot',
      description:
          'Baby is kicking more noticeably. Eyebrows and eyelids are present.',
      height: '26.7 cm',
      weight: '360 g',
      weeklyTip:
          'Swelling in feet might start; elevate your legs when possible.',
      checklist: [
        'Research breast pumps and insurance coverage',
        'Update your life insurance beneficiaries',
        'Start nursery painting/prep',
      ],
    ),
    22: FetusDevelopmentInfo(
      week: 22,
      size: 'Spaghetti Squash',
      description:
          'Eyes are fully formed but lack pigment. The baby has a sleep cycle.',
      height: '27.8 cm',
      weight: '430 g',
      weeklyTip: 'Magnesium can help with leg cramps.',
      checklist: [
        'Tour the birth facility',
        'Research doulas if interested',
        'Practice relaxation techniques',
      ],
    ),
    23: FetusDevelopmentInfo(
      week: 23,
      size: 'Large Mango',
      description:
          'The baby can hear your voice and loud sounds outside the womb clearly.',
      height: '28.9 cm',
      weight: '500 g',
      weeklyTip:
          'You might notice Braxton Hicks contractions (practice contractions).',
      checklist: [
        'Check your blood pressure regularly',
        'Finalize maternity leave plans',
        'Take a babymoon if you haven\'t',
      ],
    ),
    24: FetusDevelopmentInfo(
      week: 24,
      size: 'Ear of Corn',
      description:
          'The baby is viable outside the womb with intensive care. Lungs are developing branches.',
      height: '30 cm',
      weight: '600 g',
      weeklyTip: 'Glucose screening test usually happens between 24-28 weeks.',
      checklist: [
        'Schedule glucose screening test',
        'Complete nursery setup',
        'Research car seats',
      ],
    ),
    25: FetusDevelopmentInfo(
      week: 25,
      size: 'Rutabaga',
      description: 'Hair is growing on the head. The baby is adding baby fat.',
      height: '34.6 cm',
      weight: '660 g',
      weeklyTip: 'Heartburn might increase as the baby pushes on your stomach.',
      checklist: [
        'Register for hospital admission',
        'Create a birth plan',
        'Choose a pediatrician',
      ],
    ),
    26: FetusDevelopmentInfo(
      week: 26,
      size: 'Scallion',
      description: 'Eyelids begin to open. The baby can blink.',
      height: '35.6 cm',
      weight: '760 g',
      weeklyTip: 'Stay hydrated to prevent preterm labor signs.',
      checklist: [
        'Discuss Tdap vaccine with doctor',
        'Wash baby clothes',
        'Pack a basic hospital bag',
      ],
    ),
    27: FetusDevelopmentInfo(
      week: 27,
      size: 'Cauliflower',
      description: 'Brain is very active. Welcome to the third trimester!',
      height: '36.6 cm',
      weight: '875 g',
      weeklyTip: 'You are entering the home stretch!',
      checklist: [
        'Monitor fetal movement (kick counts)',
        'Childproof the house',
        'Install the car seat',
      ],
    ),
    28: FetusDevelopmentInfo(
      week: 28,
      size: 'Eggplant',
      description: 'Eyelashes are grown. The baby can dream.',
      height: '37.6 cm',
      weight: '1 kg',
      weeklyTip:
          'Rh factor shot (RhoGAM) might be needed if you are Rh negative.',
      checklist: [
        'Schedule Tdap vaccination',
        'Attend childbirth classes',
        'Prepare post-partum recovery kit',
      ],
    ),
    29: FetusDevelopmentInfo(
      week: 29,
      size: 'Butternut Squash',
      description:
          'Muscles and lungs are maturing. The head is growing to accommodate the brain.',
      height: '38.6 cm',
      weight: '1.15 kg',
      weeklyTip:
          'Varicose veins might appear; wear compression socks if needed.',
      checklist: [
        'Stock up on household essentials',
        'Cook and freeze meals',
        'Review breastfeeding basics',
      ],
    ),
    30: FetusDevelopmentInfo(
      week: 30,
      size: 'Cabbage',
      description: 'The baby is surrounded by about a pint of amniotic fluid.',
      height: '39.9 cm',
      weight: '1.3 kg',
      weeklyTip: 'Difficuly sleeping? Try a warm bath before bed.',
      checklist: [
        'Pack hospital bag for partner',
        'Check car seat installation',
        'Plan route to hospital',
      ],
    ),
    31: FetusDevelopmentInfo(
      week: 31,
      size: 'Coconut',
      description: 'The baby can turn its head from side to side.',
      height: '41.1 cm',
      weight: '1.5 kg',
      weeklyTip: 'Colostrum (pre-milk) might leak from breasts.',
      checklist: [
        'Buy nursing bras',
        'Assemble baby gear (stroller, swing)',
        'Practice breathing techniques',
      ],
    ),
    32: FetusDevelopmentInfo(
      week: 32,
      size: 'Kale',
      description:
          'Fingernails have grown. The baby is practicing breathing movements.',
      height: '42.4 cm',
      weight: '1.7 kg',
      weeklyTip: 'Baby usually turns head-down around now.',
      checklist: [
        'Schedule bi-weekly checkups',
        'Confirm birth partner details',
        'Learn signs of labor',
      ],
    ),
    33: FetusDevelopmentInfo(
      week: 33,
      size: 'Pineapple',
      description:
          'The immune system is developing. Bones are hardening except the skull.',
      height: '43.7 cm',
      weight: '1.9 kg',
      weeklyTip: 'Listen to your body and rest as much as possible.',
      checklist: [
        'Wash bed sheets',
        'Set up baby monitor',
        'Pack going-home outfit for baby',
      ],
    ),
    34: FetusDevelopmentInfo(
      week: 34,
      size: 'Cantaloupe',
      description: 'The protective waxy coating is thickening.',
      height: '45 cm',
      weight: '2.1 kg',
      weeklyTip: 'Vision is developing; baby can see liquid environment.',
      checklist: [
        'Schedule Group B Strep test',
        'Write thank you notes for baby shower',
        'Install car seat base',
      ],
    ),
    35: FetusDevelopmentInfo(
      week: 35,
      size: 'Honeydew Melon',
      description: 'Kidneys are fully developed. Liver can process some waste.',
      height: '46.2 cm',
      weight: '2.4 kg',
      weeklyTip: 'Frequent urination is back as baby presses on bladder.',
      checklist: [
        'Finalize work hand-off',
        'Review labor signs with partner',
        'Sleep while you can',
      ],
    ),
    36: FetusDevelopmentInfo(
      week: 36,
      size: 'Romaine Lettuce',
      description:
          'The baby is shedding the downy hair (lanugo) and waxy coating.',
      height: '47.4 cm',
      weight: '2.6 kg',
      weeklyTip: 'You might "drop" (lightening) as baby engages in pelvis.',
      checklist: [
        'Weekly prenatal visits start',
        'Group B Strep swab',
        'Pack snacks for hospital',
      ],
    ),
    37: FetusDevelopmentInfo(
      week: 37,
      size: 'Swiss Chard',
      description:
          'Considered "early term". Organs are ready for life outside.',
      height: '48.6 cm',
      weight: '2.9 kg',
      weeklyTip: 'Mucus plug might pass; it\'s a sign labor is approaching.',
      checklist: [
        'Watch for contractions',
        'Ensure phone is charged',
        'Confirm pet care plans',
      ],
    ),
    38: FetusDevelopmentInfo(
      week: 38,
      size: 'Leek',
      description:
          'Grip is strong. Eye color is likely blue or gray (pigment comes later).',
      height: '49.8 cm',
      weight: '3 kg',
      weeklyTip:
          'Swelling is normal, but watch for sudden face swelling (preeclampsia).',
      checklist: [
        'Practice drive to hospital',
        'Review breastfeeding positions',
        'Relax and wait',
      ],
    ),
    39: FetusDevelopmentInfo(
      week: 39,
      size: 'Mini Watermelon',
      description: 'Full term! Physical development is complete.',
      height: '50.7 cm',
      weight: '3.3 kg',
      weeklyTip: 'Labor could start any moment.',
      checklist: [
        'Keep hospital bag by door',
        'Walk to encourage labor',
        'Monitor fetal movement',
      ],
    ),
    40: FetusDevelopmentInfo(
      week: 40,
      size: 'Small Pumpkin',
      description: 'It is your due date! Don\'t worry if baby is late.',
      height: '51.2 cm',
      weight: '3.5 kg',
      weeklyTip: 'Happy Due Date!',
      checklist: [
        'Discuss induction options if overdue',
        'Stay calm and positive',
        'Enjoy your last days of pregnancy',
      ],
    ),
  };

  static FetusDevelopmentInfo getInfo(int week) {
    if (week < 1) return weeklyData[1]!;
    if (week > 40) return weeklyData[40] ?? weeklyData[16]!;
    return weeklyData[week] ??
        FetusDevelopmentInfo(
          week: week,
          size: 'Growing',
          description: 'Your baby continues to grow and develop.',
          height: 'Unknown',
          weight: 'Unknown',
          weeklyTip: 'Stay healthy.',
          checklist: [],
        );
  }
}
