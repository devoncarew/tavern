// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';

main() {
  initConfig();
  integration("loads ordering dependencies in the correct order", () {
    d.dir("foo", [
      d.libPubspec("foo", '1.0.0'),
      d.dir("lib", [
        d.file("transformer.dart", dartTransformer('foo'))
      ])
    ]).create();

    d.dir("bar", [
      d.pubspec({
        "name": "bar",
        "version": "1.0.0",
        "transformers": ["foo/transformer"],
        "dependencies": {"foo": {"path": "../foo"}}
      }),
      d.dir("lib", [
        d.file("bar.dart", 'const TOKEN = "bar";')
      ])
    ]).create();

    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "transformers": ["myapp/transformer"],
        "dependencies": {"bar": {"path": "../bar"}}
      }),
      d.dir("lib", [
        d.file("transformer.dart", dartTransformer('myapp', import: 'bar'))
      ]),
      d.dir("web", [
        d.file("main.dart", 'const TOKEN = "main.dart";')
      ])
    ]).create();

    createLockFile('myapp', sandbox: ['foo', 'bar'], pkg: ['barback']);

    pubServe();
    requestShouldSucceed("main.dart",
        'const TOKEN = "(main.dart, myapp imports (bar, foo))";');
    endPubServe();
  });
}
