# Runs behavioral simulation in Vivado batch mode with automatic project setup.
set script_dir [file normalize [file dirname [info script]]]
set repo_root  [file normalize [file join $script_dir ".."]]
set proj_file  [file normalize [file join $repo_root "vivado" "sorter_sim" "sorter_sim.xpr"]]

# Auto-recreate project on fresh clones when vivado/ has not yet been generated.
if {![file exists $proj_file]} {
    source [file join $script_dir "create_sim_project.tcl"]
} elseif {[catch {current_project}]} {
    open_project $proj_file
}

# Allow overriding simulation top from CLI arguments (defaults to fifo_tb).
if {$argc > 0} {
    set_property top [lindex $argv 0] [get_filesets sim_1]
    update_compile_order -fileset sim_1
}

# Run to completion ($finish) instead of Vivado's default 1000ns limit.
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]

launch_simulation
