import 'dart:html';
import 'dart:async';

main() {
  var indent = '';
  // Generates a unique onRunSync handler.
  genRunAsync(id) {
    return (fn) {
      print('${indent}RUN-ASYNC: $id');
      indent += '    ';
      fn();
      indent = indent.replaceFirst('    ', '');
      print('${indent}DONE RUN-ASYNC: $id');
    };
  }

  // Generates a unique, interesting future then.
  genPrintLen(id) {
    return (data) {
      print('${indent}LEN $id ${data.length}');
      return data;
    };
  }

  // WE WANT TO WRITE THIS CODE
  // Our function gets a future from some third-party code. In this
  // case, HttpRequest.  We have no idea which zone the future was
  // created in; we shouldn't care.

  // Even though we are wrapping the future.then calls in a runZoned
  // call, the then callbacks are still executed in the zone where
  // the HttpRequest future was created.
  // -> Our onRunAsync handlers are never called.

  var future = HttpRequest.getString("http://bing.com");

  runZonedExperimental(() {
    var doublePlum = future.then(genPrintLen('single'));

    runZonedExperimental(() {
      doublePlum.then(genPrintLen('double'));
    }, onRunAsync: genRunAsync('double'));
  }, onRunAsync: genRunAsync('single'));


  // WE COULD WORK AROUND THIS LIMITATION BY WRAPPING FUTURES
  // but we need to also wrap:
  // - timers
  // - streams
  // - DOM callbacks
  // This wrapping would need to be done in application code (i.e. not Angular)
  // Therefore, application authors would need to grok zones and be aware
  // of zone boundaries.

  zoneFuture(future) {
    var c = new Completer();
    future.then((data) => c.complete(data));
    return c.future;
  }


  runZonedExperimental(() {
    var cnnFuture = HttpRequest.getString("http://cnn.com");
    var doublePlum = zoneFuture(cnnFuture).then(genPrintLen('Wrapped-single'));

    runZonedExperimental(() {
      zoneFuture(doublePlum).then(genPrintLen('Wrapped-double'));
    }, onRunAsync: genRunAsync('Wrapped-double'));
  }, onRunAsync: genRunAsync('Wrapped-single'));


  // ARE STREAMS JUST BUGGY?
  // Without the 'completerA' hack here, the 's' onRunAsync is not called.
  // This implies the location of the completer.complete() call is important,
  // as well as the 'new Completer()' call.

  Future<HttpRequest> request(String url) {
    var completerA = new Completer<HttpRequest>();
    var completer = new Completer<HttpRequest>();

    var xhr = new HttpRequest();
    xhr.open('GET', url, async: true);
    xhr.onLoad.listen((e) {
        completer.complete(xhr);
    });
    xhr.send();

    completer.future.then((x) => completerA.complete(x));

    return completerA.future;
  }

  runZonedExperimental(() {
    var doublePlum = request('http://wh.gov').then((r) => r.responseText).then(genPrintLen('s'));
  }, onRunAsync: genRunAsync('s'));


  // ANOTHER SOLUTION: ONDONE
  // on-done appears to work as expected.  Any 'then' clauses are executed before the onDone.
  // This works if the future is created inside or outside the runZoned call.

  runZonedExperimental(() {
    var bbcFuture = HttpRequest.getString('http://bbc.co.uk').then(genPrintLen('bbc'));
  }, onDone: () => print('bbc ondone'));

  var itvFuture = HttpRequest.getString('http://itv.com');
  runZonedExperimental(() {
    itvFuture = itvFuture.then(genPrintLen('itv'));
  }, onDone: () => print('itv ondone'));
  itvFuture.then((_) => print('a then outside of runZoned is run before itv-ondone'));

  print('--- sync done ---');
}
