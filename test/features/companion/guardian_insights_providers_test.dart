import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_companion/features/companion/guardian_insights_providers.dart';

void main() {
  test('guardian insights starts with assistant guidance message', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(guardianInsightsControllerProvider);

    expect(state.messages, isNotEmpty);
    expect(state.messages.first.fromGuardian, isFalse);
    expect(
      state.messages.first.text,
      contains('alerts, status, medication'),
    );
  });

  test('guardian insights falls back to local guidance when context fails',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier =
        container.read(guardianInsightsControllerProvider.notifier);
    await notifier.ask('What changed today?');

    final state = container.read(guardianInsightsControllerProvider);
    expect(state.messages.where((message) => message.fromGuardian).length, 1);
    expect(state.messages.last.fromGuardian, isFalse);
    expect(state.messages.last.text, contains('Local guidance'));
    expect(state.errorMessage, isNotNull);
  });
}
