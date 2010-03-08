ad_page_contract {
    Send out spam messages.

    This process is surprisingly complicated. It proceeds in
    three major steps:

    1. The email is set up
    2. The email is queued for delivery and
    3. The email is sent out.

    Here are the details:

    1.1. A "Multipart" item is created. This item is a kind of
         container for the various MIMI "multiparts" of the email
         (attachments, ...)
    1.2. A "Mail Body" item is created, holding header_to and
         header_from information, but no contents.
    1.3. The "mail_body.content_item" is set to the Multipart container
    1.4. A Content Repository Item (cr_item) is created.
    1.5. A Content Repository "Revision" (cr_revision) is created.
         Such a revision is a version of the content of the cr_item.
    1.6. The cr_revision is set as the "current" and "last" cr_revision
         of the cr_item.
    1.7. A "Multipart Part" relation is set up between
    ...


    Insert a spam message into spam_messages table.  Message will 
    be queued for sending by a sweeper procedure when the spam is confirmed.
} { 
    subject:allhtml,trim
    {body_plain:allhtml,trim ""}
    {body_html:allhtml,trim ""}
    {upload_file ""}
    send_date_ansi:notnull
    send_time_12hr:notnull
    spam_id:naturalnum
    selector_id:integer
    object_id
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set context [list "confirm"]
set user_id [ad_get_user_id]
# set content_mime_type "text/html"
set content_mime_type "text/plain"

set rows [db_0or1row selector_info "
	select	short_name as selector_short_name,
		selector_sql as sql_query
	from	im_sql_selectors 
	where	selector_id=:selector_id
"]

if {0 == $rows} {
    ad_return_complaint 1 "We didn't find the SQL Selector #$selector_id"
    return
}

#double-click protection
set already_there [db_string spam_check_double_click "
	select count(1) 
	from spam_messages 
	where spam_id=:spam_id
"]

if {$already_there} {
    ad_return_complaint 1 "This message has already been queued for sending.
    You can <a href=\"spam-edit?spam_id=$spam_id\">edit it</a> if you wish."
    return
}

# make sure spam cannot be sent by regular user
set approved_p "f"

# consider a user to be an admin if he is an admin for the object_id
# or if he is an admin for the spam package

if {$object_id != "" && [ad_permission_p $object_id "admin"]} {
    set approved_p "t"
} elseif {$object_id == "" && [ad_permission_p [ad_conn package_id] "admin"]} {
    set approved_p "t"
} 

# ------------------------------------------------------
# check file upload
# ------------------------------------------------------
#if {![empty_string_p $upload_file]} {
#	set tmp_size [file size ${upload_file.tmpfile}]
#	set max_file_size [ad_parameter MaxFileSize {general-comments} {0}]
#	if { $tmp_size > $max_file_size && $max_file_size > 0 } {
#		ad_complain "[_ general-comments.lt_Your_file_is_too_larg]  [_ general-comments.The_publisher_of] [ad_system_name] [_ general-comments.lt_has_chosen_to_limit_a] [util_commify_number $max_file_size] [_ general-comments.bytes].\n"
#	}
#	if { $tmp_size == 0 } {
#		ad_complain "[_ general-comments.lt_Your_file_is_zero-len]\n"
#	}
#
#	set allow_files_p [ad_parameter AllowFileAttachmentsP {general-comments} {t}]
#	if { $allow_files_p != "t" } {
#		ad_complain "[_ general-comments.lt_Attaching_files_to_co]"
#	}
#}

# -----------------------------------------------------------------
# Process the attached file (if any)
# -----------------------------------------------------------------
set tmp_file [ns_queryget upload_file.tmpfile]
im_security_alert_check_tmpnam -location "spam-send.tcl" -value $tmp_file

set tmp_size [file size $tmp_file]
if {![empty_string_p $upload_file]} {

	#title The title of the file attachment
	set title "Attached file"
  	
	# get the file extension
	set tmp_filename $tmp_file
	set file_extension [string tolower [file extension $upload_file]]

	# remove the first . from the file extension
	regsub {\.} $file_extension "" file_extension
	set guessed_file_type [cr_filename_to_mime_type -create $upload_file]

	# strip off the C:\directories... crud and just get the file name
	if ![regexp {([^/\\]+)$} $upload_file match client_filename] {
		# couldn't find a match
		set client_filename $upload_file
	}
	#make unique name - otherwise fails if try and upload same file
	set run_id [db_nextval acs_object_id_seq]
	set unique_client_filename "$run_id-$client_filename"

	set what_aolserver_told_us ""
	if { $file_extension == "jpeg" || $file_extension == "jpg" } {
		catch { set what_aolserver_told_us [ns_jpegsize $tmp_filename] }
	} elseif { $file_extension == "gif" } {
		catch { set what_aolserver_told_us [ns_gifsize $tmp_filename] }
	}

	# the AOLserver jpegsize command has some bugs where the height comes
	# through as 1 or 2
	if { ![empty_string_p $what_aolserver_told_us] && [lindex $what_aolserver_told_us 0] > 10 && [lindex $what_aolserver_told_us 1] > 10 } {
		set original_width [lindex $what_aolserver_told_us 0]
		set original_height [lindex $what_aolserver_told_us 1]
	} else {
		set original_width ""
		set original_height ""
	}
}


# ------------------------------------------------------
# Send messages
# ------------------------------------------------------
set ip_addr [ad_conn peeraddr]
db_foreach spam_full_sql "" {

    # Calculate some additional variables to be used
    # in the substitution process
    set auto_login [im_generate_auto_login -user_id $person_id]
    
    set party_from [ad_get_user_id]
    set party_to $person_id

    # Substitute <...> elements
    set key_list [list user_id first_names last_name email auto_login]
    set value_list [list $person_id $first_names $last_name $email $auto_login]

    set body_plain_subs $body_plain
    foreach key $key_list value $value_list {
	regsub -all "<$key>" $body_plain_subs $value body_plain_subs
    }

    set body_html_subs $body_html
    foreach key $key_list value $value_list {
	regsub -all "<$key>" $body_html_subs $value body_html_subs
    }

    set subject_subs $subject
    foreach key $key_list value $value_list {
	regsub -all "<$key>" $subject_subs $value subject_subs
    }

    set content $body_plain_subs
    set content_subs $body_plain_subs


    # --------------------------------------------------------
    # send mail quest
    # --------------------------------------------------------

     

    # [kh] Quickfix - attachement will not be used anyway ...
    # set storage_type lob
    set storage_type "lob"
    db_transaction {

	if {1} {

	ns_log notice "party to -----> $party_to"
	set from_addr [db_string some_sql "select email from parties where party_id = :party_from"]

	# create the multipart message ('multipart/mixed')
	set multipart_id [acs_mail_multipart_new -multipart_kind "mixed"]
	ns_log Notice "spam-send: multipart_id=$multipart_id"
	
	# create an acs_mail_body (with content_item_id = multipart_id )
	set body_id [acs_mail_body_new -header_subject $subject_subs -content_item_id $multipart_id]
	ns_log Notice "spam-send: body_id=$body_id"

	# We need a unique name for each cr_item
	set cr_item_name "$subject_subs $party_id"

	set content_item_id [db_exec_plsql create_text_item {
		begin
			:1 := content_item.new (
			 name		=> :subject_subs,
			 title		=> :subject_subs,
			 mime_type	=> :content_mime_type,
			 text		=> :content);
		end;
	}]
	ns_log Notice "spam-send: content_item_id=$content_item_id"

	# add the content_item to the multipart email
	set sequence_num [acs_mail_multipart_add_content \
		-multipart_id $multipart_id \
		-content_item_id $content_item_id]

	# Attach the $upload_file if there was a file attached...
	if {![empty_string_p $upload_file]} {
		set subject "$subject_subs-2"

		ns_log Notice "spam-send: Setting up the attachment content_item"
		set content_file_stream "[open $tmp_file "r"]"
		set content_file [read $content_file_stream]
		ns_log "notice" "contnet_file -----> $content_file"
		set attachment_item_id [db_exec_plsql create_file_item "
			begin
				:1 := content_item.new (
				 name		=> :unique_client_filename,
				 title		=> :client_filename,
				 mime_type	=> :guessed_file_type,
				 storage_type	=> :storage_type
				);
			end;
		"]
		ns_log Notice "spam-send: attachment_item_id=$attachment_item_id"


		ns_log Notice "spam-send: Setting up the attachment content_revision"
		set revision_id [db_exec_plsql create_revision "
		begin
		  :1 := content_revision.new(
	     		title 		=> :client_filename,
			mime_type	=> :guessed_file_type,
			data	  => empty_blob(),
			item_id		=> :attachment_item_id,
	 		creation_user	=> :user_id,
			creation_ip	=> :ip_addr
	  	  );
		end;"]
		ns_log Notice "spam-send: revision_id=$revision_id"


		ns_log Notice "spam-send: Updating revision & making new content_revision the ACTIVE one"
		# set this revision to be the live one
		db_exec_plsql update_revision {
			begin
			    content_item.set_live_revision(:revision_id );
			end;
		}
		ns_log notice "*************** after update revision *********************"
		set tmp_filename [cr_create_content_file $attachment_item_id $revision_id $tmp_file]
		# Nesta specific tweak: Quest added file extensions to the CR
		# in order to allow to access files directly.
		append tmp_filename ".$file_extension"

      			# manually add the path to the newly created file
      			# to cr_revisions
		#db_dml update_revision_file "
		#	update cr_revisions set
		#	filename = :tmp_filename,
		#	content_length = :tmp_size
		#	where revision_id = :revision_id
		#"
		ns_log notice "*************** after update revision *********************"

		# add the content_item to the multipart email
		set sequence_num [acs_mail_multipart_add_content \
			-multipart_id $multipart_id \
			-content_item_id $attachment_item_id]
		
		db_dml update_multiparts "
			update acs_mail_multipart_parts
			set mime_disposition='attachment; filename=\"$client_filename\"'
			where sequence_number=:sequence_num
			and multipart_id=:multipart_id"

	# End attaching uploaded file
	}

    }
	

	# Now: Send out the mail
	#
	set to_addr [db_string "get to email" "select email from parties where party_id = :party_to" -default ""]
	
	ns_log notice "spam-send: to_addr='$to_addr'"

	# send to contacts
	set sql_string "
		insert into acs_mail_queue_outgoing
		 ( message_id, envelope_from, envelope_to )
		values
		 ( :mail_link_id, :from_addr, :to_addr )"

	
        # works until here
	if {![empty_string_p $to_addr]} {
		ns_log notice "spam-send: Mailing contact '$to_addr' Begin "

		# queue it
		set mail_link_id [db_exec_plsql queue_the_mail {
			begin
				:1 := acs_mail_queue_message.new (
					null,	     -- p_mail_link_id
					:body_id,	 -- p_body_id
					null,	     -- p_context_id
					sysdate,	  -- p_creation_date
					:user_id,  	  -- p_creation_user
					:ip_addr,	 -- p_creation_ip
					'acs_mail_link'   -- p_object_type
					);
			end;
		}]

		db_dml outgoing_queue $sql_string
		ns_log notice "spam-send: Mailing contact '$to_addr' End"


	        # Add a link from the users's business object to the mail link:
	        im_biz_object_add_role $party_id $mail_link_id [im_biz_object_role_email]
	}

   } on_error {
	ad_return_error "[_ parties-extension.unable_to_send_mailshot]" "<pre>$errmsg</pre>"
	ad_script_abort
   }
}


# Commented out - let's separate for the moment
#
acs_mail_process_queue