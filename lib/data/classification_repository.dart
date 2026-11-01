import 'package:domain_template_client/nomenclature_client.dart';
import 'package:domain_template_client/tag_client.dart';
import 'package:domain_template_client/task_client.dart';

import 'app_settings.dart';

abstract interface class ClassificationRepository {
  Future<List<Tag>> tags();
  Future<List<Nomenclature>> nomenclatures();
  Future<Tag> createTag(CreateTagRequest request);
  Future<Tag> updateTag(int id, UpdateTagRequest request);
  Future<void> deleteTag(int id);
  Future<Nomenclature> createNomenclature(CreateNomenclatureRequest request);
  Future<Nomenclature> updateNomenclature(
    int id,
    UpdateNomenclatureRequest request,
  );
  Future<void> deleteNomenclature(int id);
}

class ApiClassificationRepository implements ClassificationRepository {
  ApiClassificationRepository(
    this._settings,
    this._accessTokenProvider,
    this._onUnauthorized,
  );

  final AppSettings _settings;
  final String? Function() _accessTokenProvider;
  final Future<void> Function() _onUnauthorized;

  TagClient get _tags => TagClient(
    baseUri: Uri.parse(_settings.apiBaseUrl),
    accessTokenProvider: _accessTokenProvider,
  );
  NomenclatureClient get _nomenclatures => NomenclatureClient(
    baseUri: Uri.parse(_settings.apiBaseUrl),
    accessTokenProvider: _accessTokenProvider,
  );

  Future<T> _run<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on TaskException catch (error) {
      if (error.statusCode == 401) await _onUnauthorized();
      rethrow;
    }
  }

  @override
  Future<List<Tag>> tags() => _run(_tags.findAll);
  @override
  Future<List<Nomenclature>> nomenclatures() => _run(_nomenclatures.findAll);
  @override
  Future<Tag> createTag(CreateTagRequest request) =>
      _run(() => _tags.create(request));
  @override
  Future<Tag> updateTag(int id, UpdateTagRequest request) =>
      _run(() => _tags.update(id, request));
  @override
  Future<void> deleteTag(int id) => _run(() => _tags.delete(id));
  @override
  Future<Nomenclature> createNomenclature(CreateNomenclatureRequest request) =>
      _run(() => _nomenclatures.create(request));
  @override
  Future<Nomenclature> updateNomenclature(
    int id,
    UpdateNomenclatureRequest request,
  ) => _run(() => _nomenclatures.update(id, request));
  @override
  Future<void> deleteNomenclature(int id) =>
      _run(() => _nomenclatures.delete(id));
}

String nomenclaturePath(Nomenclature item, List<Nomenclature> items) {
  final labels = [item.label];
  final visited = <int>{item.id};
  var parentId = item.parentId;
  final byId = {for (final value in items) value.id: value};
  while (parentId != null && visited.add(parentId)) {
    final parent = byId[parentId];
    if (parent == null) break;
    labels.insert(0, parent.label);
    parentId = parent.parentId;
  }
  return labels.join(' / ');
}
