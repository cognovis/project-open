# Create a workflow for an item by making assignments
# if is_edit is true, modify an existing workflow

form create case_create -elements {
    case_id         -datatype integer -widget hidden -param
    item_id         -datatype integer -widget hidden -param
    is_edit         -datatype keyword -widget hidden -param -optional
    transitions     -datatype text    -widget hidden
}


set user_id [User::getID]
set is_edit [element get_value case_create is_edit]


# check if this user has permission to create a workflow
set item_id [element get_value case_create item_id]
content::check_access $item_id cm_item_workflow \
	-mount_point workflow \
	-return_url "../items/index?item_id=$item_id" \
	-request_error

# get a list of users (this should be context-specific)
set users [db_list_of_lists get_users ""]

# Prepare the form elements

set transition_list [list]

db_foreach get_name_key  "" {

    form section case_create $transition_name

    element create case_create ${transition_key}_assign \
	    -datatype integer \
	    -widget select \
	    -options $users \
	    -label "Assignment"
 
    # Create an element to hold the old values, for later comparison
    if { [string equal $is_edit t] } {
	element create case_create ${transition_key}_assign_old \
		-datatype text \
		-widget hidden \
		-optional
    }

    element create case_create ${transition_key}_deadline \
	    -datatype date \
	    -widget date \
	    -format "DD/MONTH/YYYY" -year_interval { 2000 2001 1 } \
	    -label "Deadline" \
	    -value [util::date today]
 
    lappend transition_list $transition_key
}


# Remember the list of transitions
element set_properties case_create transitions -value $transition_list


element create case_create msg \
	-datatype text \
	-widget textarea \
	-label "Comment" \
	-html { rows 10 cols 40 wrap physical }



# Get the case id an/or current values
if { [form is_request case_create] } {

    if { [string equal $is_edit t] } {

	# Get existing case assignments
	set case_id [element get_value case_create case_id]
 
	db_foreach get_key_id "" {
	    lappend case_values($transition_key) $party_id
	}

	foreach {transition_key party_id_list} [array get case_values] {
	    element set_properties case_create \
		    "${transition_key}_assign" \
		    -values $party_id_list 
	    element set_properties case_create \
		    "${transition_key}_assign_old" \
		    -value $party_id_list
	}

	# Get existing deadlines

	db_foreach get_key_deadline "" { 
	    element set_properties case_create \
		    "${transition_key}_deadline" \
		    -value [util::date acquire sql_date $deadline]
	}

    } else {
        set case_id [db_string get_case_id ""]
	element set_properties case_create case_id -value $case_id
    }
}

if { [form is_valid case_create] } {

    form get_values case_create item_id case_id is_edit transitions msg
    set creation_ip [ns_conn peeraddr]

    db_transaction {

        if { ![string equal $is_edit t] } {


            # create the workflow
            set case_id [db_exec_plsql new_case "begin :1 := workflow_case.new(
	    workflow_key  => 'publishing_wf', 
	    context_key   => NULL,
	    object_id     => :item_id,
	    creation_user => :user_id, 
	    creation_ip   => :creation_ip,
	    case_id       => :case_id
        ); 
        end;"]


            # make assignments for each transition
            foreach transition $transitions {
                foreach value [element get_values case_create \
                                   ${transition}_assign] {

#                     db_exec_plsql add_assignment "
# 		  begin
# 		  workflow_case.add_manual_assignment(
# 		      case_id        => :case_id,
# 		      transition_key => :transition,
# 		      party_id       => :value
# 		  );
# 		  end;
# 		"

                    db_exec_plsql add_assignment ""
                }

                set deadline [element get_value case_create \
                                  ${transition}_deadline]
                set dead_sql [util::date get_property sql_date $deadline]

                db_dml insert_deadlines "
	      insert into wf_case_deadlines (
	        case_id, workflow_key, transition_key, deadline
	      ) values (
	        :case_id, 'publishing_wf', :transition, $dead_sql
	      )"
            }
        } else {

            # Modify the workflow
            foreach transition $transitions {
                set new_values \
		    [element get_values case_create ${transition}_assign]
                set old_values \
		    [element get_value case_create ${transition}_assign_old]

                # Remove cleared values
                if { [llength $old_values] > 0 } {
                    
                    set query "
		  delete from 
		    wf_case_assignments 
                  where 
	            workflow_key = 'publishing_wf' 
                  and 
	            transition_key = :transition
	          and 
	            case_id = :case_id
                  and 
	            party_id in ([join $old_values ,])"

                    if { [llength $new_values] > 0 } { 
                        append query " and party_id not in ([join $new_values ,])"
                    }
                    db_dml delete_assignments $query
                }
                
                # Update existing deadlines
                set new_deadline \
		    [element get_value case_create ${transition}_deadline] 
                set new_dead_sql [util::date get_property sql_date $new_deadline]
                db_dml update_deadlines "
	      update 
	        wf_case_deadlines 
	      set
	        deadline = $new_dead_sql
	      where
	        workflow_key = 'publishing_wf' 
	      and 
	        transition_key = :transition
	      and 
	        case_id = :case_id"   

                # Insert new values
                foreach new_value $new_values {
                    if { [lsearch $old_values $new_value] == -1 } {

                        db_exec_plsql add_new_assignment "
		      begin
	    	      workflow_case.add_manual_assignment(
		          case_id         => :case_id,
	                  transition_key  => :transition,
	                  party_id        => :new_value
		      );
		      end;
		    "
                    }         
                }
            }
        }

        # enable the transitions (insert tasks for each transition)
        db_exec_plsql start_case "
      begin
      workflow_case.start_case(
          case_id       => :case_id,
          creation_user => :user_id,
          creation_ip   => :creation_ip,
          msg           => :msg
      );
      end;
    "

        # email notifications of task assignments
        workflow::notify_of_assignments $case_id $user_id

    }

    # Flush the access cache in order to clear permissions
    content::flush_access_cache $item_id

    template::forward "../items/index?item_id=$item_id"
}
