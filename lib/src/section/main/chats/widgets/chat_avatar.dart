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

import 'package:flutter/material.dart';
import '../../widgets/avatar.dart';

import '../../../../models/chat.dart';

import '../../../../util/chat_member.dart';

class ChatAvatar extends StatelessWidget {
  final Chat chat;

  const ChatAvatar({Key key, this.chat}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final avatarUrl = chat.avatarUrl;

    final placeholderColor =
        chat.directMember != null ? chat.directMember.color(context) : null;

    if (chat.isDirect) {
      return Avatar.direct(
        url: avatarUrl,
        placeholderColor: placeholderColor,
      );
    } else if (chat.isChannel) {
      return Avatar.channel(
        url: avatarUrl,
        placeholderColor: placeholderColor,
      );
    } else {
      return Avatar.group(
        url: avatarUrl,
        placeholderColor: placeholderColor,
      );
    }
  }
}
