# /www/intranet/allocations/add-2.tcl

ad_page_contract {
    Add an allocation
    
    @param allocation_id what id are we adding?
    @param group_id the group id of the project
    @param allocated_user_id The user
    @param start_block starting week
    @param percentage_time the percentage of the allocation
    @param note Miscellaneous comments

    @author mbryzek@arsdigita.com
    @creation-date January 2000
    @cvs-id add-2.tcl,v 3.7.2.4 2000/08/16 21:24:35 mbryzek Exp
} {
    group_id:integer,notnull
    allocated_user_id:integer,notnull
    start_block:notnull
    percentage_time:notnull
    note:notnull
    allocation_id:integer,notnull
    return_url:optional
}


set user_id [ad_maybe_redirect_for_registration]


# Now check to see if the input is good as directed by the page designer

set exception_count 0
set exception_text ""

if {[string length $note] > 1000} {
    incr exception_count
    append exception_text "<LI>\"note\" is too long\n"
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

# So the input is good --
# Now we'll update the allocation.

set ns_conn_bv [ns_conn peeraddr]

set dml_type "insert"

db_transaction {

    # We want to be smart about adjusting the current allocations
    
    # if the allocation_id and the start_block are the same as an
    # existing row,  this means we are changing a particular allocation
    # decision from before. We want to do an update of that row instead of
    # creating a new row.
    
    db_dml update_allocations {
	update im_allocations 
	set last_modified = sysdate, 
	last_modifying_user = :user_id, modified_ip_address = :ns_conn_bv, 
	percentage_time = :percentage_time, 
	note = :note, user_id = :allocated_user_id, 
	group_id = :group_id 
	where start_block = :start_block 
	and allocation_id = :allocation_id
    }
	
    # if the user_id, start_date and group_id is that same
    # as an exisiting row and the allocation_id is not the same (above case), 
    # we are giving a user two different allocations
    # on the same project. we want to do an update of that row
	# instead of creating a new row
    
    db_dml update_2nd_allocation "update im_allocations 
    set last_modified = sysdate, 
    last_modifying_user = :user_id, modified_ip_address = :ns_conn_bv, 
    percentage_time = :percentage_time, 
    note = :note, 
    allocation_id = :allocation_id 
    where start_block = :start_block 
    and user_id = :allocated_user_id 
    and group_id = :group_id 
    and allocation_id <> :allocation_id"
    
    # If the conditions above don't apply, let's add a new row
    
    db_dml insert_new_row "insert into im_allocations
    (allocation_id, last_modified, last_modifying_user, 
    modified_ip_address, group_id, user_id, start_block, percentage_time, note)
    select :allocation_id, sysdate, :user_id, 
    :ns_conn_bv, :group_id, 
    :allocated_user_id, start_block, 
    :percentage_time, :note 
    from im_start_blocks 
    where start_block = :start_block 
    and im_start_blocks.start_of_larger_unit_p = 't' 
    and not exists(select 1 from im_allocations im2 
    where im2.allocation_id = :allocation_id 
    and im_start_blocks.start_block = im2.start_block) 
    and not exists(select 1 from im_allocations im3 
    where im3.user_id = :allocated_user_id 
    and im3.group_id = :group_id 
    and im3.allocation_id <> :allocation_id 
    and im_start_blocks.start_block = im3.start_block)"
    
    # clean out allocations with 0 percentage
    db_dml delete_emptys "delete from im_allocations where percentage_time=0"

}

db_release_unused_handles

if [info exist return_url] {
    ad_returnredirect $return_url
} else {
    ad_returnredirect index?[export_url_vars start_block group_id]
}
 
