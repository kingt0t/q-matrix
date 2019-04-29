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
import 'package:matrix_sdk/matrix_sdk.dart';
import 'package:pattle/src/app.dart';
import 'package:pattle/src/ui/util/matrix_image.dart';

import 'bubble.dart';

class ImageBubble extends Bubble {

  @override
  final ImageMessageEvent event;

  static const double width = 256;
  static const double maxHeight = 292;

  double get height {
    return (event.content.info.height / (event.content.info.width / width))
           .clamp(0, maxHeight);
  }

  ImageBubble({
    @required this.event,
    @required RoomEvent previousEvent,
    @required RoomEvent nextEvent,
    @required bool isMine
  }) : super(
    event: event,
    previousEvent: previousEvent,
    nextEvent: nextEvent,
    isMine: isMine
  );

  void _onTap(BuildContext context) {
    Navigator.pushNamed(context, Routes.image, arguments: event);
  }
  
  Widget buildContent(BuildContext context) =>
    Text(event.content.body ?? '',
      style: textStyle(context)
    );

  @override
  Widget buildTime(BuildContext context, {Color color}) {
    var alignment, borderRadius;
    if (isMine) {
      alignment = Alignment.bottomRight;
      borderRadius = this.borderRadius();
    } else {
      alignment = Alignment.bottomLeft;
      borderRadius = const BorderRadius.all(Bubble.radiusForBorder);
    }

    if (isEndOfGroup) {
      return Align(
        alignment: alignment,
        child: Padding(
          padding: Bubble.padding,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              color: Color(0x64000000),
            ),
            child: Padding(
              padding: EdgeInsets.all(4),
              child: super.buildTime(context, color: Colors.white),
            )
          ),
        )
      );
    } else {
      return Container(width: 0, height: 0);
    }
  }

  @override
  Widget buildSender(BuildContext context, {Color color}) {
    if (!isMine && isStartOfGroup) {
      return Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: Bubble.padding,
          child: Container(
            decoration: BoxDecoration(
              borderRadius:  borderRadius(),
              color: Color(0x64000000),
            ),
            child: Padding(
              padding: EdgeInsets.all(6),
              child: super.buildSender(context,
                color: Colors.white
              ),
            )
          ),
        )
      );
    } else {
      return Container(height: 0, width: 0);
    }
  }

  Widget _build(BuildContext context) =>
    Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius()
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: ClipRRect(
              borderRadius: borderRadius(),
              child: Hero(
                tag: event.id,
                child: Image(
                  image: MatrixImage(event.content.url),
                  fit: BoxFit.fitWidth,
                )
              )
            )
          ),
          buildTime(context),
          buildSender(context),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: border(),
                onTap: () {
                  _onTap(context);
                }
              )
            )
          ),
        ],
      )
    );

  @protected
  Widget buildMine(BuildContext context) => _build(context);

  @protected
  Widget buildTheirs(BuildContext context) => _build(context);
}