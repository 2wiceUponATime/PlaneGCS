# PlaneGCS

A standalone build of [FreeCAD](https://github.com/FreeCAD/FreeCAD)'s 2D
geometric constraint solver, extracted from
[`src/Mod/Sketcher/App/planegcs`](https://github.com/FreeCAD/FreeCAD/tree/releases/FreeCAD-1-1/src/Mod/Sketcher/App/planegcs)
on the `releases/FreeCAD-1-1` branch, for use outside of FreeCAD/Sketcher.

## What's here vs. what's generated

`include/` and `src/` are generated from FreeCAD by `update.sh` — don't edit
them directly, since the next sync will overwrite your changes. `update.sh`:

1. Clones (or updates) a local copy of FreeCAD into `freecad/`.
2. Copies the planegcs sources plus the handful of FreeCAD headers they
   depend on (`FCConfig.h`, `FCGlobal.h`, `SketcherGlobal.h`,
   `boost_graph_adjacency_list.hpp`) into `include/`/`src/`.
3. Patches out the remaining FreeCAD/Qt-specific bits (stray `QtCore.h`
   includes, path-relative header includes).
4. Installs the `console-shim/` files in place of FreeCAD's real
   `Base/Console.h`/`.cpp` — see below.

`console-shim/` and `CMakeLists.txt` are hand-maintained parts of this
project, not generated.

### The Console shim

FreeCAD's real `Base::Console` pulls in Qt and FreeCAD's Python bindings,
neither of which this project depends on otherwise. planegcs only ever calls
`Base::Console().log(...)` and `.warning(...)`, so `console-shim/` provides a
minimal drop-in replacement implementing just those two entry points. Output
goes to `stderr` by default; call `Base::Console().setLogHandler(...)` /
`.setWarningHandler(...)` to redirect it.

## Prerequisites

Eigen3, Boost, and fmt must be installed and discoverable via `find_package`
— they are not vendored or fetched automatically. Only Boost's headers are
used (Boost.Graph is header-only here), and only while building PlaneGCS
itself. No minimum versions are enforced; if `cmake` can't find one of them,
it'll say which. Requires CMake ≥ 3.26.

## Building

```sh
cmake --preset default
cmake --build --preset default
```

The `default` preset builds into `build/` and writes `compile_commands.json`.
Pass `-DBUILD_SHARED_LIBS=ON` for a shared library. When PlaneGCS is the
top-level project, install rules are generated automatically; as a
subdirectory they're off unless you set `PLANEGCS_INSTALL=ON`.

## Using it

As a subdirectory dependency:

```cmake
add_subdirectory(path/to/planegcs)
target_link_libraries(your_target PRIVATE PlaneGCS::planegcs)
```

Or, after `cmake --install`, via `find_package`:

```cmake
find_package(PlaneGCS REQUIRED)
target_link_libraries(your_target PRIVATE PlaneGCS::planegcs)
```

Either way, Eigen3 and fmt just need to be discoverable on the machine
doing the build — `PlaneGCS::planegcs` carries them as real transitive
dependencies, so you don't need to separately `find_package`/link them
yourself. Consumers of an installed PlaneGCS don't need Boost at all.
Installed headers live under `include/PlaneGCS/`, which the target adds to
the include path, so includes are still written as `#include <GCS.h>`.

### Solving: watch out for `solve()` and `applySolution()`

`GCS::System::solve()` (no arguments) silently returns `Failed` unless you've
first called the `solve(VEC_pD& params, ...)` overload at least once — only
that overload runs `declareUnknowns`/`initSolution`, which the no-argument
form skips. Pass it the list of parameter pointers that are free to move
(anything not in that list, like a pinned point, is treated as fixed):

```cpp
GCS::VEC_pD params{&p2x, &p2y};
int status = system.solve(params);
```

Separately, solving does not write results back into your original
`double*`s by itself — call `system.applySolution()` afterward, or your
parameters will look unchanged even on `Success`.

## License

LGPL-2.1-or-later, matching upstream FreeCAD. See `LICENSE`.
