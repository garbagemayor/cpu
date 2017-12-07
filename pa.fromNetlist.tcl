
# PlanAhead Launch Script for Post-Synthesis pin planning, created by Project Navigator

create_project -name tyt_cpu2 -dir "C:/Users/rv/Desktop/cpu/planAhead_run_4" -part xc3s1200efg320-4
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "C:/Users/rv/Desktop/cpu/tyt_cpu2.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {C:/Users/rv/Desktop/cpu} }
set_param project.pinAheadLayout  yes
set_property target_constrs_file "tyt_cpu2.ucf" [current_fileset -constrset]
add_files [list {tyt_cpu2.ucf}] -fileset [get_property constrset [current_run]]
link_design
