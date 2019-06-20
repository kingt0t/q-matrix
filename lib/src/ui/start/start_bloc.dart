// Copyright (C) 2019  Wilko Manger
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

import 'package:matrix_sdk/matrix_sdk.dart';
import 'package:meta/meta.dart';
import 'package:pattle/src/di.dart' as di;
import 'package:rxdart/rxdart.dart';

final bloc = StartBloc();

typedef Request = void Function(Function addError);
typedef Check = bool Function(Function addError);

class StartBloc {

  StartBloc() {
    di.registerHomeserverWith(Uri.parse("https://matrix.org"));
  }

  final _homeserverChangedSubj = BehaviorSubject<bool>();
  Observable<bool> get homeserverChanged => _homeserverChangedSubj.stream;

  Homeserver get homeserver => di.getHomeserver();

  Username _username;

  /// Duration after which a progress indicator should be shown.
  static const loadingTime = const Duration(seconds: 3);

  void _setHomeserver(Uri uri) {
    di.registerHomeserverWith(uri);
    _homeserverChangedSubj.add(true);
  }

  void setHomeserverUri(String url) {
    try {
      var uri = Uri.parse(url);

      _setHomeserver(uri);
    } on FormatException {
      _homeserverChangedSubj.addError(InvalidHostnameException());
    }
  }

  final _isUsernameAvailableSubj = ReplaySubject<RequestState>(maxSize: 1);
  Observable<RequestState> get isUsernameAvailable
    => _isUsernameAvailableSubj.stream.distinct();

  static bool _defaultValidate(Function addError) => true;
  StreamSubscription stillActiveSubscription;
  Future<void> _do({
    @required Subject<RequestState> subject,
    Function validate = _defaultValidate,
    @required Request request}) async {

    await stillActiveSubscription?.cancel();
    subject.add(RequestState.active);

    // If after three seconds it's still active, change state to
    // 'stillActive'.
    Future.delayed(loadingTime).then((_) async {
      await stillActiveSubscription?.cancel();
      stillActiveSubscription = subject.stream.listen((state) {
        if (state == RequestState.active) {
          subject.add(RequestState.stillActive);
        }
      },
      );
    });

    final addError = (error) {
      stillActiveSubscription?.cancel();
      subject.add(RequestState.none);
      subject.addError(error);
    };

    final validated = validate(addError);

    if (!validated) {
      return;
    }

    request(addError);
  }


  Future<void> checkUsernameAvailability(String username) async {
    var user;

    await _do(
      subject: _isUsernameAvailableSubj,
      validate: (addError) {
        if (username == null) {
          return false;
        }

        // Check if there is a ':' in the username,
        // if so, treat it as a full Matrix ID (with or without '@').
        // Otherwise use the local part (with or without '@').
        // So, accept all of these formats:
        // @joe:matrix.org
        // joe:matrix.org
        // joe
        // @joe
        if (username.contains(':')) {
          final split = username.split(':');
          String server = split[1];

          try {
            final serverUri = Uri.parse("https://$server");
            _setHomeserver(serverUri);

            // Add an '@' if the username does not have one, to allow
            // for this input: 'pit:pattle.im'
            if (!username.startsWith('@')) {
              username = "@$username";
            }

            if (!UserId.isValidFullyQualified(username)) {
              addError(InvalidUserIdException());
              return false;
            }

            user = UserId(username).username;
          } on FormatException {
            addError(InvalidHostnameException());
            return false;
          }

          return true;
        } else {
          if (username.startsWith('@')) {
            username = username.substring(1).toLowerCase();
          }

          if (!Username.isValid(username)) {
            addError(InvalidUsernameException());
            return false;
          }

          user = Username(username);

          return true;
        }
      },
      request: (addError) {
        homeserver.isUsernameAvailable(user).then((available) {
          _isUsernameAvailableSubj.add(RequestSuccessState(
            data: available
          ));

          _username = user;
        })
        .catchError((error) => _isUsernameAvailableSubj.addError(error));
      },
    );
  }

  final _loginSubj = BehaviorSubject<RequestState>();
  Observable<RequestState> get loginStream => _loginSubj.stream;

  void login(String password) {
    _do(
      subject: _loginSubj,
      request: (addError) {
        homeserver.login(
          _username,
          password,
          store: di.getStore()
        )
        .then((user) {
          di.registerLocalUser(user);
          _loginSubj.add(RequestState.success);
        })
        .catchError((error) => _loginSubj.addError(error));
      }
    );
  }

}

class RequestState {
  final int _value;

  const RequestState(int value) : _value = value;

  static const none = RequestState(0);
  static const active = RequestState(1);
  static const stillActive = RequestState(2);
  static const success = RequestSuccessState();

  @override
  bool operator ==(other) {
    if (other is RequestState) {
      return other._value == this._value;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => _value.hashCode;
}

class RequestSuccessState<T> extends RequestState {
  final T data;

  const RequestSuccessState({this.data}) : super(3);
}

class InvalidUserIdException implements Exception { }

class InvalidHostnameException implements Exception { }