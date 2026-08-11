import '../../ward/domain/local_talk_post.dart';
import 'issue.dart';
import 'notice.dart';
import 'win.dart';

enum FeedItemType {
  issue,
  win,
  notice,
  localTalk;

  static FeedItemType fromString(String val) {
    switch (val) {
      case 'win':
        return FeedItemType.win;
      case 'notice':
        return FeedItemType.notice;
      case 'local_talk':
        return FeedItemType.localTalk;
      case 'issue':
      default:
        return FeedItemType.issue;
    }
  }
}

class FeedItem {
  final FeedItemType itemType;
  final Issue? issue;
  final WinItem? win;
  final NoticeItem? notice;
  final LocalTalkPost? localTalk;

  const FeedItem({
    required this.itemType,
    this.issue,
    this.win,
    this.notice,
    this.localTalk,
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    final typeStr = json['item_type'] as String? ?? 'issue';
    final itemType = FeedItemType.fromString(typeStr);

    switch (itemType) {
      case FeedItemType.win:
        return FeedItem(
          itemType: itemType,
          win: WinItem.fromJson(json),
        );
      case FeedItemType.notice:
        return FeedItem(
          itemType: itemType,
          notice: NoticeItem.fromJson(json),
        );
      case FeedItemType.localTalk:
        return FeedItem(
          itemType: itemType,
          localTalk: LocalTalkPost.fromJson(json),
        );
      case FeedItemType.issue:
        return FeedItem(
          itemType: FeedItemType.issue,
          issue: Issue.fromJson(json),
        );
    }
  }

  int get id {
    switch (itemType) {
      case FeedItemType.issue:
        return issue?.id ?? 0;
      case FeedItemType.win:
        return win?.id ?? 0;
      case FeedItemType.notice:
        return notice?.id ?? 0;
      case FeedItemType.localTalk:
        return localTalk?.id ?? 0;
    }
  }
}
