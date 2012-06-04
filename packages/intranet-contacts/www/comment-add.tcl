ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$


} {
    {comment ""}
    {comment_id:integer ""}
    {party_id:integer}
    {return_url ""}
} -validate {
    contact_exists -requires {party_id} {
	if { ![contact::exists_p -party_id $party_id] && ![ad_form_new_p -key party_id] } {
	    ad_complain "[_ intranet-contacts.lt_The_contact_specified]"
	}
    }
}
contact::require_visiblity -party_id $party_id

if { ![exists_and_not_null comment_id] } {
    set comment_id [db_nextval acs_object_id_seq]
}
# check to see if the user can create comments on this object
#ad_require_permission $object_id general_comments_create

# insert the comment into the database
set creation_user [ad_conn user_id]
set creation_ip [ad_conn peeraddr]
set context_id $party_id
set comment_mime_type "text/plain"
set title ""
if { [string trim $comment] != "" } {
    db_transaction {
	set message_id [db_exec_plsql insert_comment {
	    select acs_message__new (
				     :comment_id,		-- 1  p_message_id
				     NULL, 			-- 2  p_reply_to
				     current_timestamp,	        -- 3  p_sent_date
				     NULL, 			-- 4  p_sender
				     NULL,			-- 5  p_rfc822_id
				     :title,		        -- 6  p_title
				     NULL,			-- 7  p_description
				     :comment_mime_type,	-- 8  p_mime_type
				     :comment,        		-- 9  p_text
				     NULL, -- empty_blob(),	-- 10 p_data
				     0,			        -- 11 p_parent_id
				     :context_id,		-- 12 p_context_id
				     :creation_user,            -- 13 p_creation_user
				     :creation_ip,		-- 14 p_creation_ip
				     'acs_message',		-- 15 p_object_type
				     't'                        -- 16 p_is_live
				 )
	}]
	
	db_dml add_entry {
	    insert into general_comments
	    (comment_id,
	     object_id,
	     category)
	    values
	    (:comment_id,
	     :party_id,
	     null)
	}
    
    } on_error {
	ad_return_error "[_ intranet-contacts.Error]" $errmsg
    }
}
if { [string is false [exists_and_not_null return_url]] } {
    set return_url [contact::url -party_id $party_id]
}

ad_returnredirect -message "[_ intranet-contacts.Comment_Added]" $return_url
ad_script_abort


















ad_return_template
