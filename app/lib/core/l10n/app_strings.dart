import 'package:flutter/material.dart';

/// Lightweight in-app string table for the five supported locales.
///
/// Keys are short identifiers. Any key without a translation for the active
/// locale falls back to English so the UI never renders an empty string.
class AppStrings {
  AppStrings._();

  static const _fallback = 'en';

  static const _table = <String, Map<String, String>>{
    // ---- App shell / navigation ----
    'nav_home': {
      'en': 'Home',
      'hi': 'होम',
      'mr': 'होम',
      'ta': 'முகப்பு',
      'te': 'హోమ్',
    },
    'nav_map': {
      'en': 'Map',
      'hi': 'नक्शा',
      'mr': 'नकाशा',
      'ta': 'வரைபடம்',
      'te': 'మ్యాప్',
    },
    'nav_inbox': {
      'en': 'Inbox',
      'hi': 'इनबॉक्स',
      'mr': 'इनबॉक्स',
      'ta': 'இன்பாக்ஸ்',
      'te': 'ఇన్బాక్స్',
    },
    'nav_profile': {
      'en': 'Profile',
      'hi': 'प्रोफ़ाइल',
      'mr': 'प्रोफाइल',
      'ta': 'சுயவிவரம்',
      'te': 'ప్రొఫైల్',
    },
    'nav_create': {
      'en': 'Create',
      'hi': 'बनाएँ',
      'mr': 'तयार करा',
      'ta': 'உருவாக்கு',
      'te': 'సృష్టించు',
    },
    'action_create_issue': {
      'en': 'Report an issue',
      'hi': 'समस्या बताएं',
      'mr': 'समस्या नोंदवा',
      'ta': 'சிக்கலைப் புகாரளி',
      'te': 'సమస్య నివేదించండి',
    },
    'action_start_talk': {
      'en': 'Start a ward discussion',
      'hi': 'वार्ड चर्चा शुरू करें',
      'mr': 'वॉर्ड चर्चा सुरू करा',
      'ta': 'வார்டு கலந்துரையாடலைத் தொடங்கு',
      'te': 'వార్డు చర్చ ప్రారంభించండి',
    },
    // ---- Feed ----
    'feed_title': {
      'en': 'LocalLens',
      'hi': 'लोकललेंस',
      'mr': 'लोकललेंस',
      'ta': 'லோக்கலலென்ஸ்',
      'te': 'లోకల్లెన్స్',
    },
    'feed_filter_all': {'en': 'All', 'hi': 'सभी', 'mr': 'सर्व', 'ta': 'அனைத்து', 'te': 'అన్నీ'},
    'feed_filter_issues': {
      'en': 'Issues',
      'hi': 'समस्याएँ',
      'mr': 'समस्या',
      'ta': 'சிக்கல்கள்',
      'te': 'సమస్యలు',
    },
    'feed_filter_wins': {
      'en': 'Wins',
      'hi': 'विजय',
      'mr': 'विजय',
      'ta': 'வெற்றிகள்',
      'te': 'విజయాలు',
    },
    'feed_filter_notices': {
      'en': 'Notices',
      'hi': 'सूचनाएँ',
      'mr': 'सूचना',
      'ta': 'அறிவிப்புகள்',
      'te': 'నోటీసులు',
    },
    'feed_filter_talk': {
      'en': 'Local Talk',
      'hi': 'स्थानीय चर्चा',
      'mr': 'स्थानिक चर्चा',
      'ta': 'உள்ளூர் உரையாடல்',
      'te': 'స్థానిక చర్చ',
    },
    'feed_unavailable': {
      'en': 'Feed unavailable',
      'hi': 'फ़ीड उपलब्ध नहीं',
      'mr': 'फीड उपलब्ध नाही',
      'ta': 'ஊட்டம் கிடைக்கவில்லை',
      'te': 'ఫీడ్ అందుబాటులో లేదు',
    },
    'feed_unavailable_msg': {
      'en': 'We could not load nearby updates right now.',
      'hi': 'अभी आस-पास के अपडेट लोड नहीं हो सके।',
      'mr': 'सध्या जवळचे अपडेट लोड करता आले नाहीत.',
      'ta': 'இப்போது அருகிலுள்ள புதுப்பிப்புகளை ஏற்ற முடியவில்லை.',
      'te': 'ప్రస్తుతం సమీప నవీకరణలను లోడ్ చేయలేకపోయాము.',
    },
    'action_retry': {
      'en': 'Retry',
      'hi': 'फिर से कोशिश करें',
      'mr': 'पुन्हा प्रयत्न करा',
      'ta': 'மீண்டும் முயற்சி',
      'te': 'తిరిగి ప్రయత్నించండి',
    },
    'feed_empty_title': {
      'en': 'All clear around here',
      'hi': 'यहाँ सब ठीक है',
      'mr': 'इथे सर्व काही ठीक आहे',
      'ta': 'இங்கு எல்லாம் சரி',
      'te': 'ఇక్కడ అంతా బాగుంది',
    },
    'feed_empty_msg': {
      'en': 'Be the first to report an issue or start a talk in your area.',
      'hi': 'अपने क्षेत्र में पहली समस्या बताएं या चर्चा शुरू करें।',
      'mr': 'तुमच्या परिसरात पहिली समस्या नोंदवा किंवा चर्चा सुरू करा.',
      'ta': 'உங்கள் பகுதியில் முதல் சிக்கலைப் புகாரளிக்கவும் அல்லது உரையாடலைத் தொடங்கவும்.',
      'te': 'మీ ప్రాంతంలో మొదటి సమస్యను నివేదించండి లేదా చర్చ ప్రారంభించండి.',
    },
    'feed_end_of_feed': {
      'en': "You're all caught up!",
      'hi': 'आप सब पढ़ चुके हैं!',
      'mr': 'तुम्ही सर्व वाचले आहात!',
      'ta': 'நீங்கள் அனைத்தையும் பார்த்துவிட்டீர்கள்!',
      'te': 'మీరు అన్నీ చూసేశారు!',
    },
    'feed_end_of_feed_msg': {
      'en': 'Check back later for new local updates in your area.',
      'hi': 'अपने क्षेत्र के नए अपडेट के लिए बाद में फिर देखें।',
      'mr': 'तुमच्या परिसरातील नवीन अपडेटसाठी नंतर पुन्हा पहा.',
      'ta': 'உங்கள் பகுதியில் புதிய புதுப்பிப்புகளுக்கு பின்னர் வாருங்கள்.',
      'te': 'మీ ప్రాంతంలో కొత్త నవీకరణల కోసం తర్వాత చూడండి.',
    },
    'feed_area_label': {
      'en': 'My area',
      'hi': 'मेरा क्षेत्र',
      'mr': 'माझा परिसर',
      'ta': 'என் பகுதி',
      'te': 'నా ప్రాంతం',
    },
    'action_search': {
      'en': 'Search',
      'hi': 'खोजें',
      'mr': 'शोधा',
      'ta': 'தேடு',
      'te': 'శోధన',
    },
    'action_notifications': {
      'en': 'Notifications',
      'hi': 'सूचनाएँ',
      'mr': 'सूचना',
      'ta': 'அறிவிப்புகள்',
      'te': 'నోటిఫికేషన్లు',
    },
    'action_upvote': {
      'en': 'Upvote',
      'hi': 'अपवोट',
      'mr': 'अपवोट',
      'ta': 'ஆதரவு',
      'te': 'అప్‌వోట్',
    },
    'action_comment': {
      'en': 'Comment',
      'hi': 'टिप्पणी',
      'mr': 'टिप्पणी',
      'ta': 'கருத்து',
      'te': 'వ్యాఖ్య',
    },
    'action_share': {
      'en': 'Share',
      'hi': 'साझा करें',
      'mr': 'शेअर करा',
      'ta': 'பகிர்',
      'te': 'భాగస్వామ్యం',
    },
    // ---- Compose ----
    'compose_title': {
      'en': 'Report an issue',
      'hi': 'समस्या बताएं',
      'mr': 'समस्या नोंदवा',
      'ta': 'சிக்கலைப் புகாரளி',
      'te': 'సమస్య నివేదించండి',
    },
    'compose_whats_wrong': {
      'en': 'What is wrong?',
      'hi': 'क्या समस्या है?',
      'mr': 'काय समस्या आहे?',
      'ta': 'என்ன பிரச்சனை?',
      'te': 'ఏమి సమస్య?',
    },
    'compose_details': {
      'en': 'Details',
      'hi': 'विवरण',
      'mr': 'तपशील',
      'ta': 'விவரங்கள்',
      'te': 'వివరాలు',
    },
    'compose_fuzz': {
      'en': 'Fuzz location',
      'hi': 'स्थान धुंधला करें',
      'mr': 'स्थान फजी करा',
      'ta': 'இருப்பிடத்தை மங்கலாக்கு',
      'te': 'స్థానాన్ని మసకబార్చు',
    },
    'compose_fuzz_sub': {
      'en': 'Block-level grid precision (~1km) for home privacy',
      'hi': 'घर की निजता के लिए ब्लॉक-स्तरीय ग्रिड (~1km)',
      'mr': 'घराच्या खाजगीपणासाठी ब्लॉक स्तर ग्रिड (~1km)',
      'ta': 'வீட்டுத் தனியுரிமைக்காக அரை (~1km) துல்லியம்',
      'te': 'ఇంటి గోప్యత కోసం (~1km) గ్రిడ్ ఖచ్చితత్వం',
    },
    'compose_shield': {
      'en': 'Shield Mode (Whistleblower)',
      'hi': 'शील्ड मोड (मुखबिर)',
      'mr': 'शिल्ड मोड (माहिती देणारा)',
      'ta': 'ஷீல்டு பயன்முறை',
      'te': 'షీల్డ్ మోడ్',
    },
    'compose_anonymous': {
      'en': 'Post anonymously',
      'hi': 'गुमनाम रूप से पोस्ट करें',
      'mr': 'अनामपणे पोस्ट करा',
      'ta': 'அநாமதேயமாக இடுகையிடு',
      'te': 'అనామకంగా పోస్ట్ చేయండి',
    },
    'compose_media': {
      'en': 'Media Attachments',
      'hi': 'मीडिया संलग्न',
      'mr': 'मीडिया संलग्न',
      'ta': 'மீடியா இணைப்புகள்',
      'te': 'మీడియా జోడింపులు',
    },
    'compose_take_photo': {
      'en': 'Take Photo',
      'hi': 'फ़ोटो लें',
      'mr': 'फोटो काढा',
      'ta': 'புகைப்படம் எடு',
      'te': 'ఫోటో తీయండి',
    },
    'compose_add_gallery': {
      'en': 'Add Photos from Gallery',
      'hi': 'गैलरी से फ़ोटो जोड़ें',
      'mr': 'गॅलरीतून फोटो जोडा',
      'ta': 'கேலரியிலிருந்து புகைப்படங்கள் சேர்',
      'te': 'గ్యాలరీ నుండి ఫోటోలు జోడించండి',
    },
    'compose_publish': {
      'en': 'Publish',
      'hi': 'प्रकाशित करें',
      'mr': 'प्रकाशित करा',
      'ta': 'வெளியிடு',
      'te': 'ప్రచురించండి',
    },
    'compose_published': {
      'en': 'Issue published successfully',
      'hi': 'समस्या सफलतापूर्वक प्रकाशित',
      'mr': 'समस्या यशस्वीरित्या प्रकाशित',
      'ta': 'சிக்கல் வெற்றிகரமாக வெளியிடப்பட்டது',
      'te': 'సమస్య విజయవంతంగా ప్రచురించబడింది',
    },
    'compose_outbox_msg': {
      'en': 'Saved to offline outbox. Will sync when online.',
      'hi': 'ऑफ़लाइन आउटबॉक्स में सहेजा गया। ऑनलाइन होने पर सिंक होगा।',
      'mr': 'ऑफलाइन आउटबॉक्समध्ये जतन केले. ऑनलाइन आल्यावर सिंक होईल.',
      'ta': 'ஆஃப்லைன் அவுட்பாக்ஸில் சேமிக்கப்பட்டது. ஆன்லைனில் ஒத்திசைக்கப்படும்.',
      'te': 'ఆఫ్‌లైన్ అవుట్‌బాక్స్‌లో సేవ్ చేయబడింది. ఆన్‌లైన్‌లో సింక్ అవుతుంది.',
    },
    'compose_discard': {
      'en': 'Discard draft',
      'hi': 'ड्राफ़्ट हटाएं',
      'mr': 'मसुदा हटवा',
      'ta': 'வரைவை நீக்கு',
      'te': 'డ్రాఫ్ట్ తొలగించండి',
    },
    // ---- Comments ----
    'comments_title': {
      'en': 'Community Discussion',
      'hi': 'समुदाय चर्चा',
      'mr': 'समुदाय चर्चा',
      'ta': 'சமூக உரையாடல்',
      'te': 'సమాజ చర్చ',
    },
    'comments_empty': {
      'en': 'No comments yet. Be the first to comment!',
      'hi': 'अभी कोई टिप्पणी नहीं। पहली टिप्पणी करें!',
      'mr': 'अजून टिप्पणी नाही. पहिली टिप्पणी करा!',
      'ta': 'இன்னும் கருத்துகள் இல்லை. முதல் கருத்து தெரிவியுங்கள்!',
      'te': 'ఇంకా వ్యాఖ్యలు లేవు. మొదటి వ్యాఖ్య చేయండి!',
    },
    'comments_hint': {
      'en': 'Write a comment...',
      'hi': 'टिप्पणी लिखें...',
      'mr': 'टिप्पणी लिहा...',
      'ta': 'கருத்து எழுதுங்கள்...',
      'te': 'వ్యాఖ్య వ్రాయండి...',
    },
    'comments_reply': {
      'en': 'Reply',
      'hi': 'जवाब दें',
      'mr': 'उत्तर द्या',
      'ta': 'பதில்',
      'te': 'ప్రత్యుత్తరం',
    },
    'comments_replying_to': {
      'en': 'Replying to',
      'hi': 'जवाब दे रहे हैं',
      'mr': 'उत्तर देत आहात',
      'ta': 'பதிலளிக்கிறீர்கள்',
      'te': 'ప్రత్యుత్తరం ఇస్తున్నారు',
    },
    'comments_anonymous': {
      'en': 'Anonymous neighbour',
      'hi': 'गुमनाम पड़ोसी',
      'mr': 'अनाम शेजारी',
      'ta': 'அநாமதேய அண்டை',
      'te': 'అనామక పొరుగు',
    },
    'comments_just_now': {
      'en': 'Just now',
      'hi': 'अभी अभी',
      'mr': 'आत्ताच',
      'ta': 'இப்போதுதான்',
      'te': 'ఇప్పుడే',
    },
    // ---- Outbox ----
    'outbox_title': {
      'en': 'Offline Outbox',
      'hi': 'ऑफ़लाइन आउटबॉक्स',
      'mr': 'ऑफलाइन आउटबॉक्स',
      'ta': 'ஆஃப்லைன் அவுட்பாக்ஸ்',
      'te': 'ఆఫ్‌లైన్ అవుట్‌బాక్స్',
    },
    'outbox_sync_now': {
      'en': 'Sync Now',
      'hi': 'अभी सिंक करें',
      'mr': 'आता सिंक करा',
      'ta': 'இப்போது ஒத்திசை',
      'te': 'ఇప్పుడు సింక్ చేయండి',
    },
    'outbox_empty': {
      'en': 'Nothing queued for upload. All reports are in sync.',
      'hi': 'अपलोड के लिए कुछ भी कतार में नहीं। सभी रिपोर्ट सिंक में हैं।',
      'mr': 'अपलोडसाठी काहीही रांगेत नाही. सर्व अहवाल सिंकमध्ये आहेत.',
      'ta': 'பதிவேற்றத்திற்கு எதுவும் வரிசையில் இல்லை. அனைத்து அறிக்கைகளும் ஒத்திசைக்கப்பட்டுள்ளன.',
      'te': 'అప్‌లోడ్ కోసం ఏమీ లేదు. అన్ని నివేదికలు సింక్ అయ్యాయి.',
    },
    'outbox_pending': {
      'en': 'Pending uploads',
      'hi': 'लंबित अपलोड',
      'mr': 'प्रलंबित अपलोड',
      'ta': 'நிலுவை பதிவேற்றங்கள்',
      'te': 'పెండింగ్ అప్‌లోడ్లు',
    },
    'outbox_synced': {
      'en': 'Outbox synchronized',
      'hi': 'आउटबॉक्स सिंक हो गया',
      'mr': 'आउटबॉक्स सिंक झाले',
      'ta': 'அவுட்பாக்ஸ் ஒத்திசைக்கப்பட்டது',
      'te': 'అవుట్‌బాక్స్ సింక్ చేయబడింది',
    },
    'outbox_synced_all': {
      'en': 'All queued reports were published.',
      'hi': 'सभी कतारबद्ध रिपोर्ट प्रकाशित हुईं।',
      'mr': 'सर्व रांगेतील अहवाल प्रकाशित झाले.',
      'ta': 'வரிசையில் உள்ள அனைத்து அறிக்கைகளும் வெளியிடப்பட்டன.',
      'te': 'వరుసలో ఉన్న అన్ని నివేదికలు ప్రచురించబడ్డాయి.',
    },
    'outbox_failed_partial': {
      'en': 'Some items could not be synced yet.',
      'hi': 'कुछ आइटम अभी सिंक नहीं हो सके।',
      'mr': 'काही आयटम अजून सिंक होऊ शकले नाहीत.',
      'ta': 'சில பொருட்களை இன்னும் ஒத்திசைக்க முடியவில்லை.',
      'te': 'కొన్ని అంశాలు ఇంకా సింక్ కాలేదు.',
    },
    // ---- Session / errors ----
    'session_expired': {
      'en': 'Your session expired. Please sign in again.',
      'hi': 'आपका सत्र समाप्त हो गया। कृपया फिर से साइन इन करें।',
      'mr': 'तुमचे सत्र संपले आहे. कृपया पुन्हा साइन इन करा.',
      'ta': 'உங்கள் அமர்வு காலாவதியானது. மீண்டும் உள்நுழையவும்.',
      'te': 'మీ సెషన్ గడువు ముగిసింది. దయచేసి మళ్లీ సైన్ ఇన్ చేయండి.',
    },
    'guest_session': {
      'en': 'Guest Session',
      'hi': 'अतिथि सत्र',
      'mr': 'अतिथी सत्र',
      'ta': 'விருந்தினர் அமர்வு',
      'te': 'అతిథి సెషన్',
    },
    'guest_session_active': {
      'en': 'You are exploring as a guest. Sign in to report, comment and vote.',
      'hi': 'आप अतिथि के रूप में देख रहे हैं। बताने, टिप्पणी और वोट के लिए साइन इन करें।',
      'mr': 'तुम्ही अतिथी म्हणून पाहत आहात. नोंदवण्यासाठी, टिप्पणी व मतासाठी साइन इन करा.',
      'ta': 'நீங்கள் விருந்தினராகப் பார்க்கிறீர்கள். புகாரளிக்க உள்நுழையவும்.',
      'te': 'మీరు అతిథిగా చూస్తున్నారు. నివేదించడానికి సైన్ ఇన్ చేయండి.',
    },
    'sign_in_required': {
      'en': 'Sign in required',
      'hi': 'साइन इन आवश्यक',
      'mr': 'साइन इन आवश्यक',
      'ta': 'உள்நுழைவு தேவை',
      'te': 'సైన్ ఇన్ అవసరం',
    },
  };

  /// Returns the translated string for [key] in [languageCode], falling back
  /// to English when a translation is missing.
  static String translate(String languageCode, String key) {
    final row = _table[key];
    if (row == null) return key;
    if (row.containsKey(languageCode)) return row[languageCode]!;
    return row[_fallback] ?? key;
  }
}

/// Convenience accessor so widgets can do `context.tr('nav_home')`.
extension AppStringsContext on BuildContext {
  String tr(String key) =>
      AppStrings.translate(Localizations.localeOf(this).languageCode, key);
}