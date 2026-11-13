import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import '../utils/errors.dart';

final _fs = FirebaseFirestore.instance;

/// Tüm Firestore işlemleri.
///
/// Veri yapısı:
///   users/{uid}                     → profil, toplam süre, açık oturum
///   handles/{id}                    → benzersiz kullanıcı ID'leri
///   groups/{gid}                    → grup, roller, toplam süre
///   groups/{gid}/members/{uid}      → üye kartı (isim, grupta geçen süre)
///   groups/{gid}/requests/{uid}     → katılma istekleri
///   groups/{gid}/sessions/{uid}     → canlı çalışma oturumları
///   groups/{gid}/messages/{id}      → sohbet
class Db {
  /// Unutulan oturumlar seviyeyi şişirmesin diye tek oturum en fazla 12 saat sayılır.
  static const maxSessionSeconds = 12 * 3600;

  static DocumentReference<Json> userRef(String uid) => _fs.collection('users').doc(uid);
  static DocumentReference<Json> groupRef(String gid) => _fs.collection('groups').doc(gid);
  static CollectionReference<Json> _sub(String gid, String name) => groupRef(gid).collection(name);

  // ───────────── Kullanıcı ─────────────

  static Stream<AppUser?> userStream(String uid) =>
      userRef(uid).snapshots().map((d) => d.exists ? AppUser.fromDoc(d) : null);

  static Future<void> setHideGroups(String uid, bool hide) =>
      userRef(uid).update({'hideGroups': hide});

  // ───────────── Gruplar ─────────────

  static Stream<Group?> groupStream(String gid) =>
      groupRef(gid).snapshots().map((d) => d.exists ? Group.fromDoc(d) : null);

  /// Grup seçme ekranı: seviyeye (toplam süreye) göre sıralı.
  static Stream<List<Group>> rankedGroups() => _fs
      .collection('groups')
      .orderBy('totalSeconds', descending: true)
      .limit(100)
      .snapshots()
      .map((q) => q.docs.map(Group.fromDoc).toList());

  static Stream<List<Group>> groupsOf(String uid) => _fs
      .collection('groups')
      .where('memberIds', arrayContains: uid)
      .snapshots()
      .map((q) => q.docs.map(Group.fromDoc).toList()
        ..sort((a, b) => b.totalSeconds.compareTo(a.totalSeconds)));

  static Future<String> createGroup({
    required AppUser me,
    required String name,
    required String description,
    required int sigil,
  }) async {
    final ref = _fs.collection('groups').doc();
    final batch = _fs.batch()
      ..set(ref, {
        'name': name.trim(),
        'description': description.trim(),
        'sigil': sigil,
        'leaderId': me.uid,
        'helperIds': <String>[],
        'memberIds': [me.uid],
        'mutedIds': <String>[],
        'totalSeconds': 0,
        'memberCount': 1,
        'createdAt': FieldValue.serverTimestamp(),
      })
      ..set(ref.collection('members').doc(me.uid), _memberData(me.uid, me.name, me.handle));
    await batch.commit();
    return ref.id;
  }

  static Json _memberData(String uid, String name, String handle) => {
        'name': name,
        'handle': handle,
        'seconds': 0,
        'joinedAt': FieldValue.serverTimestamp(),
      };

  static Stream<List<Member>> membersStream(String gid) =>
      _sub(gid, 'members').snapshots().map((q) => q.docs.map(Member.fromDoc).toList());

  // ───────────── Katılma istekleri ─────────────

  static Stream<bool> hasPendingRequest(String gid, String uid) =>
      _sub(gid, 'requests').doc(uid).snapshots().map((d) => d.exists);

  static Stream<List<JoinRequest>> requestsStream(String gid) => _sub(gid, 'requests')
      .orderBy('createdAt')
      .snapshots()
      .map((q) => q.docs.map(JoinRequest.fromDoc).toList());

  static Future<void> sendRequest(String gid, AppUser me) => _sub(gid, 'requests').doc(me.uid).set({
        'name': me.name,
        'handle': me.handle,
        'createdAt': FieldValue.serverTimestamp(),
      });

  static Future<void> cancelRequest(String gid, String uid) =>
      _sub(gid, 'requests').doc(uid).delete();

  static Future<void> acceptRequest(Group g, JoinRequest r, AppUser me) async {
    final batch = _fs.batch()
      ..delete(_sub(g.id, 'requests').doc(r.uid))
      ..set(_sub(g.id, 'members').doc(r.uid), _memberData(r.uid, r.name, r.handle))
      ..update(groupRef(g.id), {
        'memberIds': FieldValue.arrayUnion([r.uid]),
        'memberCount': FieldValue.increment(1),
      });
    _systemMessage(batch, g.id, me.uid, '${r.name} loncaya katıldı');
    await batch.commit();
  }

  static Future<void> rejectRequest(String gid, String uid) =>
      _sub(gid, 'requests').doc(uid).delete();

  // ───────────── Yönetim ─────────────

  static Future<void> kick(Group g, Member target, AppUser me) async {
    final batch = _fs.batch();
    _removeMember(batch, g.id, target.uid);
    _systemMessage(batch, g.id, me.uid, '${target.name} loncadan çıkarıldı');
    await batch.commit();
  }

