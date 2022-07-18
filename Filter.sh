#!/bin/bash

### TODO ###
# Be sensible to nproc
############

[[ -d $1 ]] || { echo "Not a directory, exiting"; return 1; }   # check if first input is a directory

function ActualFiltering {
    local path="$PWD/$1$2"
    local file="HIJING_LBF_test_small.out"
    local event_counter=0 # set counter for events for run to 0
    cd $path || { echo "Path error" >&2; return 2; }  # change the directory to the specific run
    while read eventFile; do {
        cp $eventFile backup_${event_counter}.dat # backup the event file
        awk '{if ($3 == 0) print $0}' < backup_${event_counter}.dat 1>event_${event_counter}.dat  # only save primary particles
        CheckFilteringAndRemove ${event_counter}  # check if process successful and delete backups if so --> Adds significantly to runtime
        ((event_counter++))
    }; done < <(find $path -type f -name "event_*.dat")
    cd $pwd_original
}

function Filtering {
    local numberOfProcesses=$(nproc)  # not in use yet....
    for run in {0..9..1}; do {
        ( ActualFiltering $1 ${run} )
    }; done
    wait
}

function CheckFilteringAndRemove {
    local testBool=0; # initialize test variable which is set to 1 if one particles is not primary
    local line;
    while read line; do {
        awk '{if ($3 != 0) testBool=1}';  # check each particle
    if [[ testBool -eq 0 ]]; then {
        rm backup_$1.dat; # rm backup if test bool indicates no issues
    }
    else {
        echo "Warning: Filtering failed for event $1!" >&2; # Print out an error if failed for a specific file
    }; fi
    }; done < event_$1.dat
    }

Filtering $1; # run the script
