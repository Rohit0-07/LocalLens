# F-A — Compose Media & Captured-Media Library Plan

Feature: location-by-default on issue media, in-app-camera-only uploads, a persistent captured-media
library with delete/multi-select, per-image GPS driving the map, and compose-screen polish.

## 1. Scope & ownership

### Files to CREATE

**Frontend (`app/`)**
- `app/lib/features/compose/domain/captured_media.dart` (+ generated `captured_media.freezed.dart`, `captured_media.g.dart`)
- `app/lib/features/compose/data/captured_media_store.dart`
- `app/lib/features/compose/presentation/media_library_providers.dart`
- `app/lib/features/compose/presentation/media_library_screen.dart`
- Tests:
  - `app/test/features/compose/captured_media_library_test.dart`
  - `app/test/features/compose/gallery_disabled_test.dart`
  - `app/test/features/compose/captured_media_auto_save_test.dart`
  - `app/test/features/compose/compose_publish_metadata_test.dart`
  - `app/test/features/compose/offline_outbox_media_test.dart`

**Backend (`backend/`)**
- `backend/alembic/versions/<new>_add_issue_link_soft_delete_captured_at_to_media.py`
- Tests:
  - `backend/tests/features/media/test_media_delete.py`
  - `backend/tests/features/media/test_media_exif_gps.py`
  - `backend/tests/features/media/test_media_issue_link.py`

### Files to MODIFY

**Frontend**
- `app/lib/features/compose/domain/compose_draft.dart` — replace `mediaBytes` with a typed `media` list (see §3.6).
- `app/lib/features/compose/data/media_service.dart` — add `capturedAt` to `uploadMedia`/`packageExifMetadata`, add `deleteMedia(id)`.
- `app/lib/features/compose/data/offline_outbox_queue.dart` — media re-upload + per-image coords during flush.
- `app/lib/features/compose/presentation/compose_providers.dart` — new `submit(media:)` signature, coordinate resolution, outbox wiring.
- `app/lib/features/compose/presentation/compose_screen.dart` — gallery removal, auto-save on capture, media-section redesign, library picker.
- `app/lib/features/compose/presentation/widgets/camera_viewfinder.dart` — remove gallery button + callback.
- `app/lib/features/compose/presentation/drafts_screen.dart` — read `draft.media` (thumbnail + count) instead of `mediaBytes`.
- `app/lib/core/router/route_paths.dart` — add `capturedMedia = '/captured-media'`.
- `app/lib/core/router/app_router.dart` — register the library route (with `pickMode` extra).

**Backend**
- `backend/app/features/media/models.py` — add `issue_id`, `deleted_at`, `captured_at`.
- `backend/app/features/media/schemas.py` — `MediaUploadRequest` + `MediaUploadOut` additions.
- `backend/app/features/media/service.py` — `embed_exif_gps(...)`, `delete_media_record(...)`, `captured_at` plumbing.
- `backend/app/features/media/router.py` — accept `captured_at`; add `DELETE /{media_id}`.
- `backend/app/features/issues/service.py` — link uploaded media rows to the created issue (`media.issue_id`).

**Coordinated one-line touch**
- `app/lib/features/outbox/presentation/outbox_screen.dart` — invalidate `mapPinsNotifierProvider` after a successful `flush()` (only change).

### Files to NOT touch (parallel-agent conflict avoidance)
- `app/lib/features/map/**` (map rendering, `map_controller.dart` stays read-only; we only call the existing `mapPinsNotifierProvider` invalidate)
- `app/lib/features/search/**`, `app/lib/features/feed/**`, `app/lib/features/profile/**`, `app/lib/features/ward/**`
- `app/lib/features/compose/presentation/controllers/compose_controller.dart` — DEAD/legacy, not imported; do not edit.
- `backend/app/features/geo/**`, `backend/app/features/wards/**`, `backend/app/features/representatives/**`, `backend/app/features/search/**`
- `backend/app/features/feed/**`, `backend/app/features/notifications/**`, `backend/app/features/gamification/**`, `backend/app/features/auth/**` (except none)
- `app/lib/features/geo/**` (only read `feedCoordinatesProvider`, `wardLocationProvider`, `deviceLocationProvider`; never modify)

