# Recreates the Vivado simulation project referencing rtl/ and tb/ in-place.
set part "xc7a35tcpg236-1"
set project_name "sorter_sim"

# Resolve repo root relative to this script so it runs correctly regardless of caller CWD.
set script_dir [file normalize [file dirname [info script]]]
set repo_root  [file normalize [file join $script_dir ".."]]
set proj_dir   [file normalize [file join $repo_root "vivado" $project_name]]

file mkdir $proj_dir
create_project -force $project_name $proj_dir -part $part
set_property target_language Verilog [current_project]

# Remote references keep rtl/ and tb/ as single sources of truth without duplicating files.
set rtl_files [list \
    [file join $repo_root "rtl" "pkg" "sorter_pkg.sv"] \
    [file join $repo_root "rtl" "interfaces" "sorter_if.sv"] \
    [file join $repo_root "rtl" "common" "fifo.sv"] \
    [file join $repo_root "rtl" "top" "sorter_top.sv"] \
]
add_files -norecurse -fileset sources_1 $rtl_files
set_property file_type SystemVerilog [get_files -of_objects [get_filesets sources_1]]
set_property top sorter_top [get_filesets sources_1]

set tb_files [list \
    [file join $repo_root "tb" "common" "fifo_tb.sv"] \
]
add_files -norecurse -fileset sim_1 $tb_files
set_property file_type SystemVerilog [get_files -of_objects [get_filesets sim_1]]
set_property top fifo_tb [get_filesets sim_1]

set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
