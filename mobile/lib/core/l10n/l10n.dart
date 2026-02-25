import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

extension L10nBuildContextX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
