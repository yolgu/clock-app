import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/i18n/public.dart' show AppLocalizations;
import '../../../shared/ui/public.dart' show ClockRhythmLayout;
import '../domain/todo.dart';
import 'todo_inline_edit_session.dart';

final class TodoInlineTitle extends StatefulWidget {
  const TodoInlineTitle({
    required this.todo,
    required this.session,
    required this.enabled,
    required this.style,
    super.key,
  });

  final TodoSnapshot todo;
  final TodoInlineEditSession session;
  final bool enabled;
  final TextStyle? style;

  @override
  State<TodoInlineTitle> createState() => _TodoInlineTitleState();
}

final class _TodoInlineTitleState extends State<TodoInlineTitle> {
  final FocusNode _activationFocus = FocusNode(debugLabel: 'Todo title action');

  @override
  void dispose() {
    _activationFocus.dispose();
    super.dispose();
  }

  Future<void> _begin() async {
    if (await widget.session.begin(widget.todo, AppLocalizations.of(context)) &&
        mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            TickerMode.valuesOf(context).enabled &&
            widget.session.todoId == widget.todo.id) {
          widget.session.focusNode.requestFocus();
        }
      });
    }
  }

  Future<void> _commit({required bool restoreTitleFocus}) async {
    if (widget.session.todoId != widget.todo.id) {
      return;
    }
    final bool succeeded = await widget.session.commit(
      AppLocalizations.of(context),
    );
    if (!mounted || !TickerMode.valuesOf(context).enabled) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !TickerMode.valuesOf(context).enabled) {
        return;
      }
      if (!succeeded) {
        widget.session.focusNode.requestFocus();
      } else if (restoreTitleFocus) {
        _activationFocus.requestFocus();
      }
    });
  }

  void _cancel() {
    if (widget.session.isSaving) {
      return;
    }
    widget.session.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && TickerMode.valuesOf(context).enabled) {
        _activationFocus.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final TodoInlineEditSession session = widget.session;
    if (session.todoId != widget.todo.id) {
      return Semantics(
        hint: AppLocalizations.of(context).todoInlineEditHint,
        child: InkWell(
          focusNode: _activationFocus,
          onTap: widget.enabled ? () => unawaited(_begin()) : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: ClockRhythmLayout.minimumInteractiveDimension,
              minHeight: ClockRhythmLayout.minimumInteractiveDimension,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 1,
              heightFactor: 1,
              child: Text(
                widget.todo.title,
                key: ValueKey<String>('todo-title-${widget.todo.id}'),
                style: widget.style,
              ),
            ),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final TextPainter painter = TextPainter(
          text: TextSpan(text: session.originalTitle, style: widget.style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          locale: Localizations.localeOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final double height = math.max(
          ClockRhythmLayout.minimumInteractiveDimension,
          painter.height,
        );
        painter.dispose();
        return SizedBox(
          height: height,
          child: Focus(
            onFocusChange: (bool focused) {
              if (!focused &&
                  !session.isSaving &&
                  session.todoId == widget.todo.id) {
                unawaited(_commit(restoreTitleFocus: false));
              }
            },
            onKeyEvent: (FocusNode node, KeyEvent event) {
              if (event is! KeyDownEvent || session.isComposing) {
                return KeyEventResult.ignored;
              }
              if (event.logicalKey == LogicalKeyboardKey.escape) {
                _cancel();
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.numpadEnter) {
                unawaited(_commit(restoreTitleFocus: true));
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: TextField(
              key: ValueKey<String>('todo-inline-title-${widget.todo.id}'),
              controller: session.title,
              focusNode: session.focusNode,
              readOnly: session.isSaving,
              style: widget.style?.copyWith(decoration: TextDecoration.none),
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.center,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                isCollapsed: true,
                filled: false,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onEditingComplete: () {},
              onSubmitted: (_) => unawaited(_commit(restoreTitleFocus: true)),
              onTapOutside: (_) => unawaited(_commit(restoreTitleFocus: false)),
            ),
          ),
        );
      },
    );
  }
}
