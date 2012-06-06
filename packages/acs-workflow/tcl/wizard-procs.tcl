ad_library {
    Helper-procs for the process wizard.

    @author Lars Pind (lars@pinds.com)
    @creation-date 28 September 2000
    @cvs-id $Id$
}



ad_proc wf_name_to_key { 
    name
} { 
    Generates a key from a name by making it all lowercase, removing
    non-letters and putting in underscores instead of spaces.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 29 September, 2000
} {
    regsub -all { } $name {_} key
    set key [string tolower $key]
    regsub -all {[^a-z0-9_]} $key {} key
    return $key
}

ad_proc wf_valid_key_p {
    key
} {
    Check that a value is valid as a key for a workflow/transition/place in 
    a workflow definition.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 1 November, 2000
} {
    return [string is wordchar]
}

ad_proc wf_make_unique {
    -maxlen:required
    -taken_names:required
    name_part_one
    {name_part_two ""}
} {
    Takes a name (split in two parts) and makes it unique with respect to the list passed in <code>taken_names</code>,
    by putting an integer number between <code>name_part_one</code>
    and <code>name_part_two</code>, chopping <code>name_part_one</code> as required to stay within maxlen.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 29 September, 2000
} {
    set len_one [string length $name_part_one]
    set len_two [string length $name_part_two]
    if { $len_one + $len_two > $maxlen } {
	set name_part_one [string range $name_part_one 0 [expr $maxlen-$len_two-1]]
	set len_one [string length $name_part_one]
    }
    
    if { [lsearch -exact $taken_names "$name_part_one$name_part_two"] == -1 } {
	return "$name_part_one$name_part_two"
    } else {
	set num_taken_names [llength $taken_names]
	set number 2
	while 1 { 
	    set len_num [string length $number]
	    if { $len_one + $len_num + $len_two > $maxlen } {
		set name_part_one [string range $name_part_one 0 [expr $maxlen-$len_two-$len_num-1]]
		set len_one [string length $name_part_one]
	    }
	    if { [lsearch -exact $taken_names "$name_part_one$number$name_part_two"] == -1 } {
		return "$name_part_one$number$name_part_two"
	    }
	    incr number
	    if { $number > $num_taken_names + 2 } {
		return -code error "Infinite loop"
	    }
	}
    }
}


ad_proc wf_simple_wizard_process_def {} {
    Gives the process definition list for use with <code>wf_progress_bar</code>

    @author Lars Pind (lars@pinds.com)
    @creation-date 29 September, 2000
} {
    return {
	{"" "Name"}
	{"tasks" "Tasks"}
	{"loops" "Loops"}
	{"assignments" "Assignments"}
	{"create" "Done!"}
    }
}



ad_proc wf_progress_bar {
    {-nolinks:boolean}
    {-name}
    process_def
    num_completed
} {
    Returns an HTML fragment that displays the progress of a wizard nicely.

    @param process_def a list of two-tuples, with the first value being the URL to link to, the second the name to display.
    @param num_completed the number of steps completed so far. When you're at the first step, this would be 0.

    @author Lars Pind (lars@pinds.com)
    @creation-date 29 September, 2000
} {

    set steps {}

    set counter 0
    foreach step $process_def {
	if { $counter < $num_completed } {
	    if { !$nolinks_p } {
		lappend steps "<td><a href=\"[lindex $step 0]\"><b>[expr $counter+1]. [lindex $step 1]</b></a></td>"
	    } else {
		lappend steps "<td><b>[expr $counter+1]. [lindex $step 1]</b></td>"
	    }
	} elseif { $counter == $num_completed } {
	    lappend steps "<td bgcolor=#9999f6><b>[expr $counter+1]. [lindex $step 1]</b></td>"
	} elseif { $counter > $num_completed }  {
	    lappend steps "<td><font color=#999999><b>[expr $counter+1]. [lindex $step 1]</b></font></td>"
	}
	incr counter
    }

	
    set html "
<table align=center cellspacing=0 cellpadding=1 border=0>
<tr bgcolor=#999999><td>
<table width=\"100%\" cellspacing=0 cellpadding=0 border=0>
<tr bgcolor=#eeeeee>
<td>

<table width=\"100%\" cellspacing=0 cellpadding=2 border=0>
<tr bgcolor=#eeeeee>
<td>&nbsp;</td>
"
if { [info exists name] } {
    append html "
<td>Simple Process Wizard:</td>
<td>&nbsp;</td>"
}
append html "
[join $steps "<td><img src=\"slim-right-arrow\" height=32 width=32></td>"]<td>&nbsp;</td>
</tr>
</table>

</td></tr>
</table>
</td></tr>
</table>
"

    return $html
}


ad_proc wf_wizard_massage_tasks {
    the_tasks
    list_var
    array_var
    {multirow_var ""}
} {
    We store tasks in a client property as a list of array gets 
    with the keys: task_name, transition_key, task_time, loop_to_transition_key, loop_question, loop_answer,
    assigning_transition_key.
    
    <p>

    This proc massages that into three vars: 
    a list of transition_keys, which lays out the sequence of transitions,
    and an array that holds all the information, keyed by
    ($transition_key,key) where key is one of the above keys.
    Finally, a multirow datasource, containing the tasks.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 29 September, 2000
} {

    # Note also: This whole way of representing the information here in three or four different formats, 
    # actually sucks.
    # Don't do this if you happen to be porting this to a real language (e.g., Java)

    if { ![empty_string_p $list_var] } {
	upvar 1 $list_var the_list 
    }

    if { ![empty_string_p $array_var] } {
	upvar 1 $array_var the_array
    }
    
    set the_list {}
    array unset the_array *
    
    if { ![empty_string_p $multirow_var] } {
	template::multirow create $multirow_var transition_key task_name \
		task_time \
		loop_to_transition_key loop_to_task_name loop_question loop_answer \
		assigning_transition_key assigning_task_name
    }

    set the_array(,task_name) ""

    foreach task_info $the_tasks {
	array set task $task_info

	set transition_key $task(transition_key)
	lappend the_list $transition_key
	foreach name { transition_key task_name task_time loop_to_transition_key loop_question loop_answer assigning_transition_key } { 
	    if { [info exists task($name)] } {
		set the_array($transition_key,$name) $task($name)
	    } else {
		set the_array($transition_key,$name) ""
	    }
	}

	if { ![empty_string_p $multirow_var] } {
	    template::multirow append $multirow_var \
		    $transition_key \
		    $the_array($transition_key,task_name) \
		    $the_array($transition_key,task_time) \
		    $the_array($transition_key,loop_to_transition_key) \
		    $the_array($the_array($transition_key,loop_to_transition_key),task_name) \
		    $the_array($transition_key,loop_question) \
		    $the_array($transition_key,loop_answer) \
		    $the_array($transition_key,assigning_transition_key) \
		    $the_array($the_array($transition_key,assigning_transition_key),task_name)
	}
    }
}





