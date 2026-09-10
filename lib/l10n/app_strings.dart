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
      'oval': 'Oval',
    },
    'en': {
      'settings': 'Settings',
      'language': 'Language',
      'selectLanguage': 'Select Language',
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
      'oval': 'Oval',
    },
    'de': {
      'settings': 'Einstellungen',
      'language': 'Sprache',
      'selectLanguage': 'Sprache wählen',
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
      'oval': 'Oval',
    },
    'es': {
      'settings': 'Configuración',
      'language': 'Idioma',
      'selectLanguage': 'Seleccionar idioma',
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
      'oval': 'Óvalo',
    },
  };

  String get(String key) {
    return _localizedValues[languageCode]?[key] ??
        _localizedValues['tr']?[key] ??
        key;
  }

  String get settings => get('settings');
  String get language => get('language');
  String get selectLanguage => get('selectLanguage');
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
  String get oval => get('oval');

  static AppStrings of(String lang) => AppStrings(lang);
}
