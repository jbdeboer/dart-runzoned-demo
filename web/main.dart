import 'dart:html' as dom;
import 'dart:math' as math;
import 'dart:async';

import 'package:angular/angular.dart';

// THIS code prints:
// running
// yahoo: 357457
// done

main() {
  runZonedExperimental(() {
    Completer c = new Completer();
    var future = c.future;
    var httpFuture = dom.HttpRequest.getString("http://yahoo.com");

    httpFuture.then((data) => c.complete(data));

    future.then((data) { print("yahoo: ${data.length}");});
  }, onRunAsync: (fn) {
    print("running");
    fn();
    print("done");
  });
}
