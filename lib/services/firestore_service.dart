import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Couche Firestore de Shinra IA.
/// Tout est scopé par utilisateur : users/{uid}/... — personne ne peut voir
/// les données de quelqu'un d'autre (à condition d'avoir les règles de
/// sécurité Firestore correspondantes, voir en bas de ce fichier).
class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static DocumentReference<Map<String, dynamic>>? get _userDoc {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid);
  }

  // ═══════════════ 👤 PROFIL ═══════════════

  /// À appeler juste après une connexion réussie : crée le profil s'il
  /// n'existe pas encore (première connexion), sinon ne touche à rien.
  static Future<void> ensureUserProfile() async {
    final doc = _userDoc;
    if (doc == null) return;
    final snap = await doc.get();
    if (!snap.exists) {
      final user = FirebaseAuth.instance.currentUser!;
      await doc.set({
        'email': user.email,
        'displayName': user.displayName ?? '',
        'plan': 'trial', // trial (5 msg/j avec les clés de Nagato) | free (clé perso) | pro | team | business | enterprise
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } else {
      await doc.update({'lastSeen': FieldValue.serverTimestamp()});
    }
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    final doc = _userDoc;
    if (doc == null) return null;
    final snap = await doc.get();
    return snap.data();
  }

  static Stream<Map<String, dynamic>?> profileStream() {
    final doc = _userDoc;
    if (doc == null) return const Stream.empty();
    return doc.snapshots().map((s) => s.data());
  }

  static String get currentPlanSync => 'free'; // valeur par défaut avant chargement async

  // ═══════════════ 📁 PROJETS ═══════════════

  static CollectionReference<Map<String, dynamic>>? get _projectsCol =>
      _userDoc?.collection('projects');

  static Stream<List<Map<String, dynamic>>> projectsStream() {
    final col = _projectsCol;
    if (col == null) return const Stream.empty();
    return col.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs.map((d) => {...d.data(), 'id': d.id}).toList(),
        );
  }

  static Future<void> createProject(String name, {String path = '', String description = ''}) async {
    final col = _projectsCol;
    if (col == null) return;
    await col.add({
      'name': name,
      'path': path,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteProject(String id) async {
    await _projectsCol?.doc(id).delete();
  }

  // ═══════════════ 📊 MISSIONS (Mission Control) ═══════════════

  static CollectionReference<Map<String, dynamic>>? get _missionsCol =>
      _userDoc?.collection('missions');

  static Stream<List<Map<String, dynamic>>> missionsStream() {
    final col = _missionsCol;
    if (col == null) return const Stream.empty();
    return col.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs.map((d) => {...d.data(), 'id': d.id}).toList(),
        );
  }

  static Future<void> createMission(String title, {String project = '', int progress = 0, String status = 'active'}) async {
    final col = _missionsCol;
    if (col == null) return;
    await col.add({
      'title': title,
      'project': project,
      'status': status, // pending | active | done
      'progress': progress.clamp(0, 100),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateMission(String id, {int? progress, String? status, String? title}) async {
    final col = _missionsCol;
    if (col == null) return;
    final data = <String, dynamic>{};
    if (progress != null) {
      data['progress'] = progress.clamp(0, 100);
      if (progress >= 100) data['status'] = 'done';
    }
    if (status != null) data['status'] = status;
    if (title != null) data['title'] = title;
    if (data.isNotEmpty) await col.doc(id).update(data);
  }

  static Future<void> deleteMission(String id) async {
    await _missionsCol?.doc(id).delete();
  }

  // ═══════════════ 🏪 STORE (templates publics) ═══════════════
  // Sécurité importante : le Store ne partage QUE du texte (idées de
  // missions/apps), JAMAIS de code exécutable ou de commandes plugin. Un
  // vrai marketplace de plugins exécutables serait un risque de sécurité
  // majeur (code arbitraire d'inconnus tournant avec accès complet au PC
  // d'un autre utilisateur) — volontairement hors scope.
  static CollectionReference<Map<String, dynamic>> get _publicTemplates =>
      _db.collection('public_templates');

  static Stream<List<Map<String, dynamic>>> templatesStream() {
    return _publicTemplates.orderBy('createdAt', descending: true).limit(100).snapshots().map(
          (snap) => snap.docs.map((d) => {...d.data(), 'id': d.id}).toList(),
        );
  }

  static Future<void> publishTemplate(String title, String description, String promptText) async {
    final uid = _uid;
    if (uid == null) return;
    final profile = await getProfile();
    await _publicTemplates.add({
      'title': title,
      'description': description,
      'promptText': promptText,
      'authorUid': uid,
      'authorName': profile?['displayName'] ?? 'Anonyme',
      'uses': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> incrementTemplateUses(String templateId) async {
    await _publicTemplates.doc(templateId).update({'uses': FieldValue.increment(1)});
  }

  static Future<void> deleteTemplate(String templateId) async {
    await _publicTemplates.doc(templateId).delete();
  }

  // ═══════════════ 👥 COMMUNAUTÉ (profils publics) ═══════════════
  // Opt-in uniquement : rien n'est public par défaut. On ne copie que le
  // strict nécessaire (nom, bio) dans une collection publique séparée —
  // jamais les clés API, missions, ou données privées de l'utilisateur.
  static CollectionReference<Map<String, dynamic>> get _publicProfiles =>
      _db.collection('public_profiles');

  static Stream<List<Map<String, dynamic>>> publicProfilesStream() {
    return _publicProfiles.orderBy('joinedAt', descending: true).limit(100).snapshots().map(
          (snap) => snap.docs.map((d) => {...d.data(), 'id': d.id}).toList(),
        );
  }

  static Future<void> setProfilePublic(bool isPublic, {String bio = ''}) async {
    final uid = _uid;
    if (uid == null) return;
    await _userDoc?.set({'publicProfile': isPublic}, SetOptions(merge: true));
    if (isPublic) {
      final profile = await getProfile();
      await _publicProfiles.doc(uid).set({
        'displayName': profile?['displayName'] ?? 'Anonyme',
        'bio': bio,
        'joinedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _publicProfiles.doc(uid).delete();
    }
  }

  // ═══════════════ 🧠 MÉMOIRE (préférences, faits mémorisés) ═══════════════

  static DocumentReference<Map<String, dynamic>>? get _memoryDoc =>
      _userDoc?.collection('memory').doc('main');

  static Future<Map<String, dynamic>> getMemory() async {
    final doc = _memoryDoc;
    if (doc == null) return {};
    final snap = await doc.get();
    return snap.data() ?? {};
  }

  static Future<void> addFact(String fact) async {
    final doc = _memoryDoc;
    if (doc == null) return;
    await doc.set({
      'facts': FieldValue.arrayUnion([fact]),
    }, SetOptions(merge: true));
  }

  static Future<void> setPreference(String key, String value) async {
    final doc = _memoryDoc;
    if (doc == null) return;
    await doc.set({
      'preferences': {key: value},
    }, SetOptions(merge: true));
  }
}

/// ═══════════════════════════════════════════════════════════════
/// RÈGLES DE SÉCURITÉ FIRESTORE À COLLER DANS LA CONSOLE FIREBASE
/// (Firestore Database → Règles). Sans ça, N'IMPORTE QUI peut lire/écrire
/// les données de N'IMPORTE QUEL utilisateur. Version complète et à jour
/// dans le fichier firestore.rules à la racine du projet.
/// ═══════════════════════════════════════════════════════════════
