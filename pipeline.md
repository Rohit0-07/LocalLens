What it does
A strict, auditable Spec-Driven Development pipeline enforced mechanically via permissions, hooks, and CLI exit codes — not just documentation.
Complete Pipeline (8 phases)
Phase Agent Input Output
0 indexer — docs/0_repo_index.json
1 product-manager raw idea docs/1_spec.md
2 architect 1_spec.md, 0_repo_index.json docs/2_tech_spec.md
3 qa-planner 1_spec.md ONLY docs/3_test_plan.md
4 interface-bridge source via extractor docs/4_interfaces.json
5 coder 2_tech_spec.md ONLY src/**
6 test-engineer 3_test_plan.md, 4_interfaces.json tests/**
7 runner — test run + .sdd/runs/latest/failures.json
8 change-manager — lock/unlock via CLI
Key Gates

- docs/1_spec.md and docs/2_tech_spec.md are locked via sdd.py approve (chmod 444 + .sdd-locks.json)
- Changes to locked docs require /request-change → unlocks that file + marks downstream phases stale
  Mechanical Isolation (enforced by permissions)
- test-engineer: no access to src/, tech spec, bash, grep/glob of src, web, subagents
- architect/product-manager: cannot read src/
- coder: cannot read test plan/interfaces, cannot edit docs, cannot commit
  Commands to develop a feature
  /generate-spec # Phase 1: write spec from raw idea
  /approve-spec # Lock spec (gate)
  /architect # Phase 2: create tech spec
  /approve-tech-spec # Lock tech spec (gate)
  /code # Phase 5: implement from tech spec only
  /extract-interfaces # Phase 4: generate interfaces.json
  /generate-tests # Phase 6: write tests from test plan + interfaces
  /run-loop # Drive full pipeline, stops at gates for approval
  /request-change # Unlock a locked doc + mark downstream stale
  Run /run-loop to drive the pipeline end-to-end; it pauses at each gate for your approval.
