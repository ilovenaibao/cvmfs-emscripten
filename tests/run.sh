#!/bin/bash

set -e

COMPILE=1
TEST=1
CHROME_EXE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-compile) COMPILE=0 ;;
        --no-test) TEST=0 ;;
        --chrome-exe) shift; CHROME_EXE=$1 ;;
    esac
    shift
done

TEST_DIR="$( cd "$( dirname "$0" )" && pwd )"
SRC_DIR="$( dirname "$TEST_DIR" )"

JS_DIR=$TEST_DIR/js
C_DIR=$TEST_DIR/c

TEST_BUILD_DIR=$TEST_DIR/build
JS_BUILD_DIR=$TEST_BUILD_DIR/js
C_BUILD_DIR=$TEST_BUILD_DIR/c

if [ $COMPILE -eq 1 ]; then
    mkdir -p $TEST_BUILD_DIR
    mkdir -p $JS_BUILD_DIR
    mkdir -p $C_BUILD_DIR

    $SRC_DIR/generate-pre.sh

    echo -n "Compiling JavaScript tests... "
    for testfile in $JS_DIR/*.js; do
        testfile=$(basename $testfile)
        [ $testfile == "common.js" ] && continue

        $SRC_DIR/emcc-cvmfs \
            -s WASM=0 \
            --post-js $JS_DIR/common.js \
            --post-js $JS_DIR/$testfile \
            --shell-file $TEST_DIR/test_container.html \
            --embed-file $TEST_DIR/data@/data \
            -o $JS_BUILD_DIR/${testfile%*.*}.html \
            $JS_DIR/do_nothing.c
    done
    echo "DONE"

    echo -n "Compiling C tests... "
    for testfile in $C_DIR/*.c; do
        testfile=$(basename $testfile)

        $SRC_DIR/emcc-cvmfs \
            -s WASM=0 \
            -s NO_EXIT_RUNTIME=0 \
            --shell-file $TEST_DIR/test_container.html \
            -o $C_BUILD_DIR/${testfile%*.*}.html \
            $C_DIR/$testfile
    done
    echo "DONE"
fi

if [ $TEST -eq 1 ]; then
    [ $COMPILE -eq 1 ] && echo ""

    echo "Running JavaScript tests:"
    for testfile in $JS_BUILD_DIR/*.html; do
        node $TEST_DIR/puppet.js $testfile $CHROME_EXE
    done

    echo ""

    echo "Running C tests:"
    for testfile in $C_BUILD_DIR/*.html; do
        node $TEST_DIR/puppet.js $testfile $CHROME_EXE
    done
fi