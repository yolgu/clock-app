import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data_transfer_actions.dart';
import 'data_transfer_state.dart';
import 'data_transfer_view_model.dart';

final Provider<DataTransferActions> dataTransferActionsProvider =
    Provider<DataTransferActions>((Ref ref) {
      throw StateError('DataTransferActions must be provided by composition.');
    });

final NotifierProvider<DataTransferViewModel, DataTransferState>
dataTransferViewModelProvider =
    NotifierProvider<DataTransferViewModel, DataTransferState>(
      DataTransferViewModel.new,
    );
