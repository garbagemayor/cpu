
# PlanAhead Launch Script for Pre-Synthesis Floorplanning, created by Project Navigator

create_project -name tyt_cpu -dir "C:/Users/Yijun Tan/Desktop/threeweeks/tyt_cpu/planAhead_run_2" -part xc3s1200efg320-4
set_param project.pinAheadLayout yes
set srcset [get_property srcset [current_run -impl]]
set_property target_constrs_file "tyt_cpu.ucf" [current_fileset -constrset]
set hdlfile [add_files [list {tyt_cpu.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set_property top tyt_cpu $srcset
add_files [list {tyt_cpu.ucf}] -fileset [get_property constrset [current_run]]
open_rtl_design -part xc3s1200efg320-4