---

## 2. Backend design

### 2.1 Media model — `backend/app/features/media/models.py`
Add three columns to `Media`:
- `issue_id: Mapped[int | None] = mapped_column(ForeignKey("issues.id"), nullable=True, index=True)`
- `deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)`
- `captured_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)`

Existing columns (`latitude`, `longitude`, `is_verified`, `is_in_app_camera`, `is_fuzzed`, `derived_hash`, `url`, `thumbnail_url`, `user_id`) are unchanged.

Alembic migration: batch `ALTER TABLE media ADD COLUMN` for the three columns (follow the `fc2945538d6e` batch-alter pattern for SQLite); `downgrade` drops them.

### 2.2 Schemas — `backend/app/features/media/schemas.py`
- `MediaUploadRequest`: add `captured_at: datetime | None = None`.
- `MediaUploadOut`: add `issue_id: int | None = None`, `deleted_at: datetime | None = None`, `captured_at: datetime | None = None`.
- New `MediaDeleteOut(BaseModel)`: `success: bool`.

### 2.3 Service — `backend/app/features/media/service.py`
- `embed_exif_gps(image_bytes: bytes, lat: float | None, lng: float | None, captured_at: datetime | None = None) -> bytes`
  - When `lat`/`lng` are both non-null, re-encode the JPEG with a GPSInfo IFD (EXIF tag 34853):
    `GPSLatitudeRef`/`GPSLatitude`, `GPSLongitudeRef`/`GPSLongitude` (DMS rationals, 6-decimal precision),
    `GPSTimeStamp`, and `DateTimeOriginal` from `captured_at`.
  - Deg to DMS helper `_to_dms(value) -> tuple[int, int, int]`; rational form `(value * 1_000_000, 1_000_000)`.
  - Convert `RGBA`/`P` to `RGB` first (as the thumbnail code does). Wrap the whole thing in `try/except` and
    return the original bytes on any failure (never 500 on a non-JPEG payload).
- `create_media_record(...)`: add `captured_at: datetime | None = None` param → pass into `Media(...)`.
  Replace the main-file write with `file_bytes = embed_exif_gps(image_bytes, lat, lng, captured_at)`; `file_path.write_bytes(file_bytes)`.
  Thumbnail generation stays as-is (does NOT need EXIF).
- New `delete_media_record(db, media_id: str, user_id: int | str) -> Media | None`:
  - `None` or already-deleted → return `None` (router → 404).
  - Ownership: `media.user_id != str(user_id)` → `AppError(403, "forbidden")`.
  - Linked check: `media.issue_id is not None` → load the `Issue`; if it exists and `not is_hidden` →
    `AppError(409, "media_linked_to_issue", "This photo is attached to a published report")`.
  - Soft-delete: `media.deleted_at = datetime.now(UTC)`, commit, return.

### 2.4 Router — `backend/app/features/media/router.py`
- Accept `captured_at` in the JSON-body parse (`datetime.fromisoformat`, ignore parse errors → `None`) and as `captured_at: datetime | None = Form(None)`; forward to `create_media_record`.
- New endpoint (route path `/{media_id}` is unambiguous vs the literal `/files/...` and `/upload`):
  ```python
  @router.delete("/{media_id}", response_model=MediaDeleteOut, status_code=status.HTTP_200_OK)
  async def delete_media(media_id: str, db: SessionDep, user: CurrentUser) -> MediaDeleteOut:
      if getattr(user, "is_guest", False):
          raise AppError("Sign in required to delete media", status_code=403, code="guest_restricted")
      media = await service.delete_media_record(db, media_id, user.id)
      if media is None:
          raise HTTPException(status_code=404, detail="Media not found")
      return MediaDeleteOut(success=True)
  ```

