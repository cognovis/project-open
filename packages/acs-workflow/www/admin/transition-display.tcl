# packages/acs-workflow/www/admin/transition-display.tcl
# @author Lars Pind (lars@pinds.com)
# @creation-date November 21, 2000
# @cvs-id $Id$
#
# Expects:
#    workflow (magic)
#    transition_key
#    selected_transition_key
#    selected_place_key
# Returns:
#    table:multirow(input_place_key input_place_name input_place_url input_place_selected_p input_place_num
#	transition_key transition_name transition_url transition_selected_p
#	output_place_key output_place_key output_place_url output_place_selected_p output_place_num)


#####
#
# Translate the decoration into something specific to the HTML-representation
#
#####

set count(in) [llength $workflow(arcs,transition,$transition_key,in)]
set count(out) [llength $workflow(arcs,transition,$transition_key,out)]
set num_rows [max $count(in) $count(out)]

# We want an uneven number of rows
if { $num_rows % 2 != 1 } {
    incr num_rows
}
# We want at least three rows
if { $num_rows < 3 } {
    set num_rows 3
}
# Find the median
set median [expr ($num_rows-1)/2]

for { set i 0 } { $i < $num_rows } { incr i } {
    set in_pat($i) 0
    set out_pat($i) 0
}

#####
#
# Distribute the input places evenly over the transition box
#
#####

foreach direction { in out } {

    # generate a bit vector containing a 1 for every row where we should display an input/output place
    # e.g., say n = count(in/out), m = num_rows, and dist(n,m) is the bit-vector function,
    #
    # dist(0,5) = (0,0,0,0,0)
    # dist(1,5) = (0,0,1,0,0)
    # dist(2,5) = (0,1,0,1,0)
    # dist(3,5) = (1,0,1,0,1)
    # dist(4,5) = (1,1,0,1,1)
    # dist(5,5) = (1,1,1,1,1)
    #
    # This is then translated into a corresponding place_vector
    # where the 1's are replaced with the place_key of the place to be displayed in that slot

    for { set i 0 } { $i < $num_rows } { incr i } {
	set bit_vector($i) 0
	set place_vector($direction,$i) {}
    }
    
    if { [expr $count($direction) % 2] == 0 } {
	# count($direction) is even
	set count_half [expr $count($direction)/2]
	for { set i 0 } { $i < $count_half } { incr i } {
	    set bit_vector([expr $median - $i - 1]) 1
	    set bit_vector([expr $median + $i + 1]) 1
	}
    } else {
	set half_of_dif [expr ($num_rows - $count($direction))/2]
	for { set i 0 } { $i < $count($direction) } { incr i } {
	    set bit_vector([expr $i + $half_of_dif]) 1
	}
    }

    # Now, given the bit-vector above, figoure out which place we should put there

    set i 0
    foreach loop_place_key $workflow(arcs,transition,$transition_key,$direction) {
	# find the next 1 in the bit vector
	while { $i < $num_rows && !$bit_vector($i) } { incr i }
	
	# put in the next place
	set place_vector($direction,$i) $loop_place_key
	
	# move to the next bit
	incr i
    }
}


#####
#
# Spit it out into a multirow for display
#
#####    

template::multirow create table input_place_key input_place_name input_place_url input_place_selected_p input_place_num \
	transition_key transition_name transition_url transition_selected_p transition_trigger_type \
	output_place_key output_place_name output_place_url output_place_selected_p output_place_num \
	output_guard_pretty

for { set i 0 } { $i < $num_rows } { incr i } {

    set input_place_key $place_vector(in,$i)
    if { ![empty_string_p $input_place_key] } {
	set input_place_name $workflow(place,$input_place_key,place_name)
	set input_place_url $workflow(place,$input_place_key,url)
	set input_place_selected_p [string equal $input_place_key $selected_place_key]
	set input_place_num $workflow(place,$input_place_key,sort_order)
    } else {
	set input_place_name ""
	set input_place_url ""
	set input_place_selected_p 0
	set input_place_num 0
    }
    
    if { $i == 0 } {
	set loop_transition_key $transition_key
	set loop_transition_name $workflow(transition,$transition_key,transition_name)
	set loop_transition_url $workflow(transition,$transition_key,url)
	set loop_transition_selected_p [string equal $loop_transition_key $selected_transition_key]
	set loop_transition_trigger_type $workflow(transition,$transition_key,trigger_type)
    } else {
	set loop_transition_key ""
	set loop_transition_name ""
	set loop_transition_url ""
	set loop_transition_selected_p 0
	set loop_transition_trigger_type ""
    }
    
    set output_place_key $place_vector(out,$i)
    if { ![empty_string_p $output_place_key] } {
	set output_place_name $workflow(place,$output_place_key,place_name)
	set output_place_url $workflow(place,$output_place_key,url)
	set output_place_selected_p [string equal $output_place_key $selected_place_key]
	set output_place_num $workflow(place,$output_place_key,sort_order)
	set output_guard_pretty [ad_decode \
		$workflow(arc,$transition_key,$output_place_key,out,guard_description) \
		"" $workflow(arc,$transition_key,$output_place_key,out,guard_callback) \
		$workflow(arc,$transition_key,$output_place_key,out,guard_description)]
    } else {
	set output_place_name ""
	set output_place_url ""
	set output_place_selected_p 0
	set output_place_num 0
	set output_guard_pretty ""
    }

    template::multirow append table $input_place_key $input_place_name $input_place_url $input_place_selected_p $input_place_num \
	    $loop_transition_key $loop_transition_name $loop_transition_url $loop_transition_selected_p $loop_transition_trigger_type \
	    $output_place_key $output_place_name $output_place_url $output_place_selected_p $output_place_num $output_guard_pretty
}


ad_return_template

