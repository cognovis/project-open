ad_page_contract {
    Edit arc.
} {
    workflow_key
    transition_key
    place_key
    direction
    return_url:optional
} -properties {
    context
    export_vars
    guard_description
    guard_options:multirow
    guard_custom_arg
}

db_1row arc_info {
    select a.guard_callback,
           a.guard_custom_arg,
           a.guard_description
    from   wf_arcs a
    where  a.workflow_key = :workflow_key
    and    a.transition_key = :transition_key
    and    a.place_key = :place_key
    and    a.direction = :direction
}

set guard_description [ad_quotehtml $guard_description]
set guard_custom_arg [ad_quotehtml $guard_custom_arg]

# Query Oracle's data dictionary to find all the functions matching the signature that guards
# must match
# Ugh! This is ugly. We really need that callback repository!

set possible_guards [util_memoize {
db_list possible_guards {
    select a0.package_name || '.' || a0.object_name
    from   user_arguments a0
    where  position = 0
    and    argument_name is null
    and    data_type = 'CHAR'
    and    in_out = 'OUT'
    and    exists (select 1 from user_arguments a1 where a1.package_name=a0.package_name and a1.object_name=a0.object_name 
                   and a1.position=1 and a1.data_type='NUMBER' and a1.in_out='IN')
    and    exists (select 1 from user_arguments a2 where a2.package_name=a0.package_name and a2.object_name=a0.object_name 
                   and a2.position=2 and a2.data_type='VARCHAR2' and a2.in_out='IN')
    and    exists (select 1 from user_arguments a3 where a3.package_name=a0.package_name and a3.object_name=a0.object_name 
                   and a3.position=3 and a3.data_type='VARCHAR2' and a3.in_out='IN')
    and    exists (select 1 from user_arguments a4 where a4.package_name=a0.package_name and a4.object_name=a0.object_name 
                   and a4.position=4 and a4.data_type='VARCHAR2' and a4.in_out='IN')
    and    exists (select 1 from user_arguments a5 where a5.package_name=a0.package_name and a5.object_name=a0.object_name 
                   and a5.position=5 and a5.data_type='VARCHAR2' and a5.in_out='IN')
    and    exists (select 1 from user_arguments a6 where a6.package_name=a0.package_name and a6.object_name=a0.object_name 
                   and a6.position=6 and a6.data_type='VARCHAR2' and a6.in_out='IN')
}} 3600]


template::multirow create guard_options value selected name

template::multirow append guard_options "" [ad_decode $guard_callback "" "SELECTED" ""] "--no guard-- [ad_decode $guard_callback "" "(current)" ""]"

template::multirow append guard_options "#" [ad_decode $guard_callback "#" "SELECTED" ""] "No other guards were satsified [ad_decode $guard_callback "#" "(current)" ""]"

if { ![empty_string_p $guard_callback] && ![string equal $guard_callback "#"] && \
	[lsearch -exact $possible_guards $guard_callback] == -1 } {
    template::multirow append guard_options [ad_quotehtml $guard_callback] "SELECTED" "[ad_quotehtml $guard_callback] (current&#151;appears to be invalid)"
}

foreach possible_guard $possible_guards {
    set selected_p [string equal $possible_guard $guard_callback]
    template::multirow append guard_options [ad_quotehtml $possible_guard] [ad_decode $selected_p 1 "SELECTED" ""] [ad_quotehtml $possible_guard] [ad_decode $selected_p 1 "(current)" ""]
}
 

set context [list [list "define?[export_url_vars workflow_key]" "Process Builder"] "Edit arc"]
set export_vars [export_form_vars workflow_key transition_key place_key direction return_url]


ad_return_template
