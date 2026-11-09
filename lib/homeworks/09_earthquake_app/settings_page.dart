import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_data_provider.dart';
import 'utils/helper_functions.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _selectDate(
    BuildContext context, {
    required bool isStart,
  }) async {
    final draft = context.read<_DateDraft>();
    final date = await showDatePicker(
      context: context,
      helpText: isStart ? 'Select start date' : 'Select end date',
      initialDate: isStart ? draft.start : draft.end,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (date != null && context.mounted) {
      draft.select(date, isStart: isStart);
    }
  }

  Future<void> _setUseLocation(BuildContext context, bool value) async {
    final error = await context.read<AppDataProvider>().setUseLocation(value);
    if (context.mounted && error != null) showMessage(context, error);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final provider = context.read<AppDataProvider>();
        return _DateDraft(provider.startDate, provider.endDate);
      },
      builder: (context, child) {
        final provider = context.watch<AppDataProvider>();
        final draft = context.watch<_DateDraft>();
        final theme = Theme.of(context);
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    Text('Time Settings', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    const Text('Choose the first and last day to include.'),
                    const SizedBox(height: 12),
                    Card.filled(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          ListTile(
                            title: const Text('Start date'),
                            subtitle: Text(formatDate(draft.start)),
                            trailing: const Icon(Icons.calendar_month_outlined),
                            onTap: () => _selectDate(context, isStart: true),
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          ListTile(
                            title: const Text('End date'),
                            subtitle: Text(formatDate(draft.end)),
                            trailing: const Icon(Icons.calendar_month_outlined),
                            onTap: () => _selectDate(context, isStart: false),
                          ),
                        ],
                      ),
                    ),
                    if (!draft.isValid)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'End date must be on or after the start date.',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: draft.isValid
                          ? () {
                              provider.applyDateRange(
                                DateTimeRange(
                                  start: draft.start,
                                  end: draft.end,
                                ),
                              );
                              showMessage(context, 'Times are updated');
                            }
                          : null,
                      icon: const Icon(Icons.check),
                      label: const Text('Update Time Changes'),
                    ),
                    const SizedBox(height: 24),
                    Text('Filters', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    const Text('Changes to these filters apply immediately.'),
                    const SizedBox(height: 12),
                    Card.filled(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          ListTile(
                            title: const Text('Minimum magnitude'),
                            trailing: DropdownButtonHideUnderline(
                              child: DropdownButton<double>(
                                value: provider.minimumMagnitude,
                                items: [
                                  for (final value in [
                                    0.0,
                                    2.5,
                                    4.0,
                                    5.0,
                                    6.0,
                                    7.0,
                                  ])
                                    DropdownMenuItem(
                                      value: value,
                                      child: Text(
                                        value == 0
                                            ? 'Any'
                                            : value.toStringAsFixed(1),
                                      ),
                                    ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    provider.setMinimumMagnitude(value);
                                  }
                                },
                              ),
                            ),
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          SwitchListTile(
                            title: const Text('Use my location'),
                            subtitle: Text(
                              provider.isLocating
                                  ? 'Finding your location…'
                                  : 'Limit results to a 300 km radius',
                            ),
                            value: provider.usesLocation,
                            onChanged: provider.isLocating
                                ? null
                                : (value) => _setUseLocation(context, value),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DateDraft extends ChangeNotifier {
  _DateDraft(this._start, this._end);

  DateTime _start;
  DateTime _end;

  DateTime get start => _start;
  DateTime get end => _end;
  bool get isValid => !_start.isAfter(_end);

  void select(DateTime date, {required bool isStart}) {
    if (isStart) {
      _start = date;
    } else {
      _end = date;
    }
    notifyListeners();
  }
}
