import 'package:flutter_test/flutter_test.dart';
import 'package:ruhh/core/data/models/transaction_local.dart';
import 'package:ruhh/core/services/agent_inbox_applier.dart';

TransactionLocal tx({String title = 'Tea', String note = ''}) =>
    TransactionLocal()
      ..amount = 10
      ..category = 'Food'
      ..title = title
      ..note = note;

void main() {
  const expected = {
    'amount': 10,
    'category': 'Food',
    'title': 'Tea',
    'note': '',
  };

  test('unchanged transaction matches the proposal precondition', () {
    expect(RepositoryInboxApplier.expectedMatches(tx(), expected), isTrue);
  });

  test('local edit after the proposal -> conflict (no overwrite)', () {
    expect(
      RepositoryInboxApplier.expectedMatches(tx()..amount = 11, expected),
      isFalse,
    );
    expect(
      RepositoryInboxApplier.expectedMatches(tx(note: 'changed'), expected),
      isFalse,
    );
    expect(
      RepositoryInboxApplier.expectedMatches(
        tx()..category = 'Bills',
        expected,
      ),
      isFalse,
    );
  });

  test('empty local title compares as the exported title (= category)', () {
    expect(
      RepositoryInboxApplier.expectedMatches(tx(title: ''), {
        ...expected,
        'title': 'Food',
      }),
      isTrue,
    );
  });

  test('malformed expected never matches', () {
    expect(
      RepositoryInboxApplier.expectedMatches(tx(), {'amount': 'x'}),
      isFalse,
    );
  });
}
