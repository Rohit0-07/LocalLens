## 2026-08-10T12:03:09Z
You are the Quality Gates Runner subagent for LocalLens.
Your working directory for metadata is `/Users/rohit/Desktop/Python/LocalLens/.agents/p8_quality_gates_1`.

Your task is to execute P8 (Quality Gates Verification) of the F-14-FLAG Spec-Driven Development pipeline:
1. Run Backend Quality Gates in directory `/Users/rohit/Desktop/Python/LocalLens/backend`:
   - `python3 -m pytest`
   - `python3 -m ruff check .`
   - `python3 -m mypy app`
2. Run Frontend Quality Gates in directory `/Users/rohit/Desktop/Python/LocalLens/app`:
   - `flutter test`
   - `flutter analyze`

3. Verify that all 5 quality gate checks pass cleanly with 0 errors.
4. Write your detailed handoff report at `/Users/rohit/Desktop/Python/LocalLens/.agents/p8_quality_gates_1/handoff.md`.
5. Send a message to parent with completion status and path to handoff.md.
