
# PlanAhead Launch Script for Post-Synthesis pin planning, created by Project Navigator

create_project -name tyt_cpu -dir "C:/Users/Yijun Tan/Desktop/threeweeks/tyt_cpu/planAhead_run_2" -part xc3s1200efg320-4
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "C:/Users/Yijun Tan/Desktop/threeweeks/tyt_cpu/tyt_cpu.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {C:/Users/Yijun Tan/Desktop/threeweeks/tyt_cpu} }
set_param project.pinAheadLayout  yes
set_property target_constrs_file "tyt_cpu.ucf" [current_fileset -constrset]
add_files [list {tyt_cpu.ucf}] -fileset [get_property constrset [current_run]]
link_design
