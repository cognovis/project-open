ad_proc wf_expenses_get_assign_panels {
    -task_info:required
} {
    array set task $task_info 

    lappend panels [list title "Input" body "$task(object_type_pretty): $task(object_name)"]
    
    lappend panels [list title "Logic and Aids" body "Here are some logics and aids."]
    
    return $panels
}
