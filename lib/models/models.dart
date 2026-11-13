import 'package:cloud_firestore/cloud_firestore.dart';

typedef Json = Map<String, dynamic>;
typedef Doc = DocumentSnapshot<Json>;

int _int(dynamic v) => (v as num?)?.toInt() ?? 0;
DateTime _date(dynamic v) => v is Timestamp ? v.toDate() : DateTime.now();
List<String> _list(dynamic v) => v is List ? List<String>.from(v) : <String>[];

/// Kullanıcının o an açık olan çalışma oturumu (aynı anda yalnızca bir tane).
class ActiveSession {
  final String groupId;
  final String groupName;
  final String task;
  final DateTime startedAt;

  const ActiveSession({
    required this.groupId,
    required this.groupName,
    required this.task,
    required this.startedAt,
  });

  int get elapsed => DateTime.now().difference(startedAt).inSeconds;

  static ActiveSession? fromMap(dynamic m) {
    if (m is! Map) return null;
    return ActiveSession(
      groupId: m['groupId'] as String? ?? '',
      groupName: m['groupName'] as String? ?? '',
      task: m['task'] as String? ?? '',
      startedAt: _date(m['startedAt']),
    );
  }
}

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String handle;
  final int totalSeconds;
  final bool hideGroups;
  final ActiveSession? activeSession;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.handle,
    required this.totalSeconds,
    required this.hideGroups,
    this.activeSession,
  });

  factory AppUser.fromDoc(Doc d) {
    final m = d.data() ?? const {};
    return AppUser(
      uid: d.id,
      name: m['name'] as String? ?? 'İsimsiz',
      email: m['email'] as String? ?? '',
      handle: m['handle'] as String? ?? '',
      totalSeconds: _int(m['totalSeconds']),
      hideGroups: m['hideGroups'] as bool? ?? false,
      activeSession: ActiveSession.fromMap(m['activeSession']),
    );
  }
}

class Group {
  final String id;
  final String name;
  final String description;
  final int sigil;
  final String leaderId;
  final List<String> helperIds;
  final List<String> memberIds;
  final List<String> mutedIds;
  final int totalSeconds;
  final int memberCount;

  const Group({
    required this.id,
    required this.name,
    required this.description,
    required this.sigil,
    required this.leaderId,
    required this.helperIds,
    required this.memberIds,
    required this.mutedIds,
    required this.totalSeconds,
    required this.memberCount,
  });

  factory Group.fromDoc(Doc d) {
    final m = d.data() ?? const {};
    return Group(
      id: d.id,
      name: m['name'] as String? ?? '',
      description: m['description'] as String? ?? '',
      sigil: _int(m['sigil']),
      leaderId: m['leaderId'] as String? ?? '',
      helperIds: _list(m['helperIds']),
      memberIds: _list(m['memberIds']),
      mutedIds: _list(m['mutedIds']),
      totalSeconds: _int(m['totalSeconds']),
      memberCount: _int(m['memberCount']),
    );
  }

  bool isLeader(String uid) => leaderId == uid;
  bool isHelper(String uid) => helperIds.contains(uid);
  bool isStaff(String uid) => isLeader(uid) || isHelper(uid);
  bool isMember(String uid) => memberIds.contains(uid);
  bool isMuted(String uid) => mutedIds.contains(uid);

  /// 0 = lider, 1 = yardımcı, 2 = üye (sıralama için)
  int rankOf(String uid) => isLeader(uid) ? 0 : (isHelper(uid) ? 1 : 2);
  String roleOf(String uid) => const ['Lider', 'Yardımcı', 'Üye'][rankOf(uid)];
}

class Member {
  final String uid;
  final String name;
  final String handle;
  final int seconds; // bu grupta toplam çalışma
  final DateTime joinedAt;

  const Member({
    required this.uid,
    required this.name,
    required this.handle,
    required this.seconds,
    required this.joinedAt,
  });

  factory Member.fromDoc(Doc d) {
    final m = d.data() ?? const {};
    return Member(
      uid: d.id,
      name: m['name'] as String? ?? '',
      handle: m['handle'] as String? ?? '',
      seconds: _int(m['seconds']),
      joinedAt: _date(m['joinedAt']),
    );
  }
}

class JoinRequest {
  final String uid;
  final String name;
  final String handle;
  final DateTime createdAt;

  const JoinRequest({
    required this.uid,
    required this.name,
    required this.handle,
    required this.createdAt,
  });

  factory JoinRequest.fromDoc(Doc d) {
    final m = d.data() ?? const {};
    return JoinRequest(
      uid: d.id,
      name: m['name'] as String? ?? '',
      handle: m['handle'] as String? ?? '',
      createdAt: _date(m['createdAt']),
    );
  }
}

/// Grup ekranında canlı gösterilen oturum.
class LiveSession {
  final String uid;
  final String name;
  final String task;
  final DateTime startedAt;

  const LiveSession({
    required this.uid,
    required this.name,
    required this.task,
    required this.startedAt,
  });

  int get elapsed => DateTime.now().difference(startedAt).inSeconds;

  factory LiveSession.fromDoc(Doc d) {
    final m = d.data() ?? const {};
    return LiveSession(
      uid: d.id,
      name: m['name'] as String? ?? '',
      task: m['task'] as String? ?? '',
      startedAt: _date(m['startedAt']),
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final bool system;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.system,
    required this.createdAt,
  });

  factory ChatMessage.fromDoc(Doc d) {
    final m = d.data() ?? const {};
    return ChatMessage(
      id: d.id,
      senderId: m['senderId'] as String? ?? '',
      senderName: m['senderName'] as String? ?? '',
      text: m['text'] as String? ?? '',
      system: m['system'] as bool? ?? false,
      createdAt: _date(m['createdAt']),
    );
  }
}

