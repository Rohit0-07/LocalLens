import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/shared/widgets/shimmer_loading.dart';
import 'package:local_lens/shared/widgets/skeleton_list.dart';

void main() {
  testWidgets('ShimmerLoading renders child correctly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ShimmerLoading(
            child: Text('Shimmering content'),
          ),
        ),
      ),
    );

    expect(find.text('Shimmering content'), findsOneWidget);
  });

  testWidgets('SkeletonList renders with ShimmerLoading wrapper', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SkeletonList(itemCount: 3),
        ),
      ),
    );

    expect(find.byType(ShimmerLoading), findsOneWidget);
    expect(find.byType(Card), findsNWidgets(3));
  });
}
