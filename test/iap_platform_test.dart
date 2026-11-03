import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperflick/services/iap_service.dart';

void main() {
  test('iOS maps to the single Gold Star product', () {
    expect(StoreService.productIdsFor(TargetPlatform.iOS), {'paperflickstar'});
    expect(StoreService.starId, 'paperflickstar');
  });
  test('Android maps to coffee + chocolate only', () {
    expect(StoreService.productIdsFor(TargetPlatform.android),
        {'paperflickcoffee', 'paperflickchocolate'});
    expect(StoreService.productIdsFor(TargetPlatform.android),
        isNot(contains('paperflickstar')));
  });
}
