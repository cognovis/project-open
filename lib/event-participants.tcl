# /intranet-events/lib/event-participants.tcl
#
# Variables from calling procedure:
# 	event_id
#	return_url

# ******************************************************
# Default & Security
# ******************************************************

set current_user_id [ad_maybe_redirect_for_registration]
im_event_permissions $current_user_id $event_id view read write admin
if {!$read} { return }

set current_url [im_url_with_query]
set form_mode "display"

# ******************************************************
# 
# ******************************************************

set participant_options [db_list_of_lists participant_options "
    	select	im_name_from_user_id(u.user_id),
		user_id
	from	users u,
		persons pe,
		parties pa,
		acs_rels r,
		im_biz_object_members bom,
		im_companies c
	where	u.user_id = pe.person_id and
		u.user_id = pa.party_id and
		r.object_id_two = u.user_id and
		r.object_id_one = c.company_id and
		r.rel_id = bom.rel_id and
		c.company_id in (
			select	object_id_two
			from	acs_rels
			where	object_id_one = :event_id     
		) and
		u.user_id not in (
			select	u.user_id
			from	users u,
				acs_rels r,
				im_biz_object_members bom
			where	r.rel_id = bom.rel_id and
				r.object_id_two = u.user_id and
				r.object_id_one = :event_id
		)
"]

# set participant_options [linsert $participant_options 0 [list "" ""]]


# ******************************************************
# Create the list of all attributes of the current type
# ******************************************************

list::create \
    -name participant_list \
    -multirow participant_list_multirow \
    -key company_id \
    -no_data "No participant associated yet" \
    -elements {
	first_names { 
	    label "First Name" 
	    link_url_col participant_url
	}
	last_name { 
	    label "Last Name" 
	    link_url_col participant_url
	}
	participant_status { 
	    label "Status" 
	    display_template {
		<select name=participant_status_id.@participant_list_multirow.participant_id@>
		<option value=[im_event_participant_status_reserved] @participant_list_multirow.reserved_enabled@>Reserved</option>
		<option value=[im_event_participant_status_confirmed] @participant_list_multirow.confirmed_enabled@>Confirmed</option>
		</select>
	    }
	}
	participant_delete {
	    label ""
	    display_template {
		<a href="@participant_list_multirow.delete_url@" class="button">#acs-kernel.common_Delete#</a>
	    }
	}
    } \
    -orderby {
	orderby {orderby first_names}
    } \
    -filters {
	form_mode {}
	event_id {}
    }


db_multirow -extend {participant_url company_url delete_url reserved_enabled confirmed_enabled} participant_list_multirow get_participants "
	select	*,
		u.user_id as participant_id,
		im_category_from_id(bom.member_status_id) as participant_status
	from	persons pe,
		parties pa,
		users u,
		acs_rels r,
		im_biz_object_members bom
	where	r.rel_id = bom.rel_id and
		r.object_id_two = u.user_id and
		r.object_id_one = :event_id and
		u.user_id = pe.person_id and
		u.user_id = pa.party_id and
		u.user_id in (
			select	member_id
			from	group_distinct_member_map
			where	group_id = [im_profile_customers]  
		)
	[template::list::orderby_clause -name participant_list -orderby]
" {
    set delete_url [export_vars -base "participant-del" { event_id user_id {return_url $current_url} }]
    set participant_url [export_vars -base "/intranet/users/view" { user_id {return_url $current_url} }]
    set reserved_enabled ""
    set confirmed_enabled ""
    if {[im_event_participant_status_reserved] == $member_status_id} { set reserved_enabled "selected" }
    if {[im_event_participant_status_confirmed] == $member_status_id} { set confirmed_enabled "selected" }
}
