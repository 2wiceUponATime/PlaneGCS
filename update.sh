#!/bin/bash

cd "$(dirname "$0")" || exit

FREECAD_BRANCH="releases/FreeCAD-1-1"

if [[ "$1" == "clean" && -d FreeCAD ]]; then
    echo "Removing local FreeCAD copy..."
    rm -rf FreeCAD
fi

if [ -d FreeCAD ]; then
    echo "Checking for updates..."
    cd FreeCAD
    git fetch --depth 1 origin "$FREECAD_BRANCH" && git reset --hard FETCH_HEAD
    cd ..
else
    git clone \
        -b "$FREECAD_BRANCH" \
        https://github.com/FreeCAD/FreeCAD \
        --single-branch \
        --depth 1
fi

FREECAD_DIR="FreeCAD/src"
SKETCHER_DIR="$FREECAD_DIR/Mod/Sketcher"
PLANEGCS_DIR="$SKETCHER_DIR/App/planegcs"

echo "Copying source files..."
rm -rf src include
mkdir -p src/Base include/Base
cp $PLANEGCS_DIR/*.cpp src
cp $PLANEGCS_DIR/*.h include
cp $SKETCHER_DIR/SketcherGlobal.h include
cp $FREECAD_DIR/FC*.h $FREECAD_DIR/boost_graph_adjacency_list.hpp include

patch_files=$(find include src -type f)

echo "Applying patches..."
sed -i.bak 's|#include <QtCore.h>||' $patch_files
sed -i.bak 's#"\.\./\.\./SketcherGlobal\.h"#"SketcherGlobal.h"#' $patch_files
sed -i.bak 's#<Base/Console\.h>#"Base/Console.h"#' $patch_files
# Geo.h pulls this in but never uses it (no boost::math references anywhere
# in the sources); dropping it avoids requiring Boost::math as a public
# dependency just for a dead include.
sed -i.bak '/#include <boost\/math\/constants\/constants\.hpp>/d' $patch_files
# Geo.cpp relies on std::sqrt/std::abs/etc. but only pulled in <cmath>
# transitively (partly via the boost/math header removed above); include it
# explicitly. Insert before the first #include so it lands outside the license
# comment block.
sed -i.bak '0,/^#include/s//#include <cmath>\n&/' src/Geo.cpp
# Unused includes: nothing from these headers is referenced in the files that
# include them. FCConfig.h's platform macros go unused in GCS.cpp;
# graph_concepts.hpp is included by Constraints.cpp, which never touches boost.
sed -i.bak '/#include <iostream>/d' src/qp_eq.cpp
sed -i.bak '/#include <FCConfig\.h>/d' src/GCS.cpp
sed -i.bak '/#include <boost\/graph\/graph_concepts\.hpp>/d' src/Constraints.cpp
# Constraints.cpp and SubSystem.cpp use assert() but only got <cassert>
# transitively (via the boost headers removed above); include it explicitly.
sed -i.bak '0,/^#include/s//#include <cassert>\n&/' src/Constraints.cpp src/SubSystem.cpp
rm -f $(find include src -iname "*.bak")

echo "Installing standalone Console shim (replaces FreeCAD's Qt/Python-dependent Base::Console)..."
cp console-shim/Console.h include/Base
cp console-shim/Console.cpp src/Base