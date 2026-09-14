class AppStrings {
  final String languageCode;

  const AppStrings(this.languageCode);

  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'tr', 'name': 'Türkçe'},
    {'code': 'en', 'name': 'English'},
    {'code': 'de', 'name': 'Deutsch'},
    {'code': 'es', 'name': 'Español'},
  ];

  static const Map<String, Map<String, String>> _localizedValues = {
    'tr': {
      'settings': 'Ayarlar',
      'language': 'Dil',
      'selectLanguage': 'Dil Seçin',
      'soundEffects': 'Ses Efektleri',
      'soundOn': 'Açık',
      'soundOff': 'Kapalı',
      'newChart': 'Yeni Grafik',
      'openChart': 'Grafik Aç',
      'saveChart': 'Grafiği Kaydet',
      'savedDesigns': 'Kayıtlı Tasarımlar',
      'dataView': 'Veri Görünümü',
      'exportPng': 'PNG Olarak Dışa Aktar',
      'help': 'Kullanım Rehberi',
      'undo': 'Geri Al',
      'redo': 'Yinele',
      'menu': 'Menü',
      'stitchPalette': 'İlmek Paleti',
      'properties': 'Özellikler',
      'shape': 'Şekil',
      'stitch': 'İlmek',
      'select': 'Seç',
      'replace': 'Değiştir',
      'delete': 'Sil',
      'move': 'Taşı',
      'pan': 'Kaydır',
      'selected': 'seçili',
      'close': 'Kapat',
      'cancel': 'İptal',
      'save': 'Kaydet',
      'addRound': 'Yeni Tur',
      'round': 'Tur',
      'circle': 'Daire',
      'square': 'Kare',
      'hexagon': 'Altıgen',
      'triangle': 'Üçgen',
      'pentagon': 'Beşgen',
      'octagon': 'Sekizgen',
      'oval': 'Oval',
      'stitches': 'İlmekler',
      'searchStitches': 'İlmek ara...',
      'clearSearch': 'Aramayı temizle',
      'noStitchesFound': 'Eşleşen ilmek bulunamadı',
      'all': 'Tümü',
      'categoryDefault': 'Standart',
      'categoryStarters': 'Başlangıç',
      'hintSelectStarter': 'Grafiğinize başlamak için paletten bir başlangıç ilmeği seçin',
      'hintTapCenter': 'Başlangıç ilmeğini yerleştirmek için merkeze dokunun',
      'selectedStitchesCount': 'ilmek seçildi',
      'roundStitchesCount': 'ilmek',
      'replaceFromPalette': 'Değiştir (Paletten Seç)',
      'clearSelection': 'Seçimi Temizle',
      'selectionModeHint': 'İlmek Seçim Modu: Grafikteki ilmeklere dokunarak seçin',
      'selectionMultiHint': 'Seçmek istediğiniz ilmeklere dokunun (birden fazla seçebilirsiniz)',
      'selectAll': 'Tümünü Seç',
      'bulkReplace': 'Toplu Değiştir',
      'roundDeleted': 'silindi',
      'replaceStep1': '1. Grafikten değiştirmek istediğiniz ilmeğe dokunun',
      'replaceStep2Selected': 'Seçilen',
      'replaceStep2Choose': '2. Paletten yeni ilmeği seçin',
      'addRoundTooltip': 'Yeni Tur Ekle',
      'deleteLastRound': 'Son Turu Sil',
      'expandRound': 'Turu Genişlet',
      'contractRound': 'Turu Daralt',
      'expandAllRounds': 'Tüm Turları Genişlet',
      'contractAllRounds': 'Tüm Turları Daralt',
      'resetRoundSize': 'Tur Boyutunu Sıfırla',
      'chartNameLabel': 'Ad',
      'size': 'Boyut',
      'styleLabel': 'Stil',
      'visual': 'Görsel',
      'textual': 'Metinsel',
      'roundCount': 'Tur Sayısı',
      'rounds': 'Turlar:',
      'zoom': 'Yakınlaştırma:',
      'roundExpansion': 'Tur Genişletme / Aralık:',
      'noRoundsYet': 'Grafikte henüz tur bulunmuyor',
      'deleteRound': 'Turu Sil',
      'untitled': 'İsimsiz',
      'roundShape': 'Tur Şekli',
      'cornerRounding': 'Köşe yuvarlama:',
      'circleCornerHint': 'Daire şeklinde köşe yuvarlama bulunmaz. Çokgen grafik için 3-12 kenar seçin.',
      'polygonCornerHintSharp': 'Turlar keskin köşeli {sides} kenarlı bir çokgen olarak çizilir.',
      'polygonCornerHintRounded': 'Turlar yuvarlatılmış köşeli {sides} kenarlı bir çokgen olarak çizilir.',
      'nSided': 'kenarlı',
      'tutorialWelcomeTitle': "MystCrochet'e Hoş Geldiniz!",
      'tutorialWelcomeDesc': 'Tığ işi ve amigurumi dairesel şemalarınızı kolayca tasarlayın, görselleştirin ve dışa aktarın.',
      'tutorialWelcomeH1': '✨ Sihirli halka ve zincirle zahmetsiz başlangıç',
      'tutorialWelcomeH2': '📐 Dairesel veya çokgen (kare, altıgen vb.) turlar',
      'tutorialWelcomeH3': '📱 Dokunmatik ve mobil cihazlara tam uyumlu arayüz',
      'tutorialStep2Title': 'Başlangıç ve İlmek Ekleme',
      'tutorialStep2Desc': 'Şemanıza başlamak ve tuval üzerine ilmek yerleştirmek oldukça pratiktir:',
      'tutorialStep2H1': '1. Paletten başlangıç ilmeğinizi (Sihirli Halka vb.) seçip merkeze dokunun.',
      'tutorialStep2H2': '2. Paletten istediğiniz ilmeği (sc, dc, hdc vb.) seçin.',
      'tutorialStep2H3': '3. Tuvalde önceki turun ilmeklerinin yakınına dokunarak yeni ilmekleri ekleyin.',
      'tutorialStep3Title': 'Turlar ve Geometrik Şekiller',
      'tutorialStep3Desc': 'Şemanızın formunu ve tur boyutlarını dilediğiniz gibi kişiselleştirin:',
      'tutorialStep3H1': '📏 Tur Çubuğu: Tuval üzerindeki bardan tur boyutunu (+ / -) ayarlayabilirsiniz.',
      'tutorialStep3H2': '🔷 Geometrik Şekiller: Turlarınızı Daire, Kare, Altıgen gibi formlara dönüştürün.',
      'tutorialStep3H3': '➕ Yeni Tur: Bir sonraki tura geçmek için "Yeni Tur" butonuna dokunmanız yeterlidir.',
      'tutorialStep4Title': 'Doğal Kaydırma & Düzenleme',
      'tutorialStep4Desc': 'Dokunmatik ekranda tuval üzerinde rahatça gezinin ve ilmeklerinizi yönetin:',
      'tutorialStep4H1': '🖐️ Tek Parmak Kaydırma: Turların dışındaki boş alana dokunup sürükleyerek tuvali kaydırın.',
      'tutorialStep4H2': '🤏 İki Parmak Yakınlaşma: İki parmağınızla kıstırıp açarak (pinch) yakınlaştırın.',
      'tutorialStep4H3': '🛠️ Araç Çubuğu: Seç, Değiştir, Sil ve Taşı modlarıyla ilmeklerinizi kolayca düzenleyin.',
      'tutorialDontShowAgain': 'Bir daha otomatik gösterme',
      'tutorialBack': 'Geri',
      'tutorialSkip': 'Geç',
      'tutorialNext': 'İleri',
      'tutorialStart': 'Hemen Başla',
      'login': 'Giriş Yap',
      'register': 'Kayıt Ol',
      'logout': 'Çıkış Yap',
      'profile': 'Profil',
      'account': 'Hesap',
      'loginOrRegister': 'Giriş Yap / Kayıt Ol',
      'username': 'Kullanıcı Adı',
      'email': 'E-posta',
      'password': 'Şifre',
      'confirmPassword': 'Şifre Tekrar',
      'serverUrl': 'Sunucu Adresi (Backend URL)',
      'serverSettings': 'Sunucu Ayarı',
      'loggedInAs': 'Olarak giriş yapıldı',
      'passwordsDoNotMatch': 'Şifreler eşleşmiyor',
      'passwordTooShort': 'Şifre en az 6 karakter olmalıdır',
      'usernameRequired': 'Kullanıcı adı gereklidir',
      'emailRequired': 'Geçerli bir e-posta adresi girin',
      'loginSuccess': 'Giriş başarılı!',
      'registerSuccess': 'Kayıt başarılı!',
      'loggedOut': 'Çıkış yapıldı',
      'alreadyHaveAccount': 'Zaten hesabınız var mı? Giriş yapın',
      'dontHaveAccount': 'Hesabınız yok mu? Kayıt olun',
    },
    'en': {
      'settings': 'Settings',
      'language': 'Language',
      'selectLanguage': 'Select Language',
      'soundEffects': 'Sound Effects',
      'soundOn': 'On',
      'soundOff': 'Off',
      'newChart': 'New Chart',
      'openChart': 'Open Chart',
      'saveChart': 'Save Chart',
      'savedDesigns': 'Saved Designs',
      'dataView': 'Data View',
      'exportPng': 'Export as PNG',
      'help': 'User Guide',
      'undo': 'Undo',
      'redo': 'Redo',
      'menu': 'Menu',
      'stitchPalette': 'Stitch Palette',
      'properties': 'Properties',
      'shape': 'Shape',
      'stitch': 'Stitch',
      'select': 'Select',
      'replace': 'Replace',
      'delete': 'Delete',
      'move': 'Move',
      'pan': 'Pan',
      'selected': 'selected',
      'close': 'Close',
      'cancel': 'Cancel',
      'save': 'Save',
      'addRound': 'New Round',
      'round': 'Round',
      'circle': 'Circle',
      'square': 'Square',
      'hexagon': 'Hexagon',
      'triangle': 'Triangle',
      'pentagon': 'Pentagon',
      'octagon': 'Octagon',
      'oval': 'Oval',
      'stitches': 'Stitches',
      'searchStitches': 'Search stitches...',
      'clearSearch': 'Clear search',
      'noStitchesFound': 'No matching stitches found',
      'all': 'All',
      'categoryDefault': 'Default',
      'categoryStarters': 'Starters',
      'hintSelectStarter': 'Select a starting stitch from the palette to begin your chart',
      'hintTapCenter': 'Tap center to place the starter stitch',
      'selectedStitchesCount': 'stitches selected',
      'roundStitchesCount': 'stitches',
      'replaceFromPalette': 'Replace (Select from Palette)',
      'clearSelection': 'Clear Selection',
      'selectionModeHint': 'Stitch Selection Mode: Tap stitches on chart to select',
      'selectionMultiHint': 'Tap stitches to select (multiple selection supported)',
      'selectAll': 'Select All',
      'bulkReplace': 'Bulk Replace',
      'roundDeleted': 'deleted',
      'replaceStep1': '1. Tap the stitch on the chart you want to replace',
      'replaceStep2Selected': 'Selected',
      'replaceStep2Choose': '2. Select new stitch from palette',
      'addRoundTooltip': 'Add New Round',
      'deleteLastRound': 'Delete Last Round',
      'expandRound': 'Expand Round',
      'contractRound': 'Contract Round',
      'expandAllRounds': 'Expand All Rounds',
      'contractAllRounds': 'Contract All Rounds',
      'resetRoundSize': 'Reset Round Size',
      'chartNameLabel': 'Name',
      'size': 'Size',
      'styleLabel': 'Style',
      'visual': 'Visual',
      'textual': 'Textual',
      'roundCount': 'Round Count',
      'rounds': 'Rounds:',
      'zoom': 'Zoom:',
      'roundExpansion': 'Round Expansion / Spacing:',
      'noRoundsYet': 'No rounds in chart yet',
      'deleteRound': 'Delete Round',
      'untitled': 'Untitled',
      'roundShape': 'Round Shape',
      'cornerRounding': 'Corner rounding:',
      'circleCornerHint': 'Circles do not have corner rounding. Choose 3-12 sides for a polygon.',
      'polygonCornerHintSharp': 'Rounds are drawn as a {sides}-sided polygon with sharp corners.',
      'polygonCornerHintRounded': 'Rounds are drawn as a {sides}-sided polygon with rounded corners.',
      'nSided': 'sides',
      'tutorialWelcomeTitle': 'Welcome to MystCrochet!',
      'tutorialWelcomeDesc': 'Easily design, visualize, and export your circular crochet and amigurumi charts.',
      'tutorialWelcomeH1': '✨ Effortless start with magic ring and chains',
      'tutorialWelcomeH2': '📐 Circular or polygonal (square, hexagon, etc.) rounds',
      'tutorialWelcomeH3': '📱 Touch-friendly interface fully compatible with mobile devices',
      'tutorialStep2Title': 'Starting & Adding Stitches',
      'tutorialStep2Desc': 'Starting your pattern and placing stitches on the canvas is very easy:',
      'tutorialStep2H1': '1. Select a starter stitch (Magic Ring, etc.) from the palette and tap the center.',
      'tutorialStep2H2': '2. Choose any stitch from the palette (sc, dc, hdc, etc.).',
      'tutorialStep2H3': '3. Tap near previous round stitches on the canvas to add new stitches.',
      'tutorialStep3Title': 'Rounds & Geometric Shapes',
      'tutorialStep3Desc': 'Customize your chart form and round sizes as you like:',
      'tutorialStep3H1': '📏 Round Bar: Adjust round size (+ / -) from the toolbar on canvas.',
      'tutorialStep3H2': '🔷 Geometric Shapes: Transform rounds into Circle, Square, Hexagon, etc.',
      'tutorialStep3H3': '➕ New Round: Tap "New Round" to proceed to the next round.',
      'tutorialStep4Title': 'Natural Panning & Editing',
      'tutorialStep4Desc': 'Freely navigate the canvas and manage stitches on touch screens:',
      'tutorialStep4H1': '🖐️ One-Finger Pan: Drag empty space outside rounds to pan the canvas.',
      'tutorialStep4H2': '🤏 Pinch to Zoom: Use two fingers to pinch and zoom the canvas.',
      'tutorialStep4H3': '🛠️ Toolbar: Easily edit stitches with Select, Replace, Delete, and Move modes.',
      'tutorialDontShowAgain': 'Do not show automatically again',
      'tutorialBack': 'Back',
      'tutorialSkip': 'Skip',
      'tutorialNext': 'Next',
      'tutorialStart': 'Get Started',
      'login': 'Login',
      'register': 'Register',
      'logout': 'Logout',
      'profile': 'Profile',
      'account': 'Account',
      'loginOrRegister': 'Login / Register',
      'username': 'Username',
      'email': 'Email',
      'password': 'Password',
      'confirmPassword': 'Confirm Password',
      'serverUrl': 'Server URL (Backend URL)',
      'serverSettings': 'Server Settings',
      'loggedInAs': 'Logged in as',
      'passwordsDoNotMatch': 'Passwords do not match',
      'passwordTooShort': 'Password must be at least 6 characters',
      'usernameRequired': 'Username is required',
      'emailRequired': 'Enter a valid email address',
      'loginSuccess': 'Login successful!',
      'registerSuccess': 'Registration successful!',
      'loggedOut': 'Logged out',
      'alreadyHaveAccount': 'Already have an account? Log in',
      'dontHaveAccount': 'Do not have an account? Register',
    },
    'de': {
      'settings': 'Einstellungen',
      'language': 'Sprache',
      'selectLanguage': 'Sprache wählen',
      'soundEffects': 'Soundeffekte',
      'soundOn': 'Ein',
      'soundOff': 'Aus',
      'newChart': 'Neues Diagramm',
      'openChart': 'Diagramm öffnen',
      'saveChart': 'Diagramm speichern',
      'savedDesigns': 'Gespeicherte Designs',
      'dataView': 'Datenansicht',
      'exportPng': 'Als PNG exportieren',
      'help': 'Benutzerhandbuch',
      'undo': 'Rückgängig',
      'redo': 'Wiederholen',
      'menu': 'Menü',
      'stitchPalette': 'Maschenpalette',
      'properties': 'Eigenschaften',
      'shape': 'Form',
      'stitch': 'Masche',
      'select': 'Auswählen',
      'replace': 'Ersetzen',
      'delete': 'Löschen',
      'move': 'Verschieben',
      'pan': 'Schwenken',
      'selected': 'ausgewählt',
      'close': 'Schließen',
      'cancel': 'Abbrechen',
      'save': 'Speichern',
      'addRound': 'Neue Runde',
      'round': 'Runde',
      'circle': 'Kreis',
      'square': 'Quadrat',
      'hexagon': 'Sechseck',
      'triangle': 'Dreieck',
      'pentagon': 'Fünfeck',
      'octagon': 'Achteck',
      'oval': 'Oval',
      'stitches': 'Maschen',
      'searchStitches': 'Maschen suchen...',
      'clearSearch': 'Suche löschen',
      'noStitchesFound': 'Keine passenden Maschen gefunden',
      'all': 'Alle',
      'categoryDefault': 'Standard',
      'categoryStarters': 'Anfang',
      'hintSelectStarter': 'Wählen Sie eine Anfangsmasche aus der Palette, um Ihr Diagramm zu beginnen',
      'hintTapCenter': 'Tippen Sie in die Mitte, um die Anfangsmasche zu platzieren',
      'selectedStitchesCount': 'Maschen ausgewählt',
      'roundStitchesCount': 'Maschen',
      'replaceFromPalette': 'Ersetzen (Aus Palette wählen)',
      'clearSelection': 'Auswahl aufheben',
      'selectionModeHint': 'Maschenauswahl-Modus: Tippen Sie auf Maschen, um sie auszuwählen',
      'selectionMultiHint': 'Tippen Sie auf Maschen, um sie auszuwählen (Mehrfachauswahl möglich)',
      'selectAll': 'Alle auswählen',
      'bulkReplace': 'Massenersetzung',
      'roundDeleted': 'gelöscht',
      'replaceStep1': '1. Tippen Sie auf die zu ersetzende Masche im Diagramm',
      'replaceStep2Selected': 'Ausgewählt',
      'replaceStep2Choose': '2. Neue Masche aus Palette wählen',
      'addRoundTooltip': 'Neue Runde hinzufügen',
      'deleteLastRound': 'Letzte Runde löschen',
      'expandRound': 'Runde vergrößern',
      'contractRound': 'Runde verkleinern',
      'expandAllRounds': 'Alle Runden vergrößern',
      'contractAllRounds': 'Alle Runden verkleinern',
      'resetRoundSize': 'Rundengröße zurücksetzen',
      'chartNameLabel': 'Name',
      'size': 'Größe',
      'styleLabel': 'Stil',
      'visual': 'Visuell',
      'textual': 'Textuell',
      'roundCount': 'Rundenzahl',
      'rounds': 'Runden:',
      'zoom': 'Zoom:',
      'roundExpansion': 'Rundenerweiterung / Abstand:',
      'noRoundsYet': 'Noch keine Runden im Diagramm',
      'deleteRound': 'Runde löschen',
      'untitled': 'Ohne Titel',
      'roundShape': 'Rundenform',
      'cornerRounding': 'Eckenabrundung:',
      'circleCornerHint': 'Kreise haben keine Eckenabrundung. Wählen Sie 3-12 Seiten für ein Polygon.',
      'polygonCornerHintSharp': 'Runden werden als {sides}-Eck mit spitzen Ecken gezeichnet.',
      'polygonCornerHintRounded': 'Runden werden als {sides}-Eck mit abgerundeten Ecken gezeichnet.',
      'nSided': '-Eck',
      'tutorialWelcomeTitle': 'Willkommen bei MystCrochet!',
      'tutorialWelcomeDesc': 'Entwerfen, visualisieren und exportieren Sie mühelos Ihre kreisförmigen Häkel- und Amigurumi-Diagramme.',
      'tutorialWelcomeH1': '✨ Müheloser Start mit Fadenring und Luftmaschen',
      'tutorialWelcomeH2': '📐 Kreisförmige oder vieleckige (Quadrat, Sechseck usw.) Runden',
      'tutorialWelcomeH3': '📱 Touch-freundliche Benutzeroberfläche für mobile Geräte',
      'tutorialStep2Title': 'Starten & Maschen hinzufügen',
      'tutorialStep2Desc': 'Das Starten Ihres Musters und das Platzieren von Maschen ist ganz einfach:',
      'tutorialStep2H1': '1. Wählen Sie eine Anfangsmasche (Fadenring usw.) aus der Palette und tippen Sie in die Mitte.',
      'tutorialStep2H2': '2. Wählen Sie eine beliebige Masche (fM, Stb, hStb usw.) aus der Palette.',
      'tutorialStep2H3': '3. Tippen Sie in die Nähe der vorherigen Runde, um neue Maschen hinzuzufügen.',
      'tutorialStep3Title': 'Runden & geometrische Formen',
      'tutorialStep3Desc': 'Passen Sie die Diagrammform und Rundengrößen nach Wunsch an:',
      'tutorialStep3H1': '📏 Rundenleiste: Passen Sie die Rundengröße (+ / -) über die Leiste an.',
      'tutorialStep3H2': '🔷 Geometrische Formen: Wandeln Sie Runden in Kreis, Quadrat, Sechseck usw. um.',
      'tutorialStep3H3': '➕ Neue Runde: Tippen Sie auf "Neue Runde", um fortzufahren.',
      'tutorialStep4Title': 'Natürliches Schwenken & Bearbeiten',
      'tutorialStep4Desc': 'Navigieren Sie auf dem Touchscreen und verwalten Sie Maschen:',
      'tutorialStep4H1': '🖐️ Ein-Finger-Schwenken: Im leeren Bereich ziehen, um das Diagramm zu bewegen.',
      'tutorialStep4H2': '🤏 Pinch-to-Zoom: Mit zwei Fingern zusammen- oder auseinanderziehen.',
      'tutorialStep4H3': '🛠️ Symbolleiste: Maschen mit Auswählen, Ersetzen, Löschen und Verschieben bearbeiten.',
      'tutorialDontShowAgain': 'Nicht mehr automatisch anzeigen',
      'tutorialBack': 'Zurück',
      'tutorialSkip': 'Überspringen',
      'tutorialNext': 'Weiter',
      'tutorialStart': 'Loslegen',
      'login': 'Anmelden',
      'register': 'Registrieren',
      'logout': 'Abmelden',
      'profile': 'Profil',
      'account': 'Konto',
      'loginOrRegister': 'Anmelden / Registrieren',
      'username': 'Benutzername',
      'email': 'E-Mail',
      'password': 'Passwort',
      'confirmPassword': 'Passwort bestätigen',
      'serverUrl': 'Server-Adresse (Backend URL)',
      'serverSettings': 'Server-Einstellungen',
      'loggedInAs': 'Angemeldet als',
      'passwordsDoNotMatch': 'Passwörter stimmen nicht überein',
      'passwordTooShort': 'Passwort muss mindestens 6 Zeichen lang sein',
      'usernameRequired': 'Benutzername ist erforderlich',
      'emailRequired': 'Gültige E-Mail-Adresse erforderlich',
      'loginSuccess': 'Erfolgreich angemeldet!',
      'registerSuccess': 'Erfolgreich registriert!',
      'loggedOut': 'Abgemeldet',
      'alreadyHaveAccount': 'Bereits ein Konto? Anmelden',
      'dontHaveAccount': 'Noch kein Konto? Registrieren',
    },
    'es': {
      'settings': 'Configuración',
      'language': 'Idioma',
      'selectLanguage': 'Seleccionar idioma',
      'soundEffects': 'Efectos de sonido',
      'soundOn': 'Activado',
      'soundOff': 'Desactivado',
      'newChart': 'Nuevo gráfico',
      'openChart': 'Abrir gráfico',
      'saveChart': 'Guardar gráfico',
      'savedDesigns': 'Diseños guardados',
      'dataView': 'Vista de datos',
      'exportPng': 'Exportar como PNG',
      'help': 'Guía de uso',
      'undo': 'Deshacer',
      'redo': 'Rehacer',
      'menu': 'Menú',
      'stitchPalette': 'Paleta de puntos',
      'properties': 'Propiedades',
      'shape': 'Forma',
      'stitch': 'Punto',
      'select': 'Seleccionar',
      'replace': 'Reemplazar',
      'delete': 'Eliminar',
      'move': 'Mover',
      'pan': 'Desplazar',
      'selected': 'seleccionado',
      'close': 'Cerrar',
      'cancel': 'Cancelar',
      'save': 'Guardar',
      'addRound': 'Nueva vuelta',
      'round': 'Vuelta',
      'circle': 'Círculo',
      'square': 'Cuadrado',
      'hexagon': 'Hexágono',
      'triangle': 'Triángulo',
      'pentagon': 'Pentágono',
      'octagon': 'Octágono',
      'oval': 'Óvalo',
      'stitches': 'Puntos',
      'searchStitches': 'Buscar puntos...',
      'clearSearch': 'Limpiar búsqueda',
      'noStitchesFound': 'No se encontraron puntos coincidentes',
      'all': 'Todos',
      'categoryDefault': 'Predeterminado',
      'categoryStarters': 'Iniciales',
      'hintSelectStarter': 'Seleccione un punto de inicio de la paleta para comenzar su gráfico',
      'hintTapCenter': 'Toque el centro para colocar el punto inicial',
      'selectedStitchesCount': 'puntos seleccionados',
      'roundStitchesCount': 'puntos',
      'replaceFromPalette': 'Reemplazar (Seleccionar de paleta)',
      'clearSelection': 'Limpiar selección',
      'selectionModeHint': 'Modo de selección: Toque los puntos para seleccionarlos',
      'selectionMultiHint': 'Toque los puntos para seleccionar (selección múltiple permitida)',
      'selectAll': 'Seleccionar todo',
      'bulkReplace': 'Reemplazo masivo',
      'roundDeleted': 'eliminada',
      'replaceStep1': '1. Toque el punto del gráfico que desea reemplazar',
      'replaceStep2Selected': 'Seleccionado',
      'replaceStep2Choose': '2. Seleccione nuevo punto de la paleta',
      'addRoundTooltip': 'Añadir nueva vuelta',
      'deleteLastRound': 'Eliminar última vuelta',
      'expandRound': 'Expandir vuelta',
      'contractRound': 'Contraer vuelta',
      'expandAllRounds': 'Expandir todas las vueltas',
      'contractAllRounds': 'Contraer todas las vueltas',
      'resetRoundSize': 'Restablecer tamaño de vuelta',
      'chartNameLabel': 'Nombre',
      'size': 'Tamaño',
      'styleLabel': 'Estilo',
      'visual': 'Visual',
      'textual': 'Textual',
      'roundCount': 'Número de vueltas',
      'rounds': 'Vueltas:',
      'zoom': 'Zoom:',
      'roundExpansion': 'Expansión / Espaciado:',
      'noRoundsYet': 'Aún no hay vueltas en el gráfico',
      'deleteRound': 'Eliminar vuelta',
      'untitled': 'Sin título',
      'roundShape': 'Forma de la vuelta',
      'cornerRounding': 'Redondeo de esquinas:',
      'circleCornerHint': 'Los círculos no tienen redondeo de esquinas. Elija de 3 a 12 lados para un polígono.',
      'polygonCornerHintSharp': 'Las vueltas se dibujan como un polígono de {sides} lados con esquinas afiladas.',
      'polygonCornerHintRounded': 'Las vueltas se dibujan como un polígono de {sides} lados con esquinas redondeadas.',
      'nSided': 'lados',
      'tutorialWelcomeTitle': '¡Bienvenido a MystCrochet!',
      'tutorialWelcomeDesc': 'Diseñe, visualice y exporte fácilmente sus patrones circulares de crochet y amigurumi.',
      'tutorialWelcomeH1': '✨ Inicio sencillo con anillo mágico y cadenas',
      'tutorialWelcomeH2': '📐 Vueltas circulares o poligonales (cuadrado, hexágono, etc.)',
      'tutorialWelcomeH3': '📱 Interfaz táctil totalmente adaptada a dispositivos móviles',
      'tutorialStep2Title': 'Inicio y adición de puntos',
      'tutorialStep2Desc': 'Comenzar su patrón y colocar puntos en el lienzo es muy práctico:',
      'tutorialStep2H1': '1. Seleccione un punto inicial (anillo mágico, etc.) y toque el centro.',
      'tutorialStep2H2': '2. Elija el punto que desee de la paleta (pb, pa, mpa, etc.).',
      'tutorialStep2H3': '3. Toque cerca de los puntos de la vuelta anterior para añadir nuevos puntos.',
      'tutorialStep3Title': 'Vueltas y formas geométricas',
      'tutorialStep3Desc': 'Personalice la forma del patrón y los tamaños de vuelta a su gusto:',
      'tutorialStep3H1': '📏 Barra de vueltas: Ajuste el tamaño (+ / -) desde la barra del lienzo.',
      'tutorialStep3H2': '🔷 Formas geométricas: Transforme las vueltas en Círculo, Cuadrado, Hexágono, etc.',
      'tutorialStep3H3': '➕ Nueva vuelta: Toque "Nueva vuelta" para pasar a la siguiente.',
      'tutorialStep4Title': 'Desplazamiento natural y edición',
      'tutorialStep4Desc': 'Navegue con comodidad por el lienzo táctil y gestione sus puntos:',
      'tutorialStep4H1': '🖐️ Desplazamiento con un dedo: Arrastre el área vacía para mover el lienzo.',
      'tutorialStep4H2': '🤏 Pellizcar para zoom: Use dos dedos para ampliar o reducir.',
      'tutorialStep4H3': '🛠️ Barra de herramientas: Edite con los modos Seleccionar, Reemplazar, Eliminar y Mover.',
      'tutorialDontShowAgain': 'No mostrar automáticamente de nuevo',
      'tutorialBack': 'Atrás',
      'tutorialSkip': 'Omitir',
      'tutorialNext': 'Siguiente',
      'tutorialStart': 'Empezar',
      'login': 'Iniciar sesión',
      'register': 'Registrarse',
      'logout': 'Cerrar sesión',
      'profile': 'Perfil',
      'account': 'Cuenta',
      'loginOrRegister': 'Iniciar sesión / Registrarse',
      'username': 'Nombre de usuario',
      'email': 'Correo electrónico',
      'password': 'Contraseña',
      'confirmPassword': 'Confirmar contraseña',
      'serverUrl': 'Dirección del servidor (Backend URL)',
      'serverSettings': 'Ajustes del servidor',
      'loggedInAs': 'Conectado como',
      'passwordsDoNotMatch': 'Las contraseñas no coinciden',
      'passwordTooShort': 'La contraseña debe tener al menos 6 caracteres',
      'usernameRequired': 'Se requiere nombre de usuario',
      'emailRequired': 'Ingrese un correo electrónico válido',
      'loginSuccess': '¡Inicio de sesión exitoso!',
      'registerSuccess': '¡Registro exitoso!',
      'loggedOut': 'Sesión cerrada',
      'alreadyHaveAccount': '¿Ya tienes una cuenta? Iniciar sesión',
      'dontHaveAccount': '¿No tienes una cuenta? Registrarse',
    },
  };

  String get(String key) {
    return _localizedValues[languageCode]?[key] ??
        _localizedValues['tr']?[key] ??
        key;
  }

  String categoryName(String cat) {
    final lower = cat.toLowerCase();
    if (lower == 'default') return get('categoryDefault');
    if (lower == 'starters') return get('categoryStarters');
    return cat;
  }

  String get settings => get('settings');
  String get language => get('language');
  String get selectLanguage => get('selectLanguage');
  String get soundEffects => get('soundEffects');
  String get soundOn => get('soundOn');
  String get soundOff => get('soundOff');
  String get newChart => get('newChart');
  String get openChart => get('openChart');
  String get saveChart => get('saveChart');
  String get savedDesigns => get('savedDesigns');
  String get dataView => get('dataView');
  String get exportPng => get('exportPng');
  String get help => get('help');
  String get undo => get('undo');
  String get redo => get('redo');
  String get menu => get('menu');
  String get stitchPalette => get('stitchPalette');
  String get properties => get('properties');
  String get shape => get('shape');
  String get stitch => get('stitch');
  String get select => get('select');
  String get replace => get('replace');
  String get delete => get('delete');
  String get move => get('move');
  String get pan => get('pan');
  String get selected => get('selected');
  String get close => get('close');
  String get cancel => get('cancel');
  String get save => get('save');
  String get addRound => get('addRound');
  String get round => get('round');
  String get circle => get('circle');
  String get square => get('square');
  String get hexagon => get('hexagon');
  String get triangle => get('triangle');
  String get pentagon => get('pentagon');
  String get octagon => get('octagon');
  String get oval => get('oval');
  String get stitches => get('stitches');
  String get searchStitches => get('searchStitches');
  String get clearSearch => get('clearSearch');
  String get noStitchesFound => get('noStitchesFound');
  String get all => get('all');
  String get categoryDefault => get('categoryDefault');
  String get categoryStarters => get('categoryStarters');
  String get hintSelectStarter => get('hintSelectStarter');
  String get hintTapCenter => get('hintTapCenter');
  String get selectedStitchesCount => get('selectedStitchesCount');
  String get roundStitchesCount => get('roundStitchesCount');
  String get replaceFromPalette => get('replaceFromPalette');
  String get clearSelection => get('clearSelection');
  String get selectionModeHint => get('selectionModeHint');
  String get selectionMultiHint => get('selectionMultiHint');
  String get selectAll => get('selectAll');
  String get bulkReplace => get('bulkReplace');
  String bulkReplaceWithCount(int count) {
    if (languageCode == 'tr') return 'Toplu Değiştir ($count adet)';
    return '${get('bulkReplace')} ($count)';
  }
  String get roundDeleted => get('roundDeleted');
  String get replaceStep1 => get('replaceStep1');
  String get replaceStep2Selected => get('replaceStep2Selected');
  String get replaceStep2Choose => get('replaceStep2Choose');
  String get addRoundTooltip => get('addRoundTooltip');
  String get deleteLastRound => get('deleteLastRound');
  String get expandRound => get('expandRound');
  String get contractRound => get('contractRound');
  String get expandAllRounds => get('expandAllRounds');
  String get contractAllRounds => get('contractAllRounds');
  String get resetRoundSize => get('resetRoundSize');
  String get chartNameLabel => get('chartNameLabel');
  String get size => get('size');
  String get styleLabel => get('styleLabel');
  String get visual => get('visual');
  String get textual => get('textual');
  String get roundCount => get('roundCount');
  String get rounds => get('rounds');
  String get zoom => get('zoom');
  String get roundExpansion => get('roundExpansion');
  String get noRoundsYet => get('noRoundsYet');
  String get deleteRound => get('deleteRound');
  String get untitled => get('untitled');
  String get roundShape => get('roundShape');
  String get cornerRounding => get('cornerRounding');
  String get circleCornerHint => get('circleCornerHint');
  String get nSided => get('nSided');

  String polygonCornerHint(int sides, bool isSharp) {
    final template = get(isSharp ? 'polygonCornerHintSharp' : 'polygonCornerHintRounded');
    return template.replaceAll('{sides}', '$sides');
  }

  // Tutorial
  String get tutorialWelcomeTitle => get('tutorialWelcomeTitle');
  String get tutorialWelcomeDesc => get('tutorialWelcomeDesc');
  String get tutorialWelcomeH1 => get('tutorialWelcomeH1');
  String get tutorialWelcomeH2 => get('tutorialWelcomeH2');
  String get tutorialWelcomeH3 => get('tutorialWelcomeH3');
  String get tutorialStep2Title => get('tutorialStep2Title');
  String get tutorialStep2Desc => get('tutorialStep2Desc');
  String get tutorialStep2H1 => get('tutorialStep2H1');
  String get tutorialStep2H2 => get('tutorialStep2H2');
  String get tutorialStep2H3 => get('tutorialStep2H3');
  String get tutorialStep3Title => get('tutorialStep3Title');
  String get tutorialStep3Desc => get('tutorialStep3Desc');
  String get tutorialStep3H1 => get('tutorialStep3H1');
  String get tutorialStep3H2 => get('tutorialStep3H2');
  String get tutorialStep3H3 => get('tutorialStep3H3');
  String get tutorialStep4Title => get('tutorialStep4Title');
  String get tutorialStep4Desc => get('tutorialStep4Desc');
  String get tutorialStep4H1 => get('tutorialStep4H1');
  String get tutorialStep4H2 => get('tutorialStep4H2');
  String get tutorialStep4H3 => get('tutorialStep4H3');
  String get tutorialDontShowAgain => get('tutorialDontShowAgain');
  String get tutorialBack => get('tutorialBack');
  String get tutorialSkip => get('tutorialSkip');
  String get tutorialNext => get('tutorialNext');
  String get tutorialStart => get('tutorialStart');

  // Auth & Account
  String get login => get('login');
  String get register => get('register');
  String get logout => get('logout');
  String get profile => get('profile');
  String get account => get('account');
  String get loginOrRegister => get('loginOrRegister');
  String get username => get('username');
  String get email => get('email');
  String get password => get('password');
  String get confirmPassword => get('confirmPassword');
  String get serverUrl => get('serverUrl');
  String get serverSettings => get('serverSettings');
  String get loggedInAs => get('loggedInAs');
  String get passwordsDoNotMatch => get('passwordsDoNotMatch');
  String get passwordTooShort => get('passwordTooShort');
  String get usernameRequired => get('usernameRequired');
  String get emailRequired => get('emailRequired');
  String get loginSuccess => get('loginSuccess');
  String get registerSuccess => get('registerSuccess');
  String get loggedOut => get('loggedOut');
  String get alreadyHaveAccount => get('alreadyHaveAccount');
  String get dontHaveAccount => get('dontHaveAccount');

  static AppStrings of(String lang) => AppStrings(lang);
}
