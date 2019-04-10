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

import 'package:matrix_sdk/matrix_sdk.dart';
import 'package:pattle/src/ui/main/sync_bloc.dart';
import 'package:rxdart/rxdart.dart';

class ChatBloc {

  Room room;

  PublishSubject<List<MessageEvent>> _eventSubj = PublishSubject<List<MessageEvent>>();
  Stream<List<MessageEvent>> get events => _eventSubj.stream;

  Future<void> startLoadingEvents() async {
    await loadEvents();

    syncBloc.stream.listen((success) async => await loadEvents());
  }

  Future<void> loadEvents() async {
    var chatEvents = List<MessageEvent>();

    // Get all rooms and push them as a single list
    await for(MessageEvent event in room.events.messages()) {
      chatEvents.add(event);
    }

    _eventSubj.add(List.of(chatEvents));
  }
}