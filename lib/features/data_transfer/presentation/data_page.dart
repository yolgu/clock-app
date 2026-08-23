import 'package:flutter/material.dart';

import 'data_management_panel.dart';

final class DataPage extends StatelessWidget {
  const DataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey<String>('data-page-scroll'),
      restorationId: 'data_page_scroll',
      padding: const EdgeInsets.all(16),
      children: const <Widget>[DataManagementPanel()],
    );
  }
}
