/// English string table. Centralized so widgets never hard-code copy and so
/// future i18n only needs new locale files alongside this one.
class S {
  const S._();

  // Brand
  static const String appName = 'DocScan Pro';
  static const String appTagline = 'Scan. Save. Share.';

  // Bottom nav
  static const String navHome = 'Home';
  static const String navCamera = 'Camera';
  static const String navSettings = 'Settings';
  // Legacy aliases — kept so older screens compile during the redesign.
  static const String navLibrary = navHome;
  static const String navScanner = navCamera;
  static const String libraryEmpty = emptyDocuments;

  // Onboarding
  static const String skip = 'Skip';
  static const String next = 'Next';
  static const String getStarted = 'Get Started';
  static const String onboardScanTitle = 'Scan Documents';
  static const String onboardScanBody =
      'Use your camera to scan receipts, notes, ID cards, and any document instantly';
  static const String onboardSaveTitle = 'Save as PDF or JPG';
  static const String onboardSaveBody =
      'Export your scanned documents as high-quality PDF or JPEG files';
  static const String onboardShareTitle = 'Share Anywhere';
  static const String onboardShareBody =
      'Easily share your scanned documents via email, messaging apps, or cloud storage';

  // My Documents
  static const String myDocuments = 'My Documents';
  static const String searchDocumentsHint = 'Search documents…';
  static const String adsActiveTitle = 'Ads Active';
  static const String adsActiveBody =
      ' - Upgrade to Premium to remove ads and unlock unlimited scans!';
  static const String emptyDocuments = 'No documents yet — scan your first page.';

  // Scanning
  static const String scanDocument = 'Scan Document';
  static const String autoDetect = 'Auto Detect';
  static const String autoScan = 'Auto Scan';
  static const String flash = 'Flash';
  static const String flip = 'Flip';
  static const String cameraPreviewMissing = 'Camera preview will appear here';
  // HUD legacy keys still consumed by the old scanner widget; replaced in R5.
  static const String hudLooking = 'Looking for document…';
  static const String hudHoldSteady = 'Hold steady';
  static const String hudMoveCloser = 'Move closer';
  static const String hudCapture = 'Capture';
  static const String hudAutoCaptureOn = 'Auto-capture: on';
  static const String hudAutoCaptureOff = 'Auto-capture: off';

  // Permissions
  static const String permCameraTitle = 'Camera permission needed';
  static const String permCameraBody =
      'DocScan Pro uses the camera to detect document edges in real time.';
  static const String permGrant = 'Grant permission';
  static const String permOpenSettings = 'Open settings';

  // Editor
  static const String editorRetake = 'Retake';
  static const String editorContinue = 'Continue';
  static const String editorAdjustCorners = 'Adjust corners';
  static const String editorStraighten = 'Straighten';
  static const String editorRotateLeft = 'Rotate left';
  static const String editorRotateRight = 'Rotate right';
  static const String editorReset = 'Reset';
  static const String filterOriginal = 'Original';
  static const String filterAuto = 'Auto-Enhance';
  static const String filterGray = 'Grayscale';
  static const String filterBw = 'B&W';
  static const String filterMagic = 'Magic Color';

  // Multi-page
  static const String addAnotherPage = 'Add another page';
  static const String done = 'Done';

  // Document actions
  static const String rename = 'Rename';
  static const String delete = 'Delete';
  static const String share = 'Share';
  static const String reExport = 'Re-export';
  static const String runOcr = 'Run OCR';
  static const String exportJpg = 'Export JPGs';
  static const String exportPdf = 'Export PDF';
  static const String exportTxt = 'Export text';

  // Settings — sections
  static const String settingsTitle = 'Settings';
  static const String sectionGeneral = 'General';
  static const String sectionPrivacy = 'Privacy & Security';
  static const String sectionSupport = 'Support';

  // Settings — items
  static const String settingsNotifications = 'Notifications';
  static const String settingsTheme = 'Theme';
  static const String settingsDefaultSave = 'Default Save Format';
  static const String settingsOcrScript = 'OCR Language';
  static const String settingsPrivacyPolicy = 'Privacy Policy';
  static const String settingsTerms = 'Terms of Service';
  static const String settingsHelp = 'Help Center';
  static const String settingsRate = 'Rate App';
  static const String settingsRestore = 'Restore purchases';
  static const String settingsAbout = 'About';

  // Premium upsell
  static const String premium = 'Premium';
  static const String premiumSubhead =
      r'$4.99 lifetime — one payment unlocks all features.';
  static const String premiumPriceTag = r'$4.99 · LIFETIME · ALL FEATURES';
  static const String premiumNoAds = 'No Ads';
  static const String premiumUnlimitedScans = 'Unlimited Scans';
  static const String premiumCloudBackup = 'Cloud Backup';
  static const String premiumAdvancedFilters = 'Advanced Filters';
  static const String premiumPrioritySupport = 'Priority Support';
  static const String premiumSubscribeCta = r'Get lifetime — $4.99';
  static const String premiumActive = 'Active';

  // Legacy paywall keys still consumed by `paywall_page.dart`; the new
  // entry point is the Premium card in Settings.
  static const String removeAds = 'Premium';
  static const String paywallHeadline = 'Unlock the full app';
  static const String paywallSubhead =
      'Lifetime access. One payment, all features.';
  static const String paywallSubscribeCta = r'Get lifetime — $4.99';
  static const String paywallRestoreCta = 'Restore purchases';
}
