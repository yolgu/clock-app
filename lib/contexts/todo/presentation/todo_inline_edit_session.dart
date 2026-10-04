import 'package:flutter/widgets.dart';

import '../../../shared/i18n/public.dart' show AppLocalizations;
import '../domain/todo.dart';
import 'todo_title_feedback.dart';

final class TodoInlineEditSession extends ChangeNotifier {
  TodoInlineEditSession({required this.rename});

  final Future<bool> Function(String id, String title) rename;
  final TextEditingController title = TextEditingController();
  final FocusNode focusNode = FocusNode(debugLabel: 'Inline Todo title');
  TodoSnapshot? _todo;
  Future<bool>? _pending;
  String? _error;
  bool _disposed = false;

  String? get todoId => _todo?.id;
  String? get originalTitle => _todo?.title;
  String? get error => _error;
  bool get isSaving => _pending != null;
  bool get isComposing =>
      title.value.composing.isValid && !title.value.composing.isCollapsed;

  Future<bool> begin(TodoSnapshot todo, AppLocalizations copy) async {
    if (_todo?.id == todo.id) {
      return true;
    }
    if (!await commit(copy) || _disposed) {
      return false;
    }
    _todo = todo;
    _error = null;
    title.value = TextEditingValue(
      text: todo.title,
      selection: TextSelection.collapsed(offset: todo.title.length),
    );
    notifyListeners();
    return true;
  }

  Future<bool> commit(AppLocalizations copy) async {
    final Future<bool>? pending = _pending;
    if (pending != null) {
      return pending;
    }
    final TodoSnapshot? todo = _todo;
    if (todo == null) {
      return true;
    }
    if (isComposing) {
      return false;
    }
    final TodoTitleFeedback feedback = TodoTitleFeedback.evaluate(
      title.text,
      copy,
    );
    if (!feedback.isValid) {
      _error = feedback.error;
      notifyListeners();
      return false;
    }
    if (title.text.trim() == todo.title) {
      cancel();
      return true;
    }
    final Future<bool> operation = rename(todo.id, title.text);
    _pending = operation;
    _error = null;
    notifyListeners();
    final bool succeeded = await operation;
    if (_disposed) {
      return succeeded;
    }
    _pending = null;
    if (succeeded) {
      _todo = null;
    } else {
      _error = copy.failureTodoAction;
    }
    notifyListeners();
    return succeeded;
  }

  void cancel() {
    if (isSaving || _disposed) {
      return;
    }
    _todo = null;
    _error = null;
    focusNode.unfocus();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    title.dispose();
    focusNode.dispose();
    super.dispose();
  }
}
