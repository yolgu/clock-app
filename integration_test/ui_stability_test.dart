import 'package:integration_test/integration_test.dart';

import '../test/contexts/todo/presentation/todo_interaction_test.dart'
    as interactions;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  interactions.main();
}
