# /www/intranet/allocations/one-group-one-month-add-2.tcl

ad_page_contract {
    Update Allocations for one group (office, team, project) for
    one month

    the allocation is updated if (indicating the user changed the allocation):
    * group_id_for_allocation.$allocation_id is not no_change
    * percentage_time_for_allocation.$allocation_id is not no_change
    * note_for_allocation.$allocation_id is different than hidden_note_for_allocation_$allocation_id
    
    we also have new allcoations.  Variables will be of the form
    group_id_for_user.${count},${user_id} - project (group) id for a new allocation for user user_id
    percentage_for_user.${count}_$i{user_id} - the corresponding  percentage (match the [set counter])
    note_for_user.${count}_${user_id} - the corresponding note
    
    @param group_id_for_allocation.$allocation_id -- project (group) id this allocation id should belong to
    @param percentage_time_for_allocation.$allocation_id -- amount of time for this allocation_id
    @param hidden_note_for_allocation.$allocation_id - old value of the note for this allocation
    @param note_for_allocation.$allocation_id - note for this allocation
    
    @author teadams@arsdigita.com
    @creation-date May 2000
   
    @cvs-id one-group-one-month-add-2.tcl,v 3.2.2.8 2000/08/16 21:24:38 mbryzek Exp
} {
    start_block
    page_group_id:naturalnum,notnull
    group_id_for_allocation:array,optional
    percentage_time_for_allocation:array,optional
    hidden_note_for_allocation:array,optional
    note_for_allocation:array,optional
    group_id_for_user:array,optional
    percentage_for_user:array,optional
    note_for_user:array,optional
}

#this was an old allocation

foreach allocation_id [array names group_id_for_allocation] {
   set group_id $group_id_for_allocation($allocation_id)
   set percentage_time $percentage_time_for_allocation($allocation_id)
   set hidden_note $hidden_note_for_allocation($allocation_id)
   set note $note_for_allocation($allocation_id)


   if {$group_id != "no_change" || $percentage_time != "no_change" || $hidden_note != $note} { 

       set update_text ""

       if {$group_id != "no_change"} {
	   append update_text " group_id = $group_id, "
       }

       if {$percentage_time != "no_change"} {
	   if {$percentage_time == "too small"} { 
	       set percentage_time 0
	       set too_small_to_give_percentage_p "t"
	   } else {
	       set too_small_to_give_percentage_p "f"
	   }
	   append update_text " percentage_time = '$percentage_time', too_small_to_give_percentage_p = '$too_small_to_give_percentage_p', "

       }

       # this allocation has changed

       db_dml update_statement "update im_allocations 
				   set $update_text note = :note, 
				       last_modified = sysdate, 
				       last_modifying_user = [ad_get_user_id], 
				       modified_ip_address = '[ns_conn peeraddr]' 
				 where allocation_id = :allocation_id" 
   }
}

#this was a new allocation_id

set current_user_id [ad_get_user_id]
set peeraddr [ns_conn peeraddr]

foreach elementindex [array names group_id_for_user] {
    #elementindex in the form $counter,$user_id
    #get user_id
    set user_id [lindex [split $elementindex ","] 1]

    set group_id $group_id_for_user($elementindex)
    set percentage_time $percentage_for_user($elementindex)
    set note $note_for_user($elementindex)

   
    if {$percentage_time == "too small"} { 
	set percentage_time 0
	set too_small_to_give_percentage_p "t"
    } else {
	set too_small_to_give_percentage_p "f"
    }
    if {![empty_string_p $group_id]} {
	db_dml insert_statement \
	    "insert into im_allocations 
		 (allocation_id, group_id, user_id, start_block, 
		  percentage_time, note, last_modified, last_modifying_user, 
		  modified_ip_address, too_small_to_give_percentage_p) 
	     values     
		 (im_allocations_id_seq.nextval, :group_id, :user_id, :start_block,  :percentage_time, 
		  :note, sysdate, :current_user_id, :peeraddr, :too_small_to_give_percentage_p)"
    }
    
}

ad_returnredirect "one-group-one-month?group_id=$page_group_id"