### 2.5 Issue↔media linkage — `backend/app/features/issues/service.py`
- New private helper `_link_media_to_issue(session, issue, media_urls: list[str])`:
  ```python
  urls = set(media_urls)
  stmt = select(Media).where(or_(Media.url.in_(urls), Media.thumbnail_url.in_(urls)))
  for media in (await session.execute(stmt)).scalars().all():
      if media.issue_id is None:
          media.issue_id = issue.id
  if media_rows: await session.commit()
  ```
- Call it at the end of `create_issue(...)`. Lazy-import `Media` inside the helper (matches existing style).
- `create_issue` keeps the client-supplied `latitude`/`longitude` (the client now sends the capture location,
  §3.4). No change to `IssueCreate`/`IssueOut`.

### 2.6 Map pins — NO change to `backend/app/features/geo/**`
`get_map_pins` keeps querying `Issue` rows. The map updates because (a) the issue is created at the
per-image capture location (client-side, §3.4) and (b) the client invalidates `mapPinsNotifierProvider`
on publish and on outbox flush (§3.5). Per-image locations of a single issue are NOT separate pins
(product decision, documented in §6).

---

## 3. Frontend design

### 3.1 New freezed model — `app/lib/features/compose/domain/captured_media.dart`
```dart
@freezed
abstract class CapturedMedia with _$CapturedMedia {
  const factory CapturedMedia({
    @Default('') String id,            // 'cam_<micros>'
    @Default('') String bytesBase64,   // raw captured bytes, base64
    double? capturedLat,
    double? capturedLng,
    DateTime? capturedAt,
    @Default(false) bool isVerified,
    String? remoteMediaId,             // server Media.id after upload (for delete semantics)
  }) = _CapturedMedia;

  factory CapturedMedia.fromJson(Map<String, Object?> json) =>
      _$CapturedMediaFromJson(json);

  bool get hasGps => capturedLat != null && capturedLng != null;
}
```
Run `dart run build_runner build` after creating it and after the `ComposeDraft` change.

### 3.2 Captured-media store — `app/lib/features/compose/data/captured_media_store.dart`
- `CapturedMediaStore(LocalStore _store)`; persists a JSON array under LocalStore key
  `'locallens_captured_media_v1'` via the existing `getString`/`setString` (same drafts box; no core-storage edits).
- API:
  - `List<CapturedMedia> loadAll()` (newest first; malformed entries skipped)
  - `Future<void> save(CapturedMedia media)` (upsert by `id`, de-dupe by base64 hash if desired — see §5)
  - `Future<void> saveAll(List<CapturedMedia> items)`
  - `Future<void> delete(String id)` / `Future<void> deleteMany(List<String> ids)`
  - `Future<void> markUploaded(String id, String remoteMediaId)`
  - `void clearAll()`

### 3.3 Providers — `app/lib/features/compose/presentation/media_library_providers.dart`
- `capturedMediaStoreProvider = Provider<CapturedMediaStore>((ref) => CapturedMediaStore(ref.watch(localStoreProvider)))`
- `capturedMediaListProvider = NotifierProvider<CapturedMediaListController, List<CapturedMedia>>` where
  `build()` loads from the store; controller exposes `refresh()`, `delete(List<String> ids)`,
  `deleteWithServer(list)` (calls `MediaService.deleteMedia` for each non-null `remoteMediaId`; on
  `409 media_linked_to_issue` keep the local record and surface a snackbar; on success remove locally),
  `markUploaded(id, remoteId)`.

### 3.4 Compose data flow
- `MediaService.uploadMedia(...)` — add `DateTime? capturedAt`; build the payload from
  `packageExifMetadata(...)` so the two never drift; payload now includes `'captured_at': capturedAt?.toUtc().toIso8601String()`.
