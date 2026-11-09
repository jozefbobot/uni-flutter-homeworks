import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/earthquake_model.dart';
import '../providers/app_data_provider.dart';
import '../settings_page.dart';
import '../utils/helper_functions.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _showSortDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        final provider = context.watch<AppDataProvider>();
        return AlertDialog(
          title: const Text('Sort by'),
          scrollable: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          content: RadioGroup<EarthquakeOrder>(
            groupValue: provider.order,
            onChanged: (order) {
              if (order != null) provider.setOrder(order);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final order in EarthquakeOrder.values)
                  RadioListTile(value: order, title: Text(order.label)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    final earthquakes = provider.earthquakes;
    final error = provider.errorMessage;

    final status = switch ((provider.isLoading, error, earthquakes.isEmpty)) {
      (true, _, _) => const CircularProgressIndicator(
        semanticsLabel: 'Loading earthquakes',
      ),
      (false, final String error, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: provider.refresh,
            child: const Text('Retry'),
          ),
        ],
      ),
      (false, null, true) => const Text(
        'No earthquakes match these filters.',
        textAlign: TextAlign.center,
      ),
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earthquake App'),
        actions: [
          IconButton(
            tooltip: 'Sort',
            onPressed: () => _showSortDialog(context),
            icon: const Icon(Icons.sort),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: RefreshIndicator(
              onRefresh: provider.refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _CatalogSummary(provider: provider),
                  ),
                  if (status != null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: status,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      sliver: SliverList.separated(
                        itemCount: earthquakes.length,
                        itemBuilder: (context, index) =>
                            _EarthquakeTile(earthquake: earthquakes[index]),
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogSummary extends StatelessWidget {
  const _CatalogSummary({required this.provider});

  final AppDataProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final count = provider.earthquakes.length;
    final minimum = provider.minimumMagnitude;
    return Card.filled(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'USGS Earthquake Catalog',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              provider.usesLocation ? 'Within 300 km' : 'Worldwide',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              '${formatDate(provider.startDate)} – ${formatDate(provider.endDate)}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                Text(
                  minimum == 0
                      ? 'Any magnitude'
                      : 'M ${minimum.toStringAsFixed(1)}+',
                ),
                Text(provider.order.label),
                if (!provider.isLoading && provider.errorMessage == null)
                  Text('$count ${count == 1 ? 'event' : 'events'}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EarthquakeTile extends StatelessWidget {
  const _EarthquakeTile({required this.earthquake});

  final Earthquake earthquake;

  @override
  Widget build(BuildContext context) {
    final alertColor = switch (earthquake.alert) {
      'green' => Colors.greenAccent,
      'yellow' => Colors.yellow,
      'orange' => Colors.orange,
      'red' => Colors.redAccent,
      _ => null,
    };
    final time = earthquake.time;
    final magnitude = earthquake.magnitude?.toStringAsFixed(1);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      title: Text(earthquake.place ?? earthquake.title ?? 'Unknown location'),
      subtitle: Text(time == null ? 'Time unavailable' : formatEventTime(time)),
      trailing: Chip(
        avatar: alertColor == null
            ? null
            : Tooltip(
                message: 'USGS alert: ${earthquake.alert}',
                child: Icon(Icons.circle, color: alertColor, size: 12),
              ),
        label: Text(
          magnitude == null ? 'M —' : 'M $magnitude',
          semanticsLabel: magnitude == null
              ? 'Magnitude unavailable'
              : 'Magnitude $magnitude',
        ),
      ),
    );
  }
}
