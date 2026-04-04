import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'src/app/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await bootstrap();
}
