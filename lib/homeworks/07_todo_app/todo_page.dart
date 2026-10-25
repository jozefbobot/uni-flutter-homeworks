import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'todo_provider.dart';

/// Dáta a zmeny stavu odoberáme z TodoProvider cez Consumer.
class TodoPage extends StatelessWidget {
  const TodoPage({super.key});

  void _showAddTodoSheet(BuildContext context) {
    context.read<TodoProvider>().setPriority(TodoPriority.normal);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _AddTodoSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, provider, child) {
        final canEdit =
            !provider.isLoading && !provider.isSaving && !provider.hasLoadError;
        return Scaffold(
          appBar: AppBar(title: const Text('My Todos')),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: FloatingActionButton(
            tooltip: 'Add todo',
            onPressed: canEdit ? () => _showAddTodoSheet(context) : null,
            child: const Icon(Icons.add),
          ),
          body: Column(
            children: [
              if (provider.errorMessage != null)
                MaterialBanner(
                  content: Text(provider.errorMessage!),
                  actions: [
                    if (provider.hasLoadError)
                      TextButton(
                        onPressed: provider.isLoading
                            ? null
                            : () => provider.loadTodos(),
                        child: const Text('Retry'),
                      )
                    else
                      TextButton(
                        onPressed: provider.clearError,
                        child: const Text('Dismiss'),
                      ),
                  ],
                ),
              if (provider.isSaving) const LinearProgressIndicator(),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.hasLoadError
                    ? const Center(
                        child: Text('Your todos could not be loaded.'),
                      )
                    : provider.todos.isEmpty
                    ? const Center(child: Text('Nothing to do!'))
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 96),
                        itemCount: provider.todos.length,
                        itemBuilder: (context, index) {
                          final todo = provider.todos[index];
                          return TodoItem(
                            key: ValueKey(todo.id),
                            todo: todo,
                            onChanged: canEdit
                                ? (value) {
                                    if (!provider.isSaving) {
                                      provider.toggleTodoStatus(index, value);
                                    }
                                  }
                                : null,
                            onRemove: canEdit
                                ? () {
                                    if (!provider.isSaving) {
                                      provider.removeTodo(index);
                                    }
                                  }
                                : null,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// StatefulWidget tu spravuje iba životný cyklus textového kontroléra.
/// Zoznam úloh, priorita aj ukladanie zostávajú v TodoProvider.
class _AddTodoSheet extends StatefulWidget {
  const _AddTodoSheet();

  @override
  State<_AddTodoSheet> createState() => _AddTodoSheetState();
}

class _AddTodoSheetState extends State<_AddTodoSheet> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveTodo() async {
    final provider = context.read<TodoProvider>();
    if (provider.isLoading || provider.isSaving || provider.hasLoadError) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final added = await provider.addTodo(_controller.text);
    if (mounted && added && ModalRoute.of(context)?.isCurrent == true) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Consumer<TodoProvider>(
            builder: (context, provider, child) {
              final canEdit =
                  !provider.isLoading &&
                  !provider.isSaving &&
                  !provider.hasLoadError;
              return Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Add todo',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const ValueKey('todo-name'),
                      controller: _controller,
                      autofocus: true,
                      enabled: canEdit,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'What to do?',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Input field must not be empty'
                          : null,
                      onFieldSubmitted: (_) => _saveTodo(),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 20, bottom: 4),
                      child: Text('Select Priority'),
                    ),
                    RadioGroup<TodoPriority>(
                      groupValue: provider.priority,
                      onChanged: (value) {
                        if (canEdit && value != null) {
                          provider.setPriority(value);
                        }
                      },
                      child: Column(
                        children: [
                          for (final priority in TodoPriority.values)
                            RadioListTile<TodoPriority>(
                              value: priority,
                              title: Text(priority.label),
                              activeColor: priority.color,
                              enabled: canEdit,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: canEdit ? _saveTodo : null,
                      child: Text(provider.isSaving ? 'SAVING...' : 'SAVE'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Farba aj text priority sú súčasťou prezentácie, nie uložených dát.
extension TodoPriorityPresentation on TodoPriority {
  String get label => switch (this) {
    TodoPriority.low => 'Low',
    TodoPriority.normal => 'Normal',
    TodoPriority.high => 'High',
  };

  Color get color => switch (this) {
    TodoPriority.low => Colors.green.shade700,
    TodoPriority.normal => Colors.yellow.shade600,
    TodoPriority.high => Colors.red.shade700,
  };
}

class TodoItem extends StatelessWidget {
  const TodoItem({
    super.key,
    required this.todo,
    this.onChanged,
    this.onRemove,
  });

  final MyTodo todo;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final color = todo.priority.color;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: color.withValues(alpha: 0.10),
      child: Row(
        children: [
          Expanded(
            child: CheckboxListTile(
              title: Text(
                todo.name,
                style: TextStyle(
                  decoration: todo.completed
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
              subtitle: Text(
                'Priority: ${todo.priority.label}',
                style: TextStyle(
                  color: todo.priority == TodoPriority.normal
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : color,
                ),
              ),
              value: todo.completed,
              activeColor: color,
              checkColor: todo.priority == TodoPriority.normal
                  ? Colors.black
                  : Colors.white,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: onChanged == null
                  ? null
                  : (value) => onChanged!(value ?? false),
            ),
          ),
          IconButton(
            tooltip: 'Delete todo',
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}
