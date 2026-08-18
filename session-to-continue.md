# Overhaul issue reporting: map, heatmap, roles, UI

**Session ID:** ses_feaea5fa4ffe337vrZ9m1rJAOG
**Created:** 8/18/2026, 7:05:33 PM
**Updated:** 8/18/2026, 7:52:44 PM

---

## User

the Complete map, and issue reporting flow has flawes, first when a user uploads a issue then the location should be added in the metadata of the image by default the user uploading photos from gallery should strictly be not allowed, there should be a seperate space where user could only pick images which are clicked by the application, those images should be displayed in seprerate section, also where the images has been clicked should be updated in map, the map doesn't update at all, Also there is need of changing the heatmap from concentric ciricles, to something which is like painting the area, the current map of ward only shows a button, and a circle, that should be replace to marking the boundaries on the map, by getting appropriate data from the net, if any confution assign something meaning full, there is no ward details page, there is need of a sperate accounts for the people who are reponsible to solve the issues there account should have different display, like the number of issues resolved, how many issues pending, and more so people could view whether the repsentatives are actually doing there job or not, the search is still no working, I always shows Search unavailable, in the front end, there is need for, a better options to make the issues page more attractive instead of cluttered with information, there should be a better ui and options in adding the issues, make sure even if the image is not uploaded once it is clicked it should be saved in some space, that space should allow to delete the media, a group select, the profile page needs a better view,

Spawn as many agents as you could, write test from start to end, that os user using the app, to verifying things are reflting in backend, frontend, use a different agent to spawn test, first, for each feature spawn a plan, then a code, then a test sub agent, give them correct context, and pass the result of plan to code, the test should be indepentdent, only give important information, to avoid bias, only give relevant context to other subagents to avoid context posioning

---

## Assistant (Build · DeepSeek V4 Flash Free · 7.1s)

_Thinking:_

The user is describing a large set of changes to their LocalLens application. Let me understand what they want:

1. **Issue reporting flow fixes:**
   - When a user uploads an issue, the location should be added to the image metadata by default
   - Gallery photo uploads should strictly not be allowed
   - Separate space where users can only pick images clicked by the application (camera)
   - Those images should be displayed in a separate section
   - Where images were clicked should be updated on the map - map doesn't update at all
   - Change heatmap from concentric circles to "painting the area" style
   - Current map of ward only shows a button and circle - should be replaced with marking boundaries on the map from net data
   - No ward details page - need one
   - Separate accounts for people responsible for solving issues, different display - number of issues resolved, pending, etc. so people can view if representatives are doing their job
   - Search still not working - shows "Search unavailable" in frontend
   - Better options to make issues page more attractive instead of cluttered
   - Better UI and options for adding issues
   - If image is not uploaded once clicked, it should be saved in some space
   - That space should allow deleting media
   - Group select
   - Profile page needs better view

2. **Process request:**
   - Spawn as many agents as possible
   - Write tests from start to end - user using the app to verifying things reflect in backend/frontend
   - Use a different agent to spawn tests
   - First for each feature: spawn a plan agent, then code agent, then test sub-agent
   - Pass plan result to code
   - Tests should be independent, only give important info to avoid bias
   - Only give relevant context to subagents to avoid context poisoning

This is a big task. Let me first explore the codebase to understand what exists.

Given the SDD harness in this repo (AGENTS.md describes a strict Spec-Driven Development pipeline), I should be careful. But the user is asking me to spawn agents directly for planning/coding/testing.

Let me first understand the codebase structure. Let me check pipeline status and explore the repo.

Let me start by exploring the codebase and understanding the current state.

Let me look at the repo structure first.

**Tool: sdd_sdd_pipeline_status**

**Input:**
```json
{}
```

**Tool: bash**

**Input:**
```json
{
  "command": "ls -la"
}
```

**Output:**
```
total 1352
drwxr-xr-x@ 30 rohit  staff     960 17 Aug 15:05 .
drwx------@ 26 rohit  staff     832  9 Aug 02:23 ..
drwxr-xr-x@ 18 rohit  staff     576 10 Aug 17:54 .agents
drwxr-xr-x@  4 rohit  staff     128  9 Aug 02:39 .antigravity
drwxr-xr-x@  5 rohit  staff     160  9 Aug 02:37 .claude
-rw-r--r--@  1 rohit  staff   14340 18 Aug 15:57 .DS_Store
drwxr-xr-x@ 16 rohit  staff     512 18 Aug 18:11 .git
-rw-r--r--@  1 rohit  staff     832 11 Aug 12:46 .gitignore
-rw-r--r--@  1 rohit  staff     134  9 Aug 02:37 .mcp.json
drwxr-xr-x@  6 rohit  staff     192 10 Aug 19:48 .mypy_cache
drwxr-xr-x@ 10 rohit  staff     320 16 Aug 00:31 .opencode
drwxr-xr-x@  6 rohit  staff     192 11 Aug 01:28 .pytest_cache
drwxr-xr-x@  6 rohit  staff     192 10 Aug 01:09 .ruff_cache
drwxr-xr-x@  5 rohit  staff     160 11 Aug 01:15 .sdd
-rw-r--r--@  1 rohit  staff     315 11 Aug 00:45 .sdd-locks.json
-rw-r--r--@  1 rohit  staff    2452  9 Aug 02:36 AGENTS.md
drwxr-xr-x@ 22 rohit  staff     704 18 Aug 16:03 app
drwxr-xr-x@ 19 rohit  staff     608 18 Aug 18:43 backend
drwxr-xr-x@ 12 rohit  staff     384 16 Aug 01:27 docs
-rw-r--r--@  1 rohit  staff   14930  9 Aug 12:20 LocalLens_App_Info.md
-rw-r--r--@  1 rohit  staff   34455 17 Aug 15:05 LocalLens_Feature_Checklist.md
-rw-r--r--@  1 rohit  staff  344064 16 Aug 12:58 locallens.db
drwxr-xr-x@  4 rohit  staff     128 11 Aug 12:46 logs
-rw-r--r--@  1 rohit  staff    1302 17 Aug 15:05 Makefile
-rw-r--r--@  1 rohit  staff     605  9 Aug 02:33 opencode.json
-rw-r--r--@  1 rohit  staff   19547  9 Aug 12:08 rbl_extracted.txt
-rw-r--r--@  1 rohit  staff  172871 27 Apr 12:57 RBL.pdf
-rw-r--r--@  1 rohit  staff    5270 17 Aug 15:05 README.md
drwxr-xr-x@  5 rohit  staff     160 16 Aug 19:53 seed
drwxr-xr-x@  5 rohit  staff     160 11 Aug 13:05 uploads

```

**Tool: glob**

**Input:**
```json
{
  "pattern": "**/*"
}
```

**Output:**
```
/Users/rohit/Desktop/Python/LocalLens/LocalLens_Feature_Checklist.md
/Users/rohit/Desktop/Python/LocalLens/.antigravity/plugin/skills/code.md
/Users/rohit/Desktop/Python/LocalLens/.antigravity/plugin/skills/generate-spec.md
/Users/rohit/Desktop/Python/LocalLens/.antigravity/plugin/skills/run-loop.md
/Users/rohit/Desktop/Python/LocalLens/.antigravity/plugin/skills/approve-spec.md
/Users/rohit/Desktop/Python/LocalLens/.antigravity/plugin/skills/approve-tech-spec.md
/Users/rohit/Desktop/Python/LocalLens/.antigravity/plugin/skills/generate-tests.md
/Users/rohit/Desktop/Python/LocalLens/.antigravity/plugin/skills/request-change.md
/Users/rohit/Desktop/Python/LocalLens/.antigravity/plugin/skills/architect.md
/Users/rohit/Desktop/Python/LocalLens/.antigravity/plugin/skills/extract-interfaces.md
/Users/rohit/Desktop/Python/LocalLens/.antigravity/plugin/rules/SDD_RULES.md
/Users/rohit/Desktop/Python/LocalLens/.antigravity/plugin/hooks.json
/Users/rohit/Desktop/Python/LocalLens/.antigravity/plugin/plugin.json
/Users/rohit/Desktop/Python/LocalLens/.antigravity/plugin/agents/interface-bridge.md
/Users/rohit/Desktop/Python/LocalLens/.antigravity/plugin/agents/qa-planner.md
/Users/rohit/Desktop/Python/LocalLens/.antigravity/plugin/agents/coder.md
/Users/rohit/Desktop/Python/LocalLens/.antigravity/plugin/agents/runner.md
/Users/rohit/Desktop/Python/LocalLens/.antigravity/plugin/agents/product-manager.md
/Users/rohit/Desktop/Python/LocalLens/.antigravity/plugin/agents/change-manager.md
/Users/rohit/Desktop/Python/LocalLens/.antigravity/plugin/agents/architect.md
/Users/rohit/Desktop/Python/LocalLens/.antigravity/plugin/agents/test-engineer.md
/Users/rohit/Desktop/Python/LocalLens/.antigravity/plugin/agents/indexer.md
/Users/rohit/Desktop/Python/LocalLens/.antigravity/plugin/mcp_config.json
/Users/rohit/Desktop/Python/LocalLens/.antigravity/config.json
/Users/rohit/Desktop/Python/LocalLens/LocalLens_App_Info.md
/Users/rohit/Desktop/Python/LocalLens/AGENTS.md
/Users/rohit/Desktop/Python/LocalLens/opencode.json
/Users/rohit/Desktop/Python/LocalLens/.gitignore
/Users/rohit/Desktop/Python/LocalLens/.mypy_cache/.gitignore
/Users/rohit/Desktop/Python/LocalLens/.mypy_cache/3.12/cache.2.db
/Users/rohit/Desktop/Python/LocalLens/.mypy_cache/3.12/cache.6.db
/Users/rohit/Desktop/Python/LocalLens/.mypy_cache/3.12/cache.7.db
/Users/rohit/Desktop/Python/LocalLens/.mypy_cache/3.12/cache.3.db
/Users/rohit/Desktop/Python/LocalLens/.mypy_cache/3.12/cache.8.db
/Users/rohit/Desktop/Python/LocalLens/.mypy_cache/3.12/cache.11.db
/Users/rohit/Desktop/Python/LocalLens/.mypy_cache/3.12/cache.15.db
/Users/rohit/Desktop/Python/LocalLens/.mypy_cache/3.12/cache.14.db
/Users/rohit/Desktop/Python/LocalLens/.mypy_cache/3.12/cache.9.db
/Users/rohit/Desktop/Python/LocalLens/.mypy_cache/3.12/cache.10.db
/Users/rohit/Desktop/Python/LocalLens/.mypy_cache/3.12/cache.13.db
/Users/rohit/Desktop/Python/LocalLens/.mypy_cache/3.12/cache.12.db
/Users/rohit/Desktop/Python/LocalLens/.mypy_cache/3.12/cache.4.db
/Users/rohit/Desktop/Python/LocalLens/.mypy_cache/3.12/cache.0.db
/Users/rohit/Desktop/Python/LocalLens/.mypy_cache/3.12/cache.1.db
/Users/rohit/Desktop/Python/LocalLens/.mypy_cache/3.12/cache.5.db
/Users/rohit/Desktop/Python/LocalLens/.mypy_cache/CACHEDIR.TAG
/Users/rohit/Desktop/Python/LocalLens/.mypy_cache/missing_stubs
/Users/rohit/Desktop/Python/LocalLens/.sdd/bin/install-antigravity.sh
/Users/rohit/Desktop/Python/LocalLens/.sdd/bin/interface_extractor.py
/Users/rohit/Desktop/Python/LocalLens/.sdd/bin/sdd_mcp.py
/Users/rohit/Desktop/Python/LocalLens/.sdd/bin/hook_common.py
/Users/rohit/Desktop/Python/LocalLens/.sdd/bin/__pycache__/hook_common.cpython-312.pyc
/Users/rohit/Desktop/Python/LocalLens/.sdd/bin/__pycache__/interface_extractor.cpython-312.pyc
/Users/rohit/Desktop/Python/LocalLens/.sdd/bin/__pycache__/hook_common.cpython-314.pyc
/Users/rohit/Desktop/Python/LocalLens/.sdd/bin/__pycache__/interface_extractor.cpython-314.pyc
/Users/rohit/Desktop/Python/LocalLens/.sdd/bin/__pycache__/hooks.cpython-312.pyc
/Users/rohit/Desktop/Python/LocalLens/.sdd/bin/__pycache__/sdd_mcp.cpython-312.pyc
/Users/rohit/Desktop/Python/LocalLens/.sdd/bin/__pycache__/repo_indexer.cpython-312.pyc
/Users/rohit/Desktop/Python/LocalLens/.sdd/bin/__pycache__/sdd.cpython-312.pyc
/Users/rohit/Desktop/Python/LocalLens/.sdd/bin/sdd.py
/Users/rohit/Desktop/Python/LocalLens/.sdd/bin/repo_indexer.py
/Users/rohit/Desktop/Python/LocalLens/.sdd/bin/hooks.py
/Users/rohit/Desktop/Python/LocalLens/.sdd/state.json
/Users/rohit/Desktop/Python/LocalLens/logs/audit.jsonl
/Users/rohit/Desktop/Python/LocalLens/logs/.gitkeep
/Users/rohit/Desktop/Python/LocalLens/README.md
/Users/rohit/Desktop/Python/LocalLens/.sdd-locks.json
/Users/rohit/Desktop/Python/LocalLens/docs/1_spec.md
/Users/rohit/Desktop/Python/LocalLens/docs/3_test_plan.md
/Users/rohit/Desktop/Python/LocalLens/docs/FEATURE_INDEX.md
/Users/rohit/Desktop/Python/LocalLens/docs/0_repo_index.json
/Users/rohit/Desktop/Python/LocalLens/docs/UIUX_Review_LocalLens.md
/Users/rohit/Desktop/Python/LocalLens/docs/code_quality_report.md
/Users/rohit/Desktop/Python/LocalLens/docs/specs/F-08_search_contracts.md
/Users/rohit/Desktop/Python/LocalLens/docs/specs/F-11_validation.md
/Users/rohit/Desktop/Python/LocalLens/docs/specs/F-09-WARD_contracts.md
/Users/rohit/Desktop/Python/LocalLens/docs/specs/F-08_filters_contracts.md
/Users/rohit/Desktop/Python/LocalLens/docs/specs/F-12_gamification_validation.md
/Users/rohit/Desktop/Python/LocalLens/docs/specs/F-08_search_test_plan.md
/Users/rohit/Desktop/Python/LocalLens/docs/specs/F-14_flagging_validation.md
/Users/rohit/Desktop/Python/LocalLens/docs/specs/F-09-WARD_validation.md
/Users/rohit/Desktop/Python/LocalLens/docs/specs/F-02_email_auth_guest_mode_spec.md
/Users/rohit/Desktop/Python/LocalLens/docs/specs/F-14_flagging_contracts.md
/Users/rohit/Desktop/Python/LocalLens/docs/specs/F-08_filters_validation.md
/Users/rohit/Desktop/Python/LocalLens/docs/specs/F-08_search_spec.md
/Users/rohit/Desktop/Python/LocalLens/docs/specs/F-12_gamification_contracts.md
/Users/rohit/Desktop/Python/LocalLens/docs/specs/F-08_search_validation.md
/Users/rohit/Desktop/Python/LocalLens/docs/specs/F-03_contracts.md
/Users/rohit/Desktop/Python/LocalLens/docs/specs/F-11_contracts.md
/Users/rohit/Desktop/Python/LocalLens/docs/specs/F-03_validation.md
/Users/rohit/Desktop/Python/LocalLens/docs/4_interfaces.json
/Users/rohit/Desktop/Python/LocalLens/docs/feature_index.json
/Users/rohit/Desktop/Python/LocalLens/docs/2_tech_spec.md
/Users/rohit/Desktop/Python/LocalLens/backend/.env.example
/Users/rohit/Desktop/Python/LocalLens/backend/alembic/README
/Users/rohit/Desktop/Python/LocalLens/backend/alembic/__pycache__/env.cpython-312.pyc
/Users/rohit/Desktop/Python/LocalLens/backend/alembic/versions/3dded8bbe33a_add_is_verified_and_ward_to_users.py
/Users/rohit/Desktop/Python/LocalLens/backend/alembic/versions/b2c3d4e5f607_add_profile_change_limit_fields_to_users.py
/Users/rohit/Desktop/Python/LocalLens/backend/alembic/versions/d5e4694e6dba_add_geohash_quorum_and_escalation_fields.py
/Users/rohit/Desktop/Python/LocalLens/backend/alembic/versions/fc2945538d6e_add_media_columns_to_issues.py

(Results are truncated: showing first 100 results. Consider using a more specific path or pattern.)
```

---

## Assistant (Build · DeepSeek V4 Flash Free · 3.0s)

_Thinking:_

Let me explore the backend and app structure to understand the codebase. Let me look at the directory structures.

**Tool: bash**

**Input:**
```json
{
  "command": "ls -la backend && echo \"---\" && ls -la app && echo \"---\" && ls -la backend/app 2>/dev/null; echo \"---\"; ls -la app/lib 2>/dev/null"
}
```

**Output:**
```
total 1480
drwxr-xr-x@ 19 rohit  staff     608 18 Aug 18:43 .
drwxr-xr-x@ 30 rohit  staff     960 17 Aug 15:05 ..
-rw-r--r--@  1 rohit  staff     269 11 Aug 11:40 .env
-rw-r--r--@  1 rohit  staff     263  9 Aug 12:34 .env.example
drwxr-xr-x@  5 rohit  staff     160 17 Aug 14:50 .mypy_cache
drwxr-xr-x@  6 rohit  staff     192  9 Aug 12:37 .pytest_cache
-rw-r--r--@  1 rohit  staff       5  9 Aug 12:33 .python-version
drwxr-xr-x@  6 rohit  staff     192  9 Aug 13:19 .ruff_cache
drwxr-xr-x@  9 rohit  staff     288  9 Aug 12:33 .venv
drwxr-xr-x@  7 rohit  staff     224  9 Aug 12:40 alembic
-rw-r--r--@  1 rohit  staff    5008  9 Aug 12:39 alembic.ini
drwxr-xr-x@  8 rohit  staff     256 11 Aug 23:09 app
-rw-r--r--@  1 rohit  staff  380928 18 Aug 18:42 locallens.db
-rw-r--r--@  1 rohit  staff    1121 16 Aug 12:28 pyproject.toml
-rw-r--r--@  1 rohit  staff    2144  9 Aug 12:37 README.md
-rw-r--r--@  1 rohit  staff   24139 17 Aug 13:09 seed.py
drwxr-xr-x@ 17 rohit  staff     544 17 Aug 15:07 tests
drwxr-xr-x@  3 rohit  staff      96 11 Aug 02:00 uploads
-rw-r--r--@  1 rohit  staff  281593 16 Aug 12:28 uv.lock
---
total 184
drwxr-xr-x@ 22 rohit  staff    704 18 Aug 16:03 .
drwxr-xr-x@ 30 rohit  staff    960 17 Aug 15:05 ..
drwxr-xr-x@ 14 rohit  staff    448 18 Aug 16:03 .dart_tool
-rw-r--r--@  1 rohit  staff  10244 10 Aug 23:22 .DS_Store
-rw-r--r--@  1 rohit  staff   9309 16 Aug 01:34 .flutter-plugins-dependencies
-rw-r--r--@  1 rohit  staff    703  9 Aug 12:40 .gitignore
drwxr-xr-x@  6 rohit  staff    192  9 Aug 12:40 .idea
-rw-r--r--@  1 rohit  staff   1262  9 Aug 12:40 .metadata
-rw-r--r--@  1 rohit  staff   1420  9 Aug 12:40 analysis_options.yaml
drwxr-xr-x@ 12 rohit  staff    384  9 Aug 12:40 android
drwxr-xr-x@ 11 rohit  staff    352 18 Aug 16:03 build
-rw-r--r--@  1 rohit  staff    201 18 Aug 16:04 devtools_options.yaml
drwxr-xr-x@  9 rohit  staff    288 10 Aug 23:21 ios
drwxr-xr-x@  7 rohit  staff    224  9 Aug 12:55 lib
-rw-r--r--@  1 rohit  staff    842  9 Aug 12:40 local_lens.iml
drwxr-xr-x@  8 rohit  staff    256  9 Aug 12:40 macos
-rw-r--r--@  1 rohit  staff  35230 16 Aug 01:34 pubspec.lock
-rw-r--r--@  1 rohit  staff    802 16 Aug 01:34 pubspec.yaml
-rw-r--r--@  1 rohit  staff    632  9 Aug 12:40 README.md
drwxr-xr-x@  6 rohit  staff    192 17 Aug 15:05 test
-rw-r--r--@  1 rohit  staff   1564 10 Aug 15:41 test_scratch_debug_test.dart
drwxr-xr-x@  3 rohit  staff     96 11 Aug 14:36 tool
---
total 8
-rw-r--r--@  1 rohit  staff     0  9 Aug 12:35 __init__.py
drwxr-xr-x@  5 rohit  staff   160 11 Aug 23:27 __pycache__
drwxr-xr-x@  8 rohit  staff   256 11 Aug 23:09 .
drwxr-xr-x@ 19 rohit  staff   608 18 Aug 18:43 ..
drwxr-xr-x@  7 rohit  staff   224  9 Aug 12:37 api
drwxr-xr-x@  9 rohit  staff   288 11 Aug 23:09 core
drwxr-xr-x@ 14 rohit  staff   448 11 Aug 01:42 features
-rw-r--r--@  1 rohit  staff  2411 11 Aug 23:09 main.py
---
total 16
drwxr-xr-x@  7 rohit  staff   224  9 Aug 12:55 .
drwxr-xr-x@ 22 rohit  staff   704 18 Aug 16:03 ..
-rw-r--r--@  1 rohit  staff  1300 11 Aug 02:19 app.dart
drwxr-xr-x@ 11 rohit  staff   352 16 Aug 00:00 core
drwxr-xr-x@ 20 rohit  staff   640 16 Aug 14:10 features
-rw-r--r--@  1 rohit  staff   762  9 Aug 15:24 main.dart
drwxr-xr-x@  3 rohit  staff    96  9 Aug 12:43 shared

```

**Tool: read**

**Input:**
```json
{
  "filePath": "/Users/rohit/Desktop/Python/LocalLens/.sdd/state.json"
}
```

**Output:**
```
<path>/Users/rohit/Desktop/Python/LocalLens/.sdd/state.json</path>
<type>file</type>
<content>
1: {
2:   "version": 1,
3:   "loop_cap": 5,
4:   "loop_count": 0,
5:   "loop_open": false,
6:   "harness": null,
7:   "phases": {
8:     "0_repo_index": {
9:       "status": "done",
10:       "updated_at": "2026-08-10T09:15:31+00:00",
11:       "depends_on": []
12:     },
13:     "1_spec": {
14:       "status": "done",
15:       "updated_at": "2026-08-10T14:55:01+00:00",
16:       "depends_on": [
17:         "0_repo_index"
18:       ]
19:     },
20:     "2_tech_spec": {
21:       "status": "done",
22:       "updated_at": "2026-08-10T18:42:47+00:00",
23:       "depends_on": [
24:         "1_spec",
25:         "0_repo_index"
26:       ]
27:     },
28:     "3_test_plan": {
29:       "status": "pending",
30:       "updated_at": null,
31:       "depends_on": [
32:         "1_spec"
33:       ]
34:     },
35:     "4_interfaces": {
36:       "status": "done",
37:       "updated_at": "2026-08-10T19:45:05+00:00",
38:       "depends_on": [
39:         "2_tech_spec",
40:         "0_repo_index"
41:       ]
42:     },
43:     "5_code": {
44:       "status": "pending",
45:       "updated_at": null,
46:       "depends_on": [
47:         "2_tech_spec"
48:       ]
49:     },
50:     "6_tests": {
51:       "status": "pending",
52:       "updated_at": null,
53:       "depends_on": [
54:         "3_test_plan",
55:         "4_interfaces"
56:       ]
57:     },
58:     "7_run": {
59:       "status": "pending",
60:       "updated_at": null,
61:       "depends_on": [
62:         "5_code",
63:         "6_tests"
64:       ]
65:     }
66:   },
67:   "invalidations": [
68:     {
69:       "target": "2_tech_spec",
70:       "reason": "P6 tests (written verbatim from the binding P1 contract) expose exact-name drift in the locked docs/2_tech_spec.md. The architect worked only from spec+index and diverged from the P1 contract on: (backend) place must equal ward.name not 'Ward {code}, {name}'; validation-error envelope must use code/error_code keys (app_error_handler shape) not 'error'; (frontend) ReverseGeocode must be exposed from data/geo_api.dart as a FLAT model (latitude/longitude/place/wardSlug/wardName/wardCode/distanceKm/found) not a nested ward object; DeviceLocationService must live in domain/device_location_service.dart with Future<({double lat,double lng})> getCurrentCoordinates() that THROWS on error (not null); WardLocationSuccess uses named fields place/wardSlug/code; WardLocationChip is a PRESENTATIONAL widget taking state via constructor WardLocationChip({required WardLocationState state}) not a ConsumerWidget watching the provider; currentCoordinatesProvider is Provider<({double lat,double lng})> default (19.1136,72.8697); controller named WardLocationController.",
71:       "at": "2026-08-10T18:37:33+00:00",
72:       "invalidated": [
73:         "7_run",
74:         "6_tests",
75:         "5_code",
76:         "4_interfaces"
77:       ]
78:     }
79:   ],
80:   "escalations": [],
81:   "runs": {}
82: }

(End of file - total 82 lines)
</content>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "/Users/rohit/Desktop/Python/LocalLens/.sdd-locks.json"
}
```

**Output:**
```
<path>/Users/rohit/Desktop/Python/LocalLens/.sdd-locks.json</path>
<type>file</type>
<content>
1: {
2:   "version": 1,
3:   "locks": {
4:     "docs/1_spec.md": {
5:       "locked_at": "2026-08-10T14:55:01+00:00",
6:       "approved_by": "user",
7:       "change_request": null
8:     },
9:     "docs/2_tech_spec.md": {
10:       "locked_at": "2026-08-10T18:42:47+00:00",
11:       "approved_by": "user",
12:       "change_request": null
13:     }
14:   }
15: }

(End of file - total 15 lines)
</content>
```

---

## Assistant (Build · DeepSeek V4 Flash Free · 2.8s)

_Thinking:_

This is a Flutter + FastAPI (Python) app with an SDD harness. The user is asking me to spawn agents (plan, code, test) for a series of features. Let me understand the current codebase structure more before planning.

Let me explore the backend and app structures in detail.

**Tool: bash**

**Input:**
```json
{
  "command": "find backend/app -type f -name \"*.py\" | head -60 && echo \"---BACKEND TESTS---\" && find backend/tests -type f | head -40 && echo \"---APP LIB---\" && find app/lib -type f -name \"*.dart\" | head -100 && echo \"---APP TESTS---\" && find app/test -type f | head -60"
}
```

**Output:**
```
backend/app/core/logging.py
backend/app/core/config.py
backend/app/core/database.py
backend/app/core/security.py
backend/app/core/ratelimit.py
backend/app/core/exceptions.py
backend/app/features/representatives/service.py
backend/app/features/representatives/models.py
backend/app/features/representatives/__init__.py
backend/app/features/representatives/schemas.py
backend/app/features/representatives/router.py
backend/app/features/auth/service.py
backend/app/features/auth/models.py
backend/app/features/auth/__init__.py
backend/app/features/auth/schemas.py
backend/app/features/auth/router.py
backend/app/features/wards/service.py
backend/app/features/wards/models.py
backend/app/features/wards/__init__.py
backend/app/features/wards/schemas.py
backend/app/features/wards/router.py
backend/app/features/gamification/service.py
backend/app/features/gamification/models.py
backend/app/features/gamification/__init__.py
backend/app/features/gamification/schemas.py
backend/app/features/gamification/router.py
backend/app/features/geo/service.py
backend/app/features/geo/__init__.py
backend/app/features/geo/schemas.py
backend/app/features/geo/router.py
backend/app/features/__init__.py
backend/app/features/search/service.py
backend/app/features/search/__init__.py
backend/app/features/search/router.py
backend/app/features/feed/service.py
backend/app/features/feed/__init__.py
backend/app/features/feed/schemas.py
backend/app/features/feed/router.py
backend/app/features/issues/geo.py
backend/app/features/issues/service.py
backend/app/features/issues/models.py
backend/app/features/issues/__init__.py
backend/app/features/issues/schemas.py
backend/app/features/issues/geohash.py
backend/app/features/issues/router.py
backend/app/features/notifications/service.py
backend/app/features/notifications/models.py
backend/app/features/notifications/schemas.py
backend/app/features/notifications/router.py
backend/app/features/media/service.py
backend/app/features/media/models.py
backend/app/features/media/__init__.py
backend/app/features/media/schemas.py
backend/app/features/media/router.py
backend/app/__init__.py
backend/app/api/deps.py
backend/app/api/health.py
backend/app/api/__init__.py
backend/app/api/router.py
backend/app/main.py
---BACKEND TESTS---
backend/tests/test_reverse_geocode.py
backend/tests/conftest.py
backend/tests/test_profile_change_limits.py
backend/tests/test_upvote_proximity_ratelimit.py
backend/tests/test_issues_geohash_duplicate.py
backend/tests/features/representatives/__pycache__/test_representatives.cpython-312-pytest-9.1.1.pyc
backend/tests/features/representatives/test_representatives.py
backend/tests/features/auth/test_user_public_profile_and_my_issues.py
backend/tests/features/auth/test_auth.py
backend/tests/features/auth/__init__.py
backend/tests/features/auth/__pycache__/test_user_public_profile_and_my_issues.cpython-312-pytest-9.1.1.pyc
backend/tests/features/auth/__pycache__/test_profile_settings.cpython-312-pytest-9.1.1.pyc
backend/tests/features/auth/__pycache__/test_email_guest_auth.cpython-312-pytest-9.1.1.pyc
backend/tests/features/auth/__pycache__/test_auth.cpython-312-pytest-9.1.1.pyc
backend/tests/features/auth/__pycache__/__init__.cpython-312.pyc
backend/tests/features/auth/test_profile_settings.py
backend/tests/features/auth/test_email_guest_auth.py
backend/tests/features/gamification/test_gamification.py
backend/tests/features/gamification/__pycache__/test_gamification.cpython-312-pytest-9.1.1.pyc
backend/tests/features/geo/test_map_pins_extended.py
backend/tests/features/geo/test_geo.py
backend/tests/features/geo/__init__.py
backend/tests/features/geo/__pycache__/test_geo.cpython-312-pytest-9.1.1.pyc
backend/tests/features/geo/__pycache__/__init__.cpython-312.pyc
backend/tests/features/geo/__pycache__/test_map_pins_extended.cpython-312-pytest-9.1.1.pyc
backend/tests/features/__init__.py
backend/tests/features/__pycache__/__init__.cpython-312.pyc
backend/tests/features/search/test_search.py
backend/tests/features/search/__pycache__/test_search_filters.cpython-312-pytest-9.1.1.pyc
backend/tests/features/search/__pycache__/test_search.cpython-312-pytest-9.1.1.pyc
backend/tests/features/search/test_search_filters.py
backend/tests/features/feed/__pycache__/test_multi_feed_talk_extended.cpython-312-pytest-9.1.1.pyc
backend/tests/features/feed/__pycache__/test_feed_and_talk.cpython-312-pytest-9.1.1.pyc
backend/tests/features/feed/test_multi_feed_talk_extended.py
backend/tests/features/feed/test_feed_and_talk.py
backend/tests/features/issues/test_upvote_toggle.py
backend/tests/features/issues/test_ward_place_page.py
backend/tests/features/issues/test_flagging.py
backend/tests/features/issues/__init__.py
backend/tests/features/issues/__pycache__/test_comments.cpython-312-pytest-9.1.1.pyc
---APP LIB---
app/lib/core/l10n/locale_provider.dart
app/lib/core/l10n/app_strings.dart
app/lib/core/config/app_config.dart
app/lib/core/config/app_config_provider.dart
app/lib/core/network/api_exceptions.dart
app/lib/core/network/offline_sync_worker.dart
app/lib/core/network/network_providers.dart
app/lib/core/network/connectivity.dart
app/lib/core/network/api_client.dart
app/lib/core/utils/media_url.dart
app/lib/core/utils/profile_navigation.dart
app/lib/core/utils/relative_time.dart
app/lib/core/utils/string_formatters.dart
app/lib/core/feedback/error_boundary.dart
app/lib/core/feedback/app_infrastructure.dart
app/lib/core/feedback/app_messenger.dart
app/lib/core/feedback/toast_overlay.dart
app/lib/core/feedback/offline_banner.dart
app/lib/core/feedback/error_copy.dart
app/lib/core/storage/storage_providers.dart
app/lib/core/storage/local_store.dart
app/lib/core/theme/app_theme.dart
app/lib/core/theme/app_colors.dart
app/lib/core/theme/theme_provider.dart
app/lib/core/services/location_service.dart
app/lib/core/router/app_router.dart
app/lib/core/router/route_paths.dart
app/lib/features/outbox/presentation/outbox_screen.dart
app/lib/features/inbox/presentation/inbox_screen.dart
app/lib/features/issue_detail/data/issue_detail_api.dart
app/lib/features/issue_detail/presentation/screens/issue_detail_screen.dart
app/lib/features/issue_detail/presentation/issue_detail_screen.dart
app/lib/features/issue_detail/presentation/controllers/issue_detail_controller.dart
app/lib/features/issue_detail/presentation/widgets/comments_section.dart
app/lib/features/issue_detail/presentation/widgets/comment_card.dart
app/lib/features/issue_detail/presentation/widgets/official_response_card.dart
app/lib/features/issue_detail/presentation/widgets/resolution_proof_modal.dart
app/lib/features/issue_detail/presentation/widgets/audit_timeline_card.dart
app/lib/features/auth/data/auth_api.dart
app/lib/features/auth/data/auth_repository.dart
app/lib/features/auth/data/auth_mock.dart
app/lib/features/auth/domain/session.freezed.dart
app/lib/features/auth/domain/auth_repository.dart
app/lib/features/auth/domain/session.g.dart
app/lib/features/auth/domain/session.dart
app/lib/features/auth/presentation/screens/otp_screen.dart
app/lib/features/auth/presentation/screens/sign_in_screen.dart
app/lib/features/auth/presentation/auth_providers.dart
app/lib/features/auth/presentation/controllers/auth_controller.dart
app/lib/features/auth/presentation/widgets/guest_guard.dart
app/lib/features/auth/presentation/widgets/otp_field.dart
app/lib/features/gamification/data/gamification_api.dart
app/lib/features/gamification/domain/gamification_models.dart
app/lib/features/gamification/presentation/gamification_screen.dart
app/lib/features/gamification/presentation/gamification_providers.dart
app/lib/features/compose/data/media_service.dart
app/lib/features/compose/data/offline_outbox_queue.dart
app/lib/features/compose/data/hive_draft_store.dart
app/lib/features/compose/domain/near_duplicate_candidate.freezed.dart
app/lib/features/compose/domain/near_duplicate_candidate.g.dart
app/lib/features/compose/domain/compose_draft.freezed.dart
app/lib/features/compose/domain/compose_draft.dart
app/lib/features/compose/domain/draft_store.dart
app/lib/features/compose/domain/compose_draft.g.dart
app/lib/features/compose/domain/near_duplicate_candidate.dart
app/lib/features/compose/presentation/drafts_screen.dart
app/lib/features/compose/presentation/compose_screen.dart
app/lib/features/compose/presentation/compose_providers.dart
app/lib/features/compose/presentation/controllers/compose_controller.dart
app/lib/features/compose/presentation/widgets/media_watermark_badge.dart
app/lib/features/compose/presentation/widgets/camera_viewfinder.dart
app/lib/features/admin/presentation/providers/admin_flagged_queue_provider.dart
app/lib/features/admin/presentation/screens/admin_flagged_queue_screen.dart
app/lib/features/geo/data/geo_api.dart
app/lib/features/geo/domain/device_location_service.dart
app/lib/features/geo/presentation/providers/geo_providers.dart
app/lib/features/geo/presentation/widgets/ward_location_chip.dart
app/lib/features/reels/presentation/reels_providers.dart
app/lib/features/reels/presentation/reels_screen.dart
app/lib/features/search/data/recent_search_store.dart
app/lib/features/search/data/search_api.dart
app/lib/features/search/domain/search_repository.dart
app/lib/features/search/domain/search_filters.dart
app/lib/features/search/presentation/advanced_filter_sheet.dart
app/lib/features/search/presentation/search_providers.dart
app/lib/features/search/presentation/search_screen.dart
app/lib/features/search/presentation/search_filters_provider.dart
app/lib/features/map/data/map_api.dart
app/lib/features/map/presentation/map_screen.dart
app/lib/features/map/presentation/screens/map_screen.dart
app/lib/features/map/presentation/controllers/map_controller.dart
app/lib/features/map/presentation/widgets/map_pin_preview_sheet.dart
app/lib/features/profile/domain/user_profile.dart
app/lib/features/profile/domain/public_user_profile.dart
app/lib/features/profile/domain/user_settings.dart
app/lib/features/profile/presentation/profile_providers.dart
app/lib/features/profile/presentation/profile_screen.dart
app/lib/features/profile/presentation/screens/settings_screen.dart
app/lib/features/profile/presentation/screens/anonymity_guide_screen.dart
app/lib/features/profile/presentation/screens/profile_screen.dart
---APP TESTS---
app/test/helpers.dart
app/test/core/relative_time_test.dart
app/test/core/app_messenger_test.dart
app/test/core/error_boundary_test.dart
app/test/core/toast_overlay_test.dart
app/test/core/guest_signin_redirect_regression_test.dart
app/test/core/string_formatters_test.dart
app/test/core/router_test.dart
app/test/core/api_client_delete_test.dart
app/test/core/connectivity_test.dart
app/test/core/offline_banner_test.dart
app/test/core/app_infrastructure_test.dart
app/test/core/offline_sync_onboarding_extended_test.dart
app/test/core/dock_and_notifications_header_test.dart
app/test/core/offline_sync_worker_test.dart
app/test/core/deep_linking_test.dart
app/test/features/issue_detail/compact_comment_card_test.dart
app/test/features/issue_detail/comments_widget_test.dart
app/test/features/issue_detail/issue_detail_camera_and_timeline_test.dart
app/test/features/issue_detail/issue_detail_screen_test.dart
app/test/features/auth/sign_in_screen_test.dart
app/test/features/auth/email_guest_auth_test.dart
app/test/features/auth/otp_screen_test.dart
app/test/features/gamification/gamification_test.dart
app/test/features/compose/near_duplicate_30m_category_test.dart
app/test/features/compose/compose_outbox_fuzz_shield_test.dart
app/test/features/compose/camera_viewfinder_test.dart
app/test/features/compose/drafts_page_test.dart
app/test/features/compose/location_service_test.dart
app/test/features/compose/media_pipeline_extended_test.dart
app/test/features/geo/geo_security_test.dart
app/test/features/geo/geo_api_test.dart
app/test/features/geo/geo_screen_integration_test.dart
app/test/features/geo/geo_widget_test.dart
app/test/features/search/search_api_test.dart
app/test/features/search/search_filters_test.dart
app/test/features/search/search_api_filters_test.dart
app/test/features/search/search_screen_test.dart
app/test/features/map/map_modes_test.dart
app/test/features/map/map_pins_extended_test.dart
app/test/features/map/map_screen_test.dart
app/test/features/profile/profile_settings_test.dart
app/test/features/profile/profile_posts_and_public_profile_test.dart
app/test/features/profile/profile_identity_limits_test.dart
app/test/features/profile/profile_rework_test.dart
app/test/features/profile/public_profile_parsing_and_anonymity_test.dart
app/test/features/profile/fine_grained_settings_test.dart
app/test/features/onboarding_screen_test.dart
app/test/features/feed/issue_card_test.dart
app/test/features/feed/upvote_interaction_test.dart
app/test/features/feed/feed_screen_test.dart
app/test/features/feed/issue_test.dart
app/test/features/feed/multi_feed_talk_extended_test.dart
app/test/features/feed/reporter_navigation_test.dart
app/test/features/feed/upvote_toggle_core_test.dart
app/test/features/feed/media_display_and_like_toggle_test.dart
app/test/features/ward/ward_detail_screen_test.dart
app/test/features/rep_dashboard/rep_dashboard_test.dart
app/test/features/issues/flagging_widget_test.dart
app/test/features/notifications/notifications_test.dart

```

---

## Assistant (Build · DeepSeek V4 Flash Free · 9.4s)

_Thinking:_

This is a large Flutter + FastAPI app. Let me get more details on key files related to the features the user wants changed:

1. Issue reporting flow (upload issue → location in image metadata, camera-only, media management, group select)
2. Map (updating after image click, heatmap style change, ward boundaries)
3. Ward details page
4. Representative accounts/dashboard
5. Search (Search unavailable)
6. Issues page UI
7. Profile page

Let me look at the key files to understand current implementation. Let me look at the compose feature (issue creation), map feature, search, representative dashboard, profile.

Let me spawn parallel explore agents to understand the codebase efficiently, and also read the key files myself.

Given the user's instruction to spawn agents: "for each feature spawn a plan, then a code, then a test sub agent, give them correct context, and pass the result of plan to code, the test should be independent, only give important information".

So the workflow per feature:
1. Plan agent (using `general` agent) - produces a plan
2. Code agent (using `coder` agent or `general`) - implements plan
3. Test agent (using `general` or test-engineer) - writes tests

But there's a constraint: test-engineer is filesystem-denied from src. That's for the SDD pipeline. The user wants a different agent to spawn tests. I can use `general` agents for testing, or use the test-engineer. Actually the user said "use a different agent to spawn test". So I'll use general agents (or a dedicated test agent) to write tests.

But the tests should verify end-to-end: user using app → verifying things reflect in backend/frontend. So the tests need to be integration tests: backend pytest + Flutter widget/integration tests.

Let me first understand the codebase well. Let me explore key areas in parallel using explore agents while reading core files.

Let me plan the features:

**F1: Issue reporting flow / media**
- Location added to image metadata by default
- Gallery uploads strictly not allowed
- Separate space for app-clicked images (camera captures)
- Those images displayed in separate section
- Image location updates map (map doesn't update)
- Images saved even if not uploaded (draft media storage)
- Media deletion space
- Group select (multiple images?)

**F2: Heatmap / Map**
- Heatmap change from concentric circles to area painting (density shading / polygons)
- Ward map: currently shows button + circle → mark boundaries on map from net data
- Map should update after issue created

**F3: Ward details page**
- New ward details page

**F4: Representative accounts**
- Separate accounts for representatives
- Different display: issues resolved count, pending count, etc.

**F5: Search**
- Fix "Search unavailable" in frontend

**F6: Issues page UI**
- More attractive, less cluttered, better UI
- Better options in adding issues
- Group select

**F7: Profile page**
- Better view

Let me explore the codebase. I'll spawn explore agents in parallel for the key features to gather context. Actually, since the user wants minimal context poisoning and the plan→code→test flow, I should first gather enough understanding myself to give good prompts.

Let me look at the compose feature (issue creation), map, search, representatives, profile screens.

Let me read the key files.

This is a large task. Let me first understand the codebase thoroughly, then spawn the plan→code→test agent pipeline per feature. Let me explore the key areas in parallel.

**Tool: bash**

**Input:**
```json
{
  "command": "find backend/app -type f -name \"*.py\" | tail -30 && echo \"---\" && find app/lib -type f -name \"*.dart\" | tail -60"
}
```

**Output:**
```
backend/app/features/__init__.py
backend/app/features/search/service.py
backend/app/features/search/__init__.py
backend/app/features/search/router.py
backend/app/features/feed/service.py
backend/app/features/feed/__init__.py
backend/app/features/feed/schemas.py
backend/app/features/feed/router.py
backend/app/features/issues/geo.py
backend/app/features/issues/service.py
backend/app/features/issues/models.py
backend/app/features/issues/__init__.py
backend/app/features/issues/schemas.py
backend/app/features/issues/geohash.py
backend/app/features/issues/router.py
backend/app/features/notifications/service.py
backend/app/features/notifications/models.py
backend/app/features/notifications/schemas.py
backend/app/features/notifications/router.py
backend/app/features/media/service.py
backend/app/features/media/models.py
backend/app/features/media/__init__.py
backend/app/features/media/schemas.py
backend/app/features/media/router.py
backend/app/__init__.py
backend/app/api/deps.py
backend/app/api/health.py
backend/app/api/__init__.py
backend/app/api/router.py
backend/app/main.py
---
app/lib/features/profile/presentation/screens/anonymity_guide_screen.dart
app/lib/features/profile/presentation/screens/profile_screen.dart
app/lib/features/profile/presentation/screens/public_profile_screen.dart
app/lib/features/profile/presentation/screens/edit_profile_screen.dart
app/lib/features/profile/presentation/widgets/profile_avatar.dart
app/lib/features/feed/data/feed_api.dart
app/lib/features/feed/domain/feed_repository.dart
app/lib/features/feed/domain/issue.dart
app/lib/features/feed/domain/issue.freezed.dart
app/lib/features/feed/domain/notice.dart
app/lib/features/feed/domain/win.dart
app/lib/features/feed/domain/issue.g.dart
app/lib/features/feed/domain/feed_item.dart
app/lib/features/feed/presentation/feed_providers.dart
app/lib/features/feed/presentation/feed_screen.dart
app/lib/features/feed/presentation/widgets/issue_card.dart
app/lib/features/feed/presentation/widgets/local_talk_card.dart
app/lib/features/feed/presentation/widgets/win_card.dart
app/lib/features/feed/presentation/widgets/media_preview_widget.dart
app/lib/features/feed/presentation/widgets/notice_card.dart
app/lib/features/ward/data/repositories/ward_repository.dart
app/lib/features/ward/data/ward_repository.dart
app/lib/features/ward/domain/ward_detail_out.dart
app/lib/features/ward/domain/ward_representative_out.dart
app/lib/features/ward/domain/ward_detail_model.dart
app/lib/features/ward/domain/ward_summary_out.dart
app/lib/features/ward/domain/ward_list_response.dart
app/lib/features/ward/domain/local_talk_post.dart
app/lib/features/ward/presentation/ward_detail_screen.dart
app/lib/features/ward/presentation/providers/ward_providers.dart
app/lib/features/ward/presentation/ward_providers.dart
app/lib/features/ward/presentation/screens/ward_detail_screen.dart
app/lib/features/ward/presentation/widgets/ward_chip.dart
app/lib/features/ward/presentation/widgets/ward_hero_banner.dart
app/lib/features/ward/presentation/widgets/ward_rep_card.dart
app/lib/features/ward/presentation/widgets/local_talk_compose_sheet.dart
app/lib/features/ward/presentation/widgets/ward_recent_issues_list.dart
app/lib/features/ward/presentation/widgets/ward_metric_card.dart
app/lib/features/rep_dashboard/data/repositories/rep_dashboard_repository.dart
app/lib/features/rep_dashboard/domain/official_response.dart
app/lib/features/rep_dashboard/domain/ward_issues_response.dart
app/lib/features/rep_dashboard/domain/representative_profile.dart
app/lib/features/rep_dashboard/presentation/rep_dashboard_screen.dart
app/lib/features/rep_dashboard/presentation/rep_dashboard_providers.dart
app/lib/features/rep_dashboard/presentation/widgets/post_official_response_dialog.dart
app/lib/features/issues/presentation/providers/flag_issue_provider.dart
app/lib/features/issues/presentation/widgets/flag_issue_dialog.dart
app/lib/features/notifications/data/notifications_api.dart
app/lib/features/notifications/domain/notification_item.dart
app/lib/features/notifications/presentation/notifications_screen.dart
app/lib/features/notifications/presentation/controllers/notifications_controller.dart
app/lib/features/onboarding/presentation/screens/onboarding_screen.dart
app/lib/shared/widgets/status_badge.dart
app/lib/shared/widgets/skeleton_list.dart
app/lib/shared/widgets/placeholder_screen.dart
app/lib/shared/widgets/shimmer_loading.dart
app/lib/shared/widgets/empty_state.dart
app/lib/shared/widgets/media_preview_widget.dart
app/lib/main.dart
app/lib/app.dart

```

**Tool: bash**

**Input:**
```json
{
  "command": "cat backend/pyproject.toml && echo \"---PUBSPEC---\" && cat app/pubspec.yaml"
}
```

**Output:**
```
[project]
name = "locallens-backend"
version = "0.1.0"
description = "LocalLens civic engagement API"
readme = "README.md"
requires-python = ">=3.12"
dependencies = [
    "aiosqlite>=0.22.1",
    "alembic>=1.19.1",
    "bcrypt>=5.0.0",
    "fastapi>=0.141.1",
    "pillow>=12.3.0",
    "pydantic-settings>=2.15.0",
    "pyjwt>=2.13.0",
    "python-multipart>=0.0.32",
    "sqlalchemy[asyncio]>=2.0.51",
    "uvicorn[standard]>=0.52.1",
]

[dependency-groups]
dev = [
    "httpx>=0.28.1",
    "mypy>=2.3.0",
    "pytest>=9.1.1",
    "pytest-asyncio>=1.4.0",
    "ruff>=0.16.2",
]

[tool.ruff]
target-version = "py312"
line-length = 100
src = ["app", "tests"]
exclude = ["alembic"]

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B", "ASYNC", "RUF"]
ignore = ["B008", "E501"]

[tool.mypy]
python_version = "3.12"
strict = true
plugins = ["pydantic.mypy"]

[tool.pytest.ini_options]
asyncio_mode = "auto"
asyncio_default_fixture_loop_scope = "function"
testpaths = ["tests"]
pythonpath = ["."]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["app"]
---PUBSPEC---
name: local_lens
description: "Civic engagement platform for neighborhoods."
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.12.2

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_riverpod: ^2.6.1
  go_router: ^17.4.0
  dio: ^5.11.0
  connectivity_plus: ^7.1.1
  hive_ce: ^2.19.3
  hive_ce_flutter: ^2.3.4
  freezed_annotation: ^3.1.0
  json_annotation: ^4.12.0
  image_picker: ^1.2.1
  camera: ^0.11.1
  geolocator: ^13.0.4
  flutter_map: ^8.1.1
  latlong2: ^0.9.1
  share_plus: ^13.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  build_runner: ^2.15.1
  freezed: ^4.0.0-dev.3
  json_serializable: ^6.14.1
  mocktail: ^1.0.5
  fake_async: ^1.3.3

flutter:
  uses-material-design: true
```

---

## Assistant (Build · DeepSeek V4 Flash Free · 4.7s)

_Thinking:_

Let me read the key files related to each feature. Let me spawn parallel explore agents to gather detailed context about the key features while I read some core files myself.

Let me look at:
1. Compose/issue creation flow (compose_screen, compose_controller, media_service, compose_draft, hive_draft_store)
2. Map (map_screen, map_controller, map_api)
3. Search (search_screen, search_api, search_providers)
4. Rep dashboard (rep_dashboard_screen)
5. Profile (profile_screen)
6. Backend issues router/service, media, geo
7. Ward detail screen

Let me spawn several explore agents in parallel to build context. Actually, since I'll be spawning plan agents anyway and giving them context, I need the context myself to give good prompts. Let me use explore agents to get summaries, but also read key files directly.

Let me spawn 4 explore agents for the main areas. Actually, let me just read key files directly - it may be faster and more accurate. But there are many files. Let me use explore agents for breadth and read a few critical ones directly.

Let me check the git status first and the feature checklist for context on what's implemented.

**Tool: bash**

**Input:**
```json
{
  "command": "git log --oneline -10 && echo \"---\" && git status --short | head -30"
}
```

**Output:**
```
82a46e7 Rework profile page UI + add drafts, identity limits, and issue delete
0f6f79b add Uploads/media
1eea76f Fix reporter identity, feed visibility, proof images and profile redirect
1937591 Changes in feed
1fddee4 Major changes in ui, added camera option
ae8263f auth and feed bugs solved
62387ed few bugs solved
a485170 New fixes to signup
30333a0 New fixes related to feed
eeaf445 fix for comments
---
 M app/lib/core/router/app_router.dart
 M app/lib/core/services/location_service.dart
 M app/lib/core/utils/profile_navigation.dart
 M app/lib/features/compose/presentation/compose_providers.dart
 M app/lib/features/compose/presentation/compose_screen.dart
 M app/lib/features/compose/presentation/drafts_screen.dart
 M app/lib/features/feed/data/feed_api.dart
 M app/lib/features/feed/domain/feed_repository.dart
 M app/lib/features/feed/presentation/feed_screen.dart
 M app/lib/features/feed/presentation/widgets/issue_card.dart
 M app/lib/features/gamification/domain/gamification_models.dart
 M app/lib/features/geo/domain/device_location_service.dart
 M app/lib/features/issue_detail/presentation/screens/issue_detail_screen.dart
 M app/lib/features/issue_detail/presentation/widgets/comment_card.dart
 M app/lib/features/map/presentation/controllers/map_controller.dart
 M app/lib/features/map/presentation/screens/map_screen.dart
 M app/lib/features/map/presentation/widgets/map_pin_preview_sheet.dart
 M app/lib/features/profile/domain/public_user_profile.dart
 M app/lib/features/profile/presentation/profile_providers.dart
 M app/lib/features/profile/presentation/screens/public_profile_screen.dart
 M app/lib/features/profile/presentation/screens/settings_screen.dart
 M app/lib/features/reels/presentation/reels_screen.dart
 M app/lib/features/rep_dashboard/presentation/rep_dashboard_screen.dart
 M app/lib/features/search/data/search_api.dart
 M app/lib/features/search/domain/search_filters.dart
 M app/lib/features/search/domain/search_repository.dart
 M app/lib/features/search/presentation/advanced_filter_sheet.dart
 M app/lib/features/search/presentation/search_filters_provider.dart
 M app/lib/features/search/presentation/search_providers.dart
 M app/lib/features/search/presentation/search_screen.dart

```

**Tool: read**

**Input:**
```json
{
  "filePath": "/Users/rohit/Desktop/Python/LocalLens/LocalLens_Feature_Checklist.md"
}
```

**Output:**
```
<path>/Users/rohit/Desktop/Python/LocalLens/LocalLens_Feature_Checklist.md</path>
<type>file</type>
<content>
1: # LocalLens: Hyper-Granular Feature Checklist (Refined v2)
2: 
3: This document serves as the master development, QA, and AI agent tracker for the LocalLens platform. It breaks down the application into atomic, hyper-granular features covering UI/UX, Backend logic, Database schemas, Edge Cases, and Hardware integrations.
4: 
5: Legend: `(NEW)` = added in v2 · `(R)` = revised in v2 · `(X)` = removed in v2 (why).
6: 
7: ## Progress status
8: 
9: - [x] **Camera & Map Hardware Integration (2026-08-16 via F-05-CAMERA + F-08-MAP)**: Real camera using `camera` package (CameraController + CameraPreview, flash, front/back flip, GPS-locked capture); real GPS via `geolocator` (`LocationService`, Riverpod injectable); real interactive map via `flutter_map` + OpenStreetMap tile layer (MarkerLayer pins, GPS centering, real MapController bounds → backend `GET /api/v1/geo/map-pins`); Android permissions (CAMERA, INTERNET, ACCESS_FINE_LOCATION, READ_EXTERNAL_STORAGE, READ_MEDIA_IMAGES) and iOS Info.plist usage descriptions all set; `flutter analyze lib/` clean (0 issues); 33 new tests (16 Flutter + 17 backend) added.
10: - [x] **Backend foundation**: FastAPI + SQLAlchemy 2 (async) + Alembic under `uv`; feature-first layout (`auth`, `issues`); ruff + mypy-strict clean; 19 pytest tests green.
11: - [x] **Auth (client + server)**: phone & email OTP request/verify → JWT (`POST /auth/otp/request`, `POST /auth/email/request-otp`, `POST /auth/email/verify-otp`, `POST /auth/guest`, `GET /auth/me`); Bearer-attach dio interceptor; HMAC anonymous-identity derivation; Guest session & 403 write guard interceptor; 60s resend timer.
12: - [x] **Feed (client + server)**: `GET /issues?lat&lng&radius_km&limit&offset` (bbox + haversine, shielded filtered out, escalation re-evaluated on read); pull-to-refresh, skeleton loader, empty/error states on the client.
13: - [x] **Issue card & detail**: status badge, relative time, category/fuzzed/shielded chips, ward label, escalation hints; detail view with escalation-ladder timeline + four-stage quorum resolution UI.
14: - [x] **Compose (client + server)**: draft form (title/desc/category + anonymous/fuzz/shield toggles), hive auto-save + resume/discard, `POST /issues` with fuzz rounding, offline outbox queue + toast, near-duplicate guard via `GET /issues/near-duplicate`.
15: - [x] **Escalation / quorum backend**: `POST /acknowledge`, `/resolve`, `/quorum-vote` (proximity + duplicate guard, ≥3 confirm → resolved), `/check-quorum-status` (7-day expiry → disputed), `/evaluate-escalations`, `POST /upvote` (5 km radius + 5-per-10-min rate limit).
16: - [x] **App shell**: Riverpod 2.6 + go_router 17 `StatefulShellRoute` (4 tabs + center compose FAB, tab state preserved), theme provider (light/dark/system), typography + color tokens, skeleton/shared widgets.
17: - [x] **App shell infra (2026-08-09 via `F-01`)**: global toast system, injectable network listener, persistent offline-mode banner, and global error boundary — all wired in `AppInfrastructure`; 22 new Flutter tests; frontend-only, backend untouched.
18: - [x] **Email Auth & Guest Mode (2026-08-09 via `F-02`)**: Email OTP request/verify (client + server), Guest session creation (`POST /auth/guest`) & token persistence, 60-second Resend OTP countdown timer, GuestGuard dialog interceptor for restricted actions (issues, upvotes, quorum), full backend (60 pytest) & frontend (52 flutter) test suite.
19: - [x] **User Profile, Settings & Localization UX (2026-08-09 via `F-13`)**: Complete Material 3 `ProfileScreen` with user avatar/mask icon, `anon_id` chip, guest session banner, and 3-metric activity stats card (issues, upvotes, quorum); persistent `ThemeMode` selector (system, light, dark); persistent `AppLocale` selector (`en`, `hi`, `mr`, `ta`, `te`); `AnonymityGuideScreen` detailing zero-retention HMAC derivation, fuzzed locations, and shielded mode; backend `GET /auth/me` returning live user activity metrics; full test suite (66 pytest and 58 flutter tests green).
20: - [x] **Threaded Comments & Discussion (2026-08-10 via `F-09` subset)**: Complete Threaded Comments backend (`POST /issues/{id}/comments`, `GET /issues/{id}/comments`, `DELETE /issues/{id}/comments/{comment_id}`) & frontend (`CommentsSection`, `CommentCard`, Riverpod `commentsProvider`); `GuestGuard` write protection (403 for guest users), rate limiting (10 comments per 5 min), profanity/toxicity sanitization, HMAC zero-retention `anon_id` identity badges, nested reply threads, and updated issue card comments counter.
21: - [x] **Notifications & Inbox Engine (2026-08-10 via `F-10`)**: Complete Notifications backend (`Notification` async model, `GET /notifications`, `POST /notifications/read-all`, `PATCH /notifications/{id}/read` with user isolation & unread filtering) & frontend (`NotificationsApi`, `NotificationsNotifier`, `unreadNotificationCountProvider`, M3 `NotificationsScreen` with filter chips, type icons, unread badge dots, pull-to-refresh, skeleton & empty states, `InboxScreen` activity digest, bottom nav unread badge); full test suite (90 pytest and 76 flutter tests green).
22: - [x] **Search & Explore (2026-08-10 via `F-08` search subset)**: Backend `GET /api/v1/search` — keyword match across title/description/category/ward (SQL-parameterized `.ilike` with `%`/`_`/`\` escaping = SQLi-safe), optional proximity (bbox + haversine, `radius_km`), optional `status`/`category` filters, `limit`/`offset` pagination, shielded-non-resolved excluded, shared `SlidingWindowRateLimiter` (60/min keyed per user/`anon`), `OptionalUser`/guest allowed, feed-parity `IssueOut` serialization, geo helpers promoted to `features/issues/geo.py`. Frontend: `SearchScreen` (`Key('searchField')`, 400 ms debounce, skeleton/error/empty/results states, shared `IssueCard` reuse), Hive-persisted recent searches (`recent_searches`, max 5, dedupe, `Key('clearRecentSearches')`), `/search` route + Feed app-bar search icon. Validated PASS (25 backend + 18 frontend search tests; full suite **115 pytest / 94 flutter green**, ruff + mypy + flutter analyze clean). Map view still placeholder.
23: - [x] **Advanced Search Filters (2026-08-10 via `F-08` filters subset)**: Backend extended `GET /api/v1/search` with `categories` (repeatable, ≤20, each ≤32 chars, else 422 `invalid_category`), `created_after`/`created_before` (ISO-8601 → naive UTC; 422 `invalid_date_format`/`invalid_date_range` when after>before), `parse_iso_datetime` helper, parameterized/SQLi-safe `category.in_` + `created_at >=/<=` filters applied before ordering/escalation/shielded-exclusion/haversine (behavior unchanged). Frontend: `SearchFilters` model + `SearchDatePreset`/`SearchDistanceOption` enums, `SearchFiltersNotifier` provider, `AdvancedFilterSheet` (7 status chips single-select, 7 category chips multi-select, `SegmentedButton` any/within + 1–50 km slider, 4 date presets, Reset/Show results), screen wiring with `filterButton`/`clearFiltersButton` keys and active `Badge`, `runQuery` passing filters with area default 19.1136/72.8697. Validated PASS (22 backend + 16 frontend new tests; full suite **176 pytest / 133 flutter green**, ruff + mypy clean, flutter analyze clean under lib). 2 non-blocker defects found and resolved post-validation (SegmentedButton alignment + interfaces regeneration).
24: - [x] **Representative Dashboard & Governance Tools (2026-08-10 via `F-11`)**: Complete Representative Dashboard backend (`Representative` & `OfficialResponse` models, `GET /representatives/me`, `GET /representatives/dashboard`, `POST /issues/{id}/official-response`, `GET /issues/{id}/official-response`, ward verification & ward boundary access control) & frontend (`RepDashboardScreen` with triage tabs, ward metric cards, issue triage list with priority chips, official response dialog, `OfficialResponseCard` on issue detail, Riverpod `repDashboardNotifierProvider` & `officialResponseProvider`); full test suite (124 total backend with 9 F-11 pytest cases green, 100 total frontend with 6 F-11 Flutter widget cases green).
25: - [x] **Gamification Engine (2026-08-10 via `F-12`)**: Complete Gamification Engine backend (`UserGamificationProfile`, `UserBadge` models, `GET /gamification/me`, `POST /gamification/claim-daily-streak`, `GET /gamification/badges`, impact score calculation, 5 civic levels, UTC daily streak rollover, 5 dynamic civic badges) & frontend (`GamificationApi` with Hive offline caching, `GamificationScreen` with Impact Score card, Level progress bar, Daily Streak banner & claim button, Badges grid, Riverpod `gamificationNotifierProvider` & `badgeCatalogProvider`, GuestGuard dialog integration); full test suite (154 total backend with 30 F-12 pytest cases green [20 contract + 10 security], 115 total frontend with 15 F-12 Flutter widget cases green).
26: - [x] **Issue Flagging & Moderation System (2026-08-10 via F-14-FLAG)**: Complete content flagging backend (POST /api/v1/issues/{id}/flag with categories, details, duplicate flag guard, rate limiting 5 flags/10 min, guest user 403 restriction), admin moderation queue (GET /api/v1/admin/flagged-issues with pagination & status filters), admin moderation actions (POST /api/v1/admin/issues/{id}/moderate for dismiss/hide_issue/ban_reporter with audit notes) & frontend (IssueCard overflow menu with Key('issueCardOverflow_<id>') & Key('flagIssueOption_<id>'), FlagIssueDialog with Key('flagIssueDialog'), Key('flagCategorySelect'), Key('flagDetailsInput'), Key('submitFlagButton'), AdminFlaggedQueueScreen with Key('adminQueueFilterSelect'), Key('moderateAction_<id>'), Riverpod flagIssueNotifierProvider & adminFlaggedQueueProvider, GuestGuard modal interceptor, Hive local store box 'flagged_issues' caching user_flagged_issue_ids); full test suite (191 pytest and 141 flutter tests green).
27: - [x] **Ward Place Page & Civic Summary Engine (2026-08-10 via F-09-WARD)**: Complete Ward Place Page backend (`GET /api/v1/wards/{ward_slug}`, `GET /api/v1/wards`, ward health summary metrics, assigned representative integration, recent ward issues feed) & frontend (`WardDetailScreen`, `WardHeroBanner`, `WardMetricCard`, `WardRepCard`, `WardRecentIssuesList`, Riverpod `wardDetailProvider`, `wardListProvider`, `WardRepository`); full test suite (209 total backend pytest suite with 18 F-09-WARD green, 152 total frontend flutter test suite with 11 F-09-WARD green).
28: - [x] **Reverse Geocoding & Ward Boundary Lookup (2026-08-10 via F-03 subset)**: Backend `GET /api/v1/geo/reverse-geocode` — ward resolved from lat/lng by centroid distance (Haversine, `radius_km` optional), read-only, no auth required; frontend `WardLocationChip` and `wardLocationProvider` surfaced on Compose and Feed app bars.
29: - [x] **Camera & Media Integrity Pipeline (2026-08-11 via F-05-MEDIA)**: Backend `POST /api/v1/media/upload` (SHA-256 `derive_media_hash`, EXIF timestamp & GPS validation, "LocalLens Verified" vs "User Uploaded - Unverified" watermark badge, location fuzzing precision rounding); frontend `CameraViewfinder` UI (`Key('shutterButton')`, `Key('cameraFlipButton')`, `Key('flashToggleButton')`, `Key('gpsLockStatus')`, `Key('galleryPickerButton')`), `MediaWatermarkBadge` presentational overlay, `MediaService` compression & multipart upload, multi-select gallery picker (max 4 images).
30: - [x] **Multi-Type Spatial Feed Engine (2026-08-11 via F-06-FEED & F-09-TALK)**: Backend `GET /api/v1/feed` (type filtering `all`/`issue`/`win`/`notice`/`local_talk`, cursor pagination, shielded non-resolved exclusion); Win post auto-generation upon quorum resolution (`GET /api/v1/wins`); Local Talk ward Q&A channels (`POST`/`GET /api/v1/wards/{ward_slug}/talk`); frontend filter chips (`Key('feedFilterChip_all')`, etc.), `WinCard`, `NoticeCard`, `LocalTalkCard`, `LocalTalkComposeSheet` modal, deep link share buttons, end-of-feed state.
31: - [x] **Interactive Map & Spatial Pin Engine (2026-08-11 via F-08-MAP)**: Backend `GET /api/v1/geo/map-pins` (bounding box spatial query `min_lat`, `max_lat`, `min_lng`, `max_lng`, `category`/`status` filtering, shielded non-resolved exclusion, rate limit); frontend `MapScreen` interactive canvas, category filter chips (`Key('mapFilterChip_all')`, etc.), map pin markers (`Key('mapPin_<id>')`), `MapPinPreviewSheet` bottom sheet (`Key('mapPinPreviewSheet_<id>')`), "Search this area" floating button (`Key('searchThisAreaButton')`).
32: - [x] **Profile Identity Fields & Stale-DB Migration Fix (2026-08-17)**: Resolved `sqlite3.OperationalError: no such column: users.display_name` (500 on `GET /api/v1/feed`) caused by the dev DB being behind migration `a1b2c3d4e5f6` (`add profile identity fields to users` — `display_name`, `username`, `date_of_birth`, `photo_url` + `ix_users_username`). Root cause: `make backend` started uvicorn without running pending Alembic migrations. Fix: applied `uv run alembic upgrade head` to the live dev DB (now at head) and hardened `make backend` to auto-run `alembic upgrade head` before launching the server; feed/profile endpoints verified returning 200. Troubleshooting note added to `README.md`.
33: - [ ] **Not started / pending future increments**: Production SMS provider & APNS/FCM push dispatchers, refresh token & secure keychain/keystore storage, auto-suggest merge flow for near-duplicates, mini-map interactive pin lock in compose, live ticking countdown renderers on escalation ladder, dispute photo attachment & 48h double-claim cooldown, pin density supercluster SDK, conflict-resolution sync strategy, image vector similarity for duplicate media, PII legal process ceremony, and backend auto-translation queue.
34: 
35: ---
36: 
37: ## 1. App Shell, Theming & Global States
38: - [x] Initialize cross-platform project (Flutter) with strict linting rules. *(app/ created, `flutter_lints` + `analysis_options.yaml`, `flutter analyze` clean.)*
39: - [x] Implement global ThemeProvider (Light Mode, Dark Mode, System Auto). *(Provider + theme applied; user-facing selector available in Profile → Settings via F-13.)*
40: - [x] Define global typography scale and color palette tokens. *(`app_theme.dart`, `app_colors.dart`.)*
41: - [x] Build global Snackbar/Toast notification system for transient alerts. *(`appMessengerProvider` queue w/ dedupe + typed auto-dismiss + `ToastOverlay`; wired via `AppInfrastructure` overlay.)*
42: - [x] Implement Global Network Listener (detects Online/Offline transitions). *(`connectivity_plus`-backed `connectivitySourceProvider` → `networkStatusProvider`; injectable for tests.)*
43: - [x] Build persistent "Offline Mode" banner UI (appears when connection drops). *(`OfflineBanner`, M3 `errorContainer` tokens, no emoji/gradients.)*
44: - [x] Implement Global Error Boundary to catch UI crashes. *(`ErrorBoundary`/`SafeFallback` mounted in `AppInfrastructure`; global `FlutterError`/`PlatformDispatcher` handlers in `main.dart`; fallback never leaks exception details.)*
45: - [x] Setup local token storage — Hive (hive_ce) session/drafts boxes. *(Not yet keychain/keystore-backed secure storage; no refresh token.)*
46: - [x] Configure deep linking handling (URI schemes & Universal Links) — deep links into Issue, Local Talk post, Rep Page, Win (`locallens://`).
47: - [x] Create skeleton loading animations for list views. *(`shared/widgets/shimmer_loading.dart` — custom ShimmerLoading gradient sweep animation overlay).*
48: - [ ] (NEW) App locale manager: per-locale font/script support (Devanagari, Tamil, Telugu, etc.) with locale-aware placeholder text everywhere.
49: 
50: ## 2. Onboarding & Registration Flow
51: - [ ] Build Animated Splash Screen (App Logo + Loading indicator). *(app boots straight to sign-in/feed.)*
52: - [x] Build 5-page interactive Onboarding Carousel: value proposition ("See what's wrong"), impact ("Your upvotes are civic signals"), anonymity promise ("We can't reveal you, even if we tried"), daily ritual ("Street Check"), and Win-loop ("Every fix is celebrated"). *(`onboarding_screen.dart` with `onboardingNextButton`, `skipOnboardingButton`, `onboardingPageIndicator`.)*
53: - [x] Implement "Skip Onboarding" logic (saves flag `has_completed_onboarding` to local storage Hive session box).
54: - [x] Build Auth Landing Screen with "Login via Phone", "Login via Email", and "Guest Mode". *(SignInScreen SegmentedButton switcher + Continue as Guest button.)*
55: - [ ] **Phone Auth Flow:**
56:   - [ ] Implement Phone Input UI with searchable Country Code dropdown. *(Single `TextField`; user types `+91 …` — no dropdown.)*
57:   - [x] Client-side validation: numeric-only input formatter + `E164`-ish regex (`^\+[1-9][0-9]{6,14}$`).
58:   - [x] API Integration: `POST /auth/phone/request-otp`. *(wired to `/auth/otp/request`, 204.)*
59:   - [x] Loading state on "Send OTP" button.
60:   - [ ] Error handling: surface specific errors ("Rate limit exceeded", "Invalid number", etc.). *(Generic message now; `ApiServerException` mappings exist but not surfaced distinctly.)*
61:   - [x] Build OTP 6-digit split input UI (auto-advances focus; backspace). *(`otp_field.dart`.)*
62:   - [x] Implement 60-second Resend OTP countdown timer. *(`_startResendTimer` in `SignInScreen` / `OtpScreen`.)*
63:   - [x] API Integration: `POST /auth/phone/verify-otp`. *(wired to `/auth/otp/verify`.)*
64:   - [ ] Android-specific: integrate SMS Retriever API for auto-reading OTP.
65: - [x] **Email Auth Flow:**
66:   - [x] Implement Email Input UI with standard regex validation. *(`_emailPattern` regex in `SignInScreen`.)*
67:   - [x] API Integration: `POST /auth/email/request-otp`. *(`AuthRepository.requestEmailOtp`.)*
68:   - [x] Build Email OTP Verification UI. *(`AuthRepository.verifyEmailOtp`.)*
69: - [x] **Guest Mode Flow:**
70:   - [x] Implement "Continue as Guest" logic (generates anonymous local session via `POST /auth/guest`).
71:   - [x] Build "Sign in required" bottom-sheet interceptor for restricted actions. *(`GuestGuard` dialog widget + 403 authorization guard on `POST /issues`, `/upvote`, `/quorum-vote`.)*
72:   - [ ] Guest feed shows digest of "previous activity in this area".
73: - [ ] **Session & Token Management:**
74:   - [ ] Store JWT Access Token + Refresh Token securely. *(Access token only, in Hive — partial.)*
75:   - [x] Implement HTTP interceptor to attach Access Token automatically. *(dio `_AuthInterceptor`.)*
76:   - [ ] Implement automatic silent token refresh on 401.
77:   - [ ] (R) Device & session trust registry; **no multi-account switcher**.
78:   - [x] (NEW) One-way anonymous identity derivation: backend HMAC `derive_anonymous_identity(user_id, secret)` → `anon_id` via `/auth/verify` and `/me`. *(No inversion path or admin UI.)*
79:   - [ ] Secure logout logic (clears storage; server-side token revocation not implemented).
80: 
81: ## 3. Core Navigation Architecture
82: - [x] Implement Bottom Navigation Bar. *(Design deviation from "5 tabs": app ships **4 tabs** (Home/Map/Inbox/Profile) + **center FAB** for Create per v2 design.)*
83: - [ ] Define custom active/inactive SVG icons for each tab. *(Material Icons currently.)*
84: - [x] Build Tab Router logic preserving state of individual tabs. *(`go_router` `StatefulShellRoute.indexedStack`.)*
85: - [x] Implement central FAB for the "Create" action → opens compose route.
86: - [x] Configure nested stack navigators for each tab. *(Shell branches + pushed routes for compose / issue detail.)*
87: - [ ] Implement custom page transition animations (slide, fade).
88: - [x] (NEW) Ward "Place Page" entry point (Home header chip, Map, Rep page, router `/ward/:slug`).
89: 
90: ## 4. Home Feed Engine & Post Discovery (v2: problems + progress)
91: - [x] Build Feed Container UI with Pull-to-Refresh.
92: - [x] Implement Feed Skeleton Loaders while `GET /feed` pending.
93: - [x] **API Integration:** `GET /feed`. *(Implemented as `GET /api/v1/feed` supporting bbox+haversine, cursor pagination, and type filtering.)*
94: - [x] (R) Feed mixes post types: `issue`, `win`, `notice`, `local-talk` + type-chip filters (`Key('feedFilterChip_all')`, `Key('feedFilterChip_issues')`, etc.).
95: - [x] Implement infinite scrolling (cursor pagination, fetch next page).
96: - [x] Handle "End of Feed" state ("You're all caught up!", `Key('endOfFeedState')`).
97: - [x] Handle "Empty Feed" state. *(EmptyState: "All clear around here" / "Be the first to report an issue in your area".)*
98: - [ ] **Issue Card Component:**
99:   - [x] Header: Jurisdiction text — ward label chip ("Ward 45, Urban Central").
100:   - [x] Header: Timestamp in relative form ("2h ago" via `relative_time.dart`).
101:   - [x] Header: Status Badge UI (color-coded; `status_badge.dart`).
102:   - [x] Header: Anonymous-mask avatar icon works. *(Anonymous → mask icon + "Anonymous"-style `reporterLabel`.)*
103:   - [x] Header: Author display name / "Anonymous".
104:   - [x] Body: Issue title — bold, `maxLines: 2`, ellipsis.
105:   - [x] Body: caption snippet. *(2-line ellipsis; **no "Read More"** expander yet.)*
106:   - [x] Body: Category tags as chips (`#road`, `#water`, …).
107:   - [x] Media: image carousel, pagination dots, verified/unverified watermark overlay (`MediaWatermarkBadge`).
108:   - [x] Footer: upvote button/state toggle.
109:   - [x] Footer: upvote counter.
110:   - [x] Footer: comment button + counter.
111:   - [x] Footer: share button (OS share sheet w/ deep link `locallens://`).
112:   - [x] Footer: three-dot overflow (Flag, Copy link).
113:   - [x] Footer: (NEW) escalate-banner slot — inline status hint (`🔥 Escalating`, `⚡ Forwarded`, `👥 Quorum`) rendered when applicable.
114: - [x] **Win Card (NEW)** — `WinCard` widget (`Key('winCard_<id>')`) with before/after media slider, contributor credits, and celebration banner.
115: - [x] **Notice Card (NEW)** — `NoticeCard` widget (`Key('noticeCard_<id>')`) with official notice header and validity time.
116: - [ ] **Interactions:**
117:   - [x] Optimistic upvote (instant UI, background sync).
118:   - [x] Upvote API call sync with error state rollback & toast notification.
119:   - [x] (R) Server-side upvote validation: authenticated user + **5 km proximity** + **rate-limit (max 5 per 10 min)** + **duplicate guard** + **un-upvote endpoint**. *(Anomaly/brigade detection pending.)*
120: 
121: ## 5. Camera, Hardware & Media Pipeline (v2: privacy + speed)
122: - [x] Build OS Permission Manager (Camera, Storage, Location).
123: - [x] Handle "Permission Denied" states (show settings link).
124: - [x] Implement custom Full-Screen Camera Viewfinder (`camera_viewfinder.dart`).
125: - [x] Build Camera Controls (Shutter `Key('shutterButton')`, Flip `Key('cameraFlipButton')`, Flash `Key('flashToggleButton')`, GPS lock `Key('gpsLockStatus')`). *(Real CameraController + CameraPreview using the `camera` package; GPS lock via `geolocator`; flash mode applied to controller; front/back flip reinitializes controller; all Keys preserved.)*
126: - [x] Media Integrity Engine — GPS-lock-before-shutter, EXIF + backend-cryptographically-signed hash (`derive_media_hash`), "LocalLens Verified" vs "Unverified" watermark badge (`MediaWatermarkBadge`).
127: - [x] Location Privacy (fuzz toggle at capture, block-level precision rounding).
128: - [x] Shield Mode capture (sensitive categories).
129: - [x] Gallery import (picker up to 4 images `Key('galleryPickerButton')`, EXIF parse, "User Uploaded - Unverified" badge).
130: - [x] Cropper / rotator; client-side compression (1920×1080, ~80%).
131: - [x] (NEW) Hair-trigger capture (offline-first shutter, GPS last-fix buffer).
132: 
133: ## 6. Draft Composer & Post Publishing (v2)
134: - [x] Build Post Creation Wizard (single scrollable form, `compose_screen.dart`).
135: - [ ] **Location step:** mini-map GPS lock, manual-pin fallback, fuzz ward-level map. *(Partial — `GET /api/v1/geo/reverse-geocode` shipped 2026-08-10 via F-03 subset; compose still uses `defaultLatitude/defaultLongitude` for the draft.)*
136: - [ ] **Duplicate Guard:**
137: - [x] API Integration: `GET /issues/near-duplicate` — backend detection (bbox + haversine, `distance_meters`), backend-only.
138: - [x] "Guarded" sheet: compose "Check for Near-Duplicates" button → bottom sheet lists "…m away" candidates.
139: - [ ] Merge-link flow (auto-suggest merge, redirect upvotes/comments) — pending.
140: - [ ] **Form Inputs:**
141:   - [x] Title Input char counter (max 100).
142:   - [x] Description textarea counter (max 1000).
143:   - [x] Category selector chips (road/water/power/lighting/waste/sewage/other).
144:   - [x] Privacy: three switches for **Anonymous / Fuzz location / Shield** (equals segmented picker but not a single segmented control).
145:   - [ ] Post Type selector (Issue / Local Talk / Win) — issues only.
146: - [ ] **Local Drafts Engine:**
147:   - [x] Auto-save on every keystroke to Hive (`ComposeController.update` → `DraftStore.save`).
148:   - [ ] "Drafts" list UI in Profile.
149:   - [x] Resume / delete draft (persist via hive; discard button).
150: - [ ] **Publishing Pipeline:**
151:   - [x] Media upload to object storage. *(No media yet.)*
152:   - [x] API: `POST /issues` (create) — wired `FeedApi.createIssue` + controller.submit.
153:   - [ ] Step 4 success animation — only a SnackBar + navigation + feed invalidate.
154: - [ ] **Offline Publishing Queue:**
155:   - [x] Save `PendingUploads` to Hive outbox when offline (`OfflineOutboxQueue.enqueue`).
156:   - [x] "Saved to Outbox — will upload when online" toast.
157:   - [x] Flush worker method exists (`flush()` retries remaining); not yet attached to a reconnection crawl/Workmanager.
158: - [ ] (NEW) "Report for someone" assisted capture flow — not started.
159: 
160: ## 7. Search, Explore & Interactive Map View
161: - [x] Search bar + debounce (400 ms) + recent searches. *(`SearchScreen` at `/search`, `Key('searchField')`, Hive recents `recent_searches` max-5 dedupe, `Key('clearRecentSearches')`; entry via Feed app-bar search icon.)*
162: - [x] `GET /search` *(implemented as `GET /api/v1/search?q&latitude&longitude&radius_km&status&category&limit&offset`; title/description/category/ward `.ilike` match with `%`/`_`/`\` escaping; shield-filtered out; rate-limited 60/min; guest allowed; returns `IssueOut`.)*
163: - [x] Advanced filters sheet (status/category/type/date/distance) — `AdvancedFilterSheet` UI + backend `GET /api/v1/search` parameters (`categories`, `created_after`, `created_before`).
164: - [x] Map SDK, custom styling, bbox fetch, clustering, custom pins, peek sheet, "Search this area" — `MapScreen` with interactive map canvas (`Key('mapPin_<id>')`), `MapPinPreviewSheet` (`Key('mapPinPreviewSheet_<id>')`), `Key('searchThisAreaButton')`, backend `GET /api/v1/geo/map-pins`. *(Implemented as `flutter_map` FlutterMap widget + OSM TileLayer + MarkerLayer; GPS-centred on user location; real MapController bounds drive `GET /api/v1/geo/map-pins`; all Keys preserved.)*
165: 
166: ## 8. Issue Detail, Audit Trail & Quorum Resolution
167: - [x] Full-screen issue detail (`issue_detail_screen.dart`): header, title, description, tags, escalation ladder, quorum card; skeleton/error/retry states; fetched via `GET /issues/{id}`.
168: - [x] Header: author info, anonymous mask, ward, relative time, status badge. *(Follow/Mute buttons pending.)*
169: - [x] **Audit Timeline UI:** vertical timeline (`_EscalationLadderWidget`, 4 nodes: Reported → Escalating (24–72h) → Forwarded (>7d) → Quorum).
170: - [x] (R) Escalation ladder nodes + server re-evaluates status on read (`evaluate_escalation`).
171: - [ ] (NEW) Live countdown renderers (24h/72h/7d) — steps labeled but no timer.
172: - [ ] (NEW) Authoritative trace for Win posts (linked resolution proof media + contributors) — not started.
173: - [x] **Quorum-Backed Resolution (R):**
174: - [x] Authority "Submit Resolution" → dialog (proof URL + notes) → `/resolve` → `pending_quorum` (7-day expiry).
175: - [x] Reporter "Confirm Fix" / "Dispute Fix" buttons.
176: - [x] Quorum progress (`x/3` + `LinearProgressIndicator`).
177:   - [x] Backend rules: proximity 5 km, one vote per user, ≥3 confirms → resolved, ≥1 dispute → disputed, expiry <7d → disputed.
178:   - [ ] Neighbor nudge ("Did this get fixed for you too?") prompt — not implemented.
179:   - [ ] Dispute form (reason chips + photo option) — dispute is a one-tap vote today.
180:   - [ ] Double-claim abuse guard (48 h cooldown) — not enforced.
181:   - [x] (R) Win-generation on resolution — auto-generates `Win` post with before/after photos and contributor credits upon 3rd quorum confirm vote (`GET /api/v1/wins`).
182: - [x] **Threaded comments** — completed (`POST /issues/{id}/comments`, `GET /issues/{id}/comments`, `DELETE /issues/{id}/comments/{comment_id}`, `CommentsSection` & `CommentCard` M3 UI, Riverpod `commentsProvider`, GuestGuard dialog, profanity/toxicity sanitization, rate limiting, HMAC zero-retention identity badges).
183: - [x] **Ward Place Page & Civic Summary Engine** — completed (`GET /api/v1/wards/{ward_slug}`, `GET /api/v1/wards`, ward metrics summary, top contributors, active notices, assigned representative card, M3 `WardDetailScreen`, `WardHeroBanner`, `WardMetricCard`, `WardRepCard`, `WardRecentIssuesList`, Riverpod `wardDetailProvider`, `wardListProvider`).
184: 
185: ## 9. Inbox, Messaging & Service Notices
186: - [x] Inbox tab layout — `inbox_screen.dart` with notifications summary digest and civic activity stream.
187: - [x] Bell icon → `notifications_screen.dart` holding full Material 3 notification center.
188: - [ ] Broadcasts, Street Check Digest, offline messenger queue — **pending later increments**.
189: 
190: ## 10. Notifications Engine
191: - [x] Notifications Data Model: SQLAlchemy `Notification` model with UUID `id`, `user_id`, `title`, `body`, `type` (`escalation`, `quorum_request`, `upvote_milestone`, `comment_reply`, `system_notice`), `reference_id`, `is_read`, and `created_at`.
192: - [x] Backend Endpoints: `GET /notifications` (unread filter, pagination, user isolation), `POST /notifications/read-all` (batch read), `PATCH /notifications/{id}/read` (single read update with 404 user boundary guard).
193: - [x] Frontend API & State: Dio `NotificationsApi`, Riverpod `NotificationsNotifier` & `unreadNotificationCountProvider`.
194: - [x] Notification UI: Material 3 `NotificationsScreen` with filter chips (All / Unread), type icons, unread badge dots, header "Mark all read" action, pull-to-refresh, skeleton loaders, empty state, and guest guard.
195: - [x] Bottom Nav Unread Badge: Inbox tab displays unread counter badge.
196: - [ ] FCM/APNS push notifications & quiet-hours schedule — **pending push provider integration**.
197: 
198: ## 11. User Profile, Privacy & Settings
199: - [x] User Profile Screen (`profile_screen.dart`): Avatar/Mask header, `anon_id` chip, guest banner, 3-metric activity stats card (issues, upvotes, quorum).
200: - [x] Theme Selector: persistent Light Mode, Dark Mode, System Auto selection (`themeModeProvider`).
201: - [x] App Locale Manager: per-locale script/language selection (`en`, `hi`, `mr`, `ta`, `te`) (`appLocaleProvider`).
202: - [x] Privacy & Anonymity Guide (`anonymity_guide_screen.dart`): zero-retention HMAC identity derivation, block-level location fuzzing, shielded mode education.
203: - [x] Backend Profile API: `GET /auth/me` returning `issues_count`, `upvotes_count`, `quorum_votes_count` and user/guest metadata.
204: 
205: ## 12. Representative Dashboard & Governance Tools (Special User Roles)
206: - [x] Backend Representative Data Model & API: `Representative` & `OfficialResponse` SQLAlchemy models, `GET /representatives/me` (rep profile & verified status), `GET /representatives/dashboard` (ward issue metrics, priority triage queue, status filters), `POST /issues/{id}/official-response` (publish official response with status update: acknowledged or in_progress, ward boundary enforcement, single response limit), `GET /issues/{id}/official-response` (public retrieval of official response).
207: - [x] Frontend Representative Dashboard UI: M3 `RepDashboardScreen` (`repDashboardScreen`, `repProfileName`, `repProfileWard`), ward metric chips (`metricTotalWardIssues`, `metricEscalatedIssues`, `metricAcknowledgedIssues`), issue triage tabs (`wardFilterChip_all`, `wardFilterChip_escalated`, `wardFilterChip_in_progress`, `wardFilterChip_acknowledged`), priority issue cards (`triageIssueCard_<id>`), post response dialog (`postOfficialResponseDialog`, status dropdown, message input field).
208: - [x] Official Response Card UI: Public `OfficialResponseCard` (`officialResponseCard_<id>`) embedded on `IssueDetailScreen` showing verified rep blue-tick badge, representative name, official response message, timestamp, and updated status badge.
209: - [x] Access Control & Ward Boundary Enforcement: Representative verification check (403 for non-representatives) and Ward matching check (403 when trying to access or respond to issues outside assigned ward).
210: 
211: ## 13. Gamification Engine
212: - [x] Impact Score Formula & Level Calculation: `(resolutions * 15) + (upvotes * 2) + (quorum_votes * 5) + (streaks * 3)` dynamically evaluated into 5 civic levels (Civic Rookie, Neighborhood Scout, Community Sentinel, District Champion, Civic Legend).
213: - [x] Daily Street Check Streak Engine: `POST /api/v1/gamification/claim-daily-streak` with 24-hour window validation, UTC calendar day rollover, consecutive streak tracking, and bonus point awards.
214: - [x] Dynamic Civic Badges System: `GET /api/v1/gamification/badges` catalog and auto-unlocking evaluation for First Voice, Sentinel, Quorum Anchor, Streak Master, and Civic Legend badges.
215: - [x] Frontend State & Offline Caching: Hive `gamification_cache` storage, `GamificationApi`, Riverpod `gamificationNotifierProvider` & `badgeCatalogProvider`.
216: - [x] Material 3 Gamification UI: `GamificationScreen` (`Key('gamificationScreen')`) featuring Impact Score card, Level progress bar, Daily Streak banner & claim button, Badges grid (`Key('badgeCard_<id>')`), Activity Breakdown, and GuestGuard interception.
217: 
218: ## 14. Backend, Offline Sync, Admin & Integrity Operations
219: - [x] Async SQLAlchemy/Alembic local development DB & migrations (users, OTP requests, issues, quorum_votes, upvotes, upvote_rate_limit).
220: - [x] Backend services for everything marked done above (auth OTP, issues CRUD + geo, escalation, quorum).
221: - [x] Background sync worker — `OfflineSyncWorker` mounted in `AppInfrastructure`, listens to `networkStatusProvider` stream, automatically triggers `OfflineOutboxQueue.flush()` and shows toast notification upon network reconnection.
222: - [ ] Conflict resolution strategy — not defined.
223: - [x] **Admin Moderation & Flagging System (2026-08-10 via F-14-FLAG)**: Flagged content queue, citizen flag dialog, moderation actions (dismiss, hide, ban anon identity), audit notes, rate limiting, duplicate flag guard, and Hive local store caching.
224: - [x] (NEW) Near-Duplicate Pipeline — geohash bbox + fuzzy `distance_meters` endpoint shipped; image vector similarity not yet.
225: - [x] (NEW) One-way anonymous-identity primitives (backend HMAC derivation, surfaced as `anon_id`). *(Zero-inversion audit test, separate PII store and legal-process ceremony still pending.)*
226: - [ ] (NEW) Localization backend (translation queue, per-post translated marker, translator credits) — not started.

(End of file - total 226 lines)
</content>
```

---

## Assistant (Build · DeepSeek V4 Flash Free · 304.5s)

_Thinking:_

Now I have a good understanding of the feature set. Let me look at the specific key files related to the issues the user is reporting:

1. **Compose flow** - `compose_screen.dart`, `compose_controller.dart`, `media_service.dart`, `compose_draft.dart`, `hive_draft_store.dart`, `camera_viewfinder.dart`
2. **Map** - `map_screen.dart`, `map_controller.dart`, `map_api.dart`
3. **Search** - `search_screen.dart`, `search_api.dart`, `search_providers.dart`
4. **Rep dashboard** - `rep_dashboard_screen.dart`
5. **Profile** - `profile_screen.dart`
6. **Backend** - issues router/service, media, geo
7. **Ward detail** - `ward_detail_screen.dart`

Let me read key files to understand current implementation. I'll spawn explore agents to gather detailed context on these areas while reading critical ones directly.

Given the size, let me use explore agents to get comprehensive context in parallel. I'll spawn 4 explore agents:
1. Compose/media/issue creation flow (frontend + backend)
2. Map + geo (frontend + backend)
3. Search frontend + backend
4. Rep dashboard + profile + ward detail

Then I'll build plans and spawn plan→code→test agents per feature.

Let me launch explore agents in parallel.

Now let me gather detailed context on the key areas using parallel explore

**Tool: task**

**Input:**
```json
{
  "description": "Explore compose/media flow",
  "prompt": "Explore the LocalLens codebase (Flutter app in `app/`, FastAPI backend in `backend/`) with \"medium\" thoroughness. I need a detailed report on the ISSUE COMPOSITION / MEDIA / UPLOAD flow, because a user wants to change it so that: (1) location is added to image metadata by default, (2) gallery photo uploads are strictly NOT allowed — only camera images taken inside the app, (3) captured images are saved to a draft/media space that can be deleted, (4) captured image locations update the map.\n\nReport on:\n1. FRONTEND `app/lib/features/compose/`: read `presentation/compose_screen.dart`, `presentation/controllers/compose_controller.dart`, `presentation/compose_providers.dart`, `data/media_service.dart`, `data/hive_draft_store.dart`, `domain/compose_draft.dart`, `presentation/widgets/camera_viewfinder.dart`, `presentation/widgets/media_watermark_badge.dart`, `presentation/drafts_screen.dart`, `data/offline_outbox_queue.dart`. Describe how media is currently picked (gallery picker vs camera), how images are stored as drafts, the ComposeDraft model fields (especially location/coords and media), how GPS location is captured and stored, and what the submit flow does with media + location.\n2. BACKEND media: read `backend/app/features/media/router.py`, `service.py`, `schemas.py`, `models.py`. Describe the media upload endpoints, how EXIF/GPS is validated, what fields are stored, and how media relates to issues.\n3. BACKEND issues: read `backend/app/features/issues/router.py`, `service.py`, `schemas.py`, `models.py`. Describe POST /issues, how media is attached to an issue, what location fields the issue stores, and any endpoint that updates issue location or maps images to locations.\n4. How does the compose screen currently obtain lat/lng? Read `app/lib/core/services/location_service.dart` and `app/lib/features/geo/domain/device_location_service.dart`.\n5. Note any existing \"group select\" / multi-image selection UI and any draft media management (delete) UI.\n\nReturn a structured report with exact file paths, key class/function names, line numbers for the most important logic, and the exact data model fields. Do NOT write any code.",
  "subagent_type": "explore"
}
```

**Output:**
```
<task id="ses_feae9b5f2ffe16BbjHVZOOdkFJ" state="completed">
<task_result>
I have a complete picture of the flow. Here is the structured report.

---

# LocalLens ISSUE COMPOSITION / MEDIA / UPLOAD Flow — Investigation Report

## 0. Architecture at a glance

- **App**: Flutter (Riverpod + freezed), compose flow lives in `app/lib/features/compose/`.
- **Backend**: FastAPI + SQLAlchemy async. Media feature (`backend/app/features/media/`), issues feature (`backend/app/features/issues/`), geo map-pins (`backend/app/features/geo/`).
- Media router is mounted at `POST /api/v1/media/upload` and `GET /api/v1/media/files/{filename}` (`backend/app/main.py:53`). Issues router mounted under `/api/v1/issues` (via `api_router`).
- **Media and Issues are NOT linked in the DB.** An issue stores media as URL strings (`media_url` / `media_urls` JSON text column). The `Media` table has no `issue_id` FK.
- There are **two** `ComposeController` classes. The one in `presentation/controllers/compose_controller.dart` (a `ChangeNotifier`) is **dead/legacy code** — grep confirms nothing imports it. The **active** controller is `ComposeController extends Notifier<ComposeDraft>` inside `presentation/compose_providers.dart:64`.

---

## 1. FRONTEND — `app/lib/features/compose/`

### 1.1 `presentation/compose_screen.dart` (797 lines)

**Media state lives in widget state, not the draft.** The screen keeps a local `final List<_AttachedMedia> _attachedMediaList = []` (line 58). `_AttachedMedia` (lines 33–43) holds `id`, `bytes` (`Uint8List`), and `isVerified` — **it does NOT store per-media lat/lng**, only the verify flag.

**How media is picked today — BOTH gallery and camera are allowed:**

| Entry point | Location | Mechanism |
|---|---|---|
| `_openCameraModal` (lines 86–154) | "Take photo" button, key `openCameraButton` (lines 492–497) | Opens a bottom sheet with `CameraViewfinder`; camera capture → `onPhotoCaptured(bytes, lat, lng)` appends `_AttachedMedia(isVerified: true, id: 'cam_...')` (lines 132–145). |
| `_addGalleryImages` (lines 156–194) | "Add from gallery" button, key `openGalleryButton` (lines 498–503) | `ImagePicker().pickMultiImage(limit: 4 - count)` (lines 161–164). Each appended with `isVerified: false`, id `gallery_...` (lines 183–193). |
| `CameraViewfinder.onGalleryPickSelected` (line 146–149) | Gallery icon inside camera sheet (`camera_viewfinder.dart:312-317`) | Routes to `_addGalleryImages`. |

- **Max 4 images** enforced in multiple places (`availableSlots = 4 - _attachedMediaList.length`, lines 87, 171; snackbar "Maximum 4 images allowed.").
- **Per-image delete already exists**: `_removeMedia(String id)` (lines 196–200), wired to the X button in each media tile (key `removeMedia_<id>`, lines 574–591). Each tile renders `MediaWatermarkBadge` (lines 565–573).
- **`_saveAsDraft`** (lines 202–215): base64-encodes all `_attachedMediaList` bytes into `mediaBytes` and calls controller `saveAsDraft`; invalidates `savedDraftsProvider`.
- **`_useMyLocation`** (lines 217–251): resolves coords via `feedCoordinatesProvider` (falls back to `locationService.getCurrentPosition()`), writes `draft.copyWith(latitude, longitude)`.
- **`_publish`** (lines 352–390): near-duplicate check (30 m radius), then `submit(mediaBytes: [...], isInAppCamera: any id starts with 'cam_')` (lines 370–375). On success invalidates `savedDraftsProvider`, `multiTypeFeedProvider`, `mapPinsNotifierProvider`, navigates to feed.
- Draft restore (lines 61–84): base64-decodes `draft.mediaBytes.take(4)` back into `_attachedMediaList` with `isVerified: false`.
- Location card UI (lines 604–659): shows `draft.latitude/longitude` (5 decimals) or "Location not set" + "Use my location" button (key `useMyLocationButton`, only when lat is null).
- Toggles: `compose_fuzz_mode`, `compose_shield_mode`, `compose_anonymous` (lines 661–690).

### 1.2 `presentation/controllers/compose_controller.dart` (167 lines) — DEAD CODE

Not referenced by any other file. Contains the *intent* of per-media location capture:
- `LocalSelectedMedia` (lines 4–16): `bytes`, `isInAppCamera`, `capturedLat`, `capturedLng`.
- `ComposeState` (lines 18–49): `selectedMediaList`, `uploadedMediaList`, `isUploading`, `isFuzzed`, `maxImagesAllowed = 4`.
- `addCapturedPhoto(bytes, lat, lng)` (lines 66–88) preserves `capturedLat/capturedLng`; `addGalleryImages` (lines 91–120) sets them `null`.
- `uploadAllSelectedMedia()` (lines 132–166) forwards `capturedLat/capturedLng` + `isFuzzed` to `MediaService.uploadMedia`.

### 1.3 `presentation/compose_providers.dart` (185 lines) — ACTIVE controller

- `_createCoords(Ref)` (lines 21–27): `feedCoordinatesProvider.future`, fallback `(defaultLatitude, defaultLongitude)` = **(19.1136, 72.8697)** from `feed_providers.dart:14-15`.
- `draftStoreProvider` (29–31), `savedDraftsProvider` (36–38), `offlineOutboxProvider` (40–45), `nearDuplicateCheckProvider` (47–59).
- `ComposeController extends Notifier<ComposeDraft>` (64–183):
  - `build()` (65–75): loads single autosave draft from `LocalStore` (`loadDraft`, key `current_draft`).
  - `update(draft)` (77–84): **explicitly saves with `mediaBytes: const []`** — media never lives in the autosave draft, only in widget state and saved drafts.
  - `saveAsDraft({mediaBytes})` (94–106): stores base64 media in a saved draft (new id or in-place update of opened draft).
  - `deleteSavedDraft(id)` (108–110), `discard()` (113–120).
  - **`submit({mediaBytes, isInAppCamera})` (124–182) — the key upload path:**
    1. Lat/lng = `current.latitude/longitude`, else `_createCoords(ref)` (lines 135–141).
    2. For each byte: `mediaService.uploadMedia(bytes, isInAppCamera: isInAppCamera, isFuzzed: current.isFuzzed)` (lines 149–155). **Note: `capturedLat`/`capturedLng` are NOT passed here** — per-media GPS captured at shutter time is dropped on submit.
    3. `repo.createIssue(..., latitude, longitude, mediaUrls)` (lines 159–169).
    4. On exception: `outbox.enqueue(current)` (line 172).
    5. Deletes draft id + clears autosave + resets state (lines 176–181).

### 1.4 `data/media_service.dart` (151 lines)

- `MediaUploadResult` (lines 26–80): `id, url, thumbnailUrl, isVerified, watermarkLabel, derivedHash, latitude?, longitude?, isFuzzed, createdAt`.
- `packageExifMetadata(...)` (lines 96–109): builds `{is_in_app_camera, captured_lat, captured_lng, is_fuzzed, timestamp}` — **exists but is not called in the live submit path**.
- `uploadMedia({bytes, isInAppCamera, capturedLat, capturedLng, isFuzzed})` (lines 112–150): base64-encodes bytes (via stub `compressImage`, lines 90–93, which is a no-op), POSTs JSON to `/media/upload` with `base64_payload`, `is_in_app_camera`, `captured_lat`, `captured_lng`, `is_fuzzed` (lines 123–129). Bearer token from `sessionProvider`.
- `mediaServiceProvider` (lines 9–24): Dio with base URL `AppConfig.dev.apiBaseUrl`.

### 1.5 `data/hive_draft_store.dart` (52 lines)

Thin wrapper over `LocalStore` (`core/storage/local_store.dart`): `save`/`clear` → autosave `current_draft`; `loadAll`/`saveItem`/`deleteItem` → JSON array under `saved_drafts` key (each entry `{'id', 'data'}`). Draft JSON round-trips through `ComposeDraft.fromJson/toJson`.

### 1.6 `domain/compose_draft.dart` (33 lines) — data model

Freezed class `ComposeDraft` (serialization in `compose_draft.g.dart`):

| Field | Type | Default | Serialized key |
|---|---|---|---|
| `id` | String | `''` | `id` |
| `title` | String | `''` | `title` |
| `description` | String | `''` | `description` |
| `category` | String | `'road'` | `category` |
| `isAnonymous` | bool | `false` | `isAnonymous` |
| `isFuzzed` | bool | `false` | `isFuzzed` |
| `isShielded` | bool | `false` | `isShielded` |
| `latitude` | double? | null | `latitude` |
| `longitude` | double? | null | `longitude` |
| `createdAt` | DateTime? | null | `createdAt` |
| `updatedAt` | DateTime? | null | `updatedAt` |
| `mediaBytes` | List\<String\> | `[]` | `mediaBytes` (base64) |

Key point: **location is a single issue-level lat/lng pair; there is no per-media location field in the draft.** Media is stored as base64 strings inside the draft record.

### 1.7 `presentation/widgets/camera_viewfinder.dart` (354 lines)

- Callbacks: `onPhotoCaptured(Uint8List, double? lat, double? lng)` and `onGalleryPickSelected(List<Uint8List>)` (lines 12–13).
- `_requestLocation` (lines 58–73): calls injected `LocationService.getCurrentPosition()`; sets `_isGpsLocked`, `_currentLat`, `_currentLng`.
- `_triggerShutter` (lines 168–192): `_controller.takePicture()` → `readAsBytes()`; **attaches lat/lng only if `_isGpsLocked`** (lines 183–184). If no camera hardware, generates dummy bytes (lines 170–175).
- `_triggerGalleryPicker` (lines 194–208): **in-app gallery picker inside the camera sheet** — `picker.pickMultiImage(limit: 4)`.
- GPS status pill UI (lines 271–299), shutter (318–340), flash toggle, camera flip. Gallery button key `galleryPickerButton` (line 313).

### 1.8 `presentation/widgets/media_watermark_badge.dart` (80 lines)

Pure display widget: `isVerified ? 'LocalLens Verified' : 'User Uploaded - Unverified'` (line 20), green vs amber styling.

### 1.9 `presentation/drafts_screen.dart` (414 lines)

- **Multi-select + batch delete already exists**: `_selectMode`, `_selected` set (lines 21–49), select-all (41–49), `_confirmBatchDelete` (73–92), per-draft `_confirmDelete` (59–71).
- `_DraftCard` shows thumbnail from `draft.mediaBytes.first` (line 248), photo count tag (280–285).
- `_openDraft` pushes `RoutePaths.compose` with `extra: draft` (lines 51–57) → pre-filled compose.
- Delete dialog with key `confirmDeleteDraftsButton` (line 110).

### 1.10 `data/offline_outbox_queue.dart` (79 lines)

- Key `locallens_outbox_queue_v1` (line 12); queue of `ComposeDraft` JSON.
- `flush()` (lines 51–78): calls `createIssue(...)` per draft with `latitude ?? 19.1136`, `longitude ?? 72.8697`. **Does NOT re-upload media and does NOT pass `mediaUrls`** — offline-published issues lose their images entirely. Also does not preserve per-image GPS.

---

## 2. BACKEND MEDIA — `backend/app/features/media/`

### 2.1 `router.py` (102 lines)

- **`POST /api/v1/media/upload`** (lines 27–88): accepts multipart `file` OR form field `base64_payload`; also tolerates a JSON body (lines 46–55) reading `base64_payload`/`payload`/`file`, `is_in_app_camera`, `captured_lat`, `captured_lng`, `is_fuzzed`. Auth optional (`get_optional_current_user`). Delegates to `create_media_record`.
- **`GET /api/v1/media/files/{filename}`** (lines 91–102): serves files with a path-traversal guard.
- **No DELETE endpoint exists anywhere in the media feature** (grep for delete in media feature returned nothing). Uploaded media files are permanent.

### 2.2 `service.py` (120 lines)

- `derive_media_hash` (35–40): sha256(bytes + user_id).
- `process_location` (43–51): **fuzzes by `round(lat,2)/round(lng,2)`** when `is_fuzzed`; returns `(None, None)` if either coord missing.
- `validate_verification` (54–60): `is_verified = is_in_app_camera AND lat is not None AND lng is not None` — uses the **raw** captured coords (not fuzzed). Watermark label set accordingly.
- `create_media_record` (63–120): writes bytes to `uploads/media/{id}.jpg`, generates a 300×300 thumbnail, computes URL `/api/v1/media/files/{id}.jpg`, and inserts a `Media` row. **Important: the backend does NOT read EXIF from the image bytes** — GPS is only whatever the client passes in `captured_lat`/`captured_lng`. There is no EXIF parsing anywhere.

### 2.3 `schemas.py` (26 lines)

- `MediaUploadRequest`: `base64_payload?`, `is_in_app_camera=false`, `captured_lat?`, `captured_lng?`, `is_fuzzed=false`.
- `MediaUploadOut`: `id, url, thumbnail_url, is_verified, watermark_label, derived_hash, latitude?, longitude?, is_fuzzed, created_at`.

### 2.4 `models.py` (27 lines) — `Media` table

| Column | Type | Notes |
|---|---|---|
| `id` | String PK | uuid |
| `user_id` | String? | nullable |
| `url` | String | `/api/v1/media/files/{id}.jpg` |
| `thumbnail_url` | String | |
| `is_verified` | Boolean | |
| `watermark_label` | String | |
| `derived_hash` | String | |
| `latitude` | Float? | fuzzed-or-raw |
| `longitude` | Float? | |
| `is_fuzzed` | Boolean | |
| `is_in_app_camera` | Boolean | |
| `created_at` | DateTime | |

**No `issue_id` FK, no `deleted_at`/soft-delete flag.**

---

## 3. BACKEND ISSUES — `backend/app/features/issues/`

### 3.1 `router.py` (422 lines)

- **`POST /api/v1/issues`** (lines 128–137): `create_issue(payload: IssueCreate, session, user, settings)`; guests rejected (403 `guest_restricted`). Media is attached **only as URL strings** in `IssueCreate` → `service.create_issue`.
- `GET /api/v1/issues` (32–66): nearby listing by lat/lng/radius.
- `GET /api/v1/issues/near-duplicate` (69–85): used by compose's 30 m duplicate check.
- **There is NO endpoint that updates an issue's location** (no PATCH/PUT on lat/lng), and **no endpoint that maps images to locations**. `upvote` (239–263) and `quorum-vote` (207–228) accept a reporter `latitude`/`longitude` for proximity checks but never mutate `Issue.latitude/longitude`.

### 3.2 `service.py` (1018 lines)

- `create_issue` (194–239):
  - Fuzz: `is_fuzzed = payload.is_fuzzed or payload.fuzz_location`; if fuzzed, `round(lat, 2)` / `round(lng, 2)` (lines 198–204).
  - `gh = encode_geohash(lat, lng)` (line 206).
  - Media: merges `media_urls` + `media_url` + `video_url` into `media_urls_list`, stores `media_urls=json.dumps(...)` (lines 208–231), `media_url` = first item.
  - `ward` hardcoded `"Ward 45, Urban Central"` (line 223); `status="unacknowledged"`.
- `to_issue_out` (104–191): parses `media_urls` JSON back to a list; there is no per-media lat/lng in the issue response.
- **No function updates issue location.** `detect_near_duplicates` (314–351) reads only.

### 3.3 `schemas.py` (229 lines)

- `IssueCreate` (79–92): `title (min 5)`, `description`, `category`, `latitude (required, ge=-90/le=90)`, `longitude (required, ge=-180/le=180)`, `is_anonymous`, `fuzz_location`, `is_fuzzed`, `is_shielded`, `reporter_id?`, `media_url?`, `video_url?`, `media_urls: list[str]`.
- `IssueOut` (95–129): includes `latitude, longitude, geohash, ward, media_url, video_url, media_urls` etc. **No media-geolocation linkage.**

### 3.4 `models.py` (177 lines) — `Issue` table

`id, title, description, category, status, latitude (Float NOT NULL), longitude (Float NOT NULL), geohash?, ward, is_anonymous, fuzz_location, is_fuzzed, is_shielded, is_hidden, flag_count, reporter_id?, media_url? (String 500), video_url?, media_urls? (Text JSON), created_at, acknowledged_at?, resolved_at?, escalated_at?, upvotes_count, comments_count, resolution_proof?, resolution_notes?, confirmations_count, disputes_count, quorum_expires_at?`.

Map pins (`backend/app/features/geo/service.py:14-76`) query `Issue` lat/lng only — **they do not touch `Media`**; there is currently no map rendering of captured-image locations independent of published issues.

---

## 4. How the compose screen obtains lat/lng

Two independent sources, **with different behavior**:

1. **Real GPS** — `app/lib/core/services/location_service.dart`:
   - `LocationService` singleton via geolocator (lines 8–11); provider `locationServiceProvider` (lines 4–6).
   - `getCurrentPosition()` (lines 18–33) dedupes concurrent calls; `_fetchPositionSafely()` (lines 35–63) checks `isLocationServiceEnabled`, requests permission, then `Geolocator.getCurrentPosition(accuracy: medium, timeLimit: 4s)`. Returns `null` on any failure (never throws).
   - Used by: `compose_screen._openCameraModal` (line 101–102), `_useMyLocation` fallback (230–234), and `CameraViewfinder._requestLocation` (line 59).

2. **Stubbed device source** — `app/lib/features/geo/domain/device_location_service.dart`:
   - `PlatformDeviceLocationService.getCurrentCoordinates()` (lines 20–23) **returns the hardcoded reference point (19.1136, 72.8697) and never queries GPS**.
   - This is what `feedCoordinatesProvider` (`geo_providers.dart:57-64`) and therefore `_createCoords` (compose_providers.dart:21-27) and `_useMyLocation` (compose_screen.dart:225) use. `currentCoordinatesProvider` (geo_providers.dart:50-52) is the same hardcoded fallback.

**Bottom line**: at shutter time the viewfinder attaches real GPS lat/lng to the captured bytes (`onPhotoCaptured(bytes, lat, lng)`), and `_openCameraModal` seeds the camera sheet with real GPS. But on publish, `ComposeController.submit()` uploads media **without** those per-image coords (compose_providers.dart:149-155) and the issue lat/lng defaults to the feed coordinate source (hardcoded reference point unless the user locked a location or pressed "Use my location"). Per-image GPS exists only transiently in `LocalSelectedMedia` (dead controller) and in the `onPhotoCaptured` callback.

---

## 5. Existing "group select" / multi-image and draft-media-delete UI

- **Multi-image gallery selection (exists)**: `compose_screen.dart:_addGalleryImages` (lines 156–194) and `camera_viewfinder.dart:_triggerGalleryPicker` (lines 194–208) both use `ImagePicker().pickMultiImage(limit: 4)`.
- **Per-image delete (exists, compose screen)**: `_removeMedia` (compose_screen.dart:196–200) with the X button per tile (lines 574–591).
- **Draft management (exists, drafts screen)**: multi-select mode with checkboxes, select-all, **batch delete** (`_confirmBatchDelete`, lines 73–92), and **per-draft delete** (`_confirmDelete`, lines 59–71). Also `discard()` in compose_providers.dart (113–120) deletes the draft + autosave.
- **There is no separate "media space / captured-images gallery" screen.** Drafts are the only persistent local store of captured images, and they live as base64 inside the draft JSON in Hive (`drafts` box, `saved_drafts` key). There is no per-image draft, no standalone media entity client-side, and no backend DELETE for media.

---

## 6. Key gaps relevant to the requested changes

1. **Gallery uploads are currently allowed in three places** that must be removed/guarded: the "Add from gallery" button (compose_screen.dart:498–503), the in-camera gallery button (`camera_viewfinder.dart:312-317` → `_triggerGalleryPicker`), and the `pickMultiImage` calls at compose_screen.dart:161–164 and camera_viewfinder.dart:197.
2. **Location is not added to image metadata by default**: `MediaService.packageExifMetadata` exists but is unused; `submit()` in compose_providers.dart:149–155 drops `capturedLat/capturedLng`; the backend does no EXIF parsing and only trusts the form fields.
3. **No draft/media space that can be deleted**: media is either widget-state bytes or base64 embedded in a whole-draft record. There is no concept of an independent captured-image record that can be deleted without deleting the draft/issue; backend `Media` rows have no delete endpoint or soft-delete flag.
4. **Captured image locations don't update the map**: map pins come exclusively from published `Issue.latitude/longitude` (`geo/service.py:62-76`); `Media` is never queried for map pins, and the compose flow only invalidates `mapPinsNotifierProvider` after a successful publish (compose_screen.dart:389).
5. **Offline outbox loses media entirely** (`offline_outbox_queue.dart:58-74` — no `mediaUrls`, no media re-upload).
</task_result>
</task>
```

**Tool: task**

**Input:**
```json
{
  "description": "Explore map and geo flow",
  "prompt": "Explore the LocalLens codebase (Flutter app in `app/`, FastAPI backend in `backend/`) with \"medium\" thoroughness. I need a detailed report on the MAP and GEO features because a user reports: the map doesn't update when issues are added, the heatmap uses concentric circles (wants area-painting/density shading instead), and the ward map only shows a button + a circle (wants actual ward boundary polygons fetched from the web).\n\nReport on:\n1. FRONTEND map: read `app/lib/features/map/presentation/screens/map_screen.dart`, `app/lib/features/map/presentation/controllers/map_controller.dart`, `app/lib/features/map/data/map_api.dart`, `app/lib/features/map/presentation/widgets/map_pin_preview_sheet.dart`, and any heatmap/polygon code. Describe: how pins are fetched (bbox?), whether there is any heatmap rendering today (concentric circles? gradient circles?), any PolygonLayer usage, how the map refreshes (or fails to refresh) after a new issue is created, and whether there is any \"ward boundary\" rendering.\n2. FRONTEND geo: read `app/lib/features/geo/data/geo_api.dart`, `app/lib/features/geo/presentation/providers/geo_providers.dart`, `app/lib/features/geo/domain/device_location_service.dart`.\n3. BACKEND geo: read `backend/app/features/geo/router.py`, `service.py`, `schemas.py`. Describe the map-pins endpoint, reverse-geocode endpoint, any heatmap endpoint, any ward boundary/geometry endpoint.\n4. BACKEND wards: read `backend/app/features/wards/router.py`, `service.py`, `schemas.py`, `models.py`. Describe what ward data exists (name, code, slug, lat/lng, radius?, boundary?).\n5. Check what map libraries are available: read `app/pubspec.yaml` — is flutter_map present? Any heatmap plugin? Also check `app/lib/features/map/presentation/map_screen.dart` (the older duplicate file) vs `screens/map_screen.dart`.\n6. Check the seed data: `backend/seed.py` and `seed/` dir — what ward data is seeded (lat, lng, radius, boundaries)?\n\nReturn a structured report with exact file paths, class/function names, line numbers for key logic, and exact data model fields. Do NOT write any code.",
  "subagent_type": "explore"
}
```

**Output:**
```
<task id="ses_feae99f0cffe3jjtjua516labH" state="completed">
<task_result>
I now have a complete picture. Here is the detailed report.

---

# LocalLens MAP & GEO Feature Report

## Critical headline findings

1. The `wards` table is **empty (0 rows)** in both `backend/locallens.db` and the root `locallens.db`. `backend/seed.py` does **not seed wards at all** (no `Ward` in `_TABLES` or `_DATA_FILES`, lines 50–83).
2. **No polygon / boundary data exists anywhere** in the codebase — no GeoJSON files, no geometry field on the `Ward` model, no boundary endpoint, no `PolygonLayer` usage in the Flutter app.
3. The heatmap is rendered as **concentric `CircleMarker`s** (pixel-radius, not meters), computed client-side by grid-clustering pins. There is **no heatmap plugin** in `pubspec.yaml`.
4. The "old duplicate" `map_screen.dart` is a **3-line barrel re-export**, not a divergent implementation.

---

## 1. FRONTEND map

### Files
- `/Users/rohit/Desktop/Python/LocalLens/app/lib/features/map/presentation/screens/map_screen.dart` (931 lines) — the real screen.
- `/Users/rohit/Desktop/Python/LocalLens/app/lib/features/map/presentation/map_screen.dart` — **barrel only** (3 lines: `export 'screens/map_screen.dart';`).
- `/Users/rohit/Desktop/Python/LocalLens/app/lib/features/map/presentation/controllers/map_controller.dart` (287 lines).
- `/Users/rohit/Desktop/Python/LocalLens/app/lib/features/map/data/map_api.dart` (101 lines).
- `/Users/rohit/Desktop/Python/LocalLens/app/lib/features/map/presentation/widgets/map_pin_preview_sheet.dart` (191 lines) — bottom sheet showing pin details; no map logic.

### How pins are fetched (bbox)
- `MapApi.getMapPins(...)` — `map_api.dart:72-100`. Sends `GET /geo/map-pins` with query params `min_lat, max_lat, min_lng, max_lng` and optional `category`, `status`. Returns a flat `List<MapPin>`.
- `MapPin` model — `map_api.dart:6-61`. Fields: `id, title, category, status, latitude, longitude, wardName, isShielded, upvotesCount, createdAt` (JSON keys `ward_name`, `is_shielded`, `upvotes_count`, `created_at`).
- `MapPinsNotifier.fetchPins()` — `map_controller.dart:175-218`. Reads `state.bounds`, calls the API. If the bbox result is **empty AND** category/status are both `'all'`, it re-queries a **broad regional bbox** `minLat:8.0, maxLat:37.0, minLng:68.0, maxLng:97.0` (lines 192–206).
- `fetchPinsForCenter(lat, lng)` — `map_controller.dart:268-278`. Builds `±0.08°` (~5 km) bounds around the given point then calls `fetchPins()`.
- `_initLocationAndFetch()` — `map_controller.dart:152-173`. Runs in the notifier constructor; uses `LocationService.getCurrentPosition()` (core, real Geolocator) or falls back to default bounds.
- Default bounds — `map_controller.dart:67-72`: `19.1136 ± 0.08` / `72.8697 ± 0.08` (Mumbai / Ward 45).

### Heatmap rendering (today)
- **Computation is 100% client-side**: `MapState.heatmapCells` getter — `map_controller.dart:93-115`. Clusters `filteredPins` into ~`0.003°` (~330 m) grid cells; each `HeatmapCell {lat, lng, density}` is the **average** coordinate of the cell's pins with the pin count as `density`. (`HeatmapCell` class — lines 40–46.)
- **Rendering is concentric circles** — `map_screen.dart:219-252`. For each `HeatmapCell` it draws **3 nested `CircleMarker`s** in a `CircleLayer`:
  - Outer "soft aura": alpha `0.12`, tier 2 (radius × 2.8)
  - Mid "glow ring": alpha `0.30`, tier 1 (radius × 1.8)
  - Hot focal core: alpha `0.65`, tier 0, white border 1.0 px
  - All use `useRadiusInMeter: false` (line 229/237/246) → **radii are in pixels**, so cells render as concentric circles, not area/density shading.
- `_heatmapColor(density, alpha)` — `map_screen.dart:101-106`: green (≤1) → yellow (≤3) → orange (≤6) → red (>6).
- `_heatmapRadius(density, {tier})` — `map_screen.dart:109-127`: base radius 10/16/24/32 px scaled by tier.
- Heatmap legend UI — `map_screen.dart:572-644` (Low/Medium/High/Hotspot swatches).
- **No `PolygonLayer` anywhere** in the app (grep across `app/lib` returned zero matches). No heatmap plugin/package is installed.

### How the map refreshes (or fails to)
Refresh triggers that exist:
- `initState` → `_centerOnUserLocation()` — `map_screen.dart:61-78` → `fetchPinsForCenter` (only if GPS position non-null).
- Notifier constructor → `_initLocationAndFetch()` → `fetchPins()`.
- Manual refresh button — `map_screen.dart:176-180` → `mapNotifier.fetchPins()`.
- Error-banner retry — `map_screen.dart:561-564`.
- Category chip tap — `map_screen.dart:495-497` → `selectCategory` → `fetchPins()` (`map_controller.dart:229-233`).
- **After creating an issue**: `compose_screen.dart:389` calls `ref.invalidate(mapPinsNotifierProvider)`. The map is a `StatefulShellBranch` in an `indexedStack` shell (`app_router.dart:58-66`), so the MapScreen stays mounted; invalidation recreates the notifier → `_initLocationAndFetch` → refetch.

Refresh gaps (why "the map doesn't update"):
- **Panning does NOT refetch.** `onMapEvent` (`map_screen.dart:195-210`) only calls `updateBounds` (`map_controller.dart:257-260`), which sets `isBoundsDirty: true` and shows a "Search this area" FAB (`map_screen.dart:507-520`). Pins already rendered stay stale.
- **`filteredPins` is viewport-agnostic** — `map_controller.dart:78-91` filters only by category/status, never by current bounds, so the rendered set is whatever bbox was last fetched; pins in a newly panned-to area are invisible until manual refresh.
- **Offline-outbox sync never invalidates the map**: `outbox_screen.dart:30` only calls `ref.invalidate(multiTypeFeedProvider)` after `flush()`; `mapPinsNotifierProvider` is untouched (confirmed `offline_outbox_queue.dart:51-60` calls `_feedRepository.createIssue`).
- **No polling / websocket / stream** for live updates.
- New issues are created at `feedCoordinatesProvider` coords (`compose_providers.dart:21-27, 135-141`) — real device GPS or the fixed reference `(19.1136, 72.8697)`. If those coordinates fall outside the map's currently-fetched bbox, the new pin never appears.
- The broad-region fallback (`map_controller.dart:192-206`) only fires when the bbox result is empty **and** no filters are active — a partially-populated bbox suppresses it.

### Ward boundary rendering
- Ward Map mode — `map_screen.dart:298-394`. Renders, per ward:
  - A `CircleMarker` at `ward.centerLatitude/centerLongitude`, radius **48 px**, brand fill alpha `0.15`, 2 px brand border (`useRadiusInMeter: false`).
  - A pill-shaped `Marker` (the "button") showing ward code + "`{activeIssues} active`" (`map_screen.dart:313-393`).
- Ward data source: `wardListNotifierProvider` (`ward_providers.dart:40-44` → `GET /wards`). Because the backend `wards` table is empty, the screen falls back to **2 hard-coded `WardSummaryOut` objects** — `map_screen.dart:138-165` (`ward-45-urban-central` at 19.1136/72.8697 and `ward-12-metro-corridor` at 19.0760/72.8777).
- **No actual boundary polygons are rendered or fetched.**

---

## 2. FRONTEND geo

- `/Users/rohit/Desktop/Python/LocalLens/app/lib/features/geo/data/geo_api.dart` (113 lines):
  - `ReverseGeocode` model (lines 8–85): `latitude, longitude, place, wardSlug?, wardName?, wardCode?, distanceKm, found`.
  - `GeoApi.reverseGeocode()` (lines 98–112): `GET /geo/reverse-geocode?latitude=..&longitude=..&radius_km=..` (default `radiusKm: 50.0`).
- `/Users/rohit/Desktop/Python/LocalLens/app/lib/features/geo/presentation/providers/geo_providers.dart` (115 lines):
  - Sealed `WardLocationState` / `WardLocationLoading` / `WardLocationUnavailable` / `WardLocationSuccess` (lines 8–35; `Success` has `place`, `wardSlug?`, `code`).
  - `geoApiProvider` (37–39), `deviceLocationProvider` (43–45, default `PlatformDeviceLocationService`), `currentCoordinatesProvider` (50–52, fixed `19.1136, 72.8697`), `feedCoordinatesProvider` (57–64, device-first with fixed fallback).
  - `wardLocationProvider` + `WardLocationController` (69–114): resolves `reverseGeocode` once per lifetime; `found=false` → `place: 'Outside coverage'`.
- `/Users/rohit/Desktop/Python/LocalLens/app/lib/features/geo/domain/device_location_service.dart` (24 lines):
  - `DeviceLocationService` abstract (6–9). `PlatformDeviceLocationService.getCurrentCoordinates()` (21–23) — **despite the doc comment claiming real GPS, it ALWAYS returns the hard-coded `(19.1136, 72.8697)`.** (Real GPS is only used by the separate core `LocationService` at `app/lib/core/services/location_service.dart:18-63`, used by the map, not this geo feature.)

---

## 3. BACKEND geo

- `/Users/rohit/Desktop/Python/LocalLens/backend/app/features/geo/router.py` (57 lines):
  - `GET /geo/reverse-geocode` — lines 23–34. Params `latitude`, `longitude`, `radius_km` (default 50.0, `ge=0.1 le=50.0`). Rate-limited (60 req/min, lines 12–20).
  - `GET /geo/map-pins` — lines 37–57. Params `min_lat, max_lat, min_lng, max_lng, category, status` (all optional).
  - **No heatmap endpoint.** **No ward boundary/geometry endpoint.**
- `/Users/rohit/Desktop/Python/LocalLens/backend/app/features/geo/service.py` (148 lines):
  - `get_map_pins()` — lines 14–76. Bbox WHERE on `Issue.latitude/longitude`; privacy filter `is_hidden == False` and `NOT (is_shielded AND status != 'resolved')` (lines 43–50). Missing/invalid bbox falls back to `8/37/68/97`. Category/status matched with `lower(trim())`. Ordered `created_at DESC`. Returns flat `MapPinOut` list — **no aggregation, no geohash/grid output**.
  - `reverse_geocode()` — lines 79–148. Loads **all** wards (id, slug, name, code, center_latitude, center_longitude), computes `haversine_km` to every ward **center** (`issues/geo.py:9-17`, Earth radius 6371), picks the nearest within `radius_km`; `found=False` → `place="Outside coverage"`, `distance_km=0.0`. **Pure center-distance logic; no boundary/point-in-polygon.**
- `/Users/rohit/Desktop/Python/LocalLens/backend/app/features/geo/schemas.py` (39 lines):
  - `ReverseGeocodeWardOut` (6–14): `slug, name, code, center_latitude, center_longitude`.
  - `ReverseGeocodeOut` (16–24): `latitude, longitude, place, ward: ReverseGeocodeWardOut | None, distance_km, found`.
  - `MapPinOut` (27–39): `id, title, category, status, latitude, longitude, ward_name, is_shielded, upvotes_count, created_at`.

---

## 4. BACKEND wards

- `/Users/rohit/Desktop/Python/LocalLens/backend/app/features/wards/models.py` (62 lines):
  - `Ward` (lines 9–23), table `wards`. Fields: `id` (PK), `name` (String 255, indexed), `slug` (String 255, unique+indexed), `code` (String 50, indexed), `center_latitude` (Float NOT NULL), `center_longitude` (Float NOT NULL), `created_at`, `updated_at`.
  - **No `radius` field. No `boundary`/`geometry`/`polygon`/`geojson` field.**
  - Also defines `LocalTalkPost` (26–43) and `Notice` (46–61).
- `/Users/rohit/Desktop/Python/LocalLens/backend/app/features/wards/schemas.py` (90 lines):
  - `WardSummaryOut` (16–30): `slug, name, code, center_latitude, center_longitude, total_issues, active_issues, escalated_issues, resolved_issues, resolution_rate_pct`.
  - `WardDetailOut` (33–43) extends it with `top_categories`, `assigned_representative`, `recent_issues`, `updated_at`.
  - `WardListResponse` (46–52): `items, total, limit, offset`.
  - Plus `LocalTalkPostCreate/Out`, `NoticeOut`, `AssignedRepresentativeOut`.
- `/Users/rohit/Desktop/Python/LocalLens/backend/app/features/wards/router.py` (106 lines): `GET /by-location` (46–56), `GET /{ward_slug}` (59–69), `GET ""` (72–80), `POST /{ward_slug}/talk` (83–93), `GET /{ward_slug}/talk` (96–105). Mounted at `/api/v1/wards` (`backend/app/api/router.py:46`).
- `/Users/rohit/Desktop/Python/LocalLens/backend/app/features/wards/service.py` (412 lines):
  - `list_wards()` (197–223): paginated, computes per-ward metrics via `_get_ward_metrics` (59–110) which matches `Issue.ward` against name/slug/code with `ilike`.
  - `get_ward_detail()` (113–191), `get_ward_by_location()` (229–275, nearest center within 50 km).
  - **Data reality check:** `wards` table has **0 rows** in both `backend/locallens.db` and root `locallens.db`. Tests seed wards only via raw `INSERT OR REPLACE INTO wards (...)` (e.g., `backend/tests/features/geo/test_geo.py:81-118`, `test_ward_place_page.py:34`). So in a real run, `GET /wards` returns `items: []`, and the ward map shows only the 2 hard-coded fallbacks.

---

## 5. Map libraries available

- `/Users/rohit/Desktop/Python/LocalLens/app/pubspec.yaml`:
  - `flutter_map: ^8.1.1` (line 26) — present.
  - `latlong2: ^0.9.1` (line 27) — present.
  - **No heatmap plugin** (no `flutter_map_heatmap`, `flutter_map_marker_cluster`, etc.). `flutter_map` core provides `TileLayer`, `MarkerLayer`, `CircleLayer`, and also `PolygonLayer`/`PolylineLayer` — the latter are simply unused.
- Older duplicate: `app/lib/features/map/presentation/map_screen.dart` is **not** a divergent copy — it is a 3-line barrel re-export of `screens/map_screen.dart`.

---

## 6. Seed data

- `/Users/rohit/Desktop/Python/LocalLens/backend/seed.py` (666 lines):
  - Seeds: users, media, issues, representatives, comments, upvotes, notifications, flags, moderation_audits, gamification, official_responses, quorum_votes (`_DATA_FILES`, lines 70–83). **Wards are NOT in the seed list and NOT in `_TABLES` (lines 50–67).** No `ward` seed function exists.
  - Issues derive `geohash` and `ward` from `row["ward"]` defaulting to `"Ward 45, Urban Central"` (lines 262–292).
- `seed/data/` — 12 JSON files; **no wards file, no GeoJSON**. Issues: 19 seeded, all `ward: "Ward 45, Urban Central"`, lat ~19.11, lng ~72.86–72.87.
- Current DB state (`backend/locallens.db`): 30 issues; min lng **-122.41** (an issue far outside even the broad 68–97 lng fallback — i.e., permanently invisible on the map), max lat 37.79.

---

## Root-cause mapping to the three user complaints

**A. "Map doesn't update when issues are added"**
- The only refresh hook is `ref.invalidate(mapPinsNotifierProvider)` in `compose_screen.dart:389`, which fires only for issues submitted through that compose screen; offline-outbox sync (`outbox_screen.dart:30`) never invalidates the map.
- Panning sets `isBoundsDirty` but does not refetch (`map_screen.dart:195-210`, `map_controller.dart:257-260`); `filteredPins` (`map_controller.dart:78-91`) renders the last-fetched bbox without viewport filtering, so newly created pins in a panned-to area are invisible until the manual "Search this area" FAB is tapped.
- New-issue coordinates (`compose_providers.dart:135-141`, device GPS or fixed reference point) may fall outside the map's currently fetched `state.bounds`, and the empty-result broad fallback (`map_controller.dart:192-206`) is suppressed whenever the bbox returns even one pin.
- No live/polling mechanism exists.

**B. "Heatmap uses concentric circles"**
- Confirmed: 3 nested `CircleMarker`s per grid cell with pixel radii and fixed alpha tiers (`map_screen.dart:219-252`), client-side grid clustering only (`map_controller.dart:93-115`). There is no area-painting / density-shading raster, no heatmap plugin, and no `PolygonLayer` fill anywhere.

**C. "Ward map only shows a button + a circle"**
- Confirmed: Ward Map mode renders a 48-px translucent `CircleMarker` per ward center plus a pill `Marker` (code + active count) (`map_screen.dart:298-394`). There are **no ward boundary polygons** anywhere: no geometry field on `Ward` (`wards/models.py:9-23`), no backend boundary/geometry endpoint (`geo/router.py` has only `reverse-geocode` and `map-pins`), no GeoJSON in seed data, and the `wards` table is empty so only 2 hard-coded fallback centers are displayed (`map_screen.dart:138-165`). Real boundary polygons would have to be fetched from the web (e.g., OSM/Overpass/GeoJSON source) and rendered with a `PolygonLayer` — none of that exists today.
</task_result>
</task>
```

**Tool: task**

**Input:**
```json
{
  "description": "Explore search feature",
  "prompt": "Explore the LocalLens codebase (Flutter app in `app/`, FastAPI backend in `backend/`) with \"medium\" thoroughness. A user reports the SEARCH feature is broken: \"Search is still not working, I always shows 'Search unavailable' in the front end.\"\n\nReport on:\n1. FRONTEND search: read `app/lib/features/search/presentation/search_screen.dart`, `search_providers.dart`, `search_filters_provider.dart`, `data/search_api.dart`, `data/recent_search_store.dart`, `domain/search_repository.dart`, `domain/search_filters.dart`, `presentation/advanced_filter_sheet.dart`. Find where the string \"Search unavailable\" (or similar error copy) appears — search the whole app/lib for \"unavailable\", \"Search unavailable\", \"search\", \"error\". Explain the exact UI state/exception path that leads to showing \"Search unavailable\". Note the search API base URL, the endpoint path it calls, query parameters, and how the response is parsed. Identify any mismatch between what the frontend calls and what the backend exposes.\n2. BACKEND search: read `backend/app/features/search/router.py`, `service.py`. Describe the GET /search endpoint, its exact path/route prefix, required vs optional params, and response model.\n3. Check `app/lib/core/config/app_config.dart` and `app/lib/core/network/api_client.dart` for how the base URL is built and how search endpoint path is composed. Check `app/lib/core/router/route_paths.dart` and `app_router.dart` for the /search route.\n4. Check recent test files `app/test/features/search/search_screen_test.dart` and `search_api_test.dart` to understand what behaviour is expected.\n5. Note the routing prefix: is the backend mounted under /api/v1? Read `backend/app/api/router.py` and `backend/app/main.py`.\n\nReturn a structured report with exact file paths, function names, line numbers, the exact error copy strings, and the exact endpoint URL paths on both sides. Do NOT write any code.",
  "subagent_type": "explore"
}
```

**Output:**
```
<task id="ses_feae98538ffeLTU6JMzXck2HUV" state="completed">
<task_result>
I now have a complete picture. Here is the structured report.

---

# LocalLens SEARCH feature — investigation report

## 1. FRONTEND search

### 1.1 Exact error copy and where it appears

The string **"Search unavailable"** is a hardcoded literal (NOT from `core/l10n/app_strings.dart`) at:

- **File:** `/Users/rohit/Desktop/Python/LocalLens/app/lib/features/search/presentation/search_screen.dart`
- **Lines 290–296**, inside `_buildResultsBody(AsyncValue<List<Issue>> results)`:

```dart
error: (_, _) => EmptyState(
  icon: Icons.cloud_off_outlined,
  title: 'Search unavailable',                       // line 292
  message: 'We could not reach the server right now.', // line 293
  actionLabel: 'Retry',                              // line 294
  onAction: _retryLastQuery,                         // line 295
),
```

A full-repo grep for `unavailable` found only these frontend occurrences: `search_screen.dart:233` ("Feed unavailable" — the preloaded-feed branch, unrelated), `reels_screen.dart:56`, `ward_location_chip.dart:28`, and l10n keys `feed_unavailable`/`feed_unavailable_msg`. There is **no l10n key for search** — the copy is hardcoded.

### 1.2 Exact UI state / exception path that leads to "Search unavailable"

1. User types → `_onQueryChanged` (`search_screen.dart:40-50`) debounces 400 ms → `_runSearch(trimmed)` (`search_screen.dart:52-55`) → `ref.read(searchResultsProvider.notifier).runQuery(query)`.
2. **`SearchResultsNotifier.runQuery`** — `/Users/rohit/Desktop/Python/LocalLens/app/lib/features/search/presentation/search_providers.dart:56-94`:
   - sets `state = const AsyncLoading()`, then
   - `state = await AsyncValue.guard(() async { ... })` (line 60).
   - The guard reads `searchFiltersProvider`, computes optional `latitude`/`longitude`/`radiusKm` (using `defaultLatitude=19.1136`, `defaultLongitude=72.8697` from `feed_providers.dart:14-15` only when `SearchDistanceOption.within`), computes `createdAfter`, then calls `searchRepositoryProvider.search(...)` (lines 79-90).
   - **Any exception thrown inside the guard** (network failure, HTTP error, JSON parse failure, `TypeError` from `data as List<dynamic>`) becomes `AsyncError`.
3. `_buildResultsBody`'s `.when(error:)` branch (line 290) renders the `EmptyState` titled **"Search unavailable"**. This is the catch-all error UI — it does not distinguish 404/422/429/500/connection-refused; all of them surface the identical copy.
4. Exception mapping: `ApiClient.getJson` (`app/lib/core/network/api_client.dart:23-30`) rethrows via `mapDioException` (`app/lib/core/network/api_exceptions.dart:59-71`) → `ApiNetworkException` (timeouts/connection) or `ApiServerException` (non-401 HTTP errors, message extracted from `data['detail']`). Both are `ApiException`s; the UI ignores the message entirely.

### 1.3 Search API call: base URL, path, params, response parsing

**File:** `/Users/rohit/Desktop/Python/LocalLens/app/lib/features/search/data/search_api.dart` (`SearchApi.search`, lines 11-43)

- **Base URL:** `http://127.0.0.1:8000/api/v1` — `app/lib/core/config/app_config.dart:9` (`AppConfig.dev`), unconditionally selected by `app_config_provider.dart:5`.
- **Path passed to Dio:** `'/search'` (line 23) → composed URL: **`GET http://127.0.0.1:8000/api/v1/search`**.
- **Query parameters** (lines 24-37): `q` (required), `limit: 20` (always), and conditionally `latitude`, `longitude`, `status`, `categories` (List<String>, repeated keys via Dio `ListFormat.multi`, dio ^5.11.0), `radius_km`, `created_after`/`created_before` (Dart `toIso8601String()`, ends with `Z`), `ward`.
- **Response parsing** (lines 39-42): `final items = data as List<dynamic>;` then `Issue.fromJson(item as Map<String, Object?>)` — `app/lib/features/feed/domain/issue.dart:40` (freezed + json_serializable). Required fields on the Dart model (`id, title, description, category, status, latitude, longitude, is_anonymous, reporter_label, created_at`) all exist in the backend `IssueOut` schema.

### 1.4 Repository/provider plumbing

- `domain/search_repository.dart:3-14` — abstract `search(...)` signature (query, latitude, longitude, status, categories, radiusKm, createdAfter, createdBefore, ward).
- `search_providers.dart:13-15` — `searchRepositoryProvider` → `SearchApi(ref.watch(apiClientProvider))`; `apiClientProvider` (`core/network/network_providers.dart:9-22`) builds `ApiClient` with `config.apiBaseUrl` and the restored auth token.
- `presentation/search_filters_provider.dart` and `domain/search_filters.dart` — `SearchFilters` state (status, categories, distanceOption, radiusKm default 5.0, datePreset, ward) and the allowed status/category constants (`search_filters.dart:52-70`).
- `presentation/advanced_filter_sheet.dart` — M3 bottom sheet returning a `SearchFilters?`.

## 2. BACKEND search

**File:** `/Users/rohit/Desktop/Python/LocalLens/backend/app/features/search/router.py`

- Line 12: `router = APIRouter()` (no prefix on the router itself).
- Line 34: `@router.get("", response_model=list[IssueOut])` — function `search_issues_endpoint` (line 35).
- **Mounted at** `GET /api/v1/search` via `backend/app/api/router.py:34` (`api_router = APIRouter(prefix="/api/v1")`) + line 43 (`api_router.include_router(search_router, prefix="/search", tags=["search"])`), included in the app at `backend/app/main.py:54`.
- **Required param:** `q: Annotated[str, Query()]` (line 38) — missing/whitespace → 422 (`empty_query`, lines 53-55); >100 chars → 422 (lines 56-59).
- **Optional params** (lines 41-51):
  - `latitude` (ge=-90, le=90) / `longitude` (ge=-180, le=180) — must be provided as a pair else 400 `both_coordinates_required` (lines 60-65).
  - `radius_km` (default 5.0, ge=0.1, le=50).
  - `status` — one of `{unacknowledged, open, under_review, acknowledged, escalating, forwarded, pending_quorum, resolved, disputed}` else 422 (lines 14-24, 66-67). Note: every frontend `kSearchStatusOptions` value is in this set.
  - `category` (≤32), `categories` (list, ≤20 items of ≤32 chars), `ward` (≤64 chars, lines 80-83), `created_after`/`created_before` (ISO strings, parsed by `service.parse_iso_datetime`, lines 84-99), `limit` (default 20, 1..50), `offset` (default 0).
- **Auth:** optional bearer via `OptionalUser` (`api/deps.py:101`); `_rate_limit_search` dep (lines 27-31) → 429 `rate_limited` past 60 req/min (`main.py:42`).
- **Response:** raw `list[IssueOut]` (`backend/app/features/issues/schemas.py:95-129`), serialized with `issues.service.to_issue_out(...)` and `get_user_upvoted_issue_ids` (lines 101-129).

**File:** `/Users/rohit/Desktop/Python/LocalLens/backend/app/features/search/service.py` — `search_issues` (lines 53-139): case-insensitive `ilike` across `title/description/category/ward` with `_escape_like`; optional bbox+haversine proximity; status/category/categories/ward/date filters; `created_at desc` + limit/offset; `evaluate_escalation`; excludes `is_shielded` non-resolved.

## 3. Config / network / router wiring

- **Base URL:** hardcoded `http://127.0.0.1:8000/api/v1` (`app_config.dart:9`), always used (`app_config_provider.dart:5`). No `--dart-define` override exists anywhere.
- **Path composition:** `ApiClient` (`api_client.dart:10-16`) sets `baseUrl` on the Dio `BaseOptions`; `SearchApi` passes the relative `/search`; Dio joins → `http://127.0.0.1:8000/api/v1/search`.
- **App route:** `route_paths.dart:16` (`search = '/search'`); registered `GoRoute(path: RoutePaths.search, ... const SearchScreen())` at `app_router.dart:205-209`.
- **Platform config:** Android allows cleartext (`AndroidManifest.xml:27` `android:usesCleartextTraffic="true"`). iOS `Info.plist` has **no** `NSAppTransportSecurity` entry — cleartext HTTP to non-loopback hosts would be blocked by ATS.

## 4. Tests (expected behavior)

- `app/test/features/search/search_screen_test.dart`:
  - Lines 212-230: `'error shows Search unavailable and Retry re-runs'` — fake repo throws `StateError` → asserts `find.text('Search unavailable')` (line 223) → clears error → taps Retry → results appear, `searchCount == 2`. So the widget contract is: **any repository exception ⇒ "Search unavailable"**.
  - Other tests pin: debounced single call (135-144, 251-261), empty results → `'No issues found'` (172-179), recents rendering/tap (181-197), `RoutePaths.search == '/search'` (109-111).
- `app/test/features/search/search_api_test.dart` (lines 35-54): asserts path `'/search'`, `q`, `limit == 20`, `latitude`/`longitude` omitted when null, `Issue.fromJson` parsing.
- `app/test/features/search/search_api_filters_test.dart`: asserts filters map onto `status`, repeated `categories`, `radius_km`, `created_after`/`created_before` ending in `Z`.

## 5. Mismatch analysis — code contracts are ALIGNED

Comparing every frontend param vs the backend signature, **there is no contract mismatch**:

| Aspect | Frontend | Backend | Match |
|---|---|---|---|
| URL | `GET http://127.0.0.1:8000/api/v1/search` | `GET /api/v1/search` (prefix `/api/v1` + `/search` + `""`) | ✅ |
| Required param | `q` | `q` required | ✅ |
| Filters | status, categories[], radius_km, created_after, created_before, ward, lat/lng, limit=20 | identical names/types | ✅ |
| Response | `List<Issue>` via `Issue.fromJson` | `list[IssueOut]` | ✅ (all required Dart fields present) |

**Live verification (read-only, backend currently running):** `curl "http://127.0.0.1:8000/api/v1/search?q=pothole&limit=20"` → **HTTP 200** with a proper `IssueOut` array; repeated `categories=road&categories=water` → 200; `ward` → 200; `created_after=...Z` → 200; invalid bearer token → 200 (auth is optional). Filter-conflict combos return 200 `[]` (which the UI shows as "No issues found", not "Search unavailable").

## 6. Where the reported failure most likely originates

Because every code path and the live endpoint check out, "Search unavailable" in the real app is the **catch-all `AsyncError` branch** triggered by one of these runtime conditions:

1. **Base URL unreachable from the app's platform** (highest likelihood): `AppConfig.dev` pins `http://127.0.0.1:8000/api/v1` (`app_config.dart:9`). This only works on iOS simulator / macOS / Chrome. On an **Android emulator** it must be `10.0.2.2` (explicitly documented in `README.md:59-61` and the comment at `app_config.dart:8`); on a physical device it needs the host LAN IP. Either case → `DioException` connectionError → `ApiNetworkException` → "Search unavailable" for every query.
2. **Backend not running, or a stale backend process** that predates the `/search` route → connection refused, or HTTP 404 on `/api/v1/search` (while the older `/api/v1/feed` route still works) → error state. Restart with `make backend` (`uvicorn app.main:app --reload`), which also runs `alembic upgrade head`.
3. **Rate limit:** 60 searches/min per identity (`router.py:27-31`, `main.py:42`); repeated quick searching as a guest pools on the `"anon"` key and can return 429 `rate_limited` → error state.
4. **Any 4xx/5xx or non-list response** from `/api/v1/search` → error state (the UI never reads the error message; every failure renders the same copy).

**Additional context:** all search-related files (`app/lib/features/search/**`, `backend/app/features/search/**`, the tests) have **uncommitted modifications** (`git status`); the diffs are additive (a `ward` filter wired end-to-end + UI refinements) and do not break the basic search path. `docs/specs/F-08_search_validation.md` (2026-08-10) reports a PASS with the exact string "Search unavailable" mandated by `F-08_search_contracts.md §2.5`.
</task_result>
</task>
```

**Tool: task**

**Input:**
```json
{
  "description": "Explore rep/profile/ward pages",
  "prompt": "Explore the LocalLens codebase (Flutter app in `app/`, FastAPI backend in `backend/`) with \"medium\" thoroughness. A user wants changes to: (1) separate accounts for issue-resolvers/representatives with a different display showing issues resolved count, pending count, etc. so citizens can judge if reps are doing their job; (2) a ward details page; (3) a better profile page view.\n\nReport on:\n1. REPRESENTATIVE backend: read `backend/app/features/representatives/router.py`, `service.py`, `schemas.py`, `models.py`. Describe the Representative model fields, the `/representatives/me` and `/representatives/dashboard` endpoints, what metrics are computed (total, escalated, acknowledged, in_progress), whether resolved/pending counts exist, and how a user becomes a representative.\n2. REPRESENTATIVE frontend: read `app/lib/features/rep_dashboard/presentation/rep_dashboard_screen.dart`, `rep_dashboard_providers.dart`, `data/repositories/rep_dashboard_repository.dart`, `domain/representative_profile.dart`, `domain/ward_issues_response.dart`, `domain/official_response.dart`. Describe the dashboard UI and what metrics it shows. Note any Keys used.\n3. WARD detail frontend+backend: read `app/lib/features/ward/presentation/screens/ward_detail_screen.dart` (and `presentation/ward_detail_screen.dart` if it exists), `data/ward_repository.dart`, `domain/ward_detail_model.dart`, `presentation/widgets/*` (ward_hero_banner, ward_metric_card, ward_rep_card, ward_recent_issues_list), `app/lib/features/ward/presentation/providers/ward_providers.dart`. And backend `backend/app/features/wards/router.py`, `service.py`, `schemas.py`, `models.py`. Describe what the ward details page currently shows and what data the backend provides (metrics, rep, recent issues, boundary?).\n4. PROFILE frontend: read `app/lib/features/profile/presentation/screens/profile_screen.dart`, `profile_providers.dart`, `domain/user_profile.dart`, `domain/public_user_profile.dart`, and `app/lib/features/profile/presentation/screens/public_profile_screen.dart`. Describe the current profile page layout/sections and what data it displays. Also check the router `app/lib/core/router/app_router.dart` for the profile routes.\n5. How are users flagged as representatives? Read `backend/app/core/security.py` and `backend/app/api/deps.py` for role/scope checks.\n\nReturn a structured report with exact file paths, class names, line numbers for key logic, data model fields, and exact UI sections. Do NOT write any code.",
  "subagent_type": "explore"
}
```

**Output:**
```
<task id="ses_feae975c1ffeFQyEtgy4wzLVbz" state="completed">
<task_result>
I now have a complete picture. Here is the structured report.

---

# LocalLens Codebase Exploration Report

## 1. REPRESENTATIVE Backend

### Files
- `/Users/rohit/Desktop/Python/LocalLens/backend/app/features/representatives/models.py`
- `/Users/rohit/Desktop/Python/LocalLens/backend/app/features/representatives/schemas.py`
- `/Users/rohit/Desktop/Python/LocalLens/backend/app/features/representatives/service.py`
- `/Users/rohit/Desktop/Python/LocalLens/backend/app/features/representatives/router.py`

### Data model — `models.py`
- **`RepresentativeProfile`** (tablename `representative_profiles`, line 14):
  - `id: str` (PK, `String(255)`)
  - `user_id: int` (FK → `users.id`, `unique`, `index`)
  - `official_name: str`
  - `title: str`
  - `ward: str` (indexed)
  - `verified_at: datetime`
  - Relationships: `user` (1:1 back-populated), `official_responses`
- **`OfficialResponse`** (tablename `official_responses`, line 32):
  - `id: str` (PK), `issue_id: int` (FK), `representative_id: str` (FK), `message: str` (1000), `estimated_resolution_days: int | None`, `status_update: str | None`, `created_at: datetime`
  - `status_update` is constrained (in `schemas.py` lines 28–33) to only `"acknowledged"` or `"in_progress"`.

### Endpoints — `router.py` (there is **no `/representatives/dashboard` endpoint**; the actual endpoints are:)
| Endpoint | Line | Response |
|---|---|---|
| `GET /representatives/me` | 48 | `RepresentativeProfileOut` (the "dashboard" data) |
| `GET /representatives/ward-issues` | 57 | `WardIssuesResponse` — filter `all|escalated|needs_response`, `limit`, `offset` |
| `POST /issues/{issue_id}/official-response` | 77 | `OfficialResponseOut` |
| `GET /issues/{issue_id}/official-responses` | 92 | `list[OfficialResponseOut]` |

### Metrics computed — `service.py` `get_representative_profile_out` (lines 27–62)
| Metric | How computed |
|---|---|
| `total_ward_issues` | count of all `Issue` rows where `Issue.ward == profile.ward` (line 30) |
| `escalated_ward_issues` | count where `status == "escalated"` only (line 34) |
| `responded_ward_issues` | distinct issues in ward having ≥1 `OfficialResponse` (lines 40–47) |
| `pending_response_ward_issues` | `max(0, total - responded)` (line 49) |

**Resolved/pending counts:** There is **no `resolved` count**, and **no aggregated `acknowledged`/`in_progress` count** in the rep profile. `acknowledged`/`in_progress` exist only as per-response `status_update` values stored on `OfficialResponse` but are never aggregated. `pending_response_ward_issues` means "issues with no official response", not "issues pending resolution". This is the gap for the user's request — a "resolved count" and an "acknowledged/in_progress split" would be new work.

### How a user becomes a representative
- **No self-serve or admin API exists.** `RepresentativeProfile` rows are created only by seed data (`/Users/rohit/Desktop/Python/LocalLens/backend/seed.py`, `_seed_representatives`, line 298) and tests.
- Enforcement: `get_current_rep_profile` in `router.py` (lines 27–41) loads `RepresentativeProfile` by `user_id`; guests or users without a row get `403 not_representative`.
- `User` model (`/Users/rohit/Desktop/Python/LocalLens/backend/app/features/auth/models.py`): `representative_profile` relationship (line 41) and `is_representative` property (line 46). The `User.role` column (default `"citizen"`, line 31) is **not** used for the rep check.

---

## 2. REPRESENTATIVE Frontend

### Files
- `/Users/rohit/Desktop/Python/LocalLens/app/lib/features/rep_dashboard/presentation/rep_dashboard_screen.dart`
- `/Users/rohit/Desktop/Python/LocalLens/app/lib/features/rep_dashboard/presentation/rep_dashboard_providers.dart`
- `/Users/rohit/Desktop/Python/LocalLens/app/lib/features/rep_dashboard/data/repositories/rep_dashboard_repository.dart`
- `/Users/rohit/Desktop/Python/LocalLens/app/lib/features/rep_dashboard/domain/representative_profile.dart`
- `/Users/rohit/Desktop/Python/LocalLens/app/lib/features/rep_dashboard/domain/ward_issues_response.dart`
- `/Users/rohit/Desktop/Python/LocalLens/app/lib/features/rep_dashboard/domain/official_response.dart`

### Dashboard UI — `rep_dashboard_screen.dart` (`RepDashboardScreen`, ConsumerWidget, line 12)
Layout top-to-bottom:
1. **Rep profile card** (lines 55–108): `CircleAvatar`, `officialName` (key `repProfileName`), `title`, ward chip (key `repProfileWard`).
2. **Metrics row** (lines 112–141), 3 `_MetricCard`s:
   - `metricTotalWardIssues` → "Total Ward Issues"
   - `metricEscalatedWardIssues` → "Escalated"
   - `metricPendingResponseWardIssues` → "Pending Response"
   - **Note:** `respondedWardIssues` exists in the model but is **not displayed**.
3. **Filter chips** (lines 145–171): keys `wardFilterChip_all`, `wardFilterChip_escalated`, `wardFilterChip_needs_response` (drives `wardIssuesFilterProvider`).
4. **Ward issues list** (lines 175–264): key `wardIssueList`; each row = title + `StatusBadge`, description, category/ward, and a `FilledButton` keyed `respondToIssueButton_${issue.id}` opening `PostOfficialResponseDialog`.

There is no tab/dock entry to this screen anywhere in the app — it is reachable only via the route `/rep-dashboard` (`app_router.dart` line 186–190). The profile screen does not link to it.

### Providers — `rep_dashboard_providers.dart`
- `repProfileProvider` (FutureProvider, line 16) → `fetchRepresentativeProfile()`
- `wardIssuesFilterProvider` (StateProvider, default `'all'`, line 21)
- `wardIssuesProvider` (FutureProvider.family by filter, line 23)
- `officialResponsesProvider` (FutureProvider.family by issueId, line 28)
- `RepDashboardNotifier` (line 33) — `postOfficialResponse()` then invalidates rep profile, ward issues, and official responses.

### Repository — `rep_dashboard_repository.dart`
- `fetchRepresentativeProfile()` → `GET /representatives/me`, caches under `'rep_profile'` in `LocalStore` with cache fallback (lines 15–33).
- `fetchWardIssues({filter, limit, offset})` → `GET /representatives/ward-issues` (line 35).
- `postOfficialResponse(...)` → `POST /issues/$issueId/official-response` (line 51).
- `fetchOfficialResponses(issueId)` → `GET /issues/$issueId/official-responses` (line 69).

### Domain models
- `RepresentativeProfile` (representative_profile.dart): `id`, `userId`, `officialName`, `title`, `ward`, `verifiedAt`, `totalWardIssues`, `escalatedWardIssues`, `respondedWardIssues`, `pendingResponseWardIssues`.
- `WardIssuesResponse` (ward_issues_response.dart): `items: List<Issue>`, `total` (reuses feed `Issue`).
- `OfficialResponse` (official_response.dart): `id`, `issueId`, `representativeId`, `officialName`, `title`, `ward`, `message`, `estimatedResolutionDays`, `statusUpdate`, `createdAt`.

---

## 3. WARD Detail — Frontend + Backend

### Frontend files
- `/Users/rohit/Desktop/Python/LocalLens/app/lib/features/ward/presentation/screens/ward_detail_screen.dart` (the real screen; `presentation/ward_detail_screen.dart` is just an `export` barrel)
- `/Users/rohit/Desktop/Python/LocalLens/app/lib/features/ward/data/repositories/ward_repository.dart`
- `/Users/rohit/Desktop/Python/LocalLens/app/lib/features/ward/domain/ward_detail_out.dart`, `ward_representative_out.dart`
- `/Users/rohit/Desktop/Python/LocalLens/app/lib/features/ward/presentation/providers/ward_providers.dart`
- Widgets: `ward_hero_banner.dart`, `ward_metric_card.dart`, `ward_rep_card.dart`, `ward_recent_issues_list.dart`

### Screen — `ward_detail_screen.dart` (`WardDetailScreen`, ConsumerStatefulWidget, line 13)
Keys: `wardDetailScreen` (Scaffold, line 76), `wardDetailBackButton`, `wardIssueSearchField`. Sections rendered in `body` (lines 88–263):
1. **`WardHeroBanner`** — name, code chip, center lat/lng.
2. **`WardMetricsGrid`** — 5 `WardMetricCard`s (keys `wardMetricTotal`, `wardMetricActive`, `wardMetricEscalated`, `wardMetricResolved`, `wardMetricResolutionRate`): Total Issues, Active, Escalated, Resolved, Resolution Rate.
3. **"Ward Representatives" section** (lines 97–137): if `assignedRepresentative != null` → `WardRepCard`; **`onTap` is an empty callback** (lines 115–117: `// Navigate to public profile if available`) — no navigation wired. Otherwise a "No representative assigned yet" card.
4. **Search bar** (lines 141–165) + **filter tabs** Active/Escalated/Resolved/All (lines 190–227, `_IssueFilterChip`).
5. **Issues list** (lines 256–263): client-side filtered `IssueCard`s via `_filterIssues` (lines 33–67). The `ward_recent_issues_list.dart` widget (`WardRecentIssuesList`, key `wardRecentIssuesList`) exists but is **not used** by this screen.

### Frontend domain
- `WardDetailOut` (ward_detail_out.dart): `slug`, `name`, `code`, `centerLatitude`, `centerLongitude`, `totalIssues`, `activeIssues`, `escalatedIssues`, `resolvedIssues`, `resolutionRatePct`, `topCategories`, `assignedRepresentative?`, `recentIssues`, `updatedAt`.
- `WardRepresentativeOut` (ward_representative_out.dart): only `officialName`, `title`, `verifiedAt` — **no id, user_id, or performance metrics**, so the current ward card cannot show resolved/pending counts.

### Providers — `ward_providers.dart`
- `wardRepositoryProvider`, `wardDetailNotifierProvider` (`FutureProvider.family.autoDispose<WardDetailOut, String>` with local-store cache fallback, lines 14–38), `wardListNotifierProvider`.

### Backend files
- `/Users/rohit/Desktop/Python/LocalLens/backend/app/features/wards/models.py`
- `/Users/rohit/Desktop/Python/LocalLens/backend/app/features/wards/schemas.py`
- `/Users/rohit/Desktop/Python/LocalLens/backend/app/features/wards/service.py`
- `/Users/rohit/Desktop/Python/LocalLens/backend/app/features/wards/router.py`

### Backend model — `Ward` (models.py line 9)
`id`, `name`, `slug` (unique), `code`, `center_latitude`, `center_longitude`, `created_at`, `updated_at`. Also `LocalTalkPost` (line 26) and `Notice` (line 46). **There is no boundary/polygon data anywhere** — only the center point is stored and returned.

### Backend schemas (schemas.py)
- `AssignedRepresentativeOut` (line 8): `official_name`, `title`, `verified_at` (matches the frontend — no metrics).
- `WardSummaryOut` (line 16): `slug`, `name`, `code`, `center_latitude`, `center_longitude`, `total_issues`, `active_issues`, `escalated_issues`, `resolved_issues`, `resolution_rate_pct`.
- `WardDetailOut` (line 33): extends summary with `top_categories`, `assigned_representative`, `recent_issues` (`IssueOut[]`), `updated_at`.
- `WardListResponse`, `LocalTalkPostCreate/Out`, `NoticeOut`.

### Backend service (service.py)
- `_get_ward_metrics` (lines 59–110): total / resolved / escalated (statuses `escalated|escalating|forwarded` or `escalated_at` set) / active (a set of open statuses) / resolution rate.
- `get_ward_detail` (lines 113–191): fuzzy ward lookup by slug/name; top 5 categories (lines 142–150); **first** `RepresentativeProfile` matching ward name/slug (lines 153–163); recent issues excluding shielded-unresolved (lines 166–174).

### Backend router (router.py)
`GET /wards/by-location`, `GET /wards/{ward_slug}` (`issues_limit` query, default 10), `GET /wards`, `POST /wards/{ward_slug}/talk`, `GET /wards/{ward_slug}/talk`. Rate-limited by IP.

---

## 4. PROFILE Frontend

### Files
- `/Users/rohit/Desktop/Python/LocalLens/app/lib/features/profile/presentation/screens/profile_screen.dart` (real screen; `presentation/profile_screen.dart` is an export barrel)
- `/Users/rohit/Desktop/Python/LocalLens/app/lib/features/profile/presentation/profile_providers.dart`
- `/Users/rohit/Desktop/Python/LocalLens/app/lib/features/profile/domain/user_profile.dart`
- `/Users/rohit/Desktop/Python/LocalLens/app/lib/features/profile/domain/public_user_profile.dart`
- `/Users/rohit/Desktop/Python/LocalLens/app/lib/features/profile/presentation/screens/public_profile_screen.dart`
- `/Users/rohit/Desktop/Python/LocalLens/app/lib/core/router/app_router.dart`

### Own profile — `ProfileScreen` (screens/profile_screen.dart, 1167 lines)
`ConsumerStatefulWidget`. AppBar with settings action (key `openSettingsButton`). Body sections (in `data:` of `userProfileProvider`):
1. **Header** (lines 127–269): tappable photo avatar (key `editProfilePhotoButton`), identity label (display name / phone / email / anon via `_primaryIdentityLabel`, line 642), verified icon, edit-name button (key `editNameButton`), inline bio editor (keys `editBioButton`, `editBioField`, `saveBioButton`), Anon ID monospace chip, and a "Display Name / Anon ID" `SegmentedButton` (key `profileIdentityToggle`).
2. **Guest banner** (lines 273–306) when `isGuest`.
3. **User Activity Stats Card** (lines 309–343): `_StatMetric` rows — Issues (`issuesCount`), Upvotes (`upvotesCount`), Verified (`quorumVotesCount`).
4. **Offline Outbox & Drafts** (lines 347–453): Pending Outbox Items card (button key `viewOutboxButton` → `/outbox`), Drafts card (key `profileDraftsButton` → `/drafts`, shows saved count).
5. **My Reported Issues & Activity** (lines 457–631): "Report New" button (→ `/compose`), filter chips All/Unresolved/Resolved (keys `myIssuesFilter_all`, `myIssuesFilter_active`, `myIssuesFilter_resolved`), then a 3-column `GridView` of `_UserIssueGridTile`s (key `userIssueItem_${id}`, delete via key `deleteIssue_${id}`, long-press delete). Guest sees a "Sign in to view…" card.

**Gaps for the requested "better profile page":** `UserProfile` (user_profile.dart) has **no `role`, `ward`, or representative fields** — it models citizen stats only (id, phone, email, displayName, username, dateOfBirth, photoUrl, bio, anonId, isGuest, issuesCount, upvotesCount, quorumVotesCount + change limits). Data source: `GET /auth/me` (provider `userProfileProvider`, profile_providers.dart line 19; backend `UserOut` in auth/schemas.py line 47 **does** include `role` and `ward` but the frontend model drops them).

### Public profile — `PublicProfileScreen` (screens/public_profile_screen.dart, 744 lines)
`ConsumerWidget(userId)`. Sections:
1. **Hero header** (lines 94–205): avatar with role-based icon (`_getRoleIcon`, line 491), displayName + verified icon, `_RoleBadge` chip (line 537; colors/icons keyed on `role` containing "representative"/"official"), Anon ID chip, ward + "Member since" row.
2. **Impact & Reputation Stats Card** (key `publicImpactStatsCard`, lines 209–302): Impact Score pts + level chip + `_MetricItem`s (Issues Reported, Verified Solves, Upvotes Recv.).
3. **Unlocked Civic Badges** (lines 306–397): horizontal badge cards.
4. **Public Reported Issues** (lines 401–480): `_PublicIssueTile` list (key `publicIssueItem_${id}`) → `/issue/:id`.

Data: `publicProfileProvider` (`FutureProvider.family<PublicUserProfile, int>`, profile_providers.dart line 133) → `feed_api.dart` `fetchPublicUserProfile` (line 219) → `GET /users/$userId` (backend `auth/service.py` `get_public_user_profile`, line 263; response `PublicUserProfileOut`, auth/schemas.py line 73).

**Gap for the "rep accountability" goal:** The public profile backend returns `role` (from `User.role`, default `"citizen"`) plus citizen metrics (`issues_count`, `resolutions_count`, `upvotes_count`, `impact_score`, `badges`) — it does **not** join `RepresentativeProfile` and returns **no rep-specific metrics** (resolved/pending/official responses). `PublicUserProfile` (public_user_profile.dart) has a `role` field but no rep metrics either.

### Router — `app_router.dart`
- Shell tab: `RoutePaths.profile` = `/profile` → `ProfileScreen` (lines 76–84).
- Top-level routes (parent navigator): `repDashboard` `/rep-dashboard` → `RepDashboardScreen` (lines 186–190); `wardDetail` `/ward/:slug` → `WardDetailScreen` (lines 220–227); `publicProfile` `/users/:id` → `PublicProfileScreen` (lines 243–251); plus `settings`, `editProfile`, `compose`, `outbox`, `drafts`, `inbox`, `notifications`, `gamification`, `search`, `adminFlaggedQueue`, `issueDetail`.
- Redirects (lines 91–140): legacy `/rep/`, `/talk/`, `/win/`, `/notice/` deep links redirect to feed. **No role-based guard exists** on `/rep-dashboard` (any logged-in user can navigate there; the API returns 403 if not a rep).

---

## 5. How Users Are Flagged as Representatives (role/scope checks)

### `/Users/rohit/Desktop/Python/LocalLens/backend/app/core/security.py`
No roles/scopes at all. Contains only: `hash_secret`/`verify_secret` (bcrypt), `generate_otp`, `create_access_token`/`decode_access_token` (JWT with `sub`, `iat`, `exp`), and HMAC-based `derive_anonymous_identity`/`derive_anon_id`.

### `/Users/rohit/Desktop/Python/LocalLens/backend/app/api/deps.py`
- `get_current_user` (line 24): decodes JWT `sub` (int user id or `guest:` subject + `is_guest` flag) → returns `User` (or synthetic guest `User` with `is_guest=True`). No role check.
- Exports `SessionDep`, `CurrentUser`, `SettingsDep`, `OptionalUser` (lines 65–101).

### Actual representative gate
- **`RepresentativeProfile` row existence** is the sole flag. `get_current_rep_profile` (`representatives/router.py` lines 27–41) queries `service.get_representative_profile(session, user.id)` and raises `403 not_representative` if absent or guest. Exposed as `RepProfileDep` (line 44).
- `User.is_representative` property (auth/models.py line 46) is a convenience for the same check.
- `User.role` string column exists (default `"citizen"`) and is surfaced in `UserOut`/`PublicUserProfileOut` as `role`, but it is **not** used for authorization and does not carry rep metrics.

---

## Key gaps vs. the user's requested changes

1. **Rep accountability metrics (resolved/pending per rep):**
   - Backend `RepresentativeProfileOut` (schemas.py lines 8–20) has `total`, `escalated`, `responded`, `pending_response` — **no resolved count, no acknowledged/in_progress aggregation** (`service.py` lines 27–62).
   - Frontend `RepDashboardScreen` shows only Total/Escalated/Pending Response (`respondedWardIssues` is parsed but never rendered).
   - No public endpoint returns a rep's metrics for citizens; `WardDetailOut.assigned_representative` is name/title/verified_at only (wards/schemas.py lines 8–13).

2. **Ward details page:** exists and is functional (hero, 5 metrics, rep card, search + filters, issues list). Missing: rep performance data in the rep card; `WardRepCard.onTap` is a no-op (no public-profile navigation); **no boundary/polygon** (only center coordinates).

3. **Better profile page:** `ProfileScreen` is citizen-centric (issues/upvotes/quorum + outbox/drafts); `UserProfile` drops the backend's `role`/`ward`. `PublicProfileScreen` shows a `role` badge but the backend `get_public_user_profile` never joins rep data, so a representative's public profile shows only citizen-style metrics.

4. **Representative provisioning:** There is **no API or admin UI** to create `RepresentativeProfile` rows (seed/tests only) — relevant if the desired feature includes letting officials/representatives sign up or be assigned.
</task_result>
</task>
```

---

## Assistant (Build · DeepSeek V4 Flash Free · 26.1s)

_Thinking:_

I now have comprehensive context. Let me synthesize the features to build:

**F1: Issue reporting/media flow (camera-only, media space, location in metadata)**
- Remove gallery upload strictly (remove "Add from gallery" button, gallery picker in camera sheet)
- Location added to image metadata by default (attach capturedLat/capturedLng to uploaded media via packageExifMetadata, and backend EXIF validation)
- Separate media space where captured images are saved even if not uploaded, can be deleted (draft media store)
- Images displayed in separate section in compose
- Where images were clicked should update map (map refresh + per-media location pin)
- Group select (multi-select in media space)

**F2: Map improvements**
- Map doesn't update → refresh after issue creation, panning refetch, invalidate from outbox
- Heatmap from concentric circles → area painting (PolygonLayer density cells or gradient overlay)
- Ward map: boundary polygons fetched from net (Overpass API) + backend ward boundary storage

**F3: Ward details page** - exists but needs rep performance data + boundaries. Actually the user says "there is no ward details page" — but it exists. Hmm. Maybe they don't know it exists or it's not reachable. The ward detail page exists. I should improve it: link rep card to public profile, add rep performance metrics, boundaries.

**F4: Representative accounts**
- Separate account type with different display: resolved count, pending count, etc.
- Public visibility so citizens can judge

**F5: Search** - "Search unavailable"
- This is a runtime/network issue: base URL hardcoded to 127.0.0.1. Add configurable base URL, better error messages, retry. The report says contracts aligned; issue is likely Android emulator (10.0.2.2) or physical device LAN IP. So fix: configurable base URL via dart-define, better error copy (distinguish network vs server errors), and possibly the app uses feed which works... Actually the user says search always shows "Search unavailable". Since feed works (they browse issues), the base URL works. So maybe the actual issue is something else. Wait — the report says the live endpoint works via curl. But the user reports it fails in the app. Could be rate limiting (60/min) — they search repeatedly as guest → 429. Or could be a parsing issue. Hmm.

Actually, let me think. The explore agent verified `curl` works. The frontend contract is aligned. What could make search show "Search unavailable" always while feed works? Let me look at search_providers.dart and search_api.dart myself to see if there's a bug. There's uncommitted changes to search files. Let me examine the actual diff.

Actually, an important thing: the git status shows uncommitted modifications to search files. Let me check the diff for search to see if there's a bug introduced.

**F6: Issues page UI improvements**
- More attractive, less cluttered
- Better UI and options in adding issues
- Group select

**F7: Profile page**
- Better view

Let me look at the uncommitted changes to understand what's currently being worked on, especially for search. Also I should verify tests pass currently. Let me check git diff stat and run the backend tests quickly.

Let me also check what the current test situation is. Running full test suites may take a while but is important baseline.

Let me first check the git diff for search and map files to understand the current WIP state.

I have a full picture now. Let me check the uncommitted WIP changes and baseline test state before spawning agents

**Tool: bash**

**Input:**
```json
{
  "command": "git diff --stat | tail -30"
}
```

**Output:**
```
 app/lib/features/search/data/search_api.dart       |   2 +
 app/lib/features/search/domain/search_filters.dart |   8 +-
 .../features/search/domain/search_repository.dart  |   1 +
 .../search/presentation/advanced_filter_sheet.dart |  47 +-
 .../presentation/search_filters_provider.dart      |   5 +
 .../search/presentation/search_providers.dart      |   1 +
 .../search/presentation/search_screen.dart         |  62 +-
 .../presentation/screens/ward_detail_screen.dart   | 279 +++++++-
 .../ward/presentation/widgets/ward_rep_card.dart   | 116 ++-
 app/lib/shared/widgets/status_badge.dart           |   9 +-
 .../compose/media_pipeline_extended_test.dart      |  73 +-
 app/test/features/feed/issue_card_test.dart        |   3 +-
 .../feed/media_display_and_like_toggle_test.dart   |   3 +-
 .../feed/multi_feed_talk_extended_test.dart        |   3 +-
 .../features/feed/reporter_navigation_test.dart    |   3 +-
 .../features/feed/upvote_interaction_test.dart     |   3 +-
 .../features/feed/upvote_toggle_core_test.dart     |   3 +-
 app/test/features/map/map_pins_extended_test.dart  |   9 +-
 app/test/features/search/search_filters_test.dart  |   1 +
 app/test/features/search/search_screen_test.dart   |   3 +-
 .../features/ward/ward_detail_screen_test.dart     |   5 +-
 app/test/helpers.dart                              |   3 +-
 backend/app/features/geo/service.py                |   6 +-
 backend/app/features/issues/router.py              |   4 +-
 backend/app/features/issues/service.py             |  11 +-
 backend/app/features/search/router.py              |   6 +
 backend/app/features/search/service.py             |  38 +-
 backend/app/features/wards/service.py              |   9 +-
 backend/tests/features/search/test_search.py       |  42 ++
 52 files changed, 1936 insertions(+), 493 deletions(-)

```

**Tool: bash**

**Input:**
```json
{
  "command": "git diff app/lib/features/search/ | head -200"
}
```

**Output:**
```
diff --git a/app/lib/features/search/data/search_api.dart b/app/lib/features/search/data/search_api.dart
index 6f91322..1eeb92a 100644
--- a/app/lib/features/search/data/search_api.dart
+++ b/app/lib/features/search/data/search_api.dart
@@ -17,6 +17,7 @@ class SearchApi implements SearchRepository {
     double? radiusKm,
     DateTime? createdAfter,
     DateTime? createdBefore,
+    String? ward,
   }) async {
     final data = await _client.getJson(
       '/search',
@@ -31,6 +32,7 @@ class SearchApi implements SearchRepository {
           'created_after': createdAfter.toUtc().toIso8601String(),
         if (createdBefore != null)
           'created_before': createdBefore.toUtc().toIso8601String(),
+        'ward': ?ward,
         'limit': 20,
       },
     );
diff --git a/app/lib/features/search/domain/search_filters.dart b/app/lib/features/search/domain/search_filters.dart
index 633a6ce..9b2fba7 100644
--- a/app/lib/features/search/domain/search_filters.dart
+++ b/app/lib/features/search/domain/search_filters.dart
@@ -9,6 +9,7 @@ class SearchFilters {
     this.distanceOption = SearchDistanceOption.any,
     this.radiusKm = 5.0,
     this.datePreset = SearchDatePreset.anyTime,
+    this.ward,
   });
 
   static const Object _unset = Object();
@@ -18,12 +19,14 @@ class SearchFilters {
   final SearchDistanceOption distanceOption;
   final double radiusKm;
   final SearchDatePreset datePreset;
+  final String? ward;
 
   bool get isActive =>
       status != null ||
       categories.isNotEmpty ||
       distanceOption == SearchDistanceOption.within ||
-      datePreset != SearchDatePreset.anyTime;
+      datePreset != SearchDatePreset.anyTime ||
+      ward != null;
 
   SearchFilters copyWith({
     Object? status = _unset,
@@ -31,6 +34,7 @@ class SearchFilters {
     SearchDistanceOption? distanceOption,
     double? radiusKm,
     SearchDatePreset? datePreset,
+    Object? ward = _unset,
   }) {
     return SearchFilters(
       status: identical(status, _unset) ? this.status : status as String?,
@@ -38,6 +42,7 @@ class SearchFilters {
       distanceOption: distanceOption ?? this.distanceOption,
       radiusKm: radiusKm ?? this.radiusKm,
       datePreset: datePreset ?? this.datePreset,
+      ward: identical(ward, _unset) ? this.ward : ward as String?,
     );
   }
 
@@ -63,3 +68,4 @@ const kSearchCategoryOptions = <String>[
   'sewage',
   'other',
 ];
+
diff --git a/app/lib/features/search/domain/search_repository.dart b/app/lib/features/search/domain/search_repository.dart
index af894bf..4fc0708 100644
--- a/app/lib/features/search/domain/search_repository.dart
+++ b/app/lib/features/search/domain/search_repository.dart
@@ -10,5 +10,6 @@ abstract interface class SearchRepository {
     double? radiusKm,
     DateTime? createdAfter,
     DateTime? createdBefore,
+    String? ward,
   });
 }
\ No newline at end of file
diff --git a/app/lib/features/search/presentation/advanced_filter_sheet.dart b/app/lib/features/search/presentation/advanced_filter_sheet.dart
index 17266ef..3abe16d 100644
--- a/app/lib/features/search/presentation/advanced_filter_sheet.dart
+++ b/app/lib/features/search/presentation/advanced_filter_sheet.dart
@@ -2,6 +2,8 @@ import 'package:flutter/material.dart';
 import 'package:flutter_riverpod/flutter_riverpod.dart';
 
 import '../../../core/l10n/app_strings.dart';
+import '../../../core/utils/string_formatters.dart';
+import '../../ward/presentation/providers/ward_providers.dart';
 import '../domain/search_filters.dart';
 
 Future<SearchFilters?> showAdvancedFilterSheet(
@@ -41,6 +43,9 @@ class _AdvancedFilterSheetState extends ConsumerState<AdvancedFilterSheet> {
   Widget build(BuildContext context) {
     final theme = Theme.of(context);
     final sectionLabel = theme.textTheme.titleSmall;
+    final wardListAsync = ref.watch(wardListNotifierProvider);
+    final wards = wardListAsync.valueOrNull?.items ?? [];
+
     return SafeArea(
       child: SingleChildScrollView(
         padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
@@ -59,7 +64,7 @@ class _AdvancedFilterSheetState extends ConsumerState<AdvancedFilterSheet> {
                 for (final status in kSearchStatusOptions)
                   ChoiceChip(
                     key: Key('statusChip_$status'),
-                    label: Text(status),
+                    label: Text(StringFormatters.formatStatus(status)),
                     selected: _selection.status == status,
                     onSelected: (_) => setState(() {
                       _selection = _selection.copyWith(status: status);
@@ -77,7 +82,7 @@ class _AdvancedFilterSheetState extends ConsumerState<AdvancedFilterSheet> {
                 for (final category in kSearchCategoryOptions)
                   FilterChip(
                     key: Key('categoryChip_$category'),
-                    label: Text(category),
+                    label: Text(StringFormatters.formatCategory(category)),
                     selected: _selection.categories.contains(category),
                     onSelected: (_) => setState(() {
                       final selectedCategories =
@@ -95,6 +100,43 @@ class _AdvancedFilterSheetState extends ConsumerState<AdvancedFilterSheet> {
               ],
             ),
             const SizedBox(height: 16),
+
+            // ── Ward Selection ────────────────────────────────────
+            Text('Ward', style: sectionLabel),
+            const SizedBox(height: 8),
+            if (wards.isEmpty)
+              Text(
+                'No wards loaded',
+                style: theme.textTheme.bodySmall?.copyWith(
+                  color: theme.colorScheme.onSurfaceVariant,
+                ),
+              )
+            else
+              Wrap(
+                spacing: 8,
+                runSpacing: 8,
+                children: [
+                  ChoiceChip(
+                    key: const Key('wardChip_any'),
+                    label: const Text('Any Ward'),
+                    selected: _selection.ward == null,
+                    onSelected: (_) => setState(() {
+                      _selection = _selection.copyWith(ward: null);
+                    }),
+                  ),
+                  for (final ward in wards)
+                    ChoiceChip(
+                      key: Key('wardChip_${ward.slug}'),
+                      label: Text(ward.name),
+                      selected: _selection.ward == ward.slug,
+                      onSelected: (_) => setState(() {
+                        _selection = _selection.copyWith(ward: ward.slug);
+                      }),
+                    ),
+                ],
+              ),
+            const SizedBox(height: 16),
+
             Text(context.tr('filter_distance'), style: sectionLabel),
             const SizedBox(height: 8),
             SegmentedButton<SearchDistanceOption>(
@@ -187,3 +229,4 @@ String _datePresetLabel(SearchDatePreset preset) {
       return 'Past 30 days';
   }
 }
+
diff --git a/app/lib/features/search/presentation/search_filters_provider.dart b/app/lib/features/search/presentation/search_filters_provider.dart
index 51f80e1..678fd92 100644
--- a/app/lib/features/search/presentation/search_filters_provider.dart
+++ b/app/lib/features/search/presentation/search_filters_provider.dart
@@ -37,6 +37,10 @@ class SearchFiltersNotifier extends Notifier<SearchFilters> {
     state = state.copyWith(datePreset: preset);
   }
 
+  void setWard(String? ward) {
+    state = state.copyWith(ward: ward);
+  }
+
   void reset() {
     state = const SearchFilters();
   }
@@ -45,3 +49,4 @@ class SearchFiltersNotifier extends Notifier<SearchFilters> {
     state = filters;
   }
 }
+
diff --git a/app/lib/features/search/presentation/search_providers.dart b/app/lib/features/search/presentation/search_providers.dart
index ecfe6b0..c671988 100644
--- a/app/lib/features/search/presentation/search_providers.dart
+++ b/app/lib/features/search/presentation/search_providers.dart
@@ -86,6 +86,7 @@ class SearchResultsNotifier extends AsyncNotifier<List<Issue>> {
             categories: filters.categories,
             radiusKm: radiusKm,
             createdAfter: createdAfter,
+            ward: filters.ward,

```

---

## Assistant (Build · DeepSeek V4 Flash Free · 2.4s)

_Thinking:_

The WIP changes look additive (ward filter, UI improvements). Let me check the search_screen.dart diff to see if the user's changes broke something.

**Tool: bash**

**Input:**
```json
{
  "command": "git diff app/lib/features/search/presentation/search_screen.dart"
}
```

**Output:**
```
diff --git a/app/lib/features/search/presentation/search_screen.dart b/app/lib/features/search/presentation/search_screen.dart
index 4446bf1..6b571f1 100644
--- a/app/lib/features/search/presentation/search_screen.dart
+++ b/app/lib/features/search/presentation/search_screen.dart
@@ -4,6 +4,7 @@ import 'package:flutter/material.dart';
 import 'package:flutter_riverpod/flutter_riverpod.dart';
 
 import '../../../core/l10n/app_strings.dart';
+import '../../../core/utils/string_formatters.dart';
 import '../../../shared/widgets/empty_state.dart';
 import '../../../shared/widgets/skeleton_list.dart';
 import '../../feed/domain/feed_item.dart';
@@ -74,13 +75,18 @@ class _SearchScreenState extends ConsumerState<SearchScreen> {
     );
     if (result != null) {
       ref.read(searchFiltersProvider.notifier).apply(result);
-      _runSearch(_lastQuery.isEmpty ? _controller.text.trim() : _lastQuery);
+      final query = _lastQuery.isEmpty ? _controller.text.trim() : _lastQuery;
+      if (query.isNotEmpty) {
+        _runSearch(query);
+      }
     }
   }
 
   void _clearFilters() {
     ref.read(searchFiltersProvider.notifier).reset();
-    _runSearch(_lastQuery);
+    if (_lastQuery.isNotEmpty) {
+      _runSearch(_lastQuery);
+    }
   }
 
   @override
@@ -88,7 +94,8 @@ class _SearchScreenState extends ConsumerState<SearchScreen> {
     final query = ref.watch(searchQueryProvider);
     final recents = ref.watch(recentSearchesProvider);
     final results = ref.watch(searchResultsProvider);
-    final filtersActive = ref.watch(searchFiltersProvider).isActive;
+    final filters = ref.watch(searchFiltersProvider);
+    final filtersActive = filters.isActive;
 
     return Scaffold(
       appBar: AppBar(
@@ -102,6 +109,13 @@ class _SearchScreenState extends ConsumerState<SearchScreen> {
             border: InputBorder.none,
           ),
           onChanged: _onQueryChanged,
+          onSubmitted: (text) {
+            final trimmed = text.trim();
+            if (trimmed.isNotEmpty) {
+              _lastQuery = trimmed;
+              _runSearch(trimmed);
+            }
+          },
         ),
         actions: [
           IconButton(
@@ -121,9 +135,43 @@ class _SearchScreenState extends ConsumerState<SearchScreen> {
           const SizedBox(width: 8),
         ],
       ),
-      body: query.isEmpty
-          ? _buildPreloadedBody(recents)
-          : _buildResultsBody(results),
+      body: Column(
+        children: [
+          // ── Active Ward Filter Display ─────────────────────
+          if (filters.ward != null)
+            Container(
+              width: double.infinity,
+              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
+              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
+              child: Row(
+                children: [
+                  const Icon(Icons.location_city, size: 16),
+                  const SizedBox(width: 6),
+                  Text(
+                    'Ward: ${StringFormatters.formatWard(filters.ward)}',
+                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
+                      fontWeight: FontWeight.w600,
+                    ),
+                  ),
+                  const Spacer(),
+                  GestureDetector(
+                    onTap: () {
+                      ref.read(searchFiltersProvider.notifier).setWard(null);
+                      if (_lastQuery.isNotEmpty) _runSearch(_lastQuery);
+                    },
+                    child: const Icon(Icons.close, size: 16),
+                  ),
+                ],
+              ),
+            ),
+          // ── Body ──────────────────────────────────────────
+          Expanded(
+            child: query.isEmpty && !filtersActive
+                ? _buildPreloadedBody(recents)
+                : _buildResultsBody(results),
+          ),
+        ],
+      ),
     );
   }
 
@@ -250,7 +298,7 @@ class _SearchScreenState extends ConsumerState<SearchScreen> {
           ? const EmptyState(
               icon: Icons.search_off_outlined,
               title: 'No issues found',
-              message: 'Try a different keyword.',
+              message: 'Try a different keyword or adjust your filters.',
             )
           : ListView.separated(
               padding: const EdgeInsets.all(16),

```

**Tool: bash**

**Input:**
```json
{
  "command": "git diff backend/app/features/search/service.py backend/app/features/search/router.py backend/app/features/geo/service.py backend/app/features/issues/service.py backend/app/features/issues/router.py backend/app/features/wards/service.py"
}
```

**Output:**
```
diff --git a/backend/app/features/geo/service.py b/backend/app/features/geo/service.py
index 8c8c431..39b240d 100644
--- a/backend/app/features/geo/service.py
+++ b/backend/app/features/geo/service.py
@@ -1,4 +1,4 @@
-from sqlalchemy import select
+from sqlalchemy import func, select
 from sqlalchemy.ext.asyncio import AsyncSession
 
 from app.core.exceptions import AppError
@@ -50,10 +50,10 @@ async def get_map_pins(
     )
 
     if category and category.strip() and category.lower() != "all":
-        stmt = stmt.where(Issue.category == category)
+        stmt = stmt.where(func.lower(func.trim(Issue.category)) == category.strip().lower())
 
     if status and status.strip() and status.lower() != "all":
-        stmt = stmt.where(Issue.status == status)
+        stmt = stmt.where(func.lower(func.trim(Issue.status)) == status.strip().lower())
 
     stmt = stmt.order_by(Issue.created_at.desc())
     result = await session.execute(stmt)
diff --git a/backend/app/features/issues/router.py b/backend/app/features/issues/router.py
index 7135d22..34ef8e1 100644
--- a/backend/app/features/issues/router.py
+++ b/backend/app/features/issues/router.py
@@ -71,13 +71,15 @@ async def get_near_duplicates(
     session: SessionDep,
     latitude: Annotated[float, Query()],
     longitude: Annotated[float, Query()],
-    radius_km: Annotated[float, Query(ge=0.01, le=10)] = 0.5,
+    category: Annotated[str | None, Query()] = None,
+    radius_km: Annotated[float, Query(ge=0.001, le=10)] = 0.030,
     limit: Annotated[int, Query(ge=1, le=50)] = 10,
 ) -> list[NearDuplicateOut]:
     return await service.detect_near_duplicates(
         session,
         latitude=latitude,
         longitude=longitude,
+        category=category,
         radius_km=radius_km,
         limit=limit,
     )
diff --git a/backend/app/features/issues/service.py b/backend/app/features/issues/service.py
index 666e825..6b27b1c 100644
--- a/backend/app/features/issues/service.py
+++ b/backend/app/features/issues/service.py
@@ -316,16 +316,21 @@ async def detect_near_duplicates(
     *,
     latitude: float,
     longitude: float,
-    radius_km: float = 0.5,
+    category: str | None = None,
+    radius_km: float = 0.030,
     limit: int = 10,
 ) -> list[NearDuplicateOut]:
-    statement = await bbox_statement(latitude, longitude, radius_km)
-    statement = statement.order_by(Issue.created_at.desc()).limit(limit * 2)
+    statement = await bbox_statement(latitude, longitude, max(radius_km, 0.05))
+    statement = statement.order_by(Issue.created_at.desc()).limit(limit * 4)
     result = await session.execute(statement)
     candidates = list(result.scalars().all())
 
     duplicates: list[NearDuplicateOut] = []
     for issue in candidates:
+        if category and category.strip():
+            if issue.category.strip().lower() != category.strip().lower():
+                continue
+
         dist_km = haversine_km(latitude, longitude, issue.latitude, issue.longitude)
         if dist_km <= radius_km:
             duplicates.append(
diff --git a/backend/app/features/search/router.py b/backend/app/features/search/router.py
index b54d0c7..d3e8c3c 100644
--- a/backend/app/features/search/router.py
+++ b/backend/app/features/search/router.py
@@ -44,6 +44,7 @@ async def search_issues_endpoint(
     status: Annotated[str | None, Query()] = None,
     category: Annotated[str | None, Query()] = None,
     categories: Annotated[list[str] | None, Query()] = None,
+    ward: Annotated[str | None, Query()] = None,
     created_after: Annotated[str | None, Query()] = None,
     created_before: Annotated[str | None, Query()] = None,
     limit: Annotated[int, Query(ge=1, le=50)] = 20,
@@ -76,6 +77,10 @@ async def search_issues_endpoint(
             status_code=422,
             code="invalid_category",
         )
+    if ward is not None and len(ward) > 64:
+        raise AppError(
+            "ward must be at most 64 characters", status_code=422, code="invalid_ward"
+        )
     parsed_created_after = (
         service.parse_iso_datetime(created_after) if created_after is not None else None
     )
@@ -102,6 +107,7 @@ async def search_issues_endpoint(
         status=status,
         category=category,
         categories=categories,
+        ward=ward,
         created_after=parsed_created_after,
         created_before=parsed_created_before,
         limit=limit,
diff --git a/backend/app/features/search/service.py b/backend/app/features/search/service.py
index 0e5455e..c35c5dc 100644
--- a/backend/app/features/search/service.py
+++ b/backend/app/features/search/service.py
@@ -1,6 +1,7 @@
+import re
 from datetime import UTC, datetime
 
-from sqlalchemy import Select, or_, select
+from sqlalchemy import Select, func, or_, select
 from sqlalchemy.ext.asyncio import AsyncSession
 from sqlalchemy.orm import selectinload
 
@@ -8,6 +9,7 @@ from app.core.exceptions import AppError
 from app.features.issues.geo import bbox_statement, haversine_km
 from app.features.issues.models import Issue
 from app.features.issues.service import evaluate_escalation
+from app.features.wards.models import Ward
 
 
 def _utc_now() -> datetime:
@@ -18,6 +20,19 @@ def _escape_like(q: str) -> str:
     return q.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
 
 
+def _alnum_expr(column) -> object:
+    """Lowercases [column] and strips punctuation so slug/name/code variants
+    can be compared directly (e.g. 'ward-45-urban-central' == 'Ward 45, Urban Central')."""
+    cleaned = func.lower(column)
+    for ch in ",.-_' ":
+        cleaned = func.replace(cleaned, ch, "")
+    return cleaned
+
+
+def _alnum(value: str) -> str:
+    return re.sub(r"[^a-z0-9]+", "", value.lower())
+
+
 def parse_iso_datetime(value: str) -> datetime:
     """Parse an ISO-8601 datetime into a naive-UTC datetime.
 
@@ -47,6 +62,7 @@ async def search_issues(
     categories: list[str] | None,
     created_after: datetime | None,
     created_before: datetime | None,
+    ward: str | None,
     limit: int,
     offset: int,
 ) -> list[Issue]:
@@ -72,6 +88,26 @@ async def search_issues(
         statement = statement.where(Issue.category == category)
     if categories:
         statement = statement.where(Issue.category.in_(categories))
+    if ward is not None:
+        normalized_ward = _alnum(ward)
+        ward_match = or_(
+            Issue.ward == ward,
+            Issue.ward.ilike(f"%{_escape_like(ward)}%"),
+            _alnum_expr(Issue.ward) == normalized_ward,
+            _alnum_expr(Issue.ward).like(f"%{normalized_ward}%"),
+        )
+        ward_row = await session.scalar(
+            select(Ward).where(
+                or_(Ward.slug == ward, Ward.name == ward, Ward.code == ward)
+            )
+        )
+        if ward_row is not None:
+            for label in (ward_row.name, ward_row.code, ward_row.slug):
+                ward_match = or_(ward_match, Issue.ward == label)
+                ward_match = or_(
+                    ward_match, Issue.ward.ilike(f"%{_escape_like(label)}%")
+                )
+        statement = statement.where(ward_match)
     if created_after is not None:
         statement = statement.where(Issue.created_at >= created_after)
     if created_before is not None:
diff --git a/backend/app/features/wards/service.py b/backend/app/features/wards/service.py
index bafd658..265f3fb 100644
--- a/backend/app/features/wards/service.py
+++ b/backend/app/features/wards/service.py
@@ -57,8 +57,13 @@ def calculate_resolution_rate(total_issues: int, resolved_issues: int) -> float:
 
 
 async def _get_ward_metrics(session: AsyncSession, ward: Ward) -> tuple[int, int, int, int, float]:
-
-    where_clause = (Issue.ward == ward.name) | (Issue.ward == ward.slug)
+    where_clause = (
+        (Issue.ward == ward.name)
+        | (Issue.ward == ward.slug)
+        | (Issue.ward == ward.code)
+        | (Issue.ward.ilike(f"%{ward.name}%"))
+        | (Issue.ward.ilike(f"%{ward.code}%"))
+    )
 
     total_issues = (
         await session.execute(select(func.count(Issue.id)).where(where_clause))

```

---

## Assistant (Build · DeepSeek V4 Flash Free · 5.9s)

_Thinking:_

The WIP changes are additive features (ward filter in search, near-duplicate category filter, better ward matching). They don't obviously break search. The "Search unavailable" issue is likely environment-related (base URL). But the user says search is broken in their app. Since feed works and search uses the same base URL... Actually let me think about the actual runtime issue. The search_screen diff changed logic:

```dart
body: Column(
  children: [
    if (filters.ward != null) ...,
    Expanded(
      child: query.isEmpty && !filtersActive
          ? _buildPreloadedBody(recents)
          : _buildResultsBody(results),
    ),
  ],
),
```

Hmm, this looks fine. Let me look at the actual current search_screen.dart around lines 230-300 to see the "Feed unavailable" branch at line 233.

Actually, let me not over-analyze the search. The user's report is that it shows "Search unavailable". The plan for search feature: 
1. Make the base URL configurable (dart-define) so it works on Android emulator/device
2. Improve error handling to distinguish network vs server errors and show helpful messages
3. Make search robust: retry, empty query handling

Let me now verify the current test baseline. Let me run backend tests and flutter tests to see where things stand. Actually, running the full suite may take a while. Let me check what test infrastructure exists - Makefile.

Let me look at the Makefile and README to understand test commands.

**Tool: read**

**Input:**
```json
{
  "filePath": "/Users/rohit/Desktop/Python/LocalLens/Makefile"
}
```

**Output:**
```
<path>/Users/rohit/Desktop/Python/LocalLens/Makefile</path>
<type>file</type>
<content>
1: PY ?= uv
2: APP_DIR := app
3: BACKEND_DIR := backend
4: 
5: .PHONY: help setup backend app seed check lint test gen format
6: 
7: help:
8: 	@echo "LocalLens targets:"
9: 	@echo "  make setup       install backend deps + app packages"
10: 	@echo "  make backend     backend dev server (uvicorn --reload)"
11: 	@echo "  make app         run the Flutter app"
12: 	@echo "  make seed        wipe and reseed the dev database from seed/data"
13: 	@echo "  make gen         freezed/json_serializable codegen"
14: 	@echo "  make format      format both codebases"
15: 	@echo "  make lint        ruff + flutter analyze"
16: 	@echo "  make test        pytest + flutter test"
17: 	@echo "  make check       lint + test"
18: 
19: seed:
20: 	cd $(BACKEND_DIR) && $(PY) run python seed.py
21: 
22: setup:
23: 	cd $(BACKEND_DIR) && $(PY) sync
24: 	cd $(APP_DIR) && flutter pub get
25: 
26: backend:
27: 	cd $(BACKEND_DIR) && source .venv/bin/activate && $(PY) run alembic upgrade head && $(PY) run uvicorn app.main:app --reload
28: 
29: app:
30: 	cd $(APP_DIR) && flutter run
31: 
32: gen:
33: 	cd $(APP_DIR) && dart run build_runner build
34: 
35: format:
36: 	cd $(BACKEND_DIR) && $(PY) run ruff format .
37: 	cd $(APP_DIR) && dart format lib test
38: 
39: lint:
40: 	cd $(BACKEND_DIR) && $(PY) run ruff check . && $(PY) run mypy app
41: 	cd $(APP_DIR) && flutter analyze
42: 
43: test:
44: 	cd $(BACKEND_DIR) && $(PY) run pytest
45: 	cd $(APP_DIR) && flutter test
46: 
47: check: lint test

(End of file - total 47 lines)
</content>
```

**Tool: bash**

**Input:**
```json
{
  "command": "cat backend/README.md 2>/dev/null | head -40; echo \"===\"; cat app/README.md 2>/dev/null | head -40"
}
```

**Output:**
```
# LocalLens Backend

FastAPI + SQLAlchemy 2 (async) API for LocalLens, managed with [uv](https://docs.astral.sh/uv/).

## Layout

```
backend/
├── app/
│   ├── main.py            application factory (create_app) + lifespan
│   ├── api/               transport layer: router aggregation, deps, health
│   ├── core/              cross-cutting: config, database, security, exceptions, logging
│   └── features/          one folder per domain capability
│       ├── auth/          models / schemas / service / router — OTP + JWT
│       └── issues/        models / schemas / service / router — geo-anchored reports
└── tests/                 pytest suite mirroring features/
```

## Rules of the structure

- A feature owns its models, schemas, business logic (service) and HTTP surface (router).
  Files stay small: `service.py` holds logic, `router.py` only wires HTTP to the service.
- `core/` never imports from `features/` (features depend on core, never the reverse).
- Database sessions and auth come from `app/api/deps.py` (`SessionDep`, `CurrentUser`).
- All datetimes are UTC-naive; anything else will produce timezone bugs.
- Consumers talk to the API through schemas, never ORM objects.

## Commands

```sh
uv run uvicorn app.main:app --reload        # dev server on :8000
uv run pytest                               # tests
uv run ruff check . && uv run ruff format --check .
uv run mypy app
uv run alembic revision --autogenerate -m "..."   # schema evolution
uv run alembic upgrade head
```

## Configuration

===
# local_lens

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

```

---

## Assistant (Build · DeepSeek V4 Flash Free · 121.0s)

_Thinking:_

Let me run the baseline tests to understand where things stand. Let me run backend pytest and flutter analyze/test in parallel. These might take a while, but it's important to know the baseline. Let me run backend tests first (faster typically).

Let me run:
- backend: `uv run pytest` 
- backend lint: `uv run ruff check . && uv run mypy app`
- app: `flutter analyze` and `flutter test`

Let me run them in parallel but with appropriate timeouts.

Let me establish the test baseline before spawning

**Tool: bash**

**Input:**
```json
{
  "command": "uv run pytest -q 2>&1 | tail -20",
  "workdir": "/Users/rohit/Desktop/Python/LocalLens/backend",
  "timeout": 300000
}
```

**Output:**
```
=============================== warnings summary ===============================
tests/features/geo/test_geo.py: 21 warnings
tests/features/issues/test_ward_place_page.py: 63 warnings
tests/features/representatives/test_representatives.py: 9 warnings
  /Users/rohit/Desktop/Python/LocalLens/backend/.venv/lib/python3.12/site-packages/aiosqlite/core.py:63: DeprecationWarning: The default datetime adapter is deprecated as of Python 3.12; see the sqlite3 documentation for suggested replacement recipes
    result = function()

-- Docs: https://docs.pytest.org/en/stable/how-to/capture-warnings.html
=========================== short test summary info ============================
FAILED tests/features/media/test_media_seed_and_demo.py::test_seed_and_upload_media_directories_exist
FAILED tests/features/media/test_media_seed_and_demo.py::test_demo_video_files_exist
FAILED tests/features/media/test_media_seed_and_demo.py::test_issue_images_and_thumbnails_exist
FAILED tests/features/media/test_media_seed_and_demo.py::test_resolution_proof_assets_exist
FAILED tests/features/media/test_media_seed_and_demo.py::test_mp4_binary_structure
FAILED tests/features/media/test_media_seed_and_demo.py::test_image_binary_validity
FAILED tests/features/media/test_media_seed_and_demo.py::test_get_media_file_endpoint_video_mp4
FAILED tests/features/media/test_media_seed_and_demo.py::test_issues_seed_data_richness
FAILED tests/features/media/test_media_seed_and_demo.py::test_media_seed_data_consistency
FAILED tests/features/media/test_media_seed_and_demo.py::test_quorum_votes_and_official_responses_consistency
10 failed, 304 passed, 93 warnings in 113.91s (0:01:53)

```

**Tool: bash**

**Input:**
```json
{
  "command": "flutter analyze 2>&1 | tail -20",
  "workdir": "/Users/rohit/Desktop/Python/LocalLens/app",
  "timeout": 300000
}
```

**Output:**
```
Analyzing app...                                                

   info • Don't invoke 'print' in production code. Try using a logging framework • tool/live_auth_smoke.dart:13:3 • avoid_print
   info • Don't invoke 'print' in production code. Try using a logging framework • tool/live_auth_smoke.dart:17:3 • avoid_print
   info • Don't invoke 'print' in production code. Try using a logging framework • tool/live_auth_smoke.dart:21:3 • avoid_print

3 issues found. (ran in 2.0s)

```

---

## Assistant (Build · DeepSeek V4 Flash Free · 28.8s)

_Thinking:_

Baseline:
- Backend: 304 passed, 10 failed (all media seed/demo tests - these seem to be about seed assets existing on disk; likely pre-existing failures unrelated to my work). Let me verify these are pre-existing by checking whether these tests reference files in `backend/uploads/`.
- Flutter analyze: only 3 info-level issues in `tool/live_auth_smoke.dart` (not in lib, so `flutter analyze lib/` would be clean).

Let me run the flutter tests to get a baseline. That may take a few minutes. Let me also check the 10 failing media tests to see if they are pre-existing failures.





**Tool: bash**

**Input:**
```json
{
  "command": "uv run pytest tests/features/media/ -q 2>&1 | head -40",
  "timeout": 120000,
  "workdir": "/Users/rohit/Desktop/Python/LocalLens/backend"
}
```

**Output:**
```
......FFFFFF.F..FF.F                                                     [100%]
=================================== FAILURES ===================================
_________________ test_seed_and_upload_media_directories_exist _________________

    def test_seed_and_upload_media_directories_exist():
        """Verify that seed/media and uploads/media directories are present."""
>       assert SEED_MEDIA_DIR.exists() and SEED_MEDIA_DIR.is_dir()
E       AssertionError: assert (False)
E        +  where False = exists()
E        +    where exists = PosixPath('/Users/rohit/Desktop/Python/LocalLens/seed/media').exists

tests/features/media/test_media_seed_and_demo.py:64: AssertionError
_________________________ test_demo_video_files_exist __________________________

    def test_demo_video_files_exist():
        """Verify that all demo MP4 video assets exist in seed/media and uploads/media."""
        expected_videos = [
            "demo_traffic_pothole.mp4",
            "demo_stormwater_flow.mp4",
            "demo_dark_street.mp4",
            "demo_cattle_junction.mp4",
            "demo_resolution_proof.mp4",
            "sample_video.mp4",
        ]
        for vname in expected_videos:
            seed_path = SEED_MEDIA_DIR / vname
            upload_path = UPLOADS_MEDIA_DIR / vname
>           assert seed_path.exists(), f"Missing seed video {vname}"
E           AssertionError: Missing seed video demo_traffic_pothole.mp4
E           assert False
E            +  where False = exists()
E            +    where exists = PosixPath('/Users/rohit/Desktop/Python/LocalLens/seed/media/demo_traffic_pothole.mp4').exists

tests/features/media/test_media_seed_and_demo.py:81: AssertionError
____________________ test_issue_images_and_thumbnails_exist ____________________

    def test_issue_images_and_thumbnails_exist():
        """Verify that all 19 issue images and their thumbnails exist."""
        for issue_id in range(1, 20):
            # Find matching issue image

```

**Tool: bash**

**Input:**
```json
{
  "command": "flutter test 2>&1 | tail -25",
  "timeout": 600000,
  "workdir": "/Users/rohit/Desktop/Python/LocalLens/app"
}
```

**Output:**
```
00:20 +304: /Users/rohit/Desktop/Python/LocalLens/app/test/features/issues/flagging_widget_test.dart: F-14-FLAG Frontend Widget & Integration Tests FE-FLAG-02: Opening Flag Issue Dialog
00:20 +305: /Users/rohit/Desktop/Python/LocalLens/app/test/features/issues/flagging_widget_test.dart: F-14-FLAG Frontend Widget & Integration Tests FE-FLAG-02: Opening Flag Issue Dialog
00:20 +306: /Users/rohit/Desktop/Python/LocalLens/app/test/features/issues/flagging_widget_test.dart: F-14-FLAG Frontend Widget & Integration Tests FE-FLAG-02: Opening Flag Issue Dialog
00:20 +307: /Users/rohit/Desktop/Python/LocalLens/app/test/features/issues/flagging_widget_test.dart: F-14-FLAG Frontend Widget & Integration Tests FE-FLAG-02: Opening Flag Issue Dialog
00:20 +308: /Users/rohit/Desktop/Python/LocalLens/app/test/features/issues/flagging_widget_test.dart: F-14-FLAG Frontend Widget & Integration Tests FE-FLAG-02: Opening Flag Issue Dialog
00:20 +309: /Users/rohit/Desktop/Python/LocalLens/app/test/features/issues/flagging_widget_test.dart: F-14-FLAG Frontend Widget & Integration Tests FE-FLAG-02: Opening Flag Issue Dialog
00:20 +310: /Users/rohit/Desktop/Python/LocalLens/app/test/features/issues/flagging_widget_test.dart: F-14-FLAG Frontend Widget & Integration Tests FE-FLAG-02: Opening Flag Issue Dialog
00:20 +311: /Users/rohit/Desktop/Python/LocalLens/app/test/features/issues/flagging_widget_test.dart: F-14-FLAG Frontend Widget & Integration Tests FE-FLAG-02: Opening Flag Issue Dialog
00:20 +312: /Users/rohit/Desktop/Python/LocalLens/app/test/features/notifications/notifications_test.dart: F-10 Notifications & Inbox Engine - Widget Tests Renders NotificationsScreen route without crashing
00:20 +313: /Users/rohit/Desktop/Python/LocalLens/app/test/features/notifications/notifications_test.dart: F-10 Notifications & Inbox Engine - Widget Tests Renders NotificationsScreen route without crashing
00:20 +314: /Users/rohit/Desktop/Python/LocalLens/app/test/features/notifications/notifications_test.dart: F-10 Notifications & Inbox Engine - Widget Tests Renders NotificationsScreen route without crashing
00:20 +315: /Users/rohit/Desktop/Python/LocalLens/app/test/features/notifications/notifications_test.dart: F-10 Notifications & Inbox Engine - Widget Tests Renders NotificationsScreen route without crashing
00:20 +316: /Users/rohit/Desktop/Python/LocalLens/app/test/features/notifications/notifications_test.dart: F-10 Notifications & Inbox Engine - Widget Tests Renders NotificationsScreen route without crashing
00:20 +317: /Users/rohit/Desktop/Python/LocalLens/app/test/features/notifications/notifications_test.dart: F-10 Notifications & Inbox Engine - Widget Tests Renders NotificationsScreen route without crashing
00:20 +318: /Users/rohit/Desktop/Python/LocalLens/app/test/shared/shimmer_loading_test.dart: ShimmerLoading renders child correctly
00:21 +319: /Users/rohit/Desktop/Python/LocalLens/app/test/shared/shimmer_loading_test.dart: ShimmerLoading renders child correctly
00:21 +320: /Users/rohit/Desktop/Python/LocalLens/app/test/shared/shimmer_loading_test.dart: ShimmerLoading renders child correctly
00:21 +321: /Users/rohit/Desktop/Python/LocalLens/app/test/shared/shimmer_loading_test.dart: ShimmerLoading renders child correctly
00:21 +322: /Users/rohit/Desktop/Python/LocalLens/app/test/features/notifications/notifications_test.dart: F-10 Notifications & Inbox Engine - Widget Tests Verify list of notifications renders with titles, bodies, and relative timestamps
00:21 +323: /Users/rohit/Desktop/Python/LocalLens/app/test/shared/shimmer_loading_test.dart: SkeletonList renders with ShimmerLoading wrapper
00:21 +324: /Users/rohit/Desktop/Python/LocalLens/app/test/shared/shimmer_loading_test.dart: SkeletonList renders with ShimmerLoading wrapper
00:21 +325: /Users/rohit/Desktop/Python/LocalLens/app/test/features/notifications/notifications_test.dart: F-10 Notifications & Inbox Engine - Widget Tests Verify filter toggle (All / Unread) filters rendered list
00:21 +326: /Users/rohit/Desktop/Python/LocalLens/app/test/features/notifications/notifications_test.dart: F-10 Notifications & Inbox Engine - Widget Tests Verify "Mark all as read" action triggers controller method
00:21 +327: /Users/rohit/Desktop/Python/LocalLens/app/test/features/notifications/notifications_test.dart: F-10 Notifications & Inbox Engine - Widget Tests Tapping notification tile triggers mark single notification read
00:21 +328: All tests passed!

```

---

## Assistant (Build · DeepSeek V4 Flash Free · 66.0s)

_Thinking:_

Baseline established:
- Backend: 304 passed, 10 failed — all in `tests/features/media/test_media_seed_and_demo.py`, which fail because `seed/media/` directory doesn't exist (missing seed assets, pre-existing environment issue). These are not related to my features.
- Flutter: All 328 tests pass. `flutter analyze` has 3 info-level warnings in `tool/live_auth_smoke.dart` (not lib).
- ruff/mypy: need to verify but probably clean.

Now let me plan the work. The user wants me to spawn agents in a plan → code → test pipeline for each feature, with tests being independent and from a different agent.

Let me define the features (breaking down the user's request):

**F-A: Camera-only issue media & draft media space**
1. Gallery upload strictly not allowed (remove gallery buttons/pickers from compose + camera viewfinder)
2. Captured images get location attached to metadata by default (per-image lat/lng → backend EXIF + DB)
3. Separate "Captured Media" space where clicked images are saved even without publishing (persistent local media store, deletable, group/multi-select)
4. Captured images displayed in a separate section in compose

**F-B: Map updates + heatmap + ward boundaries**
1. Map must update when issues are added (invalidate on publish incl. outbox; auto-refetch on pan)
2. Heatmap → area painting (PolygonLayer density polygons instead of concentric circles)
3. Ward map → real boundary polygons from web data (Overpass/GeoJSON), backend ward boundary storage + endpoint

**F-C: Representative accountability accounts**
1. Backend: rep metrics (resolved count, pending count, acknowledged/in_progress aggregation) in /representatives/me + public rep profile endpoint
2. Frontend: separate rep account display (dashboard with resolved/pending counts), public visibility on ward page + public profile

**F-D: Ward details page**
1. Ward detail page improvements: rep performance data, link rep card to public profile
   (The user said "there is no ward details page" but one exists — I'll enhance it and make it reachable/functional)

**F-E: Search fix**
1. Configurable base URL (dart-define) + robust error handling distinguishing network/server errors with actionable copy
2. Fix "Search unavailable" path

**F-F: Issues page / feed UI improvements**
1. More attractive issue display, less cluttered
2. Better UI and options in adding issues (compose redesign)
3. Group select

**F-G: Profile page better view**
1. Profile page redesign (role/ward display for reps, better layout)

That's 7 feature areas. The user says "Spawn as many agents as you could". For each feature: plan agent → code agent → test agent, passing plan result to code agent, and tests independent/from a different agent with only relevant context.

Given the size, I'll batch the plan agents first (spawn all 7 plan agents in parallel), then spawn code agents (giving each the plan output), then test agents. Actually, to keep context manageable and follow the user's explicit instruction (plan → code → test per feature), I'll spawn plan agents in parallel first.

Let me think about how to structure this efficiently. The user explicitly asked:
- "for each feature spawn a plan, then a code, then a test sub agent, give them correct context, and pass the result of plan to code"
- "the test should be independent, only give important information, to avoid bias"
- "use a different agent to spawn test"
- "write test from start to end, that is user using the app, to verifying things are reflecting in backend, frontend"

So per feature:
1. Plan agent → produces a detailed plan (backend + frontend + tests)
2. Code agent → gets the plan + relevant context, implements
3. Test agent (different from code) → writes E2E-style tests (user flows) independently, verifying backend + frontend

I'll spawn 7 plan agents in parallel. Each gets a focused prompt with the exploration findings for that feature. Then based on their outputs, spawn 7 code agents in parallel. Then 7 test agents in parallel. Then run all tests, fix issues.

Actually, there's a risk of conflicts if code agents work on the same files. Let me identify file ownership per feature:
- F-A: compose/**, media/** (frontend + backend media, issues)
- F-B: map/**, geo/**, wards/** (frontend + backend geo, wards)
- F-C: rep_dashboard/**, representatives/**, profile public (frontend + backend representatives, wards)
- F-D: ward/** frontend+backend
- F-E: search/** frontend+backend + app_config
- F-F: feed/** presentation + compose screen UI
- F-G: profile/** frontend

Overlap risks:
- F-A and F-F both touch compose_screen (F-F = better UI in adding issues). Need to coordinate: F-A does media/location logic, F-F does UI polish of compose. Hmm, both touch compose_screen.dart. That could conflict.
- F-C and F-D and F-G all touch ward/profile/rep pages. F-C = rep accounts, F-D = ward details page, F-G = profile page.

To reduce conflicts, I should be careful about assigning file ownership. Let me give each code agent explicit instructions on which files they own and tell them not to touch files owned by others. Or I could merge some features. But the user wants a plan→code→test per feature.

Actually, a cleaner approach: run the pipeline features in waves. Since agents work in parallel on different files, and there could be conflicts, I'll define strict file ownership in each prompt.

Let me map ownership clearly:

**F-A (Camera-only media + media space):**
Owns: `app/lib/features/compose/data/media_service.dart`, `app/lib/features/compose/data/media_draft_store.dart` (new), `app/lib/features/compose/presentation/widgets/camera_viewfinder.dart`, `app/lib/features/compose/domain/compose_draft.dart`, `app/lib/features/compose/presentation/compose_screen.dart` (media section only — the gallery removal, media space section), `app/lib/features/compose/presentation/compose_providers.dart` (submit media logic), backend `backend/app/features/media/*`, `backend/app/features/issues/*` (only media-related bits), `app/lib/features/map/...` no.
Also new: a "captured media space" screen. Where? Could add to `app/lib/features/media/` new feature folder or inside compose. Let me keep it in compose: `presentation/media_library_screen.dart`.

**F-B (Map + heatmap + ward boundaries):**
Owns: `app/lib/features/map/**`, `app/lib/features/geo/**` (frontend), backend `backend/app/features/geo/*`, backend `backend/app/features/wards/*` (boundary field + seed), `backend/seed.py`, `seed/data/wards.json` (new), `app/lib/features/ward/data/**` maybe for boundary.
Also app_config for base URL? No, that's F-E.

**F-C (Rep accountability accounts):**
Owns: backend `backend/app/features/representatives/*`, frontend `app/lib/features/rep_dashboard/**`, backend wards assigned_representative metrics, `app/lib/features/ward/presentation/widgets/ward_rep_card.dart`, public profile rep metrics (`app/lib/features/profile/domain/public_user_profile.dart`, backend auth public profile).

**F-D (Ward details page):**
Owns: `app/lib/features/ward/presentation/screens/ward_detail_screen.dart`, `app/lib/features/ward/presentation/widgets/ward_recent_issues_list.dart`, `app/lib/features/ward/presentation/providers/ward_providers.dart`, `app/lib/features/ward/data/**`, `app/lib/features/ward/domain/*`.

**F-E (Search fix):**
Owns: `app/lib/features/search/**`, `app/lib/core/config/app_config.dart`, `app_config_provider.dart`, backend `backend/app/features/search/*` (only if needed).

**F-F (Feed UI + compose UI polish):**
Owns: `app/lib/features/feed/presentation/feed_screen.dart`, `app/lib/features/feed/presentation/widgets/issue_card.dart`, `app/lib/features/feed/presentation/widgets/*`, `app/lib/features/compose/presentation/compose_screen.dart` (UI layout only).
Conflict with F-A on compose_screen.dart. I'll tell F-A to focus on media logic and F-F to focus on layout/options, OR have F-F own compose UI and F-A only the media files. Let me assign: F-A owns compose media flow including removing gallery buttons (which appear in compose_screen and camera_viewfinder), and F-F owns feed screens + issue_card + compose "options" (like post type, toggles). Hmm, still overlapping.

Actually, let me merge F-F's "better UI in adding issues" into F-A since it's the same screen and the user listed it in the same sentence ("there should be a better ui and options in adding the issues"). So:

**F-A (Compose/media redesign):** Camera-only, media space, location-in-metadata, group select, better UI/options in adding issues, map update after issue created. This combines the compose improvements into one agent — reducing conflict.

**F-F (Feed/Issues page UI):** Just the issues list/feed page attractiveness — feed_screen + issue_card + maybe feed filter chips.

**F-G (Profile page):** Owns `app/lib/features/profile/presentation/screens/profile_screen.dart` + `profile_providers.dart` + `domain/user_profile.dart` (add role/ward) + backend auth/me already returns role/ward. And settings.

So final feature set (7 agents plan→code→test):
1. **F-A Compose & Media**: camera-only capture, per-image GPS→metadata, captured-media space (deletable, group select), compose UI/options polish, map refresh on publish.
2. **F-B Map**: area-painting heatmap (PolygonLayer density), auto-refresh on pan/publish, ward boundary polygons (Overpass/GeoJSON + backend storage + endpoint).
3. **F-C Representative Accountability**: rep metrics backend (resolved/pending/acknowledged), rep dashboard display, public rep profile metrics, ward rep card with performance.
4. **F-D Ward Details Page**: enhance ward detail page (rep performance, reachability, boundary display link).
5. **F-E Search**: fix "Search unavailable" (configurable base URL, robust error UX, verify contract).
6. **F-F Feed UI**: prettier, less cluttered issues page.
7. **F-G Profile**: better profile page view (role/ward display, layout).

File ownership plan (to minimize conflicts):
- F-A: `app/lib/features/compose/**` (all), backend `backend/app/features/media/**`, `backend/app/features/issues/**` (only media/upload bits), new media draft store. Also new route `/media-library`.
- F-B: `app/lib/features/map/**`, `app/lib/features/geo/**`, backend `backend/app/features/geo/**`, `backend/app/features/wards/**` (models/schemas/router/service for boundary), `backend/seed.py`, `seed/data/wards.json`.
- F-C: `backend/app/features/representatives/**`, `app/lib/features/rep_dashboard/**`, backend `backend/app/features/auth/**` (public profile rep metrics only), `app/lib/features/profile/domain/public_user_profile.dart`.
- F-D: `app/lib/features/ward/**` (presentation + domain + data) — but ward_rep_card is owned by F-C. Hmm. Let me give F-D the ward detail screen + providers, and F-C the ward_rep_card + public profile. Overlap: ward_detail_screen references WardRepCard. F-D can update its usage but F-C owns ward_rep_card.dart file. To avoid conflicts, F-C should implement ward_rep_card performance UI and F-D wires it. I'll instruct F-C to own `ward_rep_card.dart` and F-D to NOT edit it, only use it. And F-D owns the ward_detail_screen.dart.

Actually there's another overlap: F-D ward detail screen might want to add boundary map — that's F-B's domain (boundary polygon rendering). I'll tell F-B to render boundaries on map screen (ward mode) and optionally provide a reusable `WardBoundaryPolygon` widget; F-D can use it. To reduce risk, F-D will focus on the civic summary, rep performance, issues search UI. F-B will add boundary polygons on the ward map mode. F-D could add a boundary map in the ward detail page using F-B's widget — but that creates a dependency timing issue (parallel agents). Let me keep F-D self-contained: ward detail page improvements that don't require F-B's widget; optionally F-B's map agent adds boundary overlay to map screen ward mode only.

- F-E: `app/lib/features/search/**`, `app/lib/core/config/**`, backend search if needed.
- F-F: `app/lib/features/feed/presentation/**` (feed_screen, issue_card, win_card, notice_card, local_talk_card, media_preview_widget). Also `app/lib/features/feed/domain/**` maybe.
- F-G: `app/lib/features/profile/**` (all presentation + domain), backend auth if needed (probably not, /me already returns role/ward).

Wait, F-C owns `public_user_profile.dart` (domain) and F-G owns profile/** which includes public_user_profile.dart. Conflict. Let me assign public_user_profile.dart to F-C (rep metrics on public profile) and F-G to own only profile_screen.dart, profile_providers.dart, settings_screen.dart, user_profile.dart, and the widgets. Actually public_profile_screen.dart is under profile/presentation/screens. Let me assign F-C to own `public_profile_screen.dart` + `public_user_profile.dart` (showing rep metrics), and F-G owns `profile_screen.dart` + `user_profile.dart` + providers.

Hmm, but both F-C and F-G touch profile_providers.dart potentially. F-C needs to add a public rep metrics provider maybe in rep_dashboard or profile providers. Let me instruct F-C to keep its public profile provider in `rep_dashboard_providers.dart` or add new providers in profile_providers — conflicts. Let me assign profile_providers.dart to F-G and tell F-C to add any needed provider logic inside `rep_dashboard/presentation/rep_dashboard_providers.dart` (its own feature) and use existing `publicProfileProvider` from profile_providers (F-G owned file) — but F-C can't modify it. If F-C needs to extend publicProfileProvider response, it changes public_user_profile.dart (F-C owns) and the provider stays in profile_providers.dart. F-C can add a separate provider for rep metrics in rep_dashboard feature and use it in public_profile_screen.dart. That works: public_profile_screen.dart watches `publicRepProfileProvider` defined in rep_dashboard_providers.dart. F-G won't touch public_profile_screen.dart.

OK this is getting complex but manageable. Let me define clear ownership.

One more: F-E owns app_config.dart; no one else needs it. F-B doesn't need app_config.

Now, sequencing. The user wants plan → code → test. I'll:
1. Spawn 7 PLAN agents in parallel (each returns a written plan doc).
2. Spawn 7 CODE agents in parallel, each given its plan + relevant context + strict file ownership.
3. Spawn 7 TEST agents in parallel (different agents), each writing E2E tests from the plan (not the code), independent.
4. Run backend + frontend tests, fix breakages.

For test agents: user said "write test from start to end, that is user using the app, to verifying things are reflecting in backend, frontend". So tests should be end-to-end: a Flutter widget test that drives the compose flow → verifies media saved, and backend tests verifying the API contract. Since true E2E (integration_test driving real app against real backend) may be heavy, I'll have tests as: backend pytest (API contract, full user journey through endpoints) + Flutter widget tests (user flow in UI with fake repo/api). The test agents should write tests that pass without knowing implementation details, only the plan/contract.

Test agents writing tests before code exists is risky — they must define the contract from the plan. Then code must implement to that contract. If they disagree, tests fail. To be safe, I'll have the test agents write tests against the PLAN's specified contracts (endpoints, keys, fields) and tell code agents to honor the plan exactly. Since plan → code and plan → test both derive from the same plan, they should agree.

Actually, the user said: "pass the result of plan to code" and "the test should be independent, only give important information". So test agents get the plan too but independently write tests. Good.

But there's a subtlety: writing tests that pass requires the code to exist. I'll have test agents write the test files, then after code agents finish, run them. If a test fails due to a genuine contract mismatch, I'll reconcile.

Also the user wants "use a different agent to spawn test" — meaning use a different subagent type/agent for tests, not the code agent. I'll use `general` subagent_type for plan and code, and `general` for tests too but separate instances. Actually the available agents include `test-engineer` but it's filesystem-denied from src and only for SDD pipeline. The user wants tests "independent... only give important information... avoid bias". I'll use `general` agents for tests (fresh context, only given the plan). Since test-engineer is restricted, `general` is the practical choice for writing test files in backend/tests and app/test.

Let me also make sure I run `make gen` (build_runner) after code changes since freezed models may change.

Let me now write the plan prompts. I need to give each plan agent:
- The feature requirements (from user)
- Current-state context (from my exploration)
- Constraints (existing test framework, lint rules, architecture conventions)
- Output format (a concrete implementation plan doc saved to a file)

Should plan agents write their plan to files? That helps pass results to code. I'll have plan agents write to `docs/plans/F-A_plan.md` etc. Let me create a `docs/plans/` dir. Actually, they said docs/ are for SDD. Let me put plans in a `plans/` directory at repo root or under `.sdd/`. Hmm. The SDD harness manages docs/. Let me use `plans/F-xx_plan.md`. I'll create `plans/` dir.

Wait, but the AGENTS.md says the pipeline is strict. The user is explicitly asking me to bypass the formal pipeline and use ad-hoc plan/code/test agents. The user is the boss. I'll proceed with their requested workflow but avoid touching locked docs/1_spec.md and docs/2_tech_spec.md (they're locked). Plans go to `plans/`.

Let me create the plans directory and spawn plan agents.

Actually, let me reconsider — should plan agents write files or just return text? Returning text is simpler and avoids file conflicts. But plans can be long. The subagent's final message comes back to me, and I pass it to the code agent in the prompt. That works. However, very long plan text in prompts could bloat. I'll have plan agents write their plan to a file under `plans/` AND return a summary. Then code agents read the plan file. This is cleaner and reduces context. Test agents also read the plan file (independent).

Let me define the features precisely in prompts with the exploration findings.

Let me now write the todo list and spawn the 7 plan agents in parallel.

Let me create the plans directory first, then spawn.

Each plan agent prompt should include:
1. Role: SDD-style planner for feature X.
2. The requirements (verbatim-ish user request for that feature).
3. Current state context (from exploration — concise).
4. Architecture conventions (feature-first, service/router/schemas/models, Riverpod+freezed, M3, Keys for tests, no comments unless needed, lint).
5. Test conventions.
6. Deliverable: write plan to `plans/F-XX_plan.md` with: exact API changes (endpoints, params, response schema fields), DB changes (columns/tables), frontend changes (files, widgets, keys, providers), test plan (backend pytest cases + flutter widget cases, user-journey based), edge cases, file ownership boundaries (what NOT to touch).

Let me be careful to give them the constraints about not touching other features' files.

Let me draft the prompts now. I'll spawn them in parallel.

For the base URL / search — the explore agent found the real issue is likely the hardcoded 127.0.0.1 base URL on Android emulator/device. Also error copy is a catch-all. The fix: make base URL configurable via --dart-define with sensible defaults per-platform (Android emulator → 10.0.2.2), and improve error message mapping to show "Can't reach server — check connection" vs server errors. Also keep "Search unavailable" contract? The user wants search to actually work. I'll have plan agent design robust config + error UX, but keep the existing Key-based tests passing or update them.

Let me now spawn plan agents. I'll create the plans directory first.

For the plan agents, I need to give them accurate context. Let me condense my exploration findings per feature into the prompts.

Let me write concise but complete prompts. I'll spawn 7 in parallel.

Baseline established: backend 304 passed / 10 failed (all pre-existing media-seed tests missing `seed/media/` assets, unrelated), Flutter 328 passed. Now let me set up the feature pipeline.



**Tool: bash**

**Input:**
```json
{
  "command": "mkdir -p plans && ls plans"
}
```

**Output:**
```
(no output)
```

**Tool: todowrite**

**Input:**
```json
{
  "todos": [
    {
      "content": "Spawn 7 PLAN agents (compose/media, map, reps, ward, search, feed UI, profile)",
      "status": "in_progress",
      "priority": "high"
    },
    {
      "content": "Spawn 7 CODE agents from plan outputs",
      "status": "pending",
      "priority": "high"
    },
    {
      "content": "Spawn 7 TEST agents (independent, from plans only)",
      "status": "pending",
      "priority": "high"
    },
    {
      "content": "Run backend + flutter tests, reconcile failures",
      "status": "pending",
      "priority": "high"
    },
    {
      "content": "Run lint (ruff, mypy, flutter analyze) + build_runner",
      "status": "pending",
      "priority": "medium"
    }
  ]
}
```

**Output:**
```
[
  {
    "content": "Spawn 7 PLAN agents (compose/media, map, reps, ward, search, feed UI, profile)",
    "status": "in_progress",
    "priority": "high"
  },
  {
    "content": "Spawn 7 CODE agents from plan outputs",
    "status": "pending",
    "priority": "high"
  },
  {
    "content": "Spawn 7 TEST agents (independent, from plans only)",
    "status": "pending",
    "priority": "high"
  },
  {
    "content": "Run backend + flutter tests, reconcile failures",
    "status": "pending",
    "priority": "high"
  },
  {
    "content": "Run lint (ruff, mypy, flutter analyze) + build_runner",
    "status": "pending",
    "priority": "medium"
  }
]
```

---

## Assistant (Build · DeepSeek V4 Flash Free · 508.6s)

_Thinking:_

Now let me spawn the 7 plan agents in parallel. I'll give each a focused prompt with context. Let me write them carefully.

I'll write each prompt with:
- Role + task
- Requirements from user
- Current state findings (condensed)
- Architecture/test conventions
- Output: write to `plans/F-XX_plan.md`

Let me spawn all 7 in one message (parallel).

Now spawning the 7 PLAN agents in parallel, each focused on one feature with relevant context only



**Tool: task**

**Input:**
```json
{
  "description": "Plan F-A compose/media",
  "prompt": "You are a senior product+engineering planner for LocalLens (Flutter app in `app/`, FastAPI backend in `backend/`). Produce a precise, implementation-ready PLAN for the feature described below. Write the plan to `plans/F-A_compose_media_plan.md`. Do NOT write any application code.\n\n## Feature requirements (from the product owner)\n1. When a user uploads an issue, the location must be added to the image metadata BY DEFAULT.\n2. Users uploading photos from the gallery must be STRICTLY NOT allowed. Only images clicked with the in-app camera are permitted.\n3. There must be a separate space where the user can only pick images that were clicked by the application. Those images are displayed in a separate section.\n4. The location where each image was clicked should update the map (the map currently does not update).\n5. Even if the image is not uploaded, once clicked it should be saved in some space. That space must allow deleting the media, and support group/multi-select.\n6. Better UI and options when adding issues (compose screen polish).\n\n## Current state (verified by code exploration)\n- Compose flow lives in `app/lib/features/compose/`. The ACTIVE controller is `ComposeController extends Notifier<ComposeDraft>` in `presentation/compose_providers.dart` (the file `presentation/controllers/compose_controller.dart` is DEAD/legacy code not imported anywhere).\n- `presentation/compose_screen.dart` (797 lines) keeps `List<_AttachedMedia>` (id, bytes, isVerified) in widget state. Gallery is allowed in THREE places that must be removed: the \"Add from gallery\" button (key `openGalleryButton`, lines ~498-503), `_addGalleryImages` using `ImagePicker().pickMultiImage` (lines ~156-194), and the in-camera gallery button `_triggerGalleryPicker` in `presentation/widgets/camera_viewfinder.dart` (lines ~194-208, key `galleryPickerButton`).\n- `CameraViewfinder` captures with real GPS when locked: `onPhotoCaptured(bytes, lat, lng)`.\n- On submit, `ComposeController.submit()` in compose_providers.dart calls `mediaService.uploadMedia(bytes, isInAppCamera: ..., isFuzzed: ...)` WITHOUT passing `capturedLat/capturedLng` — per-image GPS is dropped. `MediaService.packageExifMetadata(...)` in `data/media_service.dart` exists but is UNUSED. `MediaUploadResult` already has `latitude/longitude` fields.\n- Draft model `domain/compose_draft.dart` (freezed) fields: id,title,description,category,isAnonymous,isFuzzed,isShielded,latitude,longitude,createdAt,updatedAt,mediaBytes (base64 list). Single issue-level lat/lng, NO per-media location field.\n- Draft persistence: `data/hive_draft_store.dart` → LocalStore keys `current_draft` (autosave) and `saved_drafts` (JSON array). Drafts screen `presentation/drafts_screen.dart` already has multi-select + batch delete (`confirmDeleteDraftsButton` key).\n- Backend media: `backend/app/features/media/router.py` POST `/api/v1/media/upload` accepts `is_in_app_camera`, `captured_lat`, `captured_lng`, `is_fuzzed`. `service.py` `process_location` fuzzes to round(2); `validate_verification` marks verified only when is_in_app_camera AND lat AND lng. `Media` model has id,user_id,url,thumbnail_url,is_verified,watermark_label,derived_hash,latitude,longitude,is_fuzzed,is_in_app_camera,created_at. NO EXIF parsing in backend, NO DELETE endpoint, no issue_id FK.\n- Issues: POST /api/v1/issues stores lat/lng + media as URL strings. Map pins come ONLY from published Issue.latitude/longitude (backend `features/geo/service.py get_map_pins`); Media table is never queried for pins.\n- Offline outbox (`data/offline_outbox_queue.dart`) flushes drafts WITHOUT re-uploading media — images are lost.\n- `app/lib/core/services/location_service.dart` provides real GPS via geolocator (returns null on failure). `app/lib/features/geo/domain/device_location_service.dart` `PlatformDeviceLocationService.getCurrentCoordinates()` returns HARDCODED (19.1136, 72.8697).\n- Map refresh: compose_screen.dart line ~389 invalidates `mapPinsNotifierProvider` only on successful publish via the compose screen (not outbox).\n\n## Architecture & test conventions you must plan around\n- Backend: feature-first layout, `router.py` wires HTTP→service, `schemas.py` pydantic, `models.py` SQLAlchemy async. Tests: pytest-asyncio in `backend/tests/features/<feature>/`. ruff (line-length 100, select E,F,I,UP,B,ASYNC,RUF) + mypy strict must pass.\n- Frontend: Riverpod 2.6 (Notifier/AsyncNotifier), freezed+json_serializable (run `dart run build_runner build` after model changes), Material 3, go_router. Widget tests in `app/test/features/<feature>/`. `flutter analyze` must be clean.\n- Widgets expose `Key(...)` for testability (e.g. `Key('shutterButton')`). Existing tests reference keys — preserve them where reasonable.\n- Do NOT add code comments unless needed for clarity.\n\n## Plan deliverable — `plans/F-A_compose_media_plan.md` must contain\n1. **Scope & ownership**: exact files this feature will create/modify (frontend + backend), and a list of files it must NOT touch (to avoid parallel-agent conflicts). E.g. do not touch `app/lib/features/map/**`, `app/lib/features/search/**`, `app/lib/features/feed/**`, `app/lib/features/profile/**`, `app/lib/features/ward/**`, `backend/app/features/geo/**`, `backend/app/features/wards/**`, `backend/app/features/representatives/**`, `backend/app/features/search/**`.\n2. **Backend design**: media model changes (e.g. add `issue_id`, `deleted_at` soft-delete, `captured_at`), new endpoints (e.g. DELETE /media/{id}, map-pins including media geotags or an endpoint to fetch captured-image locations), EXIF/GPS metadata writing (PIL available in backend deps), how per-image location flows into the issue and the map. Exact request/response schemas with field names.\n3. **Frontend design**: new \"captured media library\" space (new screen + provider + persistent local store, likely a new Hive box), how captured images are auto-saved even without publishing, delete + multi-select/group select UX, gallery removal changes, per-image location metadata wiring through `MediaService.uploadMedia` (pass capturedLat/capturedLng + timestamp, call packageExifMetadata), compose screen media section redesign (separate section for captured images), map invalidation on publish (including outbox flush), exact Keys for widgets, new/modified Riverpod providers, and any freezed model changes.\n4. **User-journey E2E test plan** (backend pytest + flutter widget tests): describe tests as a user flow — e.g. user opens compose → camera → captures 2 photos at GPS-locked location → images auto-save to media library → user deletes one → publishes issue → backend stores issue with media + geotag → map endpoint returns the new pin. Include negative tests (gallery attempt rejected, missing GPS behavior).\n5. **Edge cases**: no GPS lock, offline capture, camera hardware absent, max media count, duplicate media hash, delete-after-publish semantics.\n6. **Ordering/dependencies**: note anything that requires coordination with other features (e.g. map rendering lives in the map feature).\n\nBe concrete and concise. Use exact names. The plan will be handed to a coder agent and separately to an independent test agent.",
  "subagent_type": "general"
}
```

**Output:**
```
<task id="ses_feae12053ffeefkwWZpHrCVp0q" state="completed">
<task_result>
Plan written to `plans/F-A_compose_media_plan.md` (382 lines). Key decisions, verified against the code:

- **Backend**: add `issue_id` (FK), `deleted_at` (soft delete), `captured_at` to `Media`; new `DELETE /media/{id}` (403 guest, 409 when attached to a live issue); `embed_exif_gps` writes GPSInfo via PIL by default; `create_issue` links media rows to the issue. No geo-service changes.
- **Frontend**: new `CapturedMedia` freezed model + Hive-backed `CapturedMediaStore` (auto-saves every capture); new `media_library_screen.dart` with multi-select/group delete; `ComposeDraft.mediaBytes` → typed `media` list; gallery removed in all 3 spots; `submit()` passes `capturedLat/Lng/capturedAt` through `packageExifMetadata` and resolves issue coords from capture GPS (fixes the map pin issue, incl. outbox flush).
- **Not-touched**: `map/**`, `search/**`, `feed/**`, `profile/**`, `ward/**`, `geo/**` (frontend+backend), dead `compose_controller.dart`.
- **Ripples flagged**: `OfflineOutboxQueue` 3-arg constructor breaks an existing test; one-line map invalidation in `outbox_screen.dart`.
</task_result>
</task>
```

**Tool: task**

**Input:**
```json
{
  "description": "Plan F-B map/heatmap/boundaries",
  "prompt": "You are a senior product+engineering planner for LocalLens (Flutter app in `app/`, FastAPI backend in `backend/`). Produce a precise, implementation-ready PLAN for the feature described below. Write the plan to `plans/F-B_map_heatmap_boundaries_plan.md`. Do NOT write any application code.\n\n## Feature requirements (from the product owner)\n1. The map does not update at all when issues are added — fix so the map reflects new/updated issues (and captured-image locations).\n2. Change the heatmap from concentric circles to \"painting the area\" style — density shading that fills areas (e.g. grid cells / polygons filled with a density-based color), not nested circles.\n3. The current ward map only shows a button and a circle per ward. Replace that with actual ward BOUNDARIES marked on the map, by fetching appropriate boundary data from the internet (e.g. OpenStreetMap/Overpass/GeoJSON). If any confusion, assign something meaningful (e.g. fallback to derived boundary polygons).\n\n## Current state (verified by code exploration)\n- Frontend map: `app/lib/features/map/presentation/screens/map_screen.dart` (931 lines, the real screen; `presentation/map_screen.dart` is a 3-line barrel). `app/lib/features/map/presentation/controllers/map_controller.dart` (287 lines, `MapPinsNotifier`). `app/lib/features/map/data/map_api.dart` (MapPin model, getMapPins bbox query to GET /geo/map-pins).\n- Heatmap TODAY is concentric circles: client-side grid clustering in `MapState.heatmapCells` (map_controller.dart:93-115, ~0.003° cells) rendered as 3 nested `CircleMarker`s per cell in map_screen.dart:219-252 (useRadiusInMeter:false, pixel radii, fixed alpha tiers). `_heatmapColor` (density→green/yellow/orange/red), `_heatmapRadius`. No PolygonLayer anywhere, no heatmap plugin in pubspec (flutter_map ^8.1.1 + latlong2 only; flutter_map has built-in PolygonLayer/PolylineLayer).\n- Map refresh gaps: panning only sets `isBoundsDirty` and shows \"Search this area\" FAB — never refetches (`onMapEvent` map_screen.dart:195-210, `updateBounds` map_controller.dart:257-260). `filteredPins` (map_controller.dart:78-91) filters by category/status only, not viewport. Broad-region fallback (map_controller.dart:192-206) fires only when bbox empty AND no filters. Offline outbox sync never invalidates map. No polling/live refresh.\n- Ward mode: map_screen.dart:298-394 renders per ward a 48px CircleMarker at center + a pill Marker (ward code + active count). Ward data from `GET /api/v1/wards` (wardListNotifierProvider) but the `wards` TABLE IS EMPTY (0 rows in both DBs) so the screen falls back to 2 hardcoded `WardSummaryOut` (map_screen.dart:138-165).\n- Backend geo: `backend/app/features/geo/router.py` has GET /geo/reverse-geocode and GET /geo/map-pins only. `service.py get_map_pins` (bbox WHERE on Issue.lat/lng, shielded-exclusion, returns flat MapPinOut). No heatmap endpoint, no boundary endpoint.\n- Backend wards: `backend/app/features/wards/models.py` Ward table: id,name,slug,code,center_latitude,center_longitude,created_at,updated_at. NO radius, NO boundary/geometry field. `schemas.py` WardSummaryOut/WardDetailOut/WardListResponse. `service.py` computes metrics, get_ward_detail, get_ward_by_location (nearest center). Seed: `backend/seed.py` does NOT seed wards (not in _TABLES or _DATA_FILES); `seed/data/` has 12 JSON files, no wards/GeoJSON. Tests seed wards via raw SQL INSERT (e.g. `backend/tests/features/geo/test_geo.py:81-118`).\n- Backend `get_map_pins` filters recently changed to `func.lower(func.trim(column)) == value` (uncommitted WIP). Issues `ward` column holds strings like \"Ward 45, Urban Central\".\n\n## Architecture & test conventions\n- Backend: feature-first, router→service→schemas→models, SQLAlchemy async. pytest-asyncio in backend/tests. ruff (100 col, E,F,I,UP,B,ASYNC,RUF) + mypy strict clean.\n- Frontend: Riverpod 2.6, freezed, M3, go_router. flutter_map ^8.1.1. Widget tests in app/test/features/map/. `flutter analyze` clean. Widgets use `Key(...)` for tests; existing tests in `app/test/features/map/map_modes_test.dart`, `map_screen_test.dart`, `map_pins_extended_test.dart` reference keys (e.g. `mapPin_<id>`, `mapFilterChip_*`, `searchThisAreaButton`) — preserve them.\n- Do NOT add code comments unless needed.\n\n## Plan deliverable — `plans/F-B_map_heatmap_boundaries_plan.md` must contain\n1. **Scope & ownership**: exact files created/modified (frontend + backend). Files to NOT touch (parallel-agent conflict avoidance): `app/lib/features/compose/**`, `app/lib/features/search/**`, `app/lib/features/feed/**`, `app/lib/features/profile/**`, `app/lib/features/ward/presentation/screens/ward_detail_screen.dart` + ward_providers/domain/data (ward DETAIL page is another feature's scope), `backend/app/features/media/**`, `backend/app/features/representatives/**`, `backend/app/features/search/**`, `backend/app/features/issues/**` (except if strictly required, justify). NOTE: you MAY modify `backend/app/features/wards/models.py`, `schemas.py`, `router.py`, `service.py`, `backend/seed.py`, and add `seed/data/wards.json` for the boundary feature, since wards/boundaries are yours. You MAY add a reusable boundary-polygon rendering widget that the ward-detail feature could consume, but it must be self-contained in `app/lib/features/map/**` or `app/lib/features/ward/presentation/widgets/**`.\n2. **Backend design**: (a) ward boundary storage — add `boundary` GeoJSON/text column to Ward + migration + seed `seed/data/wards.json` with plausible boundaries (use real-ish polygon coordinates around the two known wards: ward-45-urban-central ~ (19.1136,72.8697) and ward-12-metro-corridor ~ (19.0760,72.8777); you may source boundaries from the web during implementation, otherwise synthesize reasonable polygon rings); (b) a boundary endpoint (e.g. GET /geo/ward-boundaries returning list of {ward_slug, name, code, boundary: [[lat,lng]...]}) or include boundary in wards list/detail responses — pick and specify exactly; (c) whether a heatmap/density endpoint is needed or if client-side density shading is sufficient — specify. (d) any map-pins changes for refresh.\n3. **Frontend design**: (a) replace concentric-circle heatmap with area-painting density shading using `PolygonLayer` (filled cells colored by density, e.g. interpolate color+opacity by density, or a tessellated fill) — exact approach; (b) ward boundaries: fetch boundaries and render `PolygonLayer` per ward in ward-map mode, replacing the circle; (c) map auto-refresh: refetch on pan (debounced) and/or when bounds change + invalidate on issue publish/outbox flush (wire if possible within your scope; otherwise document the hook), polling or listen-to-provider strategy; (d) exact Keys, providers, and any new models (e.g. WardBoundary, HeatmapCell rendering changes).\n4. **User-journey E2E test plan** (backend pytest + flutter widget tests): e.g. user opens map → sees pins for issues in viewport → pans → new area refetches → toggles heatmap → sees area-filled density shading (not circles) → switches to ward mode → sees ward boundary polygons → backend boundary endpoint returns GeoJSON. Include negative/edge cases (no issues, empty ward table, malformed boundary, offline).\n5. **Edge cases** and **ordering/dependencies** (e.g. new issue creation is the compose feature's scope; this feature consumes its map invalidation).\n\nBe concrete and concise. Use exact names. This plan is handed to a coder agent and separately to an independent test agent.",
  "subagent_type": "general"
}
```

**Output:**
```
<task id="ses_feae0d6eaffegYsMaHNHNiglca" state="completed">
<task_result>
Plan written to `plans/F-B_map_heatmap_boundaries_plan.md`. Key decisions:

- **Refresh**: debounced (800ms) auto-refetch on pan/zoom in `updateBounds`, 30s poll timer + app-resume refetch in `MapScreen`, in-flight guard. Outbox-flush hook documented (not wired — compose is out of scope; `OfflineOutboxQueue` has no change-notification).
- **Heatmap**: keep fixed 0.003° grid but `HeatmapCell` becomes corner-bounded area; rendered as filled `PolygonLayer` cells (density→color + interpolated opacity), `CircleLayer` removed. No heatmap endpoint needed.
- **Ward boundaries**: `Ward.boundary` TEXT column + alembic migration + `seed/data/wards.json` with concrete 8-point rings for both wards; new `GET /api/v1/geo/ward-boundaries` on the geo router (standalone, so the ward-detail contract stays untouched); backend/frontend both degrade to a deterministic octagon fallback when the table is empty or a ring is malformed.
- **Map-pins**: no change (issues have no `updated_at`; full bbox refetch suffices).
- Covers full E2E backend pytest + flutter widget test cases (BE-WB-01..07, FE-MAP-01..12) incl. empty/malformed/offline edges, and the file-level ownership/conflict list.
</task_result>
</task>
```

**Tool: task**

**Input:**
```json
{
  "description": "Plan F-C rep accountability",
  "prompt": "You are a senior product+engineering planner for LocalLens (Flutter app in `app/`, FastAPI backend in `backend/`). Produce a precise, implementation-ready PLAN for the feature described below. Write the plan to `plans/F-C_rep_accountability_plan.md`. Do NOT write any application code.\n\n## Feature requirements (from the product owner)\n1. There needs to be separate accounts for the people responsible for solving issues (representatives/officials). Their account should have a DIFFERENT display: number of issues resolved, how many issues pending, and more — so citizens can view whether the representatives are actually doing their job.\n2. This representative performance data must be publicly visible (e.g. on the ward details page and/or the representative's public profile) so people can judge rep performance.\n\n## Current state (verified by code exploration)\n- Backend `backend/app/features/representatives/`: `models.py` RepresentativeProfile (id, user_id FK unique, official_name, title, ward, verified_at) + OfficialResponse (id, issue_id, representative_id, message, estimated_resolution_days, status_update ['acknowledged'|'in_progress'], created_at). `router.py` endpoints: GET /representatives/me, GET /representatives/ward-issues, POST /issues/{id}/official-response, GET /issues/{id}/official-responses. No `/representatives/dashboard` endpoint. `service.py get_representative_profile_out` computes: total_ward_issues, escalated_ward_issues, responded_ward_issues (distinct issues with ≥1 OfficialResponse), pending_response_ward_issues (total - responded). NO resolved count, NO acknowledged/in_progress aggregation.\n- Reps are provisioned ONLY via seed (`backend/seed.py _seed_representatives`) and tests — no admin/self-serve API. Authorization = existence of RepresentativeProfile row (403 not_representative otherwise); User.role column exists (default 'citizen') but unused for auth.\n- Frontend `app/lib/features/rep_dashboard/`: `rep_dashboard_screen.dart` shows rep profile card (keys repProfileName, repProfileWard) + 3 metric cards (metricTotalWardIssues, metricEscalatedWardIssues, metricPendingResponseWardIssues) + filter chips (wardFilterChip_all/escalated/needs_response) + ward issues list (respondToIssueButton_<id>). Reachable only via route /rep-dashboard — no dock/tab link. `representative_profile.dart` model has totalWardIssues, escalatedWardIssues, respondedWardIssues, pendingResponseWardIssues. `respondedWardIssues` parsed but NOT displayed.\n- Ward page: `app/lib/features/ward/presentation/widgets/ward_rep_card.dart` (recently reworked, 116 lines) — shows rep on ward detail page; `onTap` in ward_detail_screen is a no-op. `app/lib/features/ward/domain/ward_representative_out.dart` only has officialName, title, verifiedAt — no metrics.\n- Public profile: backend `get_public_user_profile` (auth/service.py) returns PublicUserProfileOut with role + citizen metrics (issues_count, resolutions_count, upvotes_count, impact_score, badges) — does NOT join RepresentativeProfile / rep metrics. Frontend `app/lib/features/profile/domain/public_user_profile.dart` + `public_profile_screen.dart` show role badge + citizen stats only.\n- Auth `UserOut`/`/auth/me` already includes role and ward fields (frontend UserProfile drops them).\n- Tests: `backend/tests/features/representatives/test_representatives.py` (9 cases), `app/test/features/rep_dashboard/rep_dashboard_test.dart`.\n\n## Architecture & test conventions\n- Backend: feature-first (router→service→schemas→models), SQLAlchemy async, pytest-asyncio, ruff (100col, E,F,I,UP,B,ASYNC,RUF) + mypy strict clean. Representatives' OfficialResponse status_update constrained to acknowledged|in_progress.\n- Frontend: Riverpod 2.6, freezed, M3, go_router. Widget tests. flutter analyze clean. Preserve existing Keys.\n- Do NOT add code comments unless needed.\n\n## Plan deliverable — `plans/F-C_rep_accountability_plan.md` must contain\n1. **Scope & ownership**: exact files created/modified. Files to NOT touch (parallel-agent conflicts): `app/lib/features/compose/**`, `app/lib/features/search/**`, `app/lib/features/map/**`, `app/lib/features/feed/**`, `app/lib/features/profile/presentation/screens/profile_screen.dart` + `user_profile.dart` + `profile_providers.dart` (OWN profile page is another feature's scope), `backend/app/features/media/**`, `backend/app/features/geo/**`, `backend/app/features/search/**`, `backend/app/features/wards/presentation` frontend (ward DETAIL screen + ward providers/domain/data are another feature's scope). You MAY modify: `backend/app/features/representatives/**`, `backend/app/features/auth/**` (public profile rep metrics), `app/lib/features/rep_dashboard/**`, `app/lib/features/ward/presentation/widgets/ward_rep_card.dart`, `app/lib/features/profile/domain/public_user_profile.dart`, `app/lib/features/profile/presentation/screens/public_profile_screen.dart`. Decide where public rep-metrics providers live (recommend a provider in `app/lib/features/rep_dashboard/presentation/rep_dashboard_providers.dart` that public_profile_screen and ward_rep_card can watch) to avoid editing profile_providers.dart.\n2. **Backend design**: (a) extend rep metrics — resolved count (Issue.status == 'resolved' in ward, or issues the rep responded to that are resolved), pending/in_progress/acknowledged aggregation, response rate, average response time if feasible; (b) expose rep performance in /representatives/me response AND a public endpoint (e.g. GET /representatives/{id} or include in ward detail `assigned_representative` + a new public endpoint) with exact response schema field names; (c) exact SQL/count queries; (d) whether to seed a demo rep.\n3. **Frontend design**: (a) rep dashboard: add Resolved/Pending/In-progress/Acknowledged metric cards with keys, display respondedWardIssues, a public \"performance\" section; (b) ward_rep_card: show resolved/pending/response-rate metrics + make onTap navigate to the rep's public profile; (c) public_profile_screen: render rep performance section when the user is a representative (role check) with keys; (d) any new models/providers; (e) route linkage so reps can reach their dashboard (e.g. from profile page — but profile page is another feature's scope, so only document the hook).\n4. **User-journey E2E test plan** (backend pytest + flutter widget tests): e.g. citizen opens ward page → sees representative card with resolved/pending counts → taps → sees rep public profile with performance stats → backend /representatives/me returns metrics for the rep → counts update when a rep posts an official response and an issue resolves. Include security tests (non-rep gets 403, rep from another ward blocked), edge cases (no issues in ward, unresolved-only, rep with zero responses).\n5. **Edge cases** and **ordering/dependencies**.\n\nBe concrete and concise. Use exact names. This plan is handed to a coder agent and separately to an independent test agent.",
  "subagent_type": "general"
}
```

**Output:**
```
<task id="ses_feae0a78cffeTuooFXQEcJ03qB" state="completed">
<task_result>
Plan written to `plans/F-C_rep_accountability_plan.md`. Key decisions:

- **Backend**: shared `RepresentativeMetricsOut` base schema (flat keys, backward-compatible) extended into `RepresentativeProfileOut`, new `PublicRepresentativeProfileOut`, and `AssignedRepresentativeOut`. One public endpoint `GET /representatives/by-user/{user_id}` serves both ward card and public profile. Metrics: rep-attributable resolved, latest-response ack/in-progress bucketing, response rate, avg response time (computed in Python for SQLite/Postgres portability).
- **Frontend**: `publicRepProfileProvider` in `rep_dashboard_providers.dart` (per your recommendation) shared by `ward_rep_card` and `public_profile_screen`; new metric cards + performance section on dashboard; WardRepCard → public profile navigation.
- **Conflict-safe**: no touch to ward detail screen/providers/domain-data except a documented additive exception for `ward_representative_out.dart` (needs `user_id` to fetch/navigate); `public_profile_screen.dart` edited but `profile_providers.dart` untouched.
- **Seed**: set seeded rep user role to `representative` + add an official response on a resolved issue so demo metrics are non-zero.
- Verified accuracy against real code: existing 9 backend tests, both `WardRepresentativeOut` test constructions, and `ApiServerException.statusCode` all remain compatible.
</task_result>
</task>
```

**Tool: task**

**Input:**
```json
{
  "description": "Plan F-D ward details page",
  "prompt": "You are a senior product+engineering planner for LocalLens (Flutter app in `app/`, FastAPI backend in `backend/`). Produce a precise, implementation-ready PLAN for the feature described below. Write the plan to `plans/F-D_ward_details_plan.md`. Do NOT write any application code.\n\n## Feature requirements (from the product owner)\n1. \"There is no ward details page\" — the product owner believes it's missing. A basic `WardDetailScreen` EXISTS at `app/lib/features/ward/presentation/screens/ward_detail_screen.dart` but it is weak: rep card tap is a no-op, issues list is plain, no boundary map, no performance data. Make the ward details page a real, complete, reachable civic page: hero, metrics, assigned representative WITH performance, recent issues with search/filters, and (if feasible) a boundary mini-map. Also verify/enable navigation to it from ward chips/buttons on the feed and map.\n2. Improve reachability so users actually land on ward pages.\n\n## Current state (verified by code exploration)\n- `app/lib/features/ward/presentation/screens/ward_detail_screen.dart` (WardDetailScreen, ConsumerStatefulWidget, ~279 lines): keys wardDetailScreen, wardDetailBackButton, wardIssueSearchField. Sections: WardHeroBanner (name, code, center coords), WardMetricsGrid (5 WardMetricCards keys wardMetricTotal/Active/Escalated/Resolved/ResolutionRate), \"Ward Representatives\" section with WardRepCard (onTap empty) or \"No representative assigned yet\", search bar + filter tabs (Active/Escalated/Resolved/All, `_IssueFilterChip`), issues list via client-side `_filterIssues`. `WardRecentIssuesList` widget (key wardRecentIssuesList) exists but is UNUSED.\n- Domain: `domain/ward_detail_out.dart` WardDetailOut (slug,name,code,centerLatitude,centerLongitude,totalIssues,activeIssues,escalatedIssues,resolvedIssues,resolutionRatePct,topCategories,assignedRepresentative?,recentIssues,updatedAt). `domain/ward_representative_out.dart` (officialName,title,verifiedAt only). `domain/ward_list_response.dart`, `ward_summary_out.dart`, `local_talk_post.dart`.\n- Data: `data/repositories/ward_repository.dart` (fetchWardDetail, fetchWards). Providers: `presentation/providers/ward_providers.dart` — wardDetailNotifierProvider (FutureProvider.family autoDispose, local-store cache fallback), wardListNotifierProvider.\n- Widgets: `ward_hero_banner.dart`, `ward_metric_card.dart`, `ward_rep_card.dart` (RECENTLY REWORKED — another feature agent owns its content, see below), `ward_recent_issues_list.dart`, `ward_chip.dart`, `local_talk_compose_sheet.dart`.\n- Router: `app/lib/core/router/app_router.dart` route `/ward/:slug` → WardDetailScreen. Entry points: Home header ward chip, Map, Rep page (per checklist). Check `app/lib/core/router/route_paths.dart` and `app/lib/features/feed/presentation/feed_screen.dart` / `app/lib/features/map/presentation/screens/map_screen.dart` for actual entry widgets.\n- Backend `backend/app/features/wards/`: GET /wards/{ward_slug} → WardDetailOut (metrics, top_categories, assigned_representative [name/title/verified_at only], recent_issues). No boundary. `wards` table is EMPTY in DBs (tests seed via raw SQL).\n- Backend `get_ward_detail` (service.py:113-191) picks FIRST RepresentativeProfile matching ward name/slug as assigned_representative.\n\n## Architecture & test conventions\n- Frontend: Riverpod 2.6, freezed, M3, go_router, flutter_map available. Widget tests. flutter analyze clean. Preserve existing Keys (wardDetailScreen, wardMetricTotal, wardRepCard, wardRecentIssuesList, wardIssueSearchField, wardDetailBackButton).\n- Backend: feature-first, pytest-asyncio, ruff + mypy strict clean.\n- Do NOT add code comments unless needed.\n\n## Plan deliverable — `plans/F-D_ward_details_plan.md` must contain\n1. **Scope & ownership**: exact files created/modified. Files to NOT touch (parallel-agent conflicts): `app/lib/features/compose/**`, `app/lib/features/search/**`, `app/lib/features/map/**`, `app/lib/features/feed/**`, `app/lib/features/profile/**`, `app/lib/features/rep_dashboard/**`, `app/lib/features/geo/**` frontend, `backend/app/features/representatives/**` (rep METRICS are another feature's scope — you may DISPLAY rep metrics from providers the rep feature exposes, but do not edit rep feature files), `backend/app/features/media/**`, `backend/app/features/search/**`, `backend/app/features/issues/**`. You MAY modify: `app/lib/features/ward/presentation/screens/ward_detail_screen.dart`, `app/lib/features/ward/presentation/widgets/ward_hero_banner.dart`, `ward_metric_card.dart`, `ward_recent_issues_list.dart`, `ward_chip.dart`, `local_talk_compose_sheet.dart`, `app/lib/features/ward/domain/**`, `app/lib/features/ward/data/**`, `app/lib/features/ward/presentation/providers/**`, `app/lib/core/router/app_router.dart` + `route_paths.dart` (for reachability/navigation wiring), `backend/app/features/wards/router.py`/`service.py`/`schemas.py`/`models.py` if you need richer ward detail data (but boundary polygons are another feature's scope). Do NOT edit `app/lib/features/ward/presentation/widgets/ward_rep_card.dart` (owned by the rep-accountability feature) — you may consume whatever it exposes.\n2. **Backend design**: any changes to ward detail response needed for the page (e.g. recent_issues limit param, richer assigned_representative if the rep feature hasn't changed it yet — DEFINE a contract and note it may need aligning). Note the `wards` table is empty: plan to seed at least the 2 known wards so the page works live (seed is shared — coordinate naming with the map feature which also seeds wards; use slug `ward-45-urban-central` @ (19.1136,72.8697) and `ward-12-metro-corridor` @ (19.0760,72.8777)).\n3. **Frontend design**: full page layout spec — hero, metrics grid, representative section (show performance via the rep feature's public provider if available, else show placeholder contract), recent issues list with search + filter tabs, and a ward boundary mini-map IF the map feature exposes a reusable widget (design a graceful fallback when it doesn't). Reachability: wire ward chips/buttons (feed header ward chip, map ward mode) to navigate to /ward/:slug — check what exists and specify the additions with Keys. Exact Keys for new widgets, providers, and domain model changes (e.g. extend WardDetailOut if needed).\n4. **User-journey E2E test plan** (backend pytest + flutter widget tests): e.g. user taps ward chip on feed → ward details page opens → sees metrics + rep card → searches/filters issues → backend /wards/{slug} returns the ward detail; empty-ward and no-rep edge cases.\n5. **Edge cases** and **ordering/dependencies** (notably: rep metrics provider + boundary widget come from other parallel features — specify the interface you'll code against and a fallback).\n\nBe concrete and concise. Use exact names. This plan is handed to a coder agent and separately to an independent test agent.",
  "subagent_type": "general"
}
```

**Output:**
```
<task id="ses_feae07a6bffeGRZ6Ci2krbR4z6" state="completed">
<task_result>
Plan written to `plans/F-D_ward_details_plan.md`.

Key findings from exploration that shaped it:
- **Reachability is already wired** — feed chip (`geo/.../ward_location_chip.dart:41`) and map preview sheet (`map_screen.dart:867`) both push `/ward/:slug`; the real gap is the empty `wards` table, so the plan seeds the 2 wards via a shared `seed/data/wards.json` + `seed_wards()`.
- **Rep performance can't use the rep feature's provider** — `repProfileProvider` hits `/representatives/me`, which is auth-gated to the rep. So the plan extends backend `AssignedRepresentativeOut` (mirroring the rep feature's SQL) with `total/escalated/responded/pending` + `response_rate_pct`, plus `id`/`user_id` so the rep-card no-op tap becomes `→ /users/:id`.
- **Boundary mini-map** is in-scope via a new `WardBoundaryMiniMap` (flutter_map tile layer + center marker + `wardBoundaryProvider` seam returning `[]` → "Boundary coming soon" fallback pill).
- **`WardRecentIssuesList` and `WardChip` (both unused)** get wired in via `showHeader:false` reuse and a new nearby-wards section.

Includes exact file lists, keys (preserved + new), JSON contracts, 13 backend/10 frontend test cases, edge cases, and dependency ordering. No app code written.
</task_result>
</task>
```

**Tool: task**

**Input:**
```json
{
  "description": "Plan F-E search fix",
  "prompt": "You are a senior product+engineering planner for LocalLens (Flutter app in `app/`, FastAPI backend in `backend/`). Produce a precise, implementation-ready PLAN for the feature described below. Write the plan to `plans/F-E_search_fix_plan.md`. Do NOT write any application code.\n\n## Feature requirements (from the product owner)\n\"Search is still not working, it always shows 'Search unavailable' in the front end.\"\n\nThe goal: make search actually work for real users AND when it genuinely cannot reach the server, show a clear, actionable, differentiated error instead of a generic dead-end.\n\n## Current state (verified by code exploration)\n- The string \"Search unavailable\" is a hardcoded literal at `app/lib/features/search/presentation/search_screen.dart:290-296` in `_buildResultsBody`'s `.when(error:)` branch: `EmptyState(icon: Icons.cloud_off_outlined, title: 'Search unavailable', message: 'We could not reach the server right now.', actionLabel: 'Retry', onAction: _retryLastQuery)`. This is the catch-all for ANY exception (network, 404, 422, 429, 500, JSON parse) — the error message from the exception is ignored.\n- Frontend path: `_onQueryChanged` (400ms debounce) → `runQuery` in `search_providers.dart:56-94` (`SearchResultsNotifier extends AsyncNotifier<List<Issue>>`) → `searchRepositoryProvider.search(...)` → `SearchApi.search` (`data/search_api.dart:11-43`) calls `GET /search` on ApiClient with base URL `http://127.0.0.1:8000/api/v1`. Response parsed `data as List<dynamic>` → `Issue.fromJson`.\n- `app/lib/core/config/app_config.dart` hardcodes `apiBaseUrl: 'http://127.0.0.1:8000/api/v1'` for dev, and `app_config_provider.dart` ALWAYS selects dev. No --dart-define override. On Android emulator 127.0.0.1 must be 10.0.2.2; physical device needs LAN IP → connection refused → ApiNetworkException → \"Search unavailable\" for EVERY query. iOS Info.plist has NO NSAppTransportSecurity (ATS blocks cleartext to non-loopback). Android allows cleartext.\n- Exception mapping: `core/network/api_client.dart` rethrows via `mapDioException` (`core/network/api_exceptions.dart:59-71`) → `ApiNetworkException` (timeout/connection) or `ApiServerException` (non-401 HTTP errors, message from data['detail']).\n- Backend: `GET /api/v1/search` (backend/app/features/search/router.py, mounted via api/router.py prefix /api/v1 + /search + \"\"). Requires `q` (else 422 empty_query), optional latitude/longitude pair, radius_km (0.1-50), status (enum), category/categories (≤20), ward (≤64 chars), created_after/before (ISO), limit(1-50, default 20), offset. Auth optional; rate-limited 60/min → 429. Response `list[IssueOut]`. Contract is ALIGNED with frontend — verified live via curl (200). There is uncommitted WIP adding a `ward` filter (frontend + backend) — review it is wired correctly.\n- Existing tests: `app/test/features/search/search_screen_test.dart` line 212-230 'error shows Search unavailable and Retry re-runs' — asserts `find.text('Search unavailable')` when the fake repo throws, then Retry re-runs. `search_api_test.dart`, `search_api_filters_test.dart`, `search_filters_test.dart`, `backend/tests/features/search/test_search.py`, `test_search_filters.py`.\n\n## Architecture & test conventions\n- Frontend: Riverpod 2.6, freezed, M3. Widget tests. flutter analyze clean. Preserve existing Keys (searchField, clearRecentSearches).\n- Backend: feature-first, pytest-asyncio, ruff + mypy strict clean.\n- Do NOT add code comments unless needed.\n\n## Plan deliverable — `plans/F-E_search_fix_plan.md` must contain\n1. **Scope & ownership**: exact files created/modified. Files to NOT touch: `app/lib/features/compose/**`, `app/lib/features/map/**`, `app/lib/features/feed/**`, `app/lib/features/profile/**`, `app/lib/features/ward/**`, `app/lib/features/rep_dashboard/**`, `backend/app/features/media/**`, `backend/app/features/geo/**`, `backend/app/features/wards/**`, `backend/app/features/representatives/**`, `backend/app/features/issues/**`. You MAY modify: `app/lib/features/search/**`, `app/lib/core/config/**`, `app/lib/core/network/**` (error mapping), `backend/app/features/search/**`.\n2. **Root-cause & fix design**: (a) configurable base URL via `--dart-define` (e.g. `String.fromEnvironment('API_BASE_URL')`) with per-platform smart default (Android emulator → 10.0.2.2, else 127.0.0.1) — specify exactly how; (b) iOS ATS exception (NSAppTransportSecurity NSAllowsLocalNetworking) if needed; (c) differentiated error UX: map ApiNetworkException vs ApiServerException (and specific status codes) to distinct EmptyState messages + Retry, still exposing 'Search unavailable' title for network failure but with actionable copy, and a distinct server-error state; (d) any defensive parse handling for non-list responses; (e) verify the ward-filter WIP is complete/correct (backend + frontend wiring through runQuery); (f) ensure empty-query state does not hit the API. Keep the behavior that Retry re-runs the last query.\n3. **Exact UI/UX contract**: the state machine for search screen (idle/preload, loading, results, empty, network-error, server-error), the exact copy strings, Keys, and how `SearchResultsNotifier` should expose error kind (e.g. add an error kind enum on the AsyncError state or a separate provider).\n4. **User-journey E2E test plan** (backend pytest + flutter widget tests): e.g. user types a query → results appear; backend down → 'Search unavailable' with Retry; server returns 500 → differentiated server error; empty query → no API call; filters applied → query reflects filters; rate-limit 429 → actionable error; ward filter flows through to backend and filters results. Include the live-verification steps a tester can run (curl commands).\n5. **Edge cases** (blank query, very long query, rapid typing, offline, 429, 422) and **ordering/dependencies**.\n\nBe concrete and concise. Use exact names. This plan is handed to a coder agent and separately to an independent test agent.",
  "subagent_type": "general"
}
```

**Output:**
```
<task id="ses_feae0441cffes6nTlbf0OmhRWo" state="completed">
<task_result>
Plan written to `plans/F-E_search_fix_plan.md`. Summary of the design:

**Root causes addressed**
1. **Connectivity**: `AppConfig.dev` hardcodes `127.0.0.1` for every platform. Fix: `String.fromEnvironment('API_BASE_URL')` override + smart default (`10.0.2.2` on Android emulator, else `127.0.0.1`), iOS `NSAllowsLocalNetworking` ATS entry, and flagged macOS sandbox `network.client` entitlements (blocking all macOS-desktop traffic today).
2. **Generic dead-end**: `_buildResultsBody` ignores the exception. Fix: new `SearchErrorKind` enum + `classifySearchError()` maps `ApiNetworkException` / 429 / 422 / 5xx / 401 / parse-failure to 6 distinct EmptyStates, all keeping Retry→`_retryLastQuery` and the existing `'Search unavailable'` title for network failure.
3. **Defensive parsing**: `data as List<dynamic>` throws raw `TypeError` today → new `ApiParseException` in `api_exceptions.dart` + guarded parse in `search_api.dart`.
4. **Ward WIP**: backend + frontend wiring verified correct; gaps are test-side (no `ward` param assertion, no ward flow widget test, filter-sheet tests now need a `wardListNotifierProvider` override + `ensureVisible`).

**Deliverable structure**: scope/ownership tables (exact files, incl. flagged macOS entitlements), root-cause/fix design with code, the full UI state machine + exact copy/Keys, an independent user-journey E2E test plan (backend pytest, widget tests, live curl steps with expected status codes), edge-case matrix, and a 7-step ordering/dependency chain ending in `make check`. No application code was written.
</task_result>
</task>
```

**Tool: task**

**Input:**
```json
{
  "description": "Plan F-F feed UI redesign",
  "prompt": "You are a senior product+engineering planner for LocalLens (Flutter app in `app/`, FastAPI backend in `backend/`). Produce a precise, implementation-ready PLAN for the feature described below. Write the plan to `plans/F-F_feed_ui_plan.md`. Do NOT write any application code.\n\n## Feature requirements (from the product owner)\n\"There is a need for a better option to make the issues page more attractive instead of cluttered with information.\" — Redesign the ISSUES/FEED list page (and its cards) so it is cleaner, more attractive, less cluttered. This is a FRONTEND-ONLY visual/info-architecture redesign.\n\n## Current state (verified by code exploration)\n- Feed page: `app/lib/features/feed/presentation/feed_screen.dart` (Riverpod, filter chips keys feedFilterChip_all/issues/wins/notices/local_talk, pull-to-refresh, skeleton, empty states). Entry tab in the app shell (`app_router.dart` StatefulShellRoute, 4 tabs + center FAB).\n- Cards: `app/lib/features/feed/presentation/widgets/issue_card.dart` (dense: jurisdiction header, relative time, status badge, anonymous mask, title 2-line, caption 2-line, category chips, media carousel w/ watermark, upvote/comment/share/overflow footer, escalation hint slot), `win_card.dart`, `notice_card.dart`, `local_talk_card.dart`, `media_preview_widget.dart`.\n- Domain models in `app/lib/features/feed/domain/` (issue.dart freezed Issue, feed_item.dart, win.dart, notice.dart).\n- Backend feed endpoint: `GET /api/v1/feed` (type filter, cursor pagination, IssueOut). NO backend changes planned unless strictly needed.\n- Existing tests heavily exercise cards: `app/test/features/feed/issue_card_test.dart`, `feed_screen_test.dart`, `upvote_interaction_test.dart`, `media_display_and_like_toggle_test.dart`, `multi_feed_talk_extended_test.dart`, `reporter_navigation_test.dart`, `upvote_toggle_core_test.dart`, `win_card/notice/local_talk` tests, `issue_test.dart`. These reference widget structure and keys — READ them before planning so the redesign preserves required keys/behaviors or plans explicit test updates. Keys include things like `issueCard_<id>`, `issueCardOverflow_<id>`, `flagIssueOption_<id>`, `upvoteButton_<id>`.\n- There are UNCOMMITTED WIP changes to issue_card.dart, feed_screen.dart, status_badge.dart, feed_api.dart, feed_repository.dart, media_preview_widget.dart — review `git diff` for these files so your plan builds on them.\n\n## Architecture & test conventions\n- Frontend only. Riverpod 2.6, freezed, Material 3, go_router. Widget tests in app/test/features/feed/. `flutter analyze` clean. Do NOT add code comments unless needed.\n- Preserve functional behavior: upvote toggle, overflow menu (flag/copy link), media carousel + watermark, relative time, status badge, escalation hints, navigation to detail, deep-link share. The redesign should REDUCE visual noise (spacing, hierarchy, density, fewer competing elements) and make the page attractive (better empty/loading states, card grouping, visual rhythm) without losing information or test hooks.\n\n## Plan deliverable — `plans/F-F_feed_ui_plan.md` must contain\n1. **Scope & ownership**: exact files created/modified (frontend only). Files to NOT touch: `app/lib/features/compose/**`, `app/lib/features/search/**`, `app/lib/features/map/**`, `app/lib/features/profile/**`, `app/lib/features/ward/**`, `app/lib/features/rep_dashboard/**`, `app/lib/features/issue_detail/**`, `app/lib/features/geo/**`, `backend/**` (no backend changes). You MAY modify `app/lib/features/feed/presentation/**`, `app/lib/features/feed/domain/**` (if strictly needed for presentation), `app/lib/shared/widgets/**` (shared widgets like status_badge, empty_state) — but shared widget changes must stay backward-compatible for other features' tests.\n2. **Design spec**: the redesigned feed page + cards — layout structure, visual hierarchy, spacing/token usage (use existing theme tokens in `app/lib/core/theme/app_colors.dart`/`app_theme.dart`), which elements get emphasized/de-emphasized/grouped, new empty/loading states, and how to declutter the issue card (e.g. move category chips out of primary flow, unify footer actions, cleaner media area, better status presentation). Be specific enough for a coder to implement without further decisions. Preserve every Key and interaction listed above; specify any NEW Keys.\n3. **Compatibility notes**: which existing tests will need updates and what they assert (list them), so the coder and test agent can align.\n4. **User-journey E2E test plan** (flutter widget tests): e.g. user opens Home → sees clean feed with mixed card types → filter chips switch types → taps card → navigates to detail → upvotes optimistically → overflow flag works; plus visual/structural assertions (e.g. card shows ≤N visible action rows, hierarchy present). Keep tests independent of pixel-perfect layout but assert structure/keys/presence.\n5. **Edge cases** and **ordering/dependencies** (this is UI-only; coordinate with compose/media (F-A) only if card media rendering changes overlap — keep it self-contained).\n\nBe concrete and concise. Use exact names. This plan is handed to a coder agent and separately to an independent test agent.",
  "subagent_type": "general"
}
```

**Output:**
```
<task id="ses_feae02202ffetVWx00LWyp4Kcy" state="completed">
<task_result>
Plan written to `plans/F-F_feed_ui_plan.md`. Summary of what it covers:

- **Scope**: 2 new widgets (`FeedSkeletonList`, `FeedEmptyState`) + 5 modified files, all under `feed/presentation`; zero domain/backend/l10n/theme changes, with the forbidden-path list and the WIP diffs (status_badge, feed_api, feed_repository, feed_screen, issue_card) called out to preserve.
- **Design spec**: IssueCard collapsed from a 3-box "category+status+hint" row into a header meta line (colored category as separate `Text('WATER')`) + one subtle status row; 2-line description, media 180px, no divider, single footer action row — with every existing key preserved and new keys (`issueHeaderMeta_<id>`, `issueStatusRow_<id>`, `issueActions_<id>`) defined.
- **Compatibility**: per-file table of what each of the 12 affected tests asserts and how the redesign keeps them green (zero edits required if strings stay standalone).
- **E2E test plan**: new `feed_ui_redesign_e2e_test.dart` with 8 structural tests (mixed feed, filter switching, navigation, optimistic upvote, flag/guest-guard, hierarchy, states, no-share-on-talk).
- **Edge cases + ordering**: dark mode, anonymous, media-less, long text, status variants, filtered-empty, and the F-A overlap note (shared `media_preview_widget.dart` untouched).
</task_result>
</task>
```

**Tool: task**

**Input:**
```json
{
  "description": "Plan F-G profile redesign",
  "prompt": "You are a senior product+engineering planner for LocalLens (Flutter app in `app/`, FastAPI backend in `backend/`). Produce a precise, implementation-ready PLAN for the feature described below. Write the plan to `plans/F-G_profile_redesign_plan.md`. Do NOT write any application code.\n\n## Feature requirements (from the product owner)\n\"The profile page needs a better view.\" — Redesign the OWN profile page (`ProfileScreen`) to be cleaner, more attractive, better organized. Show the user's role/ward (backend /auth/me already returns role and ward but the frontend model drops them), surface rep status if applicable, and present activity, drafts, outbox, and my-issues in a better-organized, less-cluttered layout. Frontend-focused; small backend changes allowed only if strictly necessary.\n\n## Current state (verified by code exploration)\n- `app/lib/features/profile/presentation/screens/profile_screen.dart` (1167 lines, ConsumerStatefulWidget): header (avatar editProfilePhotoButton, identity label, verified icon, editNameButton, bio editor editBioButton/editBioField/saveBioButton, anon-id chip, SegmentedButton profileIdentityToggle), guest banner, activity stats card (Issues/Upvotes/Verified from issuesCount/upvotesCount/quorumVotesCount), Offline Outbox card (viewOutboxButton) + Drafts card (profileDraftsButton), \"My Reported Issues\" section (Report New button, filter chips myIssuesFilter_all/active/resolved, GridView userIssueItem_<id>, deleteIssue_<id>). Settings action key openSettingsButton.\n- `app/lib/features/profile/presentation/profile_providers.dart`: `userProfileProvider` (FutureProvider from GET /auth/me → UserProfile). `publicProfileProvider` (family by userId, in the same file).\n- `app/lib/features/profile/domain/user_profile.dart` (freezed UserProfile): id, phone, email, displayName, username, dateOfBirth, photoUrl, bio, anonId, isGuest, issuesCount, upvotesCount, quorumVotesCount + change-limits. NO role, NO ward — though backend `UserOut` (auth/schemas.py:47) DOES return role and ward (frontend drops them).\n- Backend: `GET /api/v1/auth/me` returns UserOut (role, ward included). Public profile: GET /users/{id} → PublicUserProfileOut.\n- Other profile screens: settings_screen.dart, edit_profile_screen.dart, anonymity_guide_screen.dart, public_profile_screen.dart (public profile is ANOTHER feature's scope — see ownership below).\n- Routes: /profile (shell tab), /settings, /edit-profile, /anonymity-guide. Router in `app/lib/core/router/app_router.dart`.\n- Existing tests: `app/test/features/profile/profile_settings_test.dart`, `profile_posts_and_public_profile_test.dart`, `profile_identity_limits_test.dart`, `profile_rework_test.dart`, `public_profile_parsing_and_anonymity_test.dart`, `fine_grained_settings_test.dart` — READ these before planning so redesign preserves keys/behaviors (editProfilePhotoButton, profileIdentityToggle, myIssuesFilter_all, userIssueItem_<id>, viewOutboxButton, profileDraftsButton, openSettingsButton, etc.).\n- There are UNCOMMITTED WIP changes to profile_providers.dart, public_user_profile.dart, public_profile_screen.dart, settings_screen.dart — review `git diff`.\n\n## Architecture & test conventions\n- Frontend: Riverpod 2.6, freezed (build_runner after model changes), Material 3. Widget tests. flutter analyze clean. Do NOT add code comments unless needed.\n- Backend (only if needed): feature-first, pytest-asyncio, ruff + mypy strict clean.\n\n## Plan deliverable — `plans/F-G_profile_redesign_plan.md` must contain\n1. **Scope & ownership**: exact files created/modified. Files to NOT touch (parallel-agent conflicts): `app/lib/features/compose/**`, `app/lib/features/search/**`, `app/lib/features/map/**`, `app/lib/features/feed/**`, `app/lib/features/ward/**`, `app/lib/features/rep_dashboard/**`, `app/lib/features/profile/presentation/screens/public_profile_screen.dart` + `app/lib/features/profile/domain/public_user_profile.dart` (PUBLIC profile + rep metrics are the rep-accountability feature's scope), `backend/app/features/representatives/**`, `backend/app/features/media/**`, `backend/app/features/geo/**`, `backend/app/features/wards/**`, `backend/app/features/search/**`. You MAY modify: `app/lib/features/profile/presentation/screens/profile_screen.dart`, `settings_screen.dart`, `edit_profile_screen.dart`, `anonymity_guide_screen.dart`, `app/lib/features/profile/presentation/profile_providers.dart`, `app/lib/features/profile/domain/user_profile.dart`, `app/lib/features/profile/presentation/widgets/**`, `app/lib/features/profile/domain/user_settings.dart`, `app/lib/core/router/app_router.dart`/`route_paths.dart` (only for profile routes), `backend/app/features/auth/**` if UserOut needs an additive field.\n2. **Design spec**: the redesigned ProfileScreen layout — clean hierarchy (header/identity, role+ward display, stats, then organized sections for drafts/outbox/my-issues), token-based styling, less clutter, better empty states, and how the rep account display differs if the current user is a representative (show role badge + ward + a link/entry to the rep dashboard — the rep dashboard screen already exists at /rep-dashboard; do NOT build rep metrics here, just surface role + navigation hook). Add `role` and `ward` to UserProfile + parse from /auth/me. Specify exact Keys for new widgets, new providers, domain model changes (freezed).\n3. **Backend design**: only if needed (e.g. UserOut already has role/ward — likely no change; state that). If you add a field, specify the schema + default.\n4. **User-journey E2E test plan** (flutter widget tests + any backend): e.g. user opens Profile → sees clean header with role/ward → rep user sees rep badge + dashboard entry → drafts/outbox/my-issues sections render → my-issues filters work → edit profile/settings reachable. Note which existing tests need updating.\n5. **Edge cases** (guest, no drafts, zero activity, rep role) and **ordering/dependencies** (rep dashboard route/link provided by rep feature; only wire the navigation).\n\nBe concrete and concise. Use exact names. This plan is handed to a coder agent and separately to an independent test agent.",
  "subagent_type": "general"
}
```

**Output:**
```
<task id="ses_feadfecdaffezrk2bMRJ7vsxG2" state="completed">
<task_result>
Plan written to `plans/F-G_profile_redesign_plan.md`.

Key decisions (grounded in the verified code):

- **No backend change** — `UserOut` already returns `role`/`ward` (`schemas.py:63-65`), populated by `GET /auth/me` (`router.py:109-135`); the frontend model just drops them.
- **Domain**: `UserProfile` is a plain class (not freezed, despite the general convention) → add `role`/`ward` as optional params + `isRepresentative` getter; no `build_runner`. All existing test fixtures compile unchanged.
- **4 files + 1 new widget** (`profile_role_badge.dart`); `settings_screen.dart`, `edit_profile_screen.dart`, `anonymity_guide_screen.dart`, router, and all rep-feature files untouched.
- **Rep display**: role pill + ward chip + a `repDashboardEntryButton` card that only does `context.push(RoutePaths.repDashboard)` (route already registered at `app_router.dart:186`); no metrics built here. Detection is `role.toLowerCase().contains('representative')`, matching the existing public-profile convention.
- **Test safety**: verified every preserved key/label the 6 existing profile test files assert (e.g. `'Offline Outbox'`, `'My Reported Issues & Activity'`, `userIssueItem_<id>`, `ACTIVE/RESOLVED` overlays, photo-left-of-bio geometry) — no existing test needs editing; new tests go in `profile_redesign_test.dart`.
</task_result>
</task>
```

---

## Assistant (Build · DeepSeek V4 Flash Free · 45.6s)

_Thinking:_

All 7 plan agents completed and wrote plans to `plans/`. Now let me spawn the 7 CODE agents in parallel, each given the plan + relevant context + file ownership. 

Before that, let me quickly review the plans to make sure there are no major conflicts between features. Key conflicts to check:
1. F-A and F-B: F-A does map invalidation (outbox_screen.dart line 30 — that's in `app/lib/features/outbox/presentation/outbox_screen.dart`). F-B does map refresh. F-A said "one-line map invalidation in outbox_screen.dart". F-B said outbox hook documented not wired. OK.
2. F-A modifies `ComposeDraft.mediaBytes` → typed `media` list. This changes compose_draft.dart + compose_draft.g.dart (needs build_runner). F-F doesn't touch compose. OK.
3. F-C owns ward_rep_card.dart. F-D uses it but doesn't edit. F-C also edits public_profile_screen.dart, public_user_profile.dart, ward_representative_out.dart (documented additive exception for ward_representative_out.dart which F-D owns... wait, F-D owns `app/lib/features/ward/domain/**` and F-C wants to modify `ward_representative_out.dart`. That's a conflict!

Let me check: F-C said "no touch to ward detail screen/providers/domain-data except a documented additive exception for ward_representative_out.dart (needs user_id to fetch/navigate)". And F-D owns `app/lib/features/ward/domain/**`. So both F-C and F-D would touch `ward_representative_out.dart`. 

This is a real conflict. Let me look at both plans to see what they want for ward_representative_out.dart and resolve. Let me read the relevant parts of F-C and F-D plans.

4. F-D seeds wards (seed/data/wards.json + seed_wards()) AND F-B also adds seed/data/wards.json with boundary. Both want to modify backend/seed.py! Conflict. F-B adds boundary column + wards seed; F-D wants to seed the 2 wards too.

I need to coordinate. Let me read the plans to understand exact touch points, then assign ownership to avoid conflicts:
- Wards seeding (backend/seed.py + seed/data/wards.json): assign to F-B ONLY (it has the boundary data). F-D should NOT seed wards; instead depend on F-B's seeding. I'll tell F-D to rely on the seed done by F-B and NOT modify seed.py or create wards.json. F-D can still write tests that seed wards via raw SQL (like existing tests do).
- ward_representative_out.dart: assign to F-C ONLY (adds user_id + metrics fields). F-D should consume it (its WardRepCard usage). Actually F-D owns ward domain... Let me just assign the file to F-C and tell F-D to code against the extended contract (adding user_id + performance fields), with a fallback. Since both run in parallel, F-D must handle the field being present. To avoid build breakage: F-C adds fields to ward_representative_out.dart; F-D's ward_detail_screen references WardRepresentativeOut fields. If F-D adds fields that F-C also adds, duplicate definitions → compile error. So I must be precise.

Simplest resolution:
- F-C OWNS `app/lib/features/ward/presentation/widgets/ward_rep_card.dart` AND `app/lib/features/ward/domain/ward_representative_out.dart` (extending with user_id + metrics).
- F-D OWNS the rest of ward: ward_detail_screen.dart, ward_hero_banner, ward_metric_card, ward_recent_issues_list, ward_chip, local_talk_compose_sheet, ward_detail_out.dart, ward_summary_out.dart, ward_list_response.dart, ward_repository.dart, ward_providers.dart. F-D does NOT edit ward_rep_card.dart or ward_representative_out.dart; it consumes them (must handle both with/without metrics gracefully — the backend will be extended by F-C so by test time the contract should be consistent; F-D can code defensively).
- Ward boundaries mini-map (F-D wants WardBoundaryMiniMap + wardBoundaryProvider): F-B owns boundary data via backend geo. F-D wants a boundary mini-map that fetches from `wardBoundaryProvider` seam. F-B adds GET /geo/ward-boundaries. F-D should consume that endpoint via its own provider (in ward feature) — that's fine, F-D owns ward providers. F-B owns the backend endpoint + map screen rendering. No file conflict as long as F-D's boundary provider lives in ward feature. Good.

- Backend seed: F-B owns seed.py + seed/data/wards.json. F-D must NOT touch seed.py. But F-D's backend plan wants to extend AssignedRepresentativeOut (wards/schemas.py). F-C ALSO wants to extend AssignedRepresentativeOut (shared schema)! Both want to modify `backend/app/features/wards/schemas.py`. Conflict!

Let me check: F-C plan says "shared RepresentativeMetricsOut base schema ... extended into ... AssignedRepresentativeOut". F-D plan says "extends backend AssignedRepresentativeOut (mirroring the rep feature's SQL) with total/escalated/responded/pending + response_rate_pct, plus id/user_id".

So BOTH want to touch `backend/app/features/wards/schemas.py` and the service that populates assigned_representative (wards/service.py get_ward_detail). That's a genuine conflict.

Resolution: Assign ALL rep-metrics-in-ward work to F-C (it owns representatives backend + the schema extension for AssignedRepresentativeOut + wards/service.py only for the assigned_representative metrics computation + the new public endpoint). F-D must NOT modify wards/schemas.py or wards/service.py; it consumes the extended WardDetailOut.assigned_representative.

But F-D also needs id/user_id in the rep card for navigation. That's covered by F-C's extension.

Let me also check F-D wants to seed wards — assign to F-B only, F-D relies on it.

Also F-D's backend plan mentions "get_ward_detail recent_issues limit param" — that's wards/router.py. F-C also touches wards/router.py? F-C's plan mentions only representatives router + auth. The public endpoint GET /representatives/by-user/{user_id} is in representatives router. Good, so wards/router.py is F-D's (except assigned_representative which is in wards/service.py get_ward_detail — F-C touches that). Hmm, get_ward_detail is in wards/service.py. F-C will edit wards/service.py's get_ward_detail to include metrics in assigned_representative. F-D wants to edit wards/router.py (limit param) and wards/service.py (get_ward_detail recent_issues limit)? That's a conflict on wards/service.py.

Resolution: F-C owns the `assigned_representative` enrichment (wards/service.py `get_ward_detail` function + wards/schemas.py `AssignedRepresentativeOut`). F-D does NOT modify wards/service.py or wards/schemas.py or wards/models.py. F-D may modify wards/router.py if needed (limit param) but must keep get_ward_detail call signature compatible — actually the router calls service.get_ward_detail; if F-D adds a param to router it must update the service call, conflicting with F-C's edit. To be safe: F-D should NOT change the backend at all for the ward detail endpoint (skip the issues_limit param — the default is fine). F-D focuses on frontend + backend test seeding. That keeps wards/router.py untouched too.

Wait — but F-D plan says "Backend design: any changes to ward detail response needed for the page (e.g. recent_issues limit param...)". I'll instruct F-D: NO backend changes to wards feature files that F-C owns (schemas.py, service.py, models.py). Router changes allowed ONLY if isolated and don't touch get_ward_detail signature — safer to skip. Just consume existing.

Let me also check the seed conflict more: F-B writes seed/data/wards.json + seed_wards() in seed.py. F-C wants seed changes too: "set seeded rep user role to representative + add an official response on a resolved issue so demo metrics are non-zero" — modifies backend/seed.py _seed_representatives. Conflict with F-B's seed.py edits.

Resolution: F-B owns seed.py wards seeding ONLY (add wards to _TABLES/_DATA_FILES + seed_wards()). F-C owns seed.py representatives/user role changes. Both edit seed.py. Parallel edits to the same file → conflict risk. 

Options: (a) sequentialize: have F-B do all seed.py changes including rep role + official response. That couples features. (b) Have F-C do seed.py changes including wards. (c) Have me (main agent) reconcile seed.py after both, merging their changes. 

Simplest: I'll tell each code agent to make minimal, well-commented, non-overlapping edits to seed.py and I'll reconcile after. Actually parallel agents editing the same file is risky because both will read the current version and write edits — second write could clobber the first depending on how they use Edit (they read then edit specific regions, so if they edit different regions it's fine; git diff will show both edits).

Actually, agents use the Edit tool which does surgical string replacements, not whole-file writes. So two agents editing DIFFERENT regions of seed.py should be compatible. But if one agent's edit overlaps another's region, conflict. I'll assign specific regions: F-B adds wards seeding function + registration (near top, _TABLES/_DATA_FILES + a new function + call in main seed); F-C modifies _seed_representatives to set role + add an official response. Different regions. Should be OK.

Let me verify the actual seed.py structure to give precise region guidance. Let me read relevant portions of seed.py. Also let me read the plans quickly to make sure I give correct context. Actually the plan files are long; I'll read the ownership/scope sections of each to be safe, but I can rely on the agent summaries. Let me read the key conflict areas of the plans: F-C and F-D ownership, and F-B seed.

Let me read the plans' scope sections.

All 7 plans are written. Let me review the conflict-prone areas (shared files between features) before dispatching code

**Tool: bash**

**Input:**
```json
{
  "command": "ls -la plans/ && wc -l plans/*.md"
}
```

**Output:**
```
total 320
drwxr-xr-x@  9 rohit  staff    288 18 Aug 19:23 .
drwxr-xr-x@ 31 rohit  staff    992 18 Aug 19:15 ..
-rw-r--r--@  1 rohit  staff  25454 18 Aug 19:19 F-A_compose_media_plan.md
-rw-r--r--@  1 rohit  staff  19862 18 Aug 19:19 F-B_map_heatmap_boundaries_plan.md
-rw-r--r--@  1 rohit  staff  22430 18 Aug 19:22 F-C_rep_accountability_plan.md
-rw-r--r--@  1 rohit  staff  19785 18 Aug 19:23 F-D_ward_details_plan.md
-rw-r--r--@  1 rohit  staff  25788 18 Aug 19:21 F-E_search_fix_plan.md
-rw-r--r--@  1 rohit  staff  20855 18 Aug 19:20 F-F_feed_ui_plan.md
-rw-r--r--@  1 rohit  staff  13608 18 Aug 19:20 F-G_profile_redesign_plan.md
     382 plans/F-A_compose_media_plan.md
     235 plans/F-B_map_heatmap_boundaries_plan.md
     366 plans/F-C_rep_accountability_plan.md
     334 plans/F-D_ward_details_plan.md
     341 plans/F-E_search_fix_plan.md
     302 plans/F-F_feed_ui_plan.md
     156 plans/F-G_profile_redesign_plan.md
    2116 total

```

**Tool: grep**

**Input:**
```json
{
  "pattern": "seed|wards\\.json|seed\\.py|ward_representative_out|AssignedRepresentativeOut|wards/schemas|wards/service|wards/router|wards/models",
  "path": "/Users/rohit/Desktop/Python/LocalLens/plans/F-C_rep_accountability_plan.md"
}
```

**Output:**
```
Found 63 matches
/Users/rohit/Desktop/Python/LocalLens/plans/F-A_compose_media_plan.md:
  Line 302: Existing `test_media_pipeline_extended.py` and `test_media_seed_and_demo.py` must remain green (new fields are nullable).


/Users/rohit/Desktop/Python/LocalLens/plans/F-E_search_fix_plan.md:
  Line 278: Prereq: `cd backend && uv run uvicorn app.main:app --reload` (port 8000), DB seeded (`uv run python seed.py`).


/Users/rohit/Desktop/Python/LocalLens/plans/F-D_ward_details_plan.md:
  Line 4: backend/seed support it needs, without touching any parallel-agent files.

  Line 16: | `backend/app/features/wards/seed.py` | New `seed_wards(session)` — idempotent upsert of the 2 known wards, reading `seed/data/wards.json`. |

  Line 17: | `seed/data/wards.json` | Shared seed data for the 2 wards (single source of truth, coordinated with the map feature). |

  Line 23: | `app/lib/features/ward/domain/ward_representative_out.dart` | Add performance + identity fields (see §3.1). |

  Line 29: | `backend/app/features/wards/schemas.py` | Extend `AssignedRepresentativeOut` with identity + performance fields (§2.1). |

  Line 30: | `backend/app/features/wards/service.py` | Compute rep performance in `get_ward_detail` (§2.2). |

  Line 31: | `backend/seed.py` | Add `Ward` to `_TABLES`, `"wards"` to `_DATA_FILES`, and a `_seed_wards(session, rows)` loader reading `seed/data/wards.json`. |

  Line 32: | `backend/app/main.py` | (Coordination-flagged, see §1.4) call `seed_wards` in `lifespan` for `environment == "development"` so the page works live without a manual `make seed`. |

  Line 57:   feature is reworking lifespan, prefer calling `seed_wards` there and share the call.

  Line 69: ### 2.1 `backend/app/features/wards/schemas.py` — extend `AssignedRepresentativeOut`

  Line 72: class AssignedRepresentativeOut(BaseModel):

  Line 96: ### 2.2 `backend/app/features/wards/service.py` — rep performance in `get_ward_detail`

  Line 115: Return `AssignedRepresentativeOut` with the existing name/title/verified_at plus `id`, `user_id`

  Line 120: `seed/data/wards.json` (new, single source of truth):

  Line 131: - `backend/app/features/wards/seed.py` — `SEED_WARDS` loaded from the JSON + `seed_wards(session)`

  Line 134: - `backend/seed.py` — add `Ward` to `_TABLES` (deletion list, no FK concerns), `"wards"` to

  Line 135:   `_DATA_FILES` (first entry), and `_seed_wards(session, rows)` that delegates to

  Line 136:   `app.features.wards.seed.seed_wards`.

  Line 138:   and call `seed_wards(session)`. Flag in PR: confirm no parallel agent is touching lifespan.

  Line 141: fallback in `map_screen.dart` and the search test seed).

  Line 147: ### 3.1 Domain: `app/lib/features/ward/domain/ward_representative_out.dart`

  Line 258: Reuse the `_seed_ward` / `_seed_representative` / `_seed_issue` helper style already in

  Line 261: - `test_be_ward_v2_01_rep_performance_fields`: seed ward + rep + open/escalated/resolved issues +

  Line 271: - `test_be_ward_v2_05_seed_idempotent_and_coordinates`: run `seed_wards` twice → exactly 2 rows

  Line 303: - **Empty `wards` table (pre-seed)**: page 404s; seeding §2.3 fixes live reachability; empty-ward

  Line 319: 1. **Backend first** (schema → service → seed → seed.py/main.py) so the API returns perf fields

  Line 323:    current-user-only — unusable for public display). Contract = extended `AssignedRepresentativeOut`.

  Line 329: 4. **Seeding**: single data source `seed/data/wards.json`; map feature must use identical slugs/


/Users/rohit/Desktop/Python/LocalLens/plans/F-B_map_heatmap_boundaries_plan.md:
  Line 16: | `seed/data/wards.json` | 2 ward records incl. `boundary` polygon rings (concrete coordinates in §2.1). |

  Line 27: | `backend/app/features/wards/models.py` | Add `boundary: Mapped[str \| None] = mapped_column(Text, nullable=True)` to `Ward` (GeoJSON ring JSON-encoded as text, pattern-matches `media_urls`). |

  Line 31: | `backend/seed.py` | Add `Ward` to `_TABLES`, `"wards"` to `_DATA_FILES`, add `_seed_wards(...)` (dedup by slug), add wards to `_report`. |

  Line 43: - `backend/app/features/wards/schemas.py` changes are limited to adding nothing to `WardSummaryOut`/`WardDetailOut` (keep ward-detail contract stable). The `wards/models.py` column addition and `geo/schemas.py` are permitted per plan intro.

  Line 49: ### 2a. Ward boundary storage, migration, seed

  Line 51: - **Column:** `Ward.boundary` — SQLAlchemy `Text`, nullable. Value = JSON-encoded single outer ring `[[lat, lng], ...]` (no holes, ≥3 points). Nullable so existing raw-SQL test helpers (`backend/tests/features/geo/test_geo.py:_seed_ward` `CREATE TABLE IF NOT EXISTS wards (...)` without the new column) keep working untouched.

  Line 53: - **Seed `seed/data/wards.json`:**

  Line 84:   These are ~2.2 km octagons centred on the two known ward centres. **Internet sourcing:** the coder MAY optionally attempt an Overpass query (`[out:json]; area["name"="Mumbai"]; rel(area)["admin_level"~"8"|"9"]["boundary"="administrative"]; out geom;`) during implementation, but MUST NOT block on it — the two wards are fictional, so the synthesized rings above are the authoritative seed. Runtime never fetches from the internet.

  Line 85: - **`seed.py`:** `_seed_wards` builds `Ward(...)` from each JSON row incl. `boundary=json.dumps(row["boundary"])`; dedup key = `slug`; add `"wards"` to `_DATA_FILES` (after "users" — no FK, order irrelevant) and `Ward` to `_TABLES` (clear first). `_report` gains `"wards"`.

  Line 225: | Raw-SQL ward seeding in existing tests | New column is nullable; their `CREATE TABLE`/`INSERT` untouched and still valid. |

  Line 230: 1. **Backend first:** `wards/models.py` column → alembic migration → `seed/data/wards.json` + `seed.py` → `geo/schemas.py` + `geo/service.py` (fallback helpers) → `geo/router.py`. Verify `ruff`, `mypy strict`, existing `test_geo.py` green.

  Line 235: - **Do not** hand-edit `docs/*` SDD artifacts or `.sdd/**`/`logs/**`; `seed/data/wards.json` is the only new data asset.


/Users/rohit/Desktop/Python/LocalLens/plans/F-C_rep_accountability_plan.md:
  Line 21: | `backend/app/features/wards/schemas.py` | Extend `AssignedRepresentativeOut` with `id`, `user_id`, `ward`, and metrics (reuse `RepresentativeMetricsOut`). |

  Line 22: | `backend/app/features/wards/service.py` | Populate the new `AssignedRepresentativeOut` fields via `compute_rep_metrics`. |

  Line 23: | `seed/data/users.json` | Set user `id: 2` role `citizen` → `representative` (seeded rep Meera Iyer). |

  Line 24: | `seed/data/official_responses.json` | Add one `official_response` row pointing at a `resolved` ward issue (issue 7 or 15) so the demo rep has a non-zero `resolved_ward_issues`. |

  Line 31: | `app/lib/features/ward/domain/ward_representative_out.dart` | **Documented exception** — additive fields `id`, `userId`, `ward` (defaulted). |

  Line 44: **Exception rationale for `ward_representative_out.dart`:** requirement #2 mandates rep

  Line 47: `WardDetailOut`/`AssignedRepresentativeOut` already flow through `WardRepresentativeOut.fromJson`,

  Line 94: `backend/app/features/wards/schemas.py` — `AssignedRepresentativeOut` becomes

  Line 95: `AssignedRepresentativeOut(RepresentativeMetricsOut)` with `id: str`, `user_id: int`,

  Line 165: `backend/app/features/wards/service.py` — in `get_ward_detail`, build

  Line 166: `AssignedRepresentativeOut` with `id=rep.id, user_id=rep.user_id, ward=rep.ward` plus

  Line 171: - Reps are already provisioned via `seed.py` + `seed/data/representatives.json`

  Line 172:   (`rep_ward45_urban_central`, user 2). **Yes, keep the seeded demo rep** — but:

  Line 173:   - `seed/data/users.json`: user `id: 2` `role` → `"representative"` (currently `"citizen"`),

  Line 175:   - `seed/data/official_responses.json`: add a row for a `resolved` ward issue (issue 7 or 15,

  Line 178:   - No code change to `seed.py` needed (its factories already pass `role` and `official_responses`).

  Line 195: `app/lib/features/ward/domain/ward_representative_out.dart` — ADD (defaulted so the 2 existing

  Line 300:   `resolved_ward_issues`; a `resolved` issue the rep responded to → counted. Assert seed-data

  Line 339:   in_progress bucket (documented; existing seeded rows all have status_update).

  Line 354: 3. Backend router `by-user` endpoint; wards `AssignedRepresentativeOut` + service population.

  Line 363: 10. Manual `uv run python seed.py` to refresh demo data.

```

**Tool: grep**

**Input:**
```json
{
  "pattern": "seed|wards\\.json|seed\\.py|ward_representative_out|AssignedRepresentativeOut|wards/schemas|wards/service|wards/router|wards/models|NOT touch|DO NOT",
  "path": "/Users/rohit/Desktop/Python/LocalLens/plans/F-D_ward_details_plan.md"
}
```

**Output:**
```
Found 69 matches
/Users/rohit/Desktop/Python/LocalLens/plans/F-A_compose_media_plan.md:
  Line 52: ### Files to NOT touch (parallel-agent conflict avoidance)

  Line 302: Existing `test_media_pipeline_extended.py` and `test_media_seed_and_demo.py` must remain green (new fields are nullable).


/Users/rohit/Desktop/Python/LocalLens/plans/F-E_search_fix_plan.md:
  Line 32: ### 1.3 Files to NOT touch (parallel-agent conflict avoidance)

  Line 278: Prereq: `cd backend && uv run uvicorn app.main:app --reload` (port 8000), DB seeded (`uv run python seed.py`).


/Users/rohit/Desktop/Python/LocalLens/plans/F-C_rep_accountability_plan.md:
  Line 21: | `backend/app/features/wards/schemas.py` | Extend `AssignedRepresentativeOut` with `id`, `user_id`, `ward`, and metrics (reuse `RepresentativeMetricsOut`). |

  Line 22: | `backend/app/features/wards/service.py` | Populate the new `AssignedRepresentativeOut` fields via `compute_rep_metrics`. |

  Line 23: | `seed/data/users.json` | Set user `id: 2` role `citizen` → `representative` (seeded rep Meera Iyer). |

  Line 24: | `seed/data/official_responses.json` | Add one `official_response` row pointing at a `resolved` ward issue (issue 7 or 15) so the demo rep has a non-zero `resolved_ward_issues`. |

  Line 31: | `app/lib/features/ward/domain/ward_representative_out.dart` | **Documented exception** — additive fields `id`, `userId`, `ward` (defaulted). |

  Line 33: ### Files to NOT touch (parallel-agent conflicts)

  Line 44: **Exception rationale for `ward_representative_out.dart`:** requirement #2 mandates rep

  Line 47: `WardDetailOut`/`AssignedRepresentativeOut` already flow through `WardRepresentativeOut.fromJson`,

  Line 50: additive; do NOT touch `ward_detail_screen.dart`, ward providers, or ward data layer.

  Line 94: `backend/app/features/wards/schemas.py` — `AssignedRepresentativeOut` becomes

  Line 95: `AssignedRepresentativeOut(RepresentativeMetricsOut)` with `id: str`, `user_id: int`,

  Line 165: `backend/app/features/wards/service.py` — in `get_ward_detail`, build

  Line 166: `AssignedRepresentativeOut` with `id=rep.id, user_id=rep.user_id, ward=rep.ward` plus

  Line 171: - Reps are already provisioned via `seed.py` + `seed/data/representatives.json`

  Line 172:   (`rep_ward45_urban_central`, user 2). **Yes, keep the seeded demo rep** — but:

  Line 173:   - `seed/data/users.json`: user `id: 2` `role` → `"representative"` (currently `"citizen"`),

  Line 175:   - `seed/data/official_responses.json`: add a row for a `resolved` ward issue (issue 7 or 15,

  Line 178:   - No code change to `seed.py` needed (its factories already pass `role` and `official_responses`).

  Line 195: `app/lib/features/ward/domain/ward_representative_out.dart` — ADD (defaulted so the 2 existing

  Line 300:   `resolved_ward_issues`; a `resolved` issue the rep responded to → counted. Assert seed-data

  Line 339:   in_progress bucket (documented; existing seeded rows all have status_update).

  Line 354: 3. Backend router `by-user` endpoint; wards `AssignedRepresentativeOut` + service population.

  Line 363: 10. Manual `uv run python seed.py` to refresh demo data.


/Users/rohit/Desktop/Python/LocalLens/plans/F-D_ward_details_plan.md:
  Line 4: backend/seed support it needs, without touching any parallel-agent files.

  Line 16: | `backend/app/features/wards/seed.py` | New `seed_wards(session)` — idempotent upsert of the 2 known wards, reading `seed/data/wards.json`. |

  Line 17: | `seed/data/wards.json` | Shared seed data for the 2 wards (single source of truth, coordinated with the map feature). |

  Line 23: | `app/lib/features/ward/domain/ward_representative_out.dart` | Add performance + identity fields (see §3.1). |

  Line 29: | `backend/app/features/wards/schemas.py` | Extend `AssignedRepresentativeOut` with identity + performance fields (§2.1). |

  Line 30: | `backend/app/features/wards/service.py` | Compute rep performance in `get_ward_detail` (§2.2). |

  Line 31: | `backend/seed.py` | Add `Ward` to `_TABLES`, `"wards"` to `_DATA_FILES`, and a `_seed_wards(session, rows)` loader reading `seed/data/wards.json`. |

  Line 32: | `backend/app/main.py` | (Coordination-flagged, see §1.4) call `seed_wards` in `lifespan` for `environment == "development"` so the page works live without a manual `make seed`. |

  Line 34: ### 1.3 Files / dirs to NOT touch (parallel-agent conflicts)

  Line 57:   feature is reworking lifespan, prefer calling `seed_wards` there and share the call.

  Line 69: ### 2.1 `backend/app/features/wards/schemas.py` — extend `AssignedRepresentativeOut`

  Line 72: class AssignedRepresentativeOut(BaseModel):

  Line 96: ### 2.2 `backend/app/features/wards/service.py` — rep performance in `get_ward_detail`

  Line 115: Return `AssignedRepresentativeOut` with the existing name/title/verified_at plus `id`, `user_id`

  Line 120: `seed/data/wards.json` (new, single source of truth):

  Line 131: - `backend/app/features/wards/seed.py` — `SEED_WARDS` loaded from the JSON + `seed_wards(session)`

  Line 134: - `backend/seed.py` — add `Ward` to `_TABLES` (deletion list, no FK concerns), `"wards"` to

  Line 135:   `_DATA_FILES` (first entry), and `_seed_wards(session, rows)` that delegates to

  Line 136:   `app.features.wards.seed.seed_wards`.

  Line 138:   and call `seed_wards(session)`. Flag in PR: confirm no parallel agent is touching lifespan.

  Line 141: fallback in `map_screen.dart` and the search test seed).

  Line 147: ### 3.1 Domain: `app/lib/features/ward/domain/ward_representative_out.dart`

  Line 258: Reuse the `_seed_ward` / `_seed_representative` / `_seed_issue` helper style already in

  Line 261: - `test_be_ward_v2_01_rep_performance_fields`: seed ward + rep + open/escalated/resolved issues +

  Line 271: - `test_be_ward_v2_05_seed_idempotent_and_coordinates`: run `seed_wards` twice → exactly 2 rows

  Line 303: - **Empty `wards` table (pre-seed)**: page 404s; seeding §2.3 fixes live reachability; empty-ward

  Line 319: 1. **Backend first** (schema → service → seed → seed.py/main.py) so the API returns perf fields

  Line 323:    current-user-only — unusable for public display). Contract = extended `AssignedRepresentativeOut`.

  Line 329: 4. **Seeding**: single data source `seed/data/wards.json`; map feature must use identical slugs/


/Users/rohit/Desktop/Python/LocalLens/plans/F-B_map_heatmap_boundaries_plan.md:
  Line 16: | `seed/data/wards.json` | 2 ward records incl. `boundary` polygon rings (concrete coordinates in §2.1). |

  Line 27: | `backend/app/features/wards/models.py` | Add `boundary: Mapped[str \| None] = mapped_column(Text, nullable=True)` to `Ward` (GeoJSON ring JSON-encoded as text, pattern-matches `media_urls`). |

  Line 31: | `backend/seed.py` | Add `Ward` to `_TABLES`, `"wards"` to `_DATA_FILES`, add `_seed_wards(...)` (dedup by slug), add wards to `_report`. |

  Line 38: ### 1.3 Files to NOT touch (parallel-agent conflict avoidance)

  Line 43: - `backend/app/features/wards/schemas.py` changes are limited to adding nothing to `WardSummaryOut`/`WardDetailOut` (keep ward-detail contract stable). The `wards/models.py` column addition and `geo/schemas.py` are permitted per plan intro.

  Line 49: ### 2a. Ward boundary storage, migration, seed

  Line 51: - **Column:** `Ward.boundary` — SQLAlchemy `Text`, nullable. Value = JSON-encoded single outer ring `[[lat, lng], ...]` (no holes, ≥3 points). Nullable so existing raw-SQL test helpers (`backend/tests/features/geo/test_geo.py:_seed_ward` `CREATE TABLE IF NOT EXISTS wards (...)` without the new column) keep working untouched.

  Line 53: - **Seed `seed/data/wards.json`:**

  Line 84:   These are ~2.2 km octagons centred on the two known ward centres. **Internet sourcing:** the coder MAY optionally attempt an Overpass query (`[out:json]; area["name"="Mumbai"]; rel(area)["admin_level"~"8"|"9"]["boundary"="administrative"]; out geom;`) during implementation, but MUST NOT block on it — the two wards are fictional, so the synthesized rings above are the authoritative seed. Runtime never fetches from the internet.

  Line 85: - **`seed.py`:** `_seed_wards` builds `Ward(...)` from each JSON row incl. `boundary=json.dumps(row["boundary"])`; dedup key = `slug`; add `"wards"` to `_DATA_FILES` (after "users" — no FK, order irrelevant) and `Ward` to `_TABLES` (clear first). `_report` gains `"wards"`.

  Line 225: | Raw-SQL ward seeding in existing tests | New column is nullable; their `CREATE TABLE`/`INSERT` untouched and still valid. |

  Line 230: 1. **Backend first:** `wards/models.py` column → alembic migration → `seed/data/wards.json` + `seed.py` → `geo/schemas.py` + `geo/service.py` (fallback helpers) → `geo/router.py`. Verify `ruff`, `mypy strict`, existing `test_geo.py` green.

  Line 235: - **Do not** hand-edit `docs/*` SDD artifacts or `.sdd/**`/`logs/**`; `seed/data/wards.json` is the only new data asset.

```

---

## Assistant (Build · DeepSeek V4 Flash Free · 1601.0s)

_Thinking:_

I have a clear picture of the conflicts. Let me resolve them with precise ownership assignments:

**Conflicts identified:**
1. **`backend/app/features/wards/schemas.py` + `service.py`** — touched by BOTH F-C (extend AssignedRepresentativeOut + populate metrics) and F-D (extend AssignedRepresentativeOut + populate). 
   → RESOLVE: Assign to **F-C** ONLY. F-D must NOT touch these.

2. **`seed/data/wards.json` + `backend/seed.py` ward seeding** — touched by F-B (boundary + _seed_wards) and F-D (same).
   → RESOLVE: Assign to **F-B** ONLY (it owns boundary data + ward seed). F-D must NOT create/modify seed/data/wards.json or the ward seeding in seed.py. F-D should also NOT create `backend/app/features/wards/seed.py`. F-D relies on F-B's seeding.

3. **`app/lib/features/ward/domain/ward_representative_out.dart`** — touched by F-C (additive fields) and F-D.
   → RESOLVE: Assign to **F-C** ONLY. F-D must NOT touch it.

4. **`backend/seed.py`** — F-B (ward seeding) + F-C (users.json role + official_responses.json). Note F-C's plan says "No code change to seed.py needed" — it only changes `seed/data/users.json` and `seed/data/official_responses.json`. F-B changes seed.py. So seed.py → F-B only. seed/data/users.json + official_responses.json → F-C. No conflict on seed.py if F-C doesn't touch it. Good.

5. **`backend/app/main.py` lifespan** — F-D wanted to call seed_wards in lifespan. F-B's plan mentions main.py? Not in the grep. To be safe, assign main.py to NO ONE (avoid touching). Wards will be seeded via `make seed` or via the DB migration. Actually, F-D's plan wanted lifespan seeding so the page works live. Since F-B owns seeding, I'll tell F-B to optionally add lifespan seeding but it's fine to require `make seed`. Let me instruct F-B that seed must be runnable via `make seed` and tests seed via SQL. No lifespan changes needed. Actually, for a good UX the live app should have wards. `make backend` runs alembic upgrade head, not seed. Let me tell F-B to add wards seeding into lifespan only if trivial and safe, else document `make seed`. To keep it simple and avoid main.py conflicts: instruct F-B to NOT modify main.py; instead ensure `make seed` populates wards. But the live DB already has data; `make seed` wipes and reseeds. The user's flow: they'll likely run the app against existing DB. Hmm. Let me have F-B also run `make seed` after implementation to populate the live DB with wards. Good — F-B (or me) runs seed at the end.

Also F-C's seed changes (users.json role, official_responses.json) require re-running `make seed`. F-B's seed includes wards. So a single `make seed` at the end handles all. 

6. **`app/lib/features/feed/...` vs F-F** — F-F owns feed presentation. No conflicts with others.

7. **F-A `outbox_screen.dart`** (one-line map invalidation) — outbox_screen.dart is in `app/lib/features/outbox/`. No other feature owns it. F-A takes it.

8. **`app/lib/features/geo/presentation/providers/geo_providers.dart`** — F-B owns `app/lib/features/geo/**`. F-D wants a boundary mini-map with a `wardBoundaryProvider` seam — but F-D should put that provider in ward feature (ward_providers.dart), NOT geo_providers.dart. And F-D's boundary provider would fetch GET /geo/ward-boundaries which F-B adds. Fine, no file conflict.

Wait, F-D also references geo's `feedCoordinatesProvider`? Not necessarily. Keep F-D's new provider in ward feature.

9. **`app/lib/core/router/app_router.dart` + route_paths.dart** — F-D (reachability) and F-G (profile routes) both list router as MAY modify. Both must make additive changes. F-D: no new route needed (ward route exists). Actually F-D's reachability plan may just wire existing buttons. F-G: repDashboardEntryButton push existing /rep-dashboard route. Both additive. Risk is low but if both edit the same file regions... F-G only adds UI in profile_screen (pushes existing route) — may not need router changes at all. I'll tell F-G no router changes needed (route exists). F-D no router changes (ward route exists). That removes router from both. 

10. **`app/lib/core/config/app_config.dart`** — F-E only. OK.

11. **`app/lib/core/network/api_exceptions.dart`** — F-E only (adds ApiParseException). OK.

Now, one more concern: F-A plan says it changes `ComposeDraft.mediaBytes` → typed media list (a breaking domain change requiring build_runner + updates to compose_screen, hive_draft_store, offline_outbox_queue, drafts_screen, and existing tests `drafts_page_test.dart`, `compose_outbox_fuzz_shield_test.dart`, `media_pipeline_extended_test.dart`, `location_service_test.dart`, `camera_viewfinder_test.dart`). That's a big change. The F-A plan flagged "OfflineOutboxQueue 3-arg constructor breaks an existing test". I'll let F-A handle it but tell it to keep tests passing (it should update tests it breaks as part of its implementation — wait, the user wants tests from a different agent, independent). Hmm.

The user's instruction: tests should be written by a different agent independently. But existing tests that break due to refactors must be updated. The code agent updating existing tests is acceptable (they're maintaining the suite), while the independent test agent writes NEW tests. I'll instruct code agents to update existing tests ONLY where their refactor breaks them, and the test agent adds new E2E tests.

Actually, to keep scope manageable and avoid breakage, maybe F-A should make the media model change ADDITIVE rather than breaking (keep mediaBytes but add media list)? Let me check the plan. The plan says "ComposeDraft.mediaBytes → typed media list". That's a breaking refactor. It could ripple a lot. Let me let the code agent decide but prefer additive to reduce breakage. I'll note this in the F-A code prompt: prefer additive changes to ComposeDraft if the typed-media refactor would break many existing tests; if it's cleaner, do it and update the affected existing tests.

Let me now also double check the F-B plan for heatmap: it changes map_screen.dart rendering (PolygonLayer) and map_controller HeatmapCell. F-F doesn't touch map. Good. F-D adds boundary mini-map in ward feature — uses flutter_map, fine.

Now, the test agents: 7 independent test agents, each writes E2E tests from their plan. They write to backend/tests/... and app/test/... New test files (to avoid clobbering existing tests). They should:
- Backend tests: pytest-asyncio, using the same conftest.py + seeding patterns as existing tests (raw SQL inserts). They must only use the plan's contract.
- Flutter tests: widget tests with fake repos/providers as existing tests do.

The test agents need to know: conftest.py pattern, how existing tests seed, how to override providers. Let me give each test agent a pointer to read `backend/tests/conftest.py` + an existing test file for the pattern, and `app/test/helpers.dart` + an existing widget test.

Test agents run in parallel with code agents? If they run simultaneously, they can't run the tests (code doesn't exist yet). But they can WRITE the test files. Then after code agents finish, I run everything. Writing tests against the plan contract is fine in parallel.

But there's a risk: test agents and code agents both write to the same test files? No — code agents write to lib/ and backend/app/, test agents write to app/test/ and backend/tests/. Code agents may need to update EXISTING tests broken by refactor. New test files are test agents'. There could be overlap if a code agent updates e.g. `search_screen_test.dart` (existing) and test agent adds new file `search_fix_e2e_test.dart`. OK.

Let me now dispatch the 7 code agents in parallel. Each gets:
- The plan file path to read
- Updated conflict-resolution ownership notes (critical!)
- Conventions reminder

And I'll dispatch test agents after code agents (per the user's plan→code→test sequence). Actually the user said "then a code, then a test sub agent". So sequence: code first, then test. Let me follow that: spawn 7 code agents now; when done, spawn 7 test agents.

Let me write the code agent prompts with ownership clarifications.

Common instructions for all code agents:
- Read your plan file first.
- Implement exactly to the plan.
- Respect file ownership boundaries (list).
- Run formatting/lint for your files.
- Update existing tests only if your refactor breaks them; do NOT write new feature tests (a separate test agent will).
- Do not edit docs/, .sdd/, logs/.
- Preserve existing Keys and test hooks.
- Run `dart run build_runner build` in app/ if you change freezed models.
- After implementation, run the relevant test subset to verify nothing you touched is broken (e.g. pytest for your feature, flutter test for your feature).
- Report exactly what you changed + any deviations from the plan.

Let me craft each prompt with the specific ownership fixes.

For F-A code agent:
- Plan: plans/F-A_compose_media_plan.md
- Owns: app/lib/features/compose/** (all), backend/app/features/media/**, backend/app/features/issues/** (media/upload related only — be surgical), app/lib/features/outbox/presentation/outbox_screen.dart (one-line map invalidation)
- Not: map/**, search/**, feed/**, profile/**, ward/**, rep_dashboard/**, geo/** (frontend+backend), representatives/**, wards/**, auth/**
- Prefer additive ComposeDraft changes; update broken existing tests in compose/camera/outbox area.
- Note: run build_runner if freezed changes.
- Need alembic migration for Media columns? The plan mentions new columns issue_id, deleted_at, captured_at. Migration file needed. But note: existing DB may need alembic upgrade. Let me tell F-A to create migration and run `uv run alembic upgrade head`. Careful: tests use in-memory or test DB? Check conftest. The plan said "new fields are nullable" to keep tests green. Good.

For F-B code agent:
- Plan: plans/F-B_map_heatmap_boundaries_plan.md
- Owns: app/lib/features/map/**, app/lib/features/geo/** frontend, backend/app/features/geo/**, backend/app/features/wards/models.py + alembic migration for boundary column, backend/seed.py (ward seeding only) + seed/data/wards.json
- Not: app/lib/features/ward/domain/ward_representative_out.dart, wards/schemas.py, wards/service.py, wards/router.py (F-C owns schemas/service for rep metrics; keep AssignedRepresentativeOut/WardDetailOut contract stable), compose/**, search/**, feed/**, profile/**, rep_dashboard/**, representatives/**, media/**, issues/** (except map-pins if necessary — but plan says no change), main.py
- IMPORTANT: seed/data/wards.json must have the 2 wards with slugs ward-45-urban-central and ward-12-metro-corridor (identical slugs F-D depends on). And seed.py ward seeding must be idempotent.
- Note: existing tests test_geo.py use raw SQL ward seeding with CREATE TABLE without boundary column → keep column nullable and those tests work.
- The DB has empty wards table. After implementing, run make seed so wards exist live? Actually F-C also changes seed data (users.json, official_responses.json). Re-seeding is needed after all. I'll run make seed myself at the end. But F-B should ensure seed.py works. It can run `make seed` to verify wards get created. But running make seed wipes DB — acceptable during dev.
- Run ruff/mypy on backend, flutter analyze on app.

For F-C code agent:
- Plan: plans/F-C_rep_accountability_plan.md
- Owns: backend/app/features/representatives/**, backend/app/features/wards/schemas.py (AssignedRepresentativeOut only), backend/app/features/wards/service.py (get_ward_detail assigned_representative population only), backend/app/features/auth/** (only if additive for public rep profile), seed/data/users.json (role for user id 2), seed/data/official_responses.json (add a row), app/lib/features/rep_dashboard/**, app/lib/features/ward/domain/ward_representative_out.dart, app/lib/features/ward/presentation/widgets/ward_rep_card.dart, app/lib/features/profile/domain/public_user_profile.dart, app/lib/features/profile/presentation/screens/public_profile_screen.dart
- Not: ward_detail_screen.dart, ward providers, ward data layer, ward_detail_out.dart, profile_providers.dart, user_profile.dart, profile_screen.dart, map/**, compose/**, search/**, feed/**, geo/** frontend, media/**, issues/**.
- IMPORTANT: the new public endpoint GET /representatives/by-user/{user_id} must be auth-optional (public). Public rep metrics provider should live in rep_dashboard_providers.dart so public_profile_screen and ward_rep_card can watch it.
- ward_rep_card.dart: keep compatible with existing tests (ward_detail_screen_test.dart references WardRepCard? maybe). Keep existing keys.
- seed.py: DO NOT touch (F-B owns). Only edit seed/data/users.json and official_responses.json.

For F-D code agent:
- Plan: plans/F-D_ward_details_plan.md
- IMPORTANT CONFLICT RESOLUTION: DO NOT touch backend/app/features/wards/schemas.py, service.py, router.py, models.py; DO NOT touch backend/seed.py or seed/data/wards.json or create backend/app/features/wards/seed.py; DO NOT touch app/lib/features/ward/domain/ward_representative_out.dart; DO NOT touch ward_rep_card.dart. These are owned by F-C and F-B. Consume the extended AssignedRepresentativeOut (id, user_id, ward + metrics) — code against that contract defensively (treat new fields as optional in your parsing if the type already includes them).
- Owns: app/lib/features/ward/presentation/screens/ward_detail_screen.dart, presentation/widgets/ward_hero_banner.dart, ward_metric_card.dart, ward_recent_issues_list.dart, ward_chip.dart, local_talk_compose_sheet.dart, app/lib/features/ward/domain/ward_detail_out.dart, ward_summary_out.dart, ward_list_response.dart, local_talk_post.dart (if needed), app/lib/features/ward/data/repositories/ward_repository.dart, app/lib/features/ward/presentation/providers/ward_providers.dart (add boundary provider here if implementing the mini-map)
- Not: map/**, geo/** (but you may call GET /geo/ward-boundaries from a provider in the ward feature), feed/**, profile/**, rep_dashboard/**, compose/**, search/**.
- The boundary mini-map: use flutter_map; fetch boundaries from GET /geo/ward-boundaries (F-B adds it); graceful fallback if empty.
- Reachability: ward route exists (/ward/:slug). Wire ward chips/buttons where they exist in feed/map — but feed_screen.dart and map_screen.dart are owned by F-F and F-B. So DON'T edit them; instead ensure the ward chip widget (ward_chip.dart, owned by you) navigates, and note the entry points. Actually the explore said feed chip uses geo ward_location_chip.dart (geo feature, F-B owns). Hmm. To avoid conflict, F-D reachability: make ward_chip.dart navigate (it's yours). And confirm /ward/:slug route works. Don't edit feed/map screens.

For F-E code agent:
- Plan: plans/F-E_search_fix_plan.md
- Owns: app/lib/features/search/**, app/lib/core/config/app_config.dart, app_config_provider.dart, app/lib/core/network/api_exceptions.dart + api_client.dart (if needed), ios Info.plist, macos entitlements (if needed), backend/app/features/search/** (if needed)
- Not: everything else.
- Must keep existing search tests passing (search_screen_test asserts 'Search unavailable' on error; add new error-kind behavior without breaking). The plan says keep 'Search unavailable' title for network failure.

For F-F code agent:
- Plan: plans/F-F_feed_ui_plan.md
- Owns: app/lib/features/feed/presentation/**, app/lib/shared/widgets/** (only if backward-compatible)
- Not: backend, domain (unless presentation-only), other features. Preserve existing feed tests.

For F-G code agent:
- Plan: plans/F-G_profile_redesign_plan.md
- Owns: app/lib/features/profile/presentation/screens/profile_screen.dart, settings_screen.dart, edit_profile_screen.dart, anonymity_guide_screen.dart, app/lib/features/profile/presentation/profile_providers.dart, app/lib/features/profile/domain/user_profile.dart, user_settings.dart, app/lib/features/profile/presentation/widgets/** (new profile_role_badge.dart)
- Not: public_profile_screen.dart, public_user_profile.dart, rep_dashboard/**, ward/**, map/**, compose/**, search/**, feed/**, backend (unless UserOut additive — but plan says no backend change)
- Preserve existing profile tests.

Now let me spawn the 7 code agents in parallel. I'll give each the plan path + ownership rules + verify instructions.

Let me write these prompts carefully.

Plans are solid but there are shared-file conflicts between F-B/F-C/F-D. I've resolved the ownership boundaries (F-B owns ward seeding + boundaries, F-C owns rep-metrics schema/seed roles, F-D owns the ward detail page UI only). Now dispatching all 7 CODE agents in parallel

**Tool: task**

**Input:**
```json
{
  "description": "Implement F-A compose/media",
  "prompt": "You are the CODER for feature F-A (Compose & Media: camera-only capture, per-image GPS→metadata, captured-media library, map refresh). \n\nRead your plan first: `/Users/rohit/Desktop/Python/LocalLens/plans/F-A_compose_media_plan.md` and implement it EXACTLY. Repo root: `/Users/rohit/Desktop/Python/LocalLens`. App: `app/` (Flutter, Riverpod+freezed). Backend: `backend/` (FastAPI+SQLAlchemy async).\n\n## FILE OWNERSHIP (STRICT — parallel agents are editing other files)\nYou MAY create/modify ONLY:\n- `app/lib/features/compose/**` (all files in this feature)\n- `app/lib/features/outbox/presentation/outbox_screen.dart` (ONLY the one-line map-pins invalidation the plan calls for; nothing else)\n- `backend/app/features/media/**`\n- `backend/app/features/issues/**` — ONLY media-attachment related changes the plan needs (e.g. linking media rows to issues on create); be surgical\n- new alembic migration under `backend/alembic/versions/` for any Media/Issue column changes\n- existing tests you break: `app/test/features/compose/**`, `app/test/features/outbox/**`, `backend/tests/features/media/**`, `backend/tests/features/issues/**` — update them ONLY if your refactor breaks them; keep behavior/Keys\n\nDo NOT touch: `app/lib/features/map/**`, `app/lib/features/geo/**`, `app/lib/features/search/**`, `app/lib/features/feed/**`, `app/lib/features/profile/**`, `app/lib/features/ward/**`, `app/lib/features/rep_dashboard/**`, `backend/app/features/geo/**`, `backend/app/features/wards/**`, `backend/app/features/representatives/**`, `backend/app/features/search/**`, `backend/app/features/auth/**`, `backend/seed.py`, `seed/**`, `docs/**`, `.sdd/**`, `logs/**`.\n\n## KEY GUIDANCE\n- Per the plan, gallery upload must be STRICTLY removed in all 3 places (compose `openGalleryButton`/`_addGalleryImages`, camera viewfinder gallery button). Preserve the in-app camera flow and its Keys (`shutterButton`, `cameraFlipButton`, `flashToggleButton`, `gpsLockStatus`).\n- Wire per-image captured lat/lng + timestamp through `MediaService.uploadMedia` (use `packageExifMetadata`) and into backend `POST /media/upload`, and have backend `create_media_record` write EXIF GPS via PIL (Pillow is a backend dep) so location is IN the image metadata by default.\n- Create the captured-media library (screen + Hive store + provider): captured images auto-save on capture even without publishing; support delete + multi-select/group delete; compose screen shows captured images in a separate section; a route to the media library.\n- Map refresh: after successful publish invalidate `mapPinsNotifierProvider` (already done in compose) AND add the same invalidation to the outbox flush path (that one line in outbox_screen.dart); ALSO ensure issue coordinates derive from captured GPS when available (so the new pin lands where the photo was taken).\n- `ComposeDraft.mediaBytes` → typed media list is a LARGE refactor; if it breaks many existing tests (drafts_page_test, compose_outbox_fuzz_shield_test, media_pipeline_extended_test, camera_viewfinder_test, location_service_test), PREFER an ADDITIVE approach (keep `mediaBytes` field, add new fields) to keep the suite green — the plan's intent is what matters. You MAY update existing tests you break.\n- If you add/modify freezed models, run `cd app && dart run build_runner build` and commit nothing (no git commit).\n- Backend: create the alembic migration and run `cd backend && uv run alembic upgrade head`. Run `uv run ruff check app && uv run mypy app` on your changed files. Do NOT commit.\n\n## VERIFY BEFORE FINISHING\n- `cd backend && uv run pytest tests/features/media tests/features/issues -q` passes (plus your feature area).\n- `cd app && flutter test test/features/compose test/features/outbox -q` passes (or the targeted subset). `flutter analyze lib` clean for your files.\n- `cd app && dart run build_runner build` if freezed changed.\n\nReport back: exact files changed (created/modified), deviations from the plan, and test results (counts). Do NOT write any spec docs.",
  "subagent_type": "coder"
}
```

**Output:**
```
<task id="ses_fead829d2fferkkFfjOOQRggw6" state="completed">
<task_result>

</task_result>
</task>
```

**Tool: task**

**Input:**
```json
{
  "description": "Implement F-B map/boundaries",
  "prompt": "You are the CODER for feature F-B (Map: auto-refresh, area-painting heatmap, ward boundary polygons).\n\nRead your plan first: `/Users/rohit/Desktop/Python/LocalLens/plans/F-B_map_heatmap_boundaries_plan.md` and implement it EXACTLY. Repo root: `/Users/rohit/Desktop/Python/LocalLens`. App: `app/` (Flutter, flutter_map ^8.1.1 + latlong2). Backend: `backend/` (FastAPI+SQLAlchemy async, feature-first).\n\n## FILE OWNERSHIP (STRICT — parallel agents are editing other files)\nYou MAY create/modify ONLY:\n- `app/lib/features/map/**`\n- `app/lib/features/geo/**` (frontend)\n- `backend/app/features/geo/**`\n- `backend/app/features/wards/models.py` (ONLY add the `boundary` Text column)\n- a new alembic migration under `backend/alembic/versions/` for the boundary column\n- `backend/seed.py` — ONLY ward seeding (`_seed_wards`, add `Ward` to `_TABLES`, `\"wards\"` to `_DATA_FILES`, `_report`) \n- `seed/data/wards.json` — NEW file: 2 wards with slugs EXACTLY `ward-45-urban-central` (center 19.1136,72.8697) and `ward-12-metro-corridor` (center 19.0760,72.8777), each with a `boundary` ring (the synthesized octagon rings from your plan §2.1). These slugs/names are a DEPENDENCY for another feature — do not rename.\n- existing tests you break in `backend/tests/features/geo/**`, `backend/tests/features/wards/**`, `app/test/features/map/**` — update ONLY if broken; preserve Keys.\n\nDo NOT touch: `backend/app/features/wards/schemas.py`, `wards/service.py`, `wards/router.py` (rep-metrics feature owns `AssignedRepresentativeOut`; keep `WardSummaryOut`/`WardDetailOut`/`WardListResponse` contract stable), `app/lib/features/ward/domain/ward_representative_out.dart`, `app/lib/features/ward/presentation/**`, `app/lib/features/ward/domain/**`, `app/lib/features/ward/data/**`, `app/lib/features/ward/presentation/providers/**`, `app/lib/features/compose/**`, `app/lib/features/search/**`, `app/lib/features/feed/**`, `app/lib/features/profile/**`, `app/lib/features/rep_dashboard/**`, `backend/app/features/representatives/**`, `backend/app/features/media/**`, `backend/app/features/issues/**`, `backend/app/features/auth/**`, `backend/app/main.py`, `docs/**`, `.sdd/**`, `logs/**`.\n\n## KEY GUIDANCE\n- Heatmap: replace the concentric `CircleLayer` rendering (map_screen.dart ~219-252) with area-painting density shading using `PolygonLayer` — grid cells filled with density-based color + interpolated opacity. Keep `MapState.heatmapCells` (adapt as needed) and `_heatmapColor` logic. Keep heatmap legend and filter Keys (`mapFilterChip_*`).\n- Ward boundaries: new endpoint `GET /api/v1/geo/ward-boundaries` (geo router) returning list of `{ward_slug, ward_name, ward_code, boundary: [[lat,lng],...]}`. Frontend fetches via a geo/map provider and renders `PolygonLayer` per ward in ward-map mode, REPLACING the circle+button. Degrade to a deterministic octagon fallback (per plan) when table empty/malformed.\n- Map refresh: implement debounced refetch on pan/zoom + periodic poll (30s) + app-resume refetch per plan; keep `searchThisAreaButton`, `mapPin_<id>`, `mapFilterChip_*` Keys working. The outbox-flush hook stays documented-only (do not touch outbox_screen.dart).\n- Internet sourcing of boundaries is OPTIONAL (Overpass) and MUST NOT block; the synthesized rings in the plan are authoritative.\n- Run `cd app && dart run build_runner build` only if freezed changed (unlikely here). Backend: `uv run alembic upgrade head` after adding the migration. Do NOT commit.\n\n## VERIFY BEFORE FINISHING\n- `cd backend && uv run pytest tests/features/geo tests/features/wards -q` passes.\n- `cd app && flutter test test/features/map -q` passes. `flutter analyze` clean for your files.\n- `cd backend && uv run ruff check app && uv run mypy app` for your changed files. Optionally verify `uv run python seed.py` creates 2 wards with boundary.\n\nReport back: exact files changed, deviations from plan, test results (counts). Do NOT write any spec docs.",
  "subagent_type": "coder"
}
```

**Output:**
```
<task id="ses_fead7f3d9ffeNU8rxTEyr8x9OQ" state="completed">
<task_result>
Everything is complete and verified. Here is my final report.

---

## F-B Implementation Report (Map: auto-refresh, area-painting heatmap, ward boundary polygons)

### Files changed (exactly my ownership scope)

**Backend**
| File | Change |
|---|---|
| `backend/app/features/wards/models.py` | Added `boundary: Mapped[str \| None] = mapped_column(Text, nullable=True)` to `Ward` |
| `backend/alembic/versions/c4d5e6f70819_add_ward_boundary.py` | **NEW** migration — `batch_alter_table('wards') → add_column('boundary', sa.Text(), nullable=True)`; `down_revision = b2c3d4e5f607` (verified head); downgrade drops it |
| `seed/data/wards.json` | **NEW** — 2 wards, slugs exactly `ward-45-urban-central` (19.1136, 72.8697) and `ward-12-metro-corridor` (19.0760, 72.8777), each with the plan §2.1 octagon ring |
| `backend/seed.py` | `Ward` in `_TABLES`, `"wards"` in `_DATA_FILES`, `_seed_wards` (dedup by slug, `boundary=json.dumps(...)`), `_report` + `_main` wiring |
| `backend/app/features/geo/schemas.py` | `WardBoundaryOut` (`ward_slug, name, code, boundary: list[list[float]]`) |
| `backend/app/features/geo/service.py` | `list_ward_boundaries(session)` (order by id, malformed→fallback), `parse_ward_boundary(raw)` (None/empty/non-JSON/<3 pts/out-of-range → None), `derived_boundary_ring(lat, lng)` (0.02° octagon, `0.02/cos(lat)` lng — same algorithm as frontend); also removed a pre-existing unused `AppError` import |
| `backend/app/features/geo/router.py` | `GET /geo/ward-boundaries` — rate-limited via `_check_rate_limit`, no auth, always 200 |

**Frontend**
| File | Change |
|---|---|
| `app/lib/features/map/data/map_api.dart` | `WardBoundary` model (`slug/name/code/ring`) + `MapApi.getWardBoundaries()` |
| `app/lib/features/map/presentation/controllers/map_controller.dart` | `HeatmapCell` → area cell; fixed-floor `heatmapCells`; 800 ms debounced `updateBounds`; `_fetching` guard in `fetchPins`; `refreshIfIdle()`; `wardBoundariesProvider`; timer cleanup in `dispose` |
| `app/lib/features/map/presentation/widgets/ward_boundary_layer.dart` | **NEW** `WardBoundaryLayer` + public static `derivedWardRing(lat, lng)` |
| `app/lib/features/map/presentation/screens/map_screen.dart` | `WidgetsBindingObserver` + 30 s poll timer + resume refetch; heatmap `PolygonLayer` area fill (all `CircleLayer`/`CircleMarker` heatmap code removed); ward `WardBoundaryLayer` replacing per-ward 48 px circle; `_heatmapOpacity` (0.18→0.68) replaces `_heatmapRadius`; legend + all preserved Keys (`mapPin_<id>`, `mapFilterChip_*`, `searchThisAreaButton`, `mapEmptyState`, `mapErrorRetryButton`, `wardMarker_<slug>`) intact |

**Docs**: `docs/2_tech_spec_issues.md` — **NEW** (see deviations).

### Deviations from plan (all documented, none silent)
1. **Heatmap rendering**: plan sketch shows one `PolygonLayer` with all cell polygons; I render one keyed `PolygonLayer` per cell (`heatmapCell_<latIdx>_<lngIdx>`). `flutter_map`'s `Polygon` has no `key` parameter, so per-cell layers are the only way to satisfy the plan's explicit key requirement (§3a/§3d). Verified example key `heatmapCell_6370_24289` matches the plan.
2. **Ward label**: `Polygon.label` is `String?` in flutter_map 8.3.1 (not `TextSpan`), so `label: ward.code` + `labelStyle`; used non-deprecated `labelPlacementCalculator: const PolygonLabelPlacementCalculator.centroid()` to keep `flutter analyze` clean.
3. **`seed/data/wards.json` shape**: bare JSON list (like all sibling data files) instead of the plan's `{"wards": [...]}` wrapper — matches `_load_data`/`_seed_wards` contract ("from each JSON row").
4. **`HeatmapCell`** stores floor indices and derives bounds (not vice-versa) — fixes a real floating-point key mismatch (`(6366·0.003)/0.003` floors to 6365).
5. **Migration infeasibility** (itemized in `docs/2_tech_spec_issues.md`): `alembic upgrade head` fails on a fresh DB because the alembic chain never created the `wards` table (pre-existing gap — only `otp_codes`/`users`/`issues` are migrated). I did **not** fix forward; the migration is exactly as specified. Dev DB (`backend/locallens.db`) had the column already via `create_all` → stamped to head (bookkeeping only).

### Verification results
- `cd backend && uv run pytest tests/features/geo -q` → **33 passed** (no `tests/features/wards` dir exists yet)
- `uv run ruff check app/features/geo app/features/wards` → clean; `uv run mypy app/features/geo app/features/wards` → clean
- `uv run python seed.py --db <temp>` → **2 wards** with 8-point boundary rings (verified via sqlite + `list_ward_boundaries`); endpoint smoke test → 200
- `cd app && flutter analyze lib/features/map lib/features/geo` → **No issues**
- `flutter test test/features/map` → **15 passed**
- Full `flutter test`: 307 passed / 4 failed — all 4 failures are compilation errors in parallel agents' files (`compose/**`, `issue_detail/**`, `offline_sync_onboarding_extended_test.dart`), unrelated to my changes

Not done (per plan): Overpass internet sourcing (optional — synthesized rings authoritative), `build_runner` (no freezed changes), outbox-flush hook (documented-only, compose untouched).
</task_result>
</task>
```

**Tool: task**

**Input:**
```json
{
  "description": "Implement F-C rep accountability",
  "prompt": "You are the CODER for feature F-C (Representative accountability: resolved/pending metrics, public rep profiles, dashboard display).\n\nRead your plan first: `/Users/rohit/Desktop/Python/LocalLens/plans/F-C_rep_accountability_plan.md` and implement it EXACTLY. Repo root: `/Users/rohit/Desktop/Python/LocalLens`. App: `app/` (Flutter, Riverpod+freezed). Backend: `backend/` (FastAPI+SQLAlchemy async).\n\n## FILE OWNERSHIP (STRICT — parallel agents are editing other files)\nYou MAY create/modify ONLY:\n- `backend/app/features/representatives/**`\n- `backend/app/features/wards/schemas.py` — ONLY `AssignedRepresentativeOut` (extend with `id`, `user_id`, `ward`, metrics) \n- `backend/app/features/wards/service.py` — ONLY the `assigned_representative` construction inside `get_ward_detail` (populate the extended fields via your metrics computation)\n- `backend/app/features/auth/**` — ONLY additive public-rep-profile support if your plan requires it\n- `seed/data/users.json` — set user id 2 `role` to `\"representative\"`\n- `seed/data/official_responses.json` — add a row for a resolved ward issue (per plan) so demo metrics are non-zero\n- `app/lib/features/rep_dashboard/**`\n- `app/lib/features/ward/domain/ward_representative_out.dart` — ADDITIVE fields only (`id`, `userId`, `ward`, plus metrics if needed), defaulted so existing constructors/parsing compile\n- `app/lib/features/ward/presentation/widgets/ward_rep_card.dart` — show resolved/pending/response-rate performance + navigate to the rep public profile\n- `app/lib/features/profile/domain/public_user_profile.dart` — additive rep-metrics fields\n- `app/lib/features/profile/presentation/screens/public_profile_screen.dart` — rep performance section when the profile is a representative\n- existing tests you break in `backend/tests/features/representatives/**`, `app/test/features/rep_dashboard/**`, `app/test/features/profile/public_profile_parsing_and_anonymity_test.dart`, `app/test/features/ward/ward_detail_screen_test.dart` — update ONLY if broken; preserve Keys\n\nDo NOT touch: `backend/seed.py` (ward seeding owned by another agent — your seed data edits above are DATA ONLY and need no seed.py change; `seed.py` already passes `role` and `official_responses`), `backend/app/features/wards/models.py`, `wards/router.py` (keep GET /wards/{slug} signature), `app/lib/features/ward/presentation/screens/ward_detail_screen.dart`, `app/lib/features/ward/presentation/providers/**`, `app/lib/features/ward/data/**`, `app/lib/features/ward/domain/ward_detail_out.dart`, `app/lib/features/profile/presentation/profile_providers.dart`, `app/lib/features/profile/domain/user_profile.dart`, `app/lib/features/profile/presentation/screens/profile_screen.dart`, `app/lib/features/map/**`, `app/lib/features/geo/**`, `app/lib/features/compose/**`, `app/lib/features/search/**`, `app/lib/features/feed/**`, `backend/app/features/media/**`, `backend/app/features/geo/**`, `backend/app/features/issues/**`, `docs/**`, `.sdd/**`, `logs/**`.\n\n## KEY GUIDANCE\n- New PUBLIC endpoint: `GET /api/v1/representatives/by-user/{user_id}` (auth-optional, no auth required) returning the rep's public performance profile (id, user_id, official_name, title, ward, total/escalated/responded/pending/resolved counts, response_rate_pct, avg response time if computed). Metrics must be computed in Python (portable across SQLite/Postgres).\n- Extend `GET /representatives/me` (RepresentativeProfileOut) with resolved/pending/acknowledged/in_progress aggregates.\n- Frontend: `publicRepProfileProvider` (family by userId) lives in `app/lib/features/rep_dashboard/presentation/rep_dashboard_providers.dart` so BOTH `public_profile_screen.dart` and `ward_rep_card.dart` can watch it. Dashboard: add Resolved/Pending/Response-rate metric cards (new Keys, e.g. `metricResolvedWardIssues`, `metricPendingResolvedWardIssues`) and display `respondedWardIssues`. Preserve existing Keys (`repProfileName`, `repProfileWard`, `metricTotalWardIssues`, `metricEscalatedWardIssues`, `metricPendingResponseWardIssues`, `wardFilterChip_*`, `respondToIssueButton_<id>`).\n- `ward_rep_card.dart`: show the metrics and make its tap navigate to `/users/{userId}` (RoutePaths.publicProfile exists).\n- Seed data only: update `seed/data/users.json` + `seed/data/official_responses.json`. Verify `cd backend && uv run python seed.py` runs.\n- Run `cd app && dart run build_runner build` if freezed changed. Do NOT commit.\n\n## VERIFY BEFORE FINISHING\n- `cd backend && uv run pytest tests/features/representatives tests/features/issues/test_ward_place_page.py -q` passes (update test_ward_place_page only if the schema extension breaks it).\n- `cd app && flutter test test/features/rep_dashboard test/features/ward/ward_detail_screen_test.dart test/features/profile/public_profile_parsing_and_anonymity_test.dart -q` passes. `flutter analyze` clean.\n- `cd backend && uv run ruff check app && uv run mypy app` clean.\n\nReport back: exact files changed, deviations, test results. Do NOT write spec docs.",
  "subagent_type": "coder"
}
```

**Output:**
```
<task id="ses_fead7ccbfffe46ogE4VtgbL0sS" state="completed">
<task_result>

</task_result>
</task>
```

**Tool: task**

**Input:**
```json
{
  "description": "Implement F-D ward details",
  "prompt": "You are the CODER for feature F-D (Ward details page: complete civic page + reachability).\n\nRead your plan first: `/Users/rohit/Desktop/Python/LocalLens/plans/F-D_ward_details_plan.md` and implement it, APPLYING THE CONFLICT RESOLUTIONS below (they override the plan where they conflict).\n\nRepo root: `/Users/rohit/Desktop/Python/LocalLens`. App: `app/` (Flutter, Riverpod+freezed, flutter_map available). Backend: `backend/`.\n\n## CRITICAL OWNERSHIP OVERRIDES (parallel agents own these files — DO NOT create/modify them)\n- Do NOT touch `backend/app/features/wards/schemas.py`, `wards/service.py`, `wards/router.py`, `wards/models.py` (the rep-metrics agent extends `AssignedRepresentativeOut`; the map agent adds the `boundary` column). \n- Do NOT touch `backend/seed.py`, `seed/data/wards.json`, and do NOT create `backend/app/features/wards/seed.py` (the map agent owns ward seeding; it seeds wards with slugs `ward-45-urban-central` and `ward-12-metro-corridor`).\n- Do NOT touch `app/lib/features/ward/domain/ward_representative_out.dart` and `app/lib/features/ward/presentation/widgets/ward_rep_card.dart` (rep-accountability agent owns them; they will expose `id`, `userId`, `ward`, and performance metrics).\n- Do NOT touch `app/lib/features/map/**`, `app/lib/features/geo/**`, `app/lib/features/feed/**` (feed/map screens are other agents' files — reachability wiring into them is OUT of scope; instead make your own `ward_chip.dart` navigate).\n\n## WHAT YOU MAY create/modify\n- `app/lib/features/ward/presentation/screens/ward_detail_screen.dart` — complete the page: hero, metrics grid, representative section (use `WardRepCard` as-is; wire its presence to the assigned_representative in WardDetailOut), recent issues list with search + filter tabs, and a boundary mini-map (see below)\n- `app/lib/features/ward/presentation/widgets/ward_hero_banner.dart`, `ward_metric_card.dart`, `ward_recent_issues_list.dart` (wire it in — it is currently unused), `ward_chip.dart`, `local_talk_compose_sheet.dart`\n- `app/lib/features/ward/domain/ward_detail_out.dart`, `ward_summary_out.dart`, `ward_list_response.dart`, `local_talk_post.dart` (additive only if needed)\n- `app/lib/features/ward/data/repositories/ward_repository.dart`\n- `app/lib/features/ward/presentation/providers/ward_providers.dart` — add a `wardBoundaryProvider` (family by slug) that calls `GET /api/v1/geo/ward-boundaries` (the map agent is adding this endpoint). Also expose a `WardBoundaryMiniMap` widget (new file under `app/lib/features/ward/presentation/widgets/`) using flutter_map TileLayer + the boundary PolygonLayer + center marker, with a graceful \"Boundary coming soon\" fallback when no boundary data exists.\n- existing tests you break in `app/test/features/ward/**` — update ONLY if broken; preserve Keys (`wardDetailScreen`, `wardDetailBackButton`, `wardIssueSearchField`, `wardMetricTotal`, `wardMetricActive`, `wardMetricEscalated`, `wardMetricResolved`, `wardMetricResolutionRate`, `wardRecentIssuesList`, `wardRepCard`).\n\nDo NOT touch anything else: `backend/**` entirely (no backend changes for F-D), `app/lib/features/compose/**`, `search/**`, `profile/**`, `rep_dashboard/**`, `app/lib/features/ward/domain/ward_representative_out.dart`, `docs/**`, `.sdd/**`, `logs/**`.\n\n## KEY GUIDANCE\n- Code against the extended `AssignedRepresentativeOut` contract (will have `id`, `user_id`, `ward` + metrics `total_ward_issues`/`resolved_ward_issues`/`pending_*` etc.) — parse defensively (treat the metrics as optional in your Dart model if you add one; WardRepCard handles rendering).\n- Reachability: ensure `ward_chip.dart` navigates to `/ward/:slug` (route already registered). Do NOT edit feed/map screens to add entries.\n- Preserve all existing behavior and Keys; the page must still work when the wards table is empty (fallback states) and when `assignedRepresentative` is null (\"No representative assigned yet\").\n- Run `cd app && dart run build_runner build` if freezed changed. Do NOT commit.\n\n## VERIFY BEFORE FINISHING\n- `cd app && flutter test test/features/ward -q` passes. `flutter analyze` clean for your files.\n\nReport back: exact files changed, deviations, test results. Do NOT write spec docs.",
  "subagent_type": "coder"
}
```

**Output:**
```
<task id="ses_fead763b9fferMO6vcJjQ6Igmx" state="completed">
<task_result>
Everything is verified and complete. Here's the final report:

## F-D Implementation Complete

### Files changed (all within allowed scope)
| File | Change |
|---|---|
| `app/lib/features/ward/presentation/screens/ward_detail_screen.dart` | Rewritten: hero → metrics grid → rep section → boundary mini-map → search + filter tabs → issues list → nearby-wards reachability section |
| `app/lib/features/ward/presentation/widgets/ward_boundary_mini_map.dart` | **New** `WardBoundaryMiniMap` (flutter_map, OSM tiles, polygon overlay, center marker, fallback pill) |
| `app/lib/features/ward/presentation/providers/ward_providers.dart` | Added `wardBoundaryProvider` (family by slug) → `GET /api/v1/geo/ward-boundaries`, defensive `[]` fallback |
| `app/lib/features/ward/presentation/widgets/ward_hero_banner.dart` | Added top-category chips, "Updated …" caption, "View Map" → `RoutePaths.map` |
| `app/lib/features/ward/presentation/widgets/ward_recent_issues_list.dart` | Added `showHeader`/`emptyMessage` params; now wired into the screen |

### Keys
Preserved: `wardDetailScreen`, `wardDetailBackButton`, `wardIssueSearchField`, `wardMetricTotal/Active/Escalated/Resolved/ResolutionRate`, `wardRecentIssuesList`, `wardRepCard`. Added per plan: `wardRepSectionHeader`, `wardNoRepPlaceholder`, `wardBoundaryMiniMap`, `wardBoundaryCenterMarker`, `wardBoundaryFallback`, `wardTopCategoryChip_<cat>`, `wardHeroViewMapButton`, `wardNearbyWardsSection`, `wardChip_<slug>`.

### Deviations from plan (all conflict-resolution driven)
1. **No `WardRepPerformanceStrip`** — dropped by conflict resolution; F-C's `WardRepCard` renders metrics itself (keys `wardRepResolvedMetric`/`wardRepPendingMetric`/`wardRepResponseRateMetric`).
2. **Rep section header text is "Ward Representatives"** (existing plural) instead of the plan's "Ward Representative" — required to keep FE-WARD-04 (`find.text('Ward Representative')` findsOneWidget) passing.
3. **`rep.userId > 0` guard** instead of `userId != null` — F-C landed `userId` as non-nullable `int` (default 0); `onTap` pushes `/users/:id` only when > 0, else null (chevron auto-hides).
4. **No backend work** — conflict resolution forbids `backend/**`; the boundary endpoint is the map agent's responsibility (my provider degrades gracefully if absent).
5. **No domain changes** — F-C's tolerant `WardRepresentativeOut.fromJson` (all new fields defaulted) means old cached JSON still parses.

### Verification
- `flutter test test/features/ward` → **11/11 pass** (FE-WARD-01..11)
- `flutter analyze` → 3 pre-existing info-level issues only (`tool/live_auth_smoke.dart` prints, not mine); `flutter analyze lib/features/ward` → **No issues found!**
- Full suite: 327 pass / 1 fail — the failure is `test/features/search/search_screen_test.dart` ("Search unavailable" text), caused by the **search agent's own in-flight rework** (they modified `search_screen.dart`, added `search_error_kind.dart`, and modified that test file themselves). Search has zero imports from ward, so it's unrelated to my changes — left untouched per ownership boundaries.
- `git status` confirms I only touched the 5 ward files above (the other modified files — `ward_representative_out.dart`, `ward_rep_card.dart`, `ward_detail_screen_test.dart` — are the F-C agent's concurrent changes, not mine).

No commit made, per instructions.
</task_result>
</task>
```

**Tool: task**

**Input:**
```json
{
  "description": "Implement F-E search fix",
  "prompt": "You are the CODER for feature F-E (Search: fix \"Search unavailable\" — configurable base URL + differentiated error UX + robust parsing).\n\nRead your plan first: `/Users/rohit/Desktop/Python/LocalLens/plans/F-E_search_fix_plan.md` and implement it EXACTLY. Repo root: `/Users/rohit/Desktop/Python/LocalLens`. App: `app/` (Flutter). Backend: `backend/` (FastAPI).\n\n## FILE OWNERSHIP (STRICT)\nYou MAY create/modify ONLY:\n- `app/lib/features/search/**`\n- `app/lib/core/config/app_config.dart`, `app/lib/core/config/app_config_provider.dart`\n- `app/lib/core/network/api_exceptions.dart` (add `ApiParseException` if the plan calls for it), `app/lib/core/network/api_client.dart` (only if needed)\n- `app/ios/Runner/Info.plist` (ATS NSAllowsLocalNetworking if needed)\n- `app/macos/Runner/*.entitlements` (network.client if needed) and `app/macos/Runner/DebugProfile.entitlements`/`Release.entitlements`\n- `backend/app/features/search/**` (only if needed; contract is already aligned)\n- existing tests you break in `app/test/features/search/**`, `backend/tests/features/search/**` — update ONLY if broken; preserve Keys and the existing contract tests (e.g. 'Search unavailable' title on network error, Retry re-runs).\n\nDo NOT touch: `app/lib/features/compose/**`, `map/**`, `feed/**`, `profile/**`, `ward/**`, `rep_dashboard/**`, `geo/**`, `backend/app/features/media/**`, `geo/**`, `wards/**`, `representatives/**`, `issues/**`, `auth/**`, `docs/**`, `.sdd/**`, `logs/**`.\n\n## KEY GUIDANCE\n- Base URL: `String.fromEnvironment('API_BASE_URL')` override; smart default per platform — Android → `http://10.0.2.2:8000/api/v1` (emulator) else `http://127.0.0.1:8000/api/v1`. Keep `AppConfig.dev` structure but make it configurable; keep existing tests (they construct AppConfig/dev directly) compiling.\n- Differentiated errors: add a `SearchErrorKind` enum (`network`, `rateLimited`, `validation`, `server`, `unauthorized`, `parse`) + a classifier mapping exceptions (ApiNetworkException, ApiServerException with statusCode 429/422/5xx/401, ApiParseException). `SearchResultsNotifier` must expose the error kind (e.g. an `AsyncValue` state extension or a separate provider). `_buildResultsBody` renders distinct EmptyState copy per kind — KEEP title 'Search unavailable' + Retry for network kind; add distinct titles/messages for others (e.g. 429 → rate-limit message, 5xx → server message). Keep `_retryLastQuery` behavior and Keys.\n- Guard the `data as List<dynamic>` parse in `search_api.dart` with a typed catch → ApiParseException.\n- Ensure empty-query never hits the API; keep debounce behavior.\n- Verify the ward-filter WIP (frontend + backend) is fully wired and add nothing that breaks it.\n- Do NOT commit.\n\n## VERIFY BEFORE FINISHING\n- `cd app && flutter test test/features/search -q` passes. `flutter analyze` clean for your files.\n- `cd backend && uv run pytest tests/features/search -q` passes. `uv run ruff check app && uv run mypy app` clean (if you touched backend).\n- If the backend is reachable (`curl -s http://127.0.0.1:8000/api/v1/search?q=road`), do a live sanity check; if not reachable, note it.\n\nReport back: exact files changed, deviations, test results. Do NOT write spec docs.",
  "subagent_type": "coder"
}
```

**Output:**
```
<task id="ses_fead74508ffew24M1j2r4jmE7c" state="completed">
<task_result>
All verification complete. Here is my report.

## F-E Implementation Report

### Files changed (implementation, all under `app/lib/**`)
| File | Change |
|---|---|
| `app/lib/core/config/app_config.dart` | Configurable base URL: `String.fromEnvironment('API_BASE_URL')` compile-time override; per-platform default host (Android non-web → `10.0.2.2`, else `127.0.0.1`); `resolveApiBaseUrl([String? override])` with the plan's §4.2(c) test seam; `AppConfig.dev` now a getter — all existing callers (`app_config_provider`, `media_url`, `media_service`) keep compiling unchanged. |
| `app/lib/core/network/api_exceptions.dart` | Added `class ApiParseException extends ApiException` (server responded but body wasn't a parseable `Issue` list). |
| `app/lib/features/search/domain/search_error_kind.dart` | **NEW** — `enum SearchErrorKind { network, rateLimited, invalidQuery, server, unauthorized, unexpected }` + pure `classifySearchError` (network / unauthorized / 429→rateLimited / 422→invalidQuery / 5xx-other→server / else→unexpected). |
| `app/lib/features/search/data/search_api.dart` | Guarded parse: non-`List` body → `ApiParseException('Search response was not a list: ...')`; per-item `Issue.fromJson` wrapped in `on Object catch` → `ApiParseException`. Query param mapping unchanged (`ward` null-aware element kept). |
| `app/lib/features/search/presentation/search_screen.dart` | `.when(error:)` now routes through `classifySearchError` → `_buildSearchErrorState`, rendering 6 distinct `EmptyState`s with exact §3.3 copy/icons. All keep `actionLabel: 'Retry'` → `_retryLastQuery` (network kind keeps title `'Search unavailable'`). Keys untouched; empty/loading branches unchanged. |

### Platform/test items from the plan — MECHANICALLY BLOCKED (documented, not bypassed)
The coder agent's enforced permission table allows edits **only** to `backend/app/**`, `app/lib/**`, `docs/2_tech_spec_issues.md`. Attempts to edit the following were denied by the harness, and per AGENTS.md I did not bypass via bash. Full itemization is in the new `docs/2_tech_spec_issues.md`:
1. **`app/ios/Runner/Info.plist`** — ATS `NSAllowsLocalNetworking` (plan §2b). Without it, physical iOS devices still fail cleartext HTTP → `ApiNetworkException` → "Search unavailable".
2. **`app/macos/Runner/DebugProfile.entitlements` + `Release.entitlements`** — `com.apple.security.network.client` (plan §1.2/§1.4/§2a). macOS sandbox still blocks all outbound network.
3. **`app/test/features/search/search_screen_test.dart`** — the existing `'error shows Search unavailable and Retry re-runs'` test now fails (34/35 pass) because it seeds `StateError('offline')`, which correctly classifies as `unexpected` → "Something went wrong". Plan §4.2 prescribes changing it to `throw ApiNetworkException('offline')` (preserves the "Search unavailable on network error + Retry re-runs" contract) — this must land via the Test Engineer or an explicit grant.
4. **All plan §4.1/§4.2 test-only items** (ward param assertion, harness overrides, ward-length 422 backend test, app_config_test) — Test Engineer territory.
5. **README §Quickstart** run instructions (plan §2a) — doc outside coder scope.

### Deviations (deliberate, to keep `flutter analyze` clean)
- Plan §1.2's `search_providers.dart` "import `search_error_kind.dart`" was **not** applied: the plan's own final design (§3.2) puts `classifySearchError` at the UI boundary (in `search_screen.dart`); importing it in `search_providers.dart` would be an unused import → analyzer failure. Error-kind exposure is implemented exactly per §3.2.

### Verification results
- `flutter analyze` → clean for my files (only 3 pre-existing `info`-level `avoid_print` in `tool/live_auth_smoke.dart`, untouched).
- `flutter test test/features/search` → **34 passed / 1 failed** (the §1.3 test awaiting the Test Engineer's prescribed `ApiNetworkException` update).
- `flutter test test/core` → 60 passed (no regression from the `core/config` change).
- `cd backend && uv run pytest tests/features/search -q` → **48 passed** (backend untouched; ward-filter WIP already aligned — I verified the router/service, made no changes).
- Live sanity check (backend IS reachable at `127.0.0.1:8000`): `q=road` → **200 JSON list**; whitespace `q` → **422 `empty_query`**; 101-char `q` → **422 `query_too_long`** — all consistent with the app-side classifier (422 → "Adjust your search").
- No commit or push made.
</task_result>
</task>
```

**Tool: task**

**Input:**
```json
{
  "description": "Implement F-F feed UI",
  "prompt": "You are the CODER for feature F-F (Feed/Issues page UI redesign: cleaner, more attractive, less cluttered). FRONTEND-ONLY.\n\nRead your plan first: `/Users/rohit/Desktop/Python/LocalLens/plans/F-F_feed_ui_plan.md` and implement it EXACTLY. Repo root: `/Users/rohit/Desktop/Python/LocalLens`. App: `app/` (Flutter, Material 3, Riverpod).\n\n## FILE OWNERSHIP (STRICT)\nYou MAY create/modify ONLY:\n- `app/lib/features/feed/presentation/**` (feed_screen.dart, issue_card.dart, win_card.dart, notice_card.dart, local_talk_card.dart, media_preview_widget.dart, and NEW widgets per plan: FeedSkeletonList, FeedEmptyState)\n- `app/lib/shared/widgets/**` ONLY if strictly needed and strictly backward-compatible (shared/status_badge.dart, shared/empty_state.dart etc.) — other features' tests depend on them, so prefer additive changes\n- existing tests you break in `app/test/features/feed/**` — update ONLY if broken\n\nDo NOT touch: `app/lib/features/feed/domain/**` (unless the plan explicitly needs a presentation-only change — prefer not), `app/lib/features/compose/**`, `search/**`, `map/**`, `profile/**`, `ward/**`, `rep_dashboard/**`, `issue_detail/**`, `geo/**`, `backend/**` (NO backend changes), `app/lib/core/l10n/**` (unless plan says; prefer inline strings that match existing), `docs/**`, `.sdd/**`, `logs/**`.\n\n## KEY GUIDANCE\n- There is UNCOMMITTED WIP in issue_card.dart, feed_screen.dart, status_badge.dart, feed_api.dart, feed_repository.dart, media_preview_widget.dart — run `cd app && git diff` on those to see it and build ON TOP of it (do not revert it).\n- The redesign must REDUCE clutter: header meta line, one subtle status row, clean media area, single footer action row — per your plan. \n- CRITICAL: preserve EVERY existing functional behavior and test hook: `issueCard_<id>`, `issueCardOverflow_<id>`, `flagIssueOption_<id>`, upvote buttons/counters, comment buttons, share, media carousel + watermark, relative time, status badge, escalation hints, filter chips `feedFilterChip_*`, pull-to-refresh, skeleton, empty states, navigation to detail, deep-link share. Read `app/test/features/feed/*` tests FIRST so you know exactly what they assert, and keep them green (per plan, zero edits may be needed).\n- Add the new structural Keys the plan specifies (`issueHeaderMeta_<id>`, `issueStatusRow_<id>`, `issueActions_<id>`, FeedSkeletonList/FeedEmptyState as applicable).\n- Do NOT commit.\n\n## VERIFY BEFORE FINISHING\n- `cd app && flutter test test/features/feed -q` passes (all feed tests).\n- `flutter analyze` clean for your files.\n\nReport back: exact files changed, deviations, test results. Do NOT write spec docs.",
  "subagent_type": "coder"
}
```

**Output:**
```
<task id="ses_fead727f6fferSCUlo2vI0fYL2" state="completed">
<task_result>
All verification complete. Here's my final report.

## F-F Feed/Issues Page UI Redesign — Implementation Report

### Files changed (exactly per plan)

**Created (2):**
- `app/lib/features/feed/presentation/widgets/feed_skeleton_list.dart` — new `FeedSkeletonList` (shimmer skeleton matching the NEW card geometry: header row → title bar → status bar → media block; radius 16, `lightSurface`/`darkCard`, 1px border). Replaces `SkeletonList` in the feed only.
- `app/lib/features/feed/presentation/widgets/feed_empty_state.dart` — new `FeedEmptyState` (decorative icon-ring, optional action). Used for both feed-empty and feed-error bodies; renders the exact existing l10n strings passed in.

**Modified (5):**
- `issue_card.dart` — full §2.1 redesign: header (avatar 36 + reporter label + `issueHeaderMeta_<id>` row with standalone category/ward/time `Text`s), one subtle `issueStatusRow_<id>` (StatusBadge + plain inline ESCALATING/VERIFY hint, no background box), 2-line title, 2-line `_ExpandableDescription`, media `maxHeight: 180`, meta chips, single `issueActions_<id>` footer row (no Divider, `_SocialAction` minHeight 44→40, 4px gaps). Card: radius 16, elevation 0, `lightSurface`/`darkCard`, `Clip.antiAlias`. Removed the now-unused `_StatusHint`. All keys preserved verbatim (`issueCard_<id>`, `issueCardReporter_<id>`, `issueCardOverflow_<id>`, `flagIssueOption_<id>`, `issueMedia_<id>`, `upvote_button_<id>`, `comment_button_<id>`, `share_button_<id>`).
- `win_card.dart` — gallery 220→200, surface unified to `darkCard` (was `darkSurface`), swipe hint de-emphasized (fontSize 11, onSurfaceVariant icon).
- `notice_card.dart` — valid-pill `verified 0.12`→`0.08`, icon 12→11, unified surface + `Clip.antiAlias`.
- `local_talk_card.dart` — unified surface + `Clip.antiAlias`, bottom row spacing 12→10, media already 180. No share/overflow icon added.
- `feed_screen.dart` — AppBar bottom 90→84, ward→chips gap 8→4, list padding `fromLTRB(16,8,16,24)` + 16px separators, loading via `FeedSkeletonList(key: feedSkeleton)`, error via `FeedEmptyState` (Retry→refresh preserved), empty via `FeedEmptyState(key: feedEmptyState)` inside `AlwaysScrollableScrollPhysics` ListView, end-of-feed vertical padding 32. `feedAreaLabel`, filter chips, `feedNotificationButton` (WIP) all preserved.

### WIP preserved
Built on top of the uncommitted WIP in `issue_card.dart` (humanized category, always-on reporter tap), `status_badge.dart`, `feed_api.dart`, `feed_repository.dart`, and `feed_screen.dart` (notification button) — none reverted. `media_preview_widget.dart` untouched.

### Test results
- `flutter test test/features/feed` → **47/47 passed** (issue_card, upvote_interaction, multi_feed_talk_extended, reporter_navigation, feed_screen, media_display_and_like_toggle, upvote_toggle_core, issue).
- Cross-cutting: `geo_screen_integration_test`, `dock_and_notifications_header_test`, `shimmer_loading_test`, `offline_sync_onboarding_extended_test`, `profile_posts_and_public_profile_test`, `deep_linking_test`, `flagging_widget_test` → all pass.
- `flutter analyze` → clean for all my files (only 3 pre-existing `avoid_print` infos in `tool/live_auth_smoke.dart`, not mine).

### Deviations
- **None from the plan.** One note: `test/features/search/search_screen_test.dart` "error shows Search unavailable and Retry re-runs" fails, but I verified it is **pre-existing** (it fails identically with all my changes stashed) and it exercises `SearchScreen`, which is outside my ownership — not caused by this work.
</task_result>
</task>
```

**Tool: task**

**Input:**
```json
{
  "description": "Implement F-G profile redesign",
  "prompt": "You are the CODER for feature F-G (Own Profile page redesign: cleaner view, show role + ward, rep entry).\n\nRead your plan first: `/Users/rohit/Desktop/Python/LocalLens/plans/F-G_profile_redesign_plan.md` and implement it EXACTLY. Repo root: `/Users/rohit/Desktop/Python/LocalLens`. App: `app/` (Flutter, Material 3, Riverpod). Backend: `backend/` — your plan should require NO backend change (UserOut already returns role/ward).\n\n## FILE OWNERSHIP (STRICT)\nYou MAY create/modify ONLY:\n- `app/lib/features/profile/presentation/screens/profile_screen.dart`\n- `app/lib/features/profile/presentation/profile_providers.dart` (only if additive/needed for UserProfile parsing)\n- `app/lib/features/profile/domain/user_profile.dart` (add `role` + `ward` optional fields + `isRepresentative` getter; it is a plain class per plan — no build_runner needed)\n- `app/lib/features/profile/presentation/widgets/**` — including a NEW `profile_role_badge.dart` widget\n- `app/lib/features/profile/domain/user_settings.dart` (only if needed)\n- `app/lib/core/router/app_router.dart` + `app/lib/core/router/route_paths.dart` ONLY if an additive profile route is required (the rep dashboard route `/rep-dashboard` ALREADY exists — you likely only push it, no router edit)\n- existing tests you break in `app/test/features/profile/**` — update ONLY if broken; preserve Keys\n\nDo NOT touch: `app/lib/features/profile/presentation/screens/public_profile_screen.dart`, `app/lib/features/profile/domain/public_user_profile.dart` (rep-accountability agent owns public profile rep metrics), `app/lib/features/profile/presentation/screens/settings_screen.dart`, `edit_profile_screen.dart`, `anonymity_guide_screen.dart` (per plan, untouched), `app/lib/features/rep_dashboard/**`, `ward/**`, `map/**`, `compose/**`, `search/**`, `feed/**`, `geo/**`, `backend/**` (NO backend changes), `docs/**`, `.sdd/**`, `logs/**`.\n\n## KEY GUIDANCE\n- There is UNCOMMITTED WIP in profile_providers.dart, public_user_profile.dart, public_profile_screen.dart, settings_screen.dart — run `cd app && git diff` on those; do not revert them.\n- Redesign ProfileScreen: clean header/identity (keep avatar `editProfilePhotoButton`, identity label, `profileIdentityToggle`, bio editor Keys), add role pill + ward chip from the new `UserProfile.role/ward`, activity stats, organized sections for Outbox/Drafts/My-Reported-Issues (keep `viewOutboxButton`, `profileDraftsButton`, `myIssuesFilter_all/active/resolved`, `userIssueItem_<id>`, `deleteIssue_<id>`, `openSettingsButton`), better empty states, less clutter.\n- Rep display: if `isRepresentative` → show `ProfileRoleBadge` + ward chip + a `repDashboardEntryButton` card that pushes the EXISTING `/rep-dashboard` route. Detection: `role.toLowerCase().contains('representative')`. Do NOT build rep metrics here.\n- Keep the guest banner behavior for guests.\n- Do NOT commit.\n\n## VERIFY BEFORE FINISHING\n- `cd app && flutter test test/features/profile -q` passes (all profile tests).\n- `flutter analyze` clean for your files.\n\nReport back: exact files changed, deviations, test results. Do NOT write spec docs.",
  "subagent_type": "coder"
}
```

**Output:**
```
<task id="ses_fead70df8ffeMTTAX1e3BkXC1v" state="completed">
<task_result>
All changes are complete and verified. Here's my report:

## Files changed (4 files, 1 new)

1. **`app/lib/features/profile/domain/user_profile.dart`** — Added `role` (`String`, default `'citizen'`), `ward` (`String?`, default `null`), the `isRepresentative` getter (`role.toLowerCase().contains('representative')`), and fallback-safe parsing of both in `fromJson`. Plain hand-written class — no build_runner. All existing direct-constructor fixtures compile unchanged (new params optional).

2. **`app/lib/features/profile/presentation/profile_providers.dart`** — Additive only: mock `'Demo Resident'` profile now carries `role: 'citizen'`, `ward: 'Ward 45, Urban Central'`; the guest fallback carries `role: 'guest'`, `ward: null` (mock guest branch too). The uncommitted `resetToDefaults()` WIP was left untouched.

3. **`app/lib/features/profile/presentation/screens/profile_screen.dart`** — Layout reorganized per plan §2.2:
   - Identity header preserved (photo left, `editProfilePhotoButton`, `ProfileAvatar`, `editNameButton`, verified icon, bio editor, anon-id chip, `profileIdentityToggle`).
   - New meta row directly below the name row (above bio): `ProfileRoleBadge` (key `profileRoleBadge`) + ward `Chip` (key `profileWardChip`, `surfaceContainerHigh`, hidden when ward null/empty). Both hidden for guests.
   - Rep-only dashboard entry card (key `repDashboardEntryButton`) under the header: tonal `how_to_reg` circle in `primaryContainer`, title `Representative Dashboard`, subtitle `ward ?? 'Your ward'`, chevron, `context.push(RoutePaths.repDashboard)`. No rep metrics built.
   - Guest banner unchanged; stats card gained key `profileStatsCard`.
   - "Offline Outbox & Drafts" section replaced with **"Your Activity"** header + ONE card containing two `ListTile`s (`profileDraftsButton` → Drafts with `'$count saved'`/`'No drafts yet'`; `viewOutboxButton` → `Offline Outbox` with `'Pending Outbox Items: $n'` + `profile_outbox_queued`/`profile_outbox_synced` tr lines) separated by `Divider(height: 1)`.
   - "My Reported Issues & Activity" section, filter chips, `userIssueItem_<id>`/`deleteIssue_<id>`, ACTIVE/RESOLVED overlays, guest prompt, error card, empty-filter state — all preserved.

4. **`app/lib/features/profile/presentation/widgets/profile_role_badge.dart`** (NEW) — Public reusable pill mirroring `_RoleBadge` in `public_profile_screen.dart:537` (12% alpha fill, 30% border; rep → `AppColors.brand` + `how_to_reg_rounded`, official → indigo + `account_balance_rounded`, default → primary + `person_rounded`). Displays the role title-cased (`'citizen'` → `'Citizen'`, `'ward_official'` → `'Ward Official'`) so the §4 test contract "renders `profileRoleBadge` with text `Citizen`" holds.

## Deviations
- None material. Minor: this Flutter version rejects `-q` on `flutter test`, so I ran without it (same suite).
- `ProfileRoleBadge` title-cases the raw role for display only; the model keeps the raw string.

## Verification
- `flutter test test/features/profile` → **41/41 passed** (all 6 profile suites).
- `flutter analyze` → **clean for my files** (only pre-existing `avoid_print` infos in `tool/live_auth_smoke.dart`).
- Adjacent suites `gamification_test.dart` + `compose_outbox_fuzz_shield_test.dart` → passed (no cross-feature breakage).

No backend, router, docs, or forbidden-file changes. Nothing committed.
</task_result>
</task>
```

---

## Assistant (Build · DeepSeek V4 Flash Free · 55.9s)

---

## User

complete the task

---

## User

complete the task

---

## Assistant (Build · Gemini 3.7 Flash · 0.8s)

---

