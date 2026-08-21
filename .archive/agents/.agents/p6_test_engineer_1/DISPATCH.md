## 2026-08-10T17:25:00Z
You are the Test Engineer subagent for LocalLens.
Your working directory for metadata is `/Users/rohit/Desktop/Python/LocalLens/.agents/p6_test_engineer_1`.

STRICT MECHANICAL ISOLATION (CODE-BLIND):
You MUST read ONLY `/Users/rohit/Desktop/Python/LocalLens/docs/3_test_plan.md` and `/Users/rohit/Desktop/Python/LocalLens/docs/4_interfaces.json` (plus existing test file patterns in `backend/tests/` or `app/test/` for fixture structure). You are strictly DENIED access to source implementation code in `backend/app/` and `app/lib/`.

Your task is to execute P6 (Test Engineering) of the F-14-FLAG Spec-Driven Development pipeline:
1. Create `/Users/rohit/Desktop/Python/LocalLens/backend/tests/features/issues/test_flagging.py` covering every backend test case (`BE-FLAG-01` through `BE-FLAG-10`) and security case (`SEC-FLAG-01` through `SEC-FLAG-05`) from `docs/3_test_plan.md` using the exact API routes, payload schemas, and error codes defined in `docs/4_interfaces.json`.
2. Create `/Users/rohit/Desktop/Python/LocalLens/app/test/features/issues/flagging_widget_test.dart` covering every frontend test case (`FE-FLAG-01` through `FE-FLAG-08`) using the exact Key string names from `docs/4_interfaces.json`.
3. Write your handoff report at `/Users/rohit/Desktop/Python/LocalLens/.agents/p6_test_engineer_1/handoff.md`.
4. Send a message to parent with completion status and path to handoff.md.