  static Future<void> leave(Group g, AppUser me) async {
    if (g.isLeader(me.uid)) {
      throw const AppError('Lider ayrılmadan önce liderliği devretmeli.');
    }
    if (me.activeSession?.groupId == g.id) await endSession(me);
    final batch = _fs.batch();
    if (g.isStaff(me.uid)) {
      _systemMessage(batch, g.id, me.uid, '${me.name} loncadan ayrıldı');
    }
    _removeMember(batch, g.id, me.uid);
    await batch.commit();
  }

  static void _removeMember(WriteBatch batch, String gid, String uid) {
    batch
      ..delete(_sub(gid, 'members').doc(uid))
      ..delete(_sub(gid, 'sessions').doc(uid))
      ..update(groupRef(gid), {
        'memberIds': FieldValue.arrayRemove([uid]),
        'helperIds': FieldValue.arrayRemove([uid]),
        'mutedIds': FieldValue.arrayRemove([uid]),
        'memberCount': FieldValue.increment(-1),
      });
  }

  static Future<void> setMuted(String gid, String uid, bool muted) => groupRef(gid).update({
        'mutedIds': muted ? FieldValue.arrayUnion([uid]) : FieldValue.arrayRemove([uid]),
      });

  static Future<void> setHelper(String gid, String uid, bool helper) => groupRef(gid).update({
        'helperIds': helper ? FieldValue.arrayUnion([uid]) : FieldValue.arrayRemove([uid]),
      });

  /// Liderlik devri: yeni lider atanır, eski lider yardımcı olur.
  static Future<void> transferLeadership(Group g, Member target, AppUser me) async {
    await _fs.runTransaction((tx) async {
      final snap = await tx.get(groupRef(g.id));
      final fresh = Group.fromDoc(snap);
      if (!fresh.isLeader(me.uid)) throw const AppError('Artık lider değilsin.');
      if (!fresh.isMember(target.uid)) throw const AppError('Bu kişi artık grupta değil.');
      final helpers = [...fresh.helperIds]..remove(target.uid);
      if (!helpers.contains(me.uid)) helpers.add(me.uid);
      tx.update(groupRef(g.id), {
        'leaderId': target.uid,
        'helperIds': helpers,
        'mutedIds': FieldValue.arrayRemove([target.uid]),
      });
    });
    final batch = _fs.batch();
    _systemMessage(batch, g.id, me.uid, 'Liderlik ${target.name} kişisine devredildi');
    await batch.commit();
  }

  // ───────────── Çalışma oturumları ─────────────

  static Stream<List<LiveSession>> sessionsStream(String gid) =>
      _sub(gid, 'sessions').snapshots().map((q) => q.docs.map(LiveSession.fromDoc).toList());

  static Future<void> startSession(Group g, AppUser me, String task) async {
    if (me.activeSession != null) {
      throw AppError('Önce "${me.activeSession!.groupName}" loncasındaki oturumunu bitir.');
    }
    final now = Timestamp.now();
    final batch = _fs.batch()
      ..set(_sub(g.id, 'sessions').doc(me.uid), {
        'name': me.name,
        'task': task.trim(),
        'startedAt': now,
      })
      ..update(userRef(me.uid), {
        'activeSession': {
          'groupId': g.id,
          'groupName': g.name,
          'task': task.trim(),
          'startedAt': now,
        },
      });
    await batch.commit();
  }

  /// Oturumu kapatır; geçen süre kullanıcıya, gruba ve üyelik kartına eklenir.
  /// Eklenen saniyeyi döner.
  static Future<int> endSession(AppUser me) async {
    final s = me.activeSession;
    if (s == null) return 0;
    final secs = math.min(math.max(0, s.elapsed), maxSessionSeconds);

    final gSnap = await groupRef(s.groupId).get();
    final stillMember = gSnap.exists && Group.fromDoc(gSnap).isMember(me.uid);

    final batch = _fs.batch()
      ..update(userRef(me.uid), {
        'activeSession': FieldValue.delete(),
        'totalSeconds': FieldValue.increment(secs),
      });
    if (stillMember) {
      batch.delete(_sub(s.groupId, 'sessions').doc(me.uid));
      if (secs > 0) {
        batch
          ..update(groupRef(s.groupId), {'totalSeconds': FieldValue.increment(secs)})
          ..update(_sub(s.groupId, 'members').doc(me.uid), {'seconds': FieldValue.increment(secs)});
      }
    }
    await batch.commit();
    return secs;
  }

  // ───────────── Sohbet ─────────────

  static Stream<List<ChatMessage>> messagesStream(String gid) => _sub(gid, 'messages')
      .orderBy('createdAt', descending: true)
      .limit(200)
      .snapshots()
      .map((q) => q.docs.map(ChatMessage.fromDoc).toList());

  static Future<void> sendMessage(String gid, AppUser me, String text) =>
      _sub(gid, 'messages').add({
        'senderId': me.uid,
        'senderName': me.name,
        'text': text.trim(),
        'system': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

  static void _systemMessage(WriteBatch batch, String gid, String byUid, String text) {
    batch.set(_sub(gid, 'messages').doc(), {
      'senderId': byUid,
      'senderName': '',
      'text': text,
      'system': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

