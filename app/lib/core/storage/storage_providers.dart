import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/local_store.dart';

final localStoreProvider = Provider<LocalStore>((ref) => LocalStore.instance);
