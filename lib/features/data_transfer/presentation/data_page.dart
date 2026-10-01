import 'package:flutter/material.dart';

import '../../../shared/i18n/public.dart';
import '../../../shared/ui/public.dart'
    show ClockRhythmLayout, ClockRhythmPageHeader;
import 'data_management_panel.dart';

final class DataPage extends StatelessWidget {
  const DataPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations copy = AppLocalizations.of(context);
    return ListView(
      key: const PageStorageKey<String>('data-page-scroll'),
      restorationId: 'data_page_scroll',
      padding: ClockRhythmLayout.pageInsetsFor(
        MediaQuery.sizeOf(context).width,
      ),
      children: <Widget>[
        ClockRhythmPageHeader(
          title: copy.navigationData,
          description: copy.dataPageDescription,
        ),
        const DataManagementPanel(),
      ],
    );
  }
}
