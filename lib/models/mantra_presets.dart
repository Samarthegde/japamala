import 'mantra.dart';

/// Common mantras offered on first run, so a new user isn't staring at an
/// empty screen wondering what to type.
class MantraPreset {
  final String name;
  final int rounds;
  final int beadsPerRound;
  final String description;

  /// The mantra in Devanagari.
  final String devanagari;

  /// IAST-style romanisation, for pronunciation.
  final String transliteration;

  /// A plain-language rendering. Translations of mantras are always
  /// approximate; these aim to convey sense rather than be authoritative.
  final String meaning;

  /// Where it comes from, when it has a well-known source.
  final String? source;

  const MantraPreset({
    required this.name,
    required this.description,
    required this.devanagari,
    required this.transliteration,
    required this.meaning,
    this.source,
    this.rounds = 1,
    this.beadsPerRound = 108,
  });

  int get targetCount => rounds * beadsPerRound;

  Mantra toMantra({bool isDaily = true}) => Mantra.create(
    name: name,
    targetCount: targetCount,
    description: description,
    isDaily: isDaily,
    beadsPerRound: beadsPerRound,
  );

  static const List<MantraPreset> all = [
    MantraPreset(
      name: 'Om',
      rounds: 1,
      description: 'The primordial sound. A complete mala of 108 repetitions.',
      devanagari: 'ॐ',
      transliteration: 'oṃ',
      meaning:
          'The primordial sound from which all else arises; the syllable is '
          'said to contain the whole of creation.',
      source: 'Mandukya Upanishad',
    ),
    MantraPreset(
      name: 'Om Namah Shivaya',
      rounds: 1,
      description:
          'Salutations to Shiva. One of the great five-syllable mantras.',
      devanagari: 'ॐ नमः शिवाय',
      transliteration: 'oṃ namaḥ śivāya',
      meaning: 'I bow to Shiva — to the auspicious inner Self.',
      source: 'Krishna Yajurveda, Shri Rudram',
    ),
    MantraPreset(
      name: 'Gayatri Mantra',
      rounds: 1,
      description:
          'A prayer for illumination of the intellect, traditionally '
          'chanted at dawn.',
      devanagari:
          'ॐ भूर्भुवः स्वः\n'
          'तत्सवितुर्वरेण्यं\n'
          'भर्गो देवस्य धीमहि\n'
          'धियो यो नः प्रचोदयात्',
      transliteration:
          'oṃ bhūr bhuvaḥ svaḥ\n'
          'tat savitur vareṇyaṃ\n'
          'bhargo devasya dhīmahi\n'
          'dhiyo yo naḥ pracodayāt',
      meaning:
          'We meditate on the radiance of the divine sun; may it illuminate '
          'our understanding.',
      source: 'Rigveda 3.62.10',
    ),
    MantraPreset(
      name: 'Mahamrityunjaya',
      rounds: 1,
      description:
          'The great death-conquering mantra, chanted for healing and courage.',
      devanagari:
          'ॐ त्र्यम्बकं यजामहे\n'
          'सुगन्धिं पुष्टिवर्धनम्\n'
          'उर्वारुकमिव बन्धनान्\n'
          'मृत्योर्मुक्षीय मामृतात्',
      transliteration:
          'oṃ tryambakaṃ yajāmahe\n'
          'sugandhiṃ puṣṭi-vardhanam\n'
          'urvārukam iva bandhanān\n'
          'mṛtyor mukṣīya māmṛtāt',
      meaning:
          'We worship the three-eyed one who nourishes all beings. As a ripe '
          'cucumber falls from its stem, may we be freed from death — but not '
          'from immortality.',
      source: 'Rigveda 7.59.12',
    ),
    MantraPreset(
      name: 'Hare Krishna',
      rounds: 16,
      description:
          'The maha-mantra of sixteen names. Sixteen rounds is the '
          'traditional daily commitment.',
      devanagari:
          'हरे कृष्ण हरे कृष्ण\n'
          'कृष्ण कृष्ण हरे हरे\n'
          'हरे राम हरे राम\n'
          'राम राम हरे हरे',
      transliteration:
          'hare kṛṣṇa hare kṛṣṇa\n'
          'kṛṣṇa kṛṣṇa hare hare\n'
          'hare rāma hare rāma\n'
          'rāma rāma hare hare',
      meaning:
          'A calling out to the divine by name — to Krishna, to Rama, and to '
          'Hara, the divine energy.',
      source: 'Kali-Santarana Upanishad',
    ),
    MantraPreset(
      name: 'Om Mani Padme Hum',
      rounds: 1,
      description:
          'The mantra of compassion, central to Tibetan Buddhist practice.',
      devanagari: 'ॐ मणिपद्मे हूँ',
      transliteration: 'oṃ maṇi padme hūṃ',
      meaning:
          'The jewel in the lotus — invoking the compassion of Avalokiteshvara.',
      source: 'Karandavyuha Sutra',
    ),
    MantraPreset(
      name: 'So Ham',
      rounds: 1,
      description: 'A breath mantra: "so" on the inhale, "ham" on the exhale.',
      devanagari: 'सोऽहम्',
      transliteration: 'so\'ham',
      meaning:
          'I am That — the practitioner and the absolute are not separate.',
      source: 'Isha Upanishad',
    ),
  ];
}
