# Assume that we have the following vars:
#   num_completed
#   no_links (optional)


if { ![info exists no_links] } {
    set no_links 0
}

set counter 0

template::multirow create steps url name status

foreach step {
    {"" "Name"}
    {"tasks" "Tasks"}
    {"loops" "Loops"}
    {"assignments" "Assignments"}
    {"create" "Done!"}
} {
    if { $counter < $num_completed } {
	set status "completed"
    } elseif { $counter == $num_completed } {
	set status "current"
    } elseif { $counter > $num_completed }  {
	set status "future"
    }
    template::multirow append steps [lindex $step 0] "[expr {$counter + 1}]. [lindex $step 1]" $status
    incr counter
}