- `MediaService.packageExifMetadata(...)` — replace the `'timestamp'` field with `'captured_at'`
  (`(capturedAt ?? DateTime.now()).toUtc().toIso8601String()`); keep `is_in_app_camera`, `captured_lat`, `captured_lng`, `is_fuzzed`.
- `MediaService.deleteMedia(String id)` — `DELETE /media/$id` with the bearer token; throw on non-2xx.

`ComposeController` (`presentation/compose_providers.dart`):
- New signature `Future<bool> submit({List<CapturedMedia> media = const []})`.
- Coordinate resolution helper `resolveComposeCoords(ComposeDraft draft, List<CapturedMedia> media)`:
  1. first attached `CapturedMedia` with `hasGps` → `(m.capturedLat, m.capturedLng)`
  2. else `draft.latitude`/`draft.longitude` (user "Use my location" lock)
  3. else `feedCoordinatesProvider.future` (fallback reference point)
- Direct path: for each `CapturedMedia` → `uploadMedia(bytes: base64Decode(m.bytesBase64), isInAppCamera: true,
  capturedLat: m.capturedLat, capturedLng: m.capturedLng, isFuzzed: current.isFuzzed, capturedAt: m.capturedAt)`;
  collect `result.url`; then `repo.createIssue(..., latitude: lat, longitude: lng, mediaUrls: urls)`.
  After each upload call `capturedMediaStore.markUploaded(m.id, result.id)` so the library can soft-delete the server copy.
- Fallback path: `outbox.enqueue(current.copyWith(media: media, latitude: lat, longitude: lng))`.
- `update(draft)` now strips media via `copyWith(media: const [])`; `saveAsDraft(media: [...])` persists the typed list.
- `offlineOutboxProvider` constructor gains a third arg: `ref.watch(mediaServiceProvider)`.

`OfflineOutboxQueue` (`data/offline_outbox_queue.dart`):
- `OfflineOutboxQueue(LocalStore, FeedRepository, MediaService)`.
- `flush()`: per draft — upload each `draft.media` (same `uploadMedia` call shape), resolve coords
  (`draft.latitude ?? first media GPS ?? default`), `createIssue(..., mediaUrls: urls)`; keep failing drafts;
  drain on success. This fixes the current bug where outbox-flushed issues lost all images.

### 3.5 Map update on publish (req #4)
- Compose `_publish` already does `ref.invalidate(mapPinsNotifierProvider)` on success — keep.
- `outbox_screen._syncNow()`: after `synced > 0`, add `ref.invalidate(mapPinsNotifierProvider);` (the only
  cross-feature change; the map feature itself is untouched).

### 3.6 `ComposeDraft` change — `domain/compose_draft.dart`
- Replace `@Default(<String>[]) List<String> mediaBytes` with `@Default(<CapturedMedia>[]) List<CapturedMedia> media`.
- Update getters: `hasMedia => media.isNotEmpty`, `mediaCount => media.length`.
- Old persisted JSON with a `mediaBytes` key simply restores with `media == []` (json_serializable ignores
  unknown keys) — acceptable, note in §5.

### 3.7 Gallery removal (req #2)
- `camera_viewfinder.dart`: delete `_triggerGalleryPicker`, the `onGalleryPickSelected` widget field, and the
  `Key('galleryPickerButton')` IconButton. Bottom bar becomes shutter + flip only. Keep `shutterButton`,
  `cameraFlipButton`, `flashToggleButton`, `gpsLockStatus`.
- `compose_screen.dart`: delete `import 'package:image_picker/image_picker.dart';`, `_addGalleryImages(...)`,
  and the `Key('openGalleryButton')` button. Remove the `onGalleryPickSelected:` argument to `CameraViewfinder`.
  After removal the ONLY media entry point is the in-app camera.

