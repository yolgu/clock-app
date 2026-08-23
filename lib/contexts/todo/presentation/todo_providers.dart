import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'todo_view_model.dart';

final AsyncNotifierProvider<TodoViewModel, TodoViewState>
todoViewModelProvider = AsyncNotifierProvider<TodoViewModel, TodoViewState>(
  TodoViewModel.new,
  name: 'todoViewModelProvider',
);
