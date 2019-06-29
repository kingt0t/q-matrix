import 'package:matrix_sdk/matrix_sdk.dart';                                    
import 'package:pattle/src/ui/main/models/chat_item.dart';                      
import 'package:pattle/src/ui/main/sync_bloc.dart';                             
import 'package:pattle/src/ui/util/room.dart';                                  
import 'package:rxdart/rxdart.dart';                                            
import 'package:pattle/src/di.dart' as di;

class ImageBloc {

  Room room;
  ImageMessageEvent event;

  ImageBloc(this.event);

  int _eventCount = 500;

  PublishSubject<bool> _isLoadingEventsSubj = PublishSubject<bool>();
  Stream<bool> get isLoadingEvents => _isLoadingEventsSubj.stream.distinct();

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    _isLoading = value;
    if (!isLoading) {
      _isLoadingEventsSubj.add(false);
    } else {
      // If still loading after 2 seconds, notify the UI
      Future.delayed(const Duration(seconds: 2), () {
        if (isLoading) {
          _isLoadingEventsSubj.add(true);
        }
      });
    }
  }

  PublishSubject<List<ImageMessageEvent>> _eventSubj 
      = PublishSubject<List<ImageMessageEvent>>();
  Stream<List<ImageMessageEvent>> get events => _eventSubj.stream;

  Future<void> startLoadingEvents() async {
    await loadEvents();

    syncBloc.stream.listen((success) async => await loadEvents());
  }

  Future<void> requestMoreEvents() async {
    if (!_isLoading) {
      isLoading = true;
      _eventCount += 10;
      await loadEvents();
      isLoading = false;
    }
  }

  Future<void> loadEvents() async {
    final imageMessageEvents = List<ImageMessageEvent>();

    RoomEvent event;
    await for (event in room.timeline.upTo(count: _eventCount)) {
      if (event is ImageMessageEvent) {
        imageMessageEvents.add(event);
      }
    }

    _eventSubj.add(List.of(imageMessageEvents));
  }
}