### 3.8 Compose screen media section redesign (req #6)
Replace the current media `Card` (`compose_media`) with a two-part layout:
- **Add row**: `FilledButton.icon` `Key('openCameraButton')` ("Take photo") → `_openCameraModal` (kept GPS-lock
  flow: resolve position → open `CameraViewfinder`).
  `OutlinedButton.icon` `Key('capturedLibraryButton')` ("My captured photos") →
  `final picked = await context.push<List<CapturedMedia>>(RoutePaths.capturedMedia, extra: MediaLibraryScreenArgs(pickMode: true));`
  then append `picked` up to the 4-slot cap.
- **"Captured photos" separate section** (req #3): header text + horizontal strip of attached `CapturedMedia`:
  - `Image.memory(base64Decode(m.bytesBase64))` thumbnail
  - `MediaWatermarkBadge(isVerified: m.isVerified, isCompact: true)`
  - small GPS chip `Icon(Icons.gps_fixed)` when `m.hasGps`, else `Icon(Icons.gps_off)`
  - overlay remove `Key('removeMedia_${m.id}')` (pattern preserved)
- Slot guard: max 4, snackbar `'Maximum 4 images allowed.'` (kept); counter label `Key('mediaCountLabel')`.
- `_openCameraModal`'s `onPhotoCaptured` handler becomes:
  ```dart
  final media = CapturedMedia(
    id: 'cam_${DateTime.now().microsecondsSinceEpoch}',
    bytesBase64: base64Encode(bytes),
    capturedLat: lat, capturedLng: lng,
    capturedAt: DateTime.now(),
    isVerified: lat != null && lng != null,   // mirrors backend validate_verification for in-app camera
  );
  unawaited(ref.read(capturedMediaStoreProvider).save(media));   // auto-save even if never published (req #5)
  setState(() => _attachedMedia.add(media));
  ```
- Replace the `_AttachedMedia` widget-state class with `CapturedMedia` (drop the parallel struct).
- Location card: when `draft.latitude == null` but an attached image has GPS, display the captured coords with
  label "From captured photo" and let `_publish`/near-dup check use `resolveComposeCoords` (import the helper).
- `_publish` passes `media: _attachedMedia.toList()` to `submit`.

### 3.9 Media library screen — `presentation/media_library_screen.dart` (req #3 + #5)
- `MediaLibraryScreen({this.pickMode = false})`; route extra `MediaLibraryScreenArgs(pickMode: bool)`.
- `Scaffold key: Key('mediaLibraryScreen')`, app bar "Captured media".
- Grid of `CapturedMedia` thumbnails (`capturedMediaListProvider`); per-item:
  - `Key('mediaItem_${m.id}')`
  - select-mode checkbox `Key('mediaCheckbox_${m.id}')`
  - manage-mode delete `Key('mediaDelete_${m.id}')`
  - GPS + verified badges as in §3.8
- Empty state `Key('mediaLibraryEmptyState')` ("No captured photos yet").
- App bar actions: `Key('mediaSelectModeButton')` (enter select), in select mode:
  `Key('mediaSelectAllButton')`, `Key('mediaDeleteSelectedButton')`, `Key('mediaSelectModeDoneButton')`.
  Batch-delete confirm dialog reuses the drafts pattern with `Key('confirmDeleteMediaButton')`.
- Pick mode (opened from compose): tapping an item toggles selection; footer
  `FilledButton` `Key('addSelectedMediaButton')` → `context.pop(selectedMediaList)`.
- Delete semantics: selected items with `remoteMediaId != null` → `MediaService.deleteMedia` (best-effort);
  on 409 keep the record + snackbar "Attached to a published report"; on success remove locally via the store.

### 3.10 Route — `app/lib/core/router/`
- `RoutePaths.capturedMedia = '/captured-media'`
- `app_router.dart`: `GoRoute(path: RoutePaths.capturedMedia, parentNavigatorKey: rootNavigatorKey,
  builder: ...)` reading `state.extra is MediaLibraryScreenArgs` → `MediaLibraryScreen(pickMode: args.pickMode)`.

---

## 4. User-journey E2E test plan

### Backend (pytest-asyncio, `backend/tests/features/media/`)
`test_media_delete.py`
1. `test_user_can_soft_delete_own_media` — auth upload (in-app + coords) → `DELETE /api/v1/media/{id}` → 200
   `{"success": True}`; DB row `deleted_at` set; file still served by GET `/files/...` (soft delete).
2. `test_delete_missing_media_returns_404` — random uuid → 404.
3. `test_delete_other_users_media_returns_403` — user A uploads, user B deletes → 403.
4. `test_delete_guest_media_returns_403_guest_restricted` — guest uploads, guest deletes → 403.
5. `test_delete_without_auth_returns_401`.
6. `test_delete_media_linked_to_published_issue_returns_409` — upload 2, create issue with those
   `media_urls`, `DELETE` each → 409 `media_linked_to_issue`.

`test_media_exif_gps.py`
7. `test_embed_exif_gps_writes_gpsinfo` (unit) — round-trip through PIL; GPSInfo tag 34853 present, coords
   within 1e-6 tolerance of input.
8. `test_upload_with_coords_embeds_gps_exif` — upload with `captured_lat/lng`; `GET /files/{filename}` bytes
   contain GPSInfo.
9. `test_upload_without_coords_has_no_gps_exif` — GPSInfo absent.
10. `test_captured_at_echoed_in_response` — upload with `captured_at` ISO string → response `captured_at` matches.

`test_media_issue_link.py`
11. `test_issue_links_uploaded_media` — upload 2 media; create issue with `media_urls`; assert both
    `Media.issue_id == issue.id` (query via `Media` model); follow-up `DELETE` → 409 (proves linkage).
12. `test_issue_without_media_links_nothing`.

Existing `test_media_pipeline_extended.py` and `test_media_seed_and_demo.py` must remain green (new fields are nullable).

### Flutter (widget tests, `app/test/features/compose/`)
Override `capturedMediaStoreProvider`/`capturedMediaListProvider` and `mediaServiceProvider` with in-memory fakes
(mirror the `MemoryLocalStore` + `FakeFeedRepository` pattern in `compose_outbox_fuzz_shield_test.dart`; add a
`FakeMediaService` recording `uploadMedia`/`deleteMedia` calls).

`captured_media_library_test.dart`
- Library lists captured images; empty state shows `mediaLibraryEmptyState`.
- Single delete → confirm `confirmDeleteMediaButton` → store removes item.
- Enter select mode → `mediaSelectAllButton` → `mediaDeleteSelectedButton` → confirm → batch removed.
- Pick mode: select 2 → `addSelectedMediaButton` → `Navigator.pop` returns exactly those 2 `CapturedMedia`.

`gallery_disabled_test.dart`
- Compose screen renders; `find.byKey(Key('openGalleryButton'))` findsNothing.
- `CameraViewfinder` renders; `find.byKey(Key('galleryPickerButton'))` findsNothing.
- Assert no `ImagePicker` call path remains (import removed from both files).

`captured_media_auto_save_test.dart`
- Capture (via `CapturedMediaStore.save` simulating the shutter handler) → `ComposeController.discard()` →
  store still contains the item (un-published capture persists, req #5).
- Capture with GPS → record has `isVerified == true` + coords; capture without GPS → `isVerified == false`.

`compose_publish_metadata_test.dart`
- Seed `ComposeController.submit(media: [CapturedMedia(bytesBase64: ..., capturedLat: 19.11, capturedLng: 72.87, capturedAt: t)])`
  → fake `MediaService.uploadMedia` received `capturedLat/Lng/capturedAt` and `isInAppCamera: true`;
  fake `FeedRepository.createIssue` received `latitude: 19.11, longitude: 72.87` and the uploaded URL.
- Draft-location precedence: media without GPS → issue coords fall back to `draft.latitude/longitude`.

`offline_outbox_media_test.dart`
- Enqueue draft with 2 `CapturedMedia`; `flush()` with fake service/repo → both uploaded with metadata,
  `createIssue` receives both URLs + capture coords; queue drained to empty.
- Update the existing `compose_outbox_fuzz_shield_test.dart` constructor call to the 3-arg
  `OfflineOutboxQueue(store, fakeRepo, fakeMediaService)`.

### Map update acceptance (manual/integration note)
- Widget test asserts `ref.invalidate(mapPinsNotifierProvider)` is triggered on publish success (compose already
  does this — keep the assertion if present in an existing test); outbox flush invalidation is covered by the
  `outbox_screen` one-liner (verify via `flutter analyze` + existing outbox tests).

---

## 5. Edge cases

- **No GPS lock**: capture yields `capturedLat/Lng == null` → `isVerified == false`, no EXIF written, media
  still auto-saved; issue coords fall back to draft lock → feed reference point. Library shows `gps_off` badge.
- **Offline capture / no publish**: capture is persisted to the local library instantly (Hive, no network);
  publishing offline enqueues the draft with `media` embedded (bytes + coords) so `flush()` re-uploads images —
  fixing today's image-loss bug.
- **Camera hardware absent**: `_initializeCamera` catch keeps `_cameras = []` and shows "No cameras available";
  `_triggerShutter` emits the existing dummy-byte fallback (do not regress). Gallery button is gone, so there is
  no alternative picker — the 4-slot cap snackbar and empty-state messaging guide the user.
- **Max media count**: compose enforces 4 (slot guard + snackbar); library itself is uncapped (storage concern:
  bytes kept as base64 in the drafts Hive box — recommend cap of 50 records, evict oldest, note as a follow-up).
- **Duplicate media hash**: backend already dedupes by `derived_hash` per (bytes, user_id) only for
  verification; the library de-dupes by `bytesBase64` on `save` (replace-in-place) to avoid ghost duplicates.
- **Delete-after-publish semantics**: `DELETE /media/{id}` returns 409 when `Media.issue_id` is set on a live
  issue — the library keeps the local record and informs the user; deleting an issue (existing soft-delete
  `is_hidden`) makes its media deletable (issue considered dead).
- **Legacy persisted drafts**: old JSON carries `mediaBytes`; `ComposeDraft.fromJson` ignores it → draft opens
  with zero media (no crash). Re-saving rewrites with the new `media` shape.
- **Fuzzing**: `is_fuzzed` continues to round stored media + issue coords to 2 dp server-side; client always
  sends the real captured coords and lets the backend fuzz.

---

## 6. Ordering & dependencies

1. **Freezed model first**: create `CapturedMedia`, then change `ComposeDraft` → `dart run build_runner build`
   (regenerates `compose_draft.freezed.dart/.g.dart` + new `captured_media.*`). Everything else depends on this.
2. **Backend model/schema/service/router + alembic migration** must land before the Flutter `deleteMedia`
   call and the media→issue linkage tests.
3. **Map invalidation on outbox flush** is a one-line coordinated change in `app/lib/features/outbox/...`
   (outbox feature). The map rendering pipeline (`app/lib/features/map/**`) is NOT modified; coordinate with
   the map-feature agent only to avoid editing the same file. The new pin appears because the issue's
   `latitude/longitude` is now the capture location — no geo-service change.
4. **Existing-test ripple**: `OfflineOutboxQueue` constructor gains a `MediaService` arg → the test agent must
   update `compose_outbox_fuzz_shield_test.dart` (and any other construction site) to pass a fake.
5. **Per-image pins are out of scope**: a single issue still renders one map pin at the primary capture
   location; per-media locations live in the `Media` table (available for a future admin/photo-level view).
6. **`flutter analyze` clean + `dart format`**; backend **ruff (line-length 100)** + **mypy strict** must pass.
