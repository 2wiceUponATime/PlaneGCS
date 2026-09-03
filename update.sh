#!/bin/bash

cd "$(dirname "$0")" || exit

if [[ "$1" == "clean" && -d freecad ]]; then
    echo "Removing local FreeCAD copy..."
    rm -rf freecad
fi

if [ -d freecad ]; then
    echo "Checking for updates..."
    cd freecad
    git fetch && git reset --hard
    cd ..
else
    git clone \
        -b releases/FreeCAD-1-1 \
        https://github.com/FreeCAD/FreeCAD \
        --single-branch \
        --depth 1 \
        freecad
fi

FREECAD_DIR="freecad/src"
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
rm -f $(find include src -iname "*.bak")

echo "Installing standalone Console shim (replaces FreeCAD's Qt/Python-dependent Base::Console)..."
cp console-shim/Console.h include/Base
cp console-shim/Console.cpp src/Base