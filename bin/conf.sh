#!/bin/sh

echo "-------------------------[Setting Up Project]--------------------------"

# Top level environment variables
export REPO_HOME=`pwd`
export XC_WORK=$REPO_HOME/build

if [ -z $YOSYS_ROOT ] ; then
    # Export a dummy "Yosys Root" path environment variable.
    export YOSYS_ROOT=
fi

echo "REPO_HOME      = $REPO_HOME"
echo "XC_WORK        = $XC_WORK"
echo "YOSYS_ROOT     = $YOSYS_ROOT"

echo "------------------------------[Finished]-------------------------------"
