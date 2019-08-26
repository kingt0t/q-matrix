// Copyright (C) 2019  wilko
//
// This file is part of Pattle.
//
// Pattle is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Pattle is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with Pattle.  If not, see <https://www.gnu.org/licenses/>.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:matrix_sdk/matrix_sdk.dart';
import 'package:pattle/src/sentry.dart';
import 'package:respect_24_hour/respect_24_hour.dart';
import 'package:rxdart/rxdart.dart';
import 'package:pattle/src/di.dart' as di;

import 'storage.dart';

class AppBloc {
  Sentry sentry;
  final Storage storage;
  final String _mayReportCrashesStorageKey = 'may_report_crashes';

  static AppBloc _instance;

  AppBloc._({@required this.storage});

  factory AppBloc() => _instance;

  static Future<AppBloc> create() async {
    await DotEnv().load();

    final use24Hour = await Respect24Hour.get24HourFormat;
    di.registerUse24HourFormat(use24Hour);

    _instance = AppBloc._(
      storage: await Storage.open(),
    );

    return _instance;
  }

  final _loggedInSubj = BehaviorSubject<bool>();
  Observable<bool> get loggedIn => _loggedInSubj.stream;

  Future<void> checkIfLoggedIn() async {
    di.registerStore();
    final localUser = await LocalUser.fromStore(di.getStore());

    if (localUser != null) {
      di.registerLocalUser(localUser);
    } else {
      // Delete db if user could not be retrieved from store
      await di.getStore().delete();
      di.registerStore();
    }

    final loggedIn = localUser != null;
    _loggedInSubj.add(loggedIn);

    if (loggedIn && await getMayReportCrashes()) {
      sentry = await Sentry.create();
    }
  }

  Future<void> notifyLogin() async {
    if (await getMayReportCrashes() && sentry == null) {
      sentry = await Sentry.create();
    }
  }

  void wrap(Function run) => runZoned<Future<void>>(
        () async => run(),
        onError: (error, stackTrace) => sentry?.reportError(error, stackTrace),
      );

  String get build => DotEnv().env['BUILD_TYPE'];

  bool _mayReportCrashes;
  FutureOr<bool> getMayReportCrashes({bool lookInStorage = true}) {
    if (_mayReportCrashes == null && !lookInStorage) {
      setMayReportCrashes(build != 'fdroid');
      return _mayReportCrashes;
    } else if (_mayReportCrashes != null) {
      return _mayReportCrashes;
    } else {
      return storage[_mayReportCrashesStorageKey]
          .then((v) => v as bool)
          .then((v) => _mayReportCrashes = v);
    }
  }

  void setMayReportCrashes(value) {
    _mayReportCrashes = value;
    storage[_mayReportCrashesStorageKey] = value;
  }
}
