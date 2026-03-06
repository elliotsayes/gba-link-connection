# Quick Guide

## Build ROMs
- List discovered projects: `./rom list`
- Build one project: `./rom build <target>`
  - Example: `./rom build scenarios/HelloWorld`
- Build a folder recursively: `./rom build scenarios/LinkRawWireless`
- Build everything in a group: `./rom build examples` or `./rom build scenarios`
- Defaults: `--mode docker --kind standalone`
  - Override if needed: `--mode native`, `--kind multiboot`, `--kind both`
- Artifacts go to `dist/<kind>/<group>/...` and keep nested subdirs.

## Scaffold New Projects
- Create a project scaffold:
  - `tools/scaffold_project.sh <project-dir>`
  - Example: `tools/scaffold_project.sh scenarios/MyScenario`
- Optional flags:
  - `--title <rom-title>` to set ROM header title
  - `--force` to overwrite scaffold files
- Scaffold creates:
  - `Makefile`
  - `src/main.c` (hello world)
  - `data/`

## Use The Project
- Core libraries are in `lib/` (C++ headers).
- C bindings are in `lib/c_bindings/` (`C_Link*.h/.cpp`).
- `examples/` are the reference implementations.
- `scenarios/` is for custom projects/tests using the same Makefile conventions.
