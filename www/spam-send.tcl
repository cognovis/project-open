ad_page_contract {
    insert a spam message into spam_messages table.  Message will 
    be queued for sending by a sweeper procedure when the spam is confirmed.
} { 
    subject:notnull
    {body_plain:trim ""}
    {body_html:allhtml,trim ""}
    {upload_file ""}
    send_date_ansi:notnull
    send_time_12hr:notnull
    spam_id:naturalnum
    sql_query
    object_id
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set context [list "confirm"]

set user_id [ad_get_user_id]
set content_mime_type "text/html"
#double-click protection
set already_there [db_string spam_check_double_click " select count(1) from spam_messages where spam_id=:spam_id"]

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
# Send message
# ------------------------------------------------------
set ip_addr [ad_conn peeraddr]
db_foreach spam_full_sql "" {

    set content [subst $body_plain]
    set subject [subst $subject]
    set party_from [ad_get_user_id]
    set party_to $party_id

    
    # --------------------------------------------------------
    # send mail quest
    # --------------------------------------------------------

    set storage_type lob

    #We're doing a Mail Shot to these contacts

    db_transaction {
        if {![exists_and_not_null multipart_id]} {
        	ns_log notice "party to -----> $party_to"
		set from_addr [db_string some_sql "select email from parties where party_id = :party_from"]

		# create the multipart message ('multipart/mixed')
		set multipart_id [acs_mail_multipart_new -multipart_kind "mixed"]
		ns_log Notice "/intranet-spam/www/spam-send: multipart_id=$multipart_id"
		
		# create an acs_mail_body (with content_item_id = multipart_id )
		
		set body_id [acs_mail_body_new -header_subject $subject -content_item_id $multipart_id]
		
		ns_log Notice "/intranet-spam/www/spam-send: body_id=$body_id"

		set content_item_id [db_exec_plsql create_text_item {
			begin
				:1 := content_item.new (
				 name		=> :subject,
				 title		=> :subject,
				 mime_type	=> :content_mime_type,
				 text		=> :content);
			end;
		}]
		ns_log Notice "//intranet-spam/www/spam-send: content_item_id=$content_item_id"


		# add the content_item to the multipart email
		set sequence_num [acs_mail_multipart_add_content \
			-multipart_id $multipart_id \
			-content_item_id $content_item_id]

		# Attach the $upload_file if there was a file attached...
		if {![empty_string_p $upload_file]} {

			set subject "$subject-2"

			ns_log Notice "//intranet-spam/www/spam-send: Setting up the attachment content_item"
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
			ns_log Notice "//intranet-spam/www/spam-send: attachment_item_id=$attachment_item_id"


			ns_log Notice "//intranet-spam/www/spam-send: Setting up the attachment content_revision"
			set revision_id [db_exec_plsql create_revision "
			begin
			  :1 := content_revision.new(
		     		title 		=> :client_filename,
				mime_type	=> :guessed_file_type,
		        	data          => empty_blob(),
				item_id		=> :attachment_item_id,
		 		creation_user	=> :user_id,
				creation_ip	=> :ip_addr
		  	  );
			end;"]
			ns_log Notice "//intranet-spam/www/spam-send: revision_id=$revision_id"


			ns_log Notice "//intranet-spam/www/spam-send: Updating revision & making new content_revision the ACTIVE one"
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
		}

	}
	
	set to_addr [db_string "get to email" "select email from parties where party_id = :party_to" -default ""]
	
	ns_log notice "/intranet-spam/www/spam-send: to_addr='$to_addr'"

	# send to contacts
	set sql_string "
		insert into acs_mail_queue_outgoing
		 ( message_id, envelope_from, envelope_to )
		values
		 ( :mail_link_id, :from_addr, :to_addr )"

	
	
	#set to_addr "fraber@fraber.de"

	if {![empty_string_p $to_addr]} {
		ns_log notice "/intranet-spam/www/spam-send: Mailing contact '$to_addr' Begin "

		# queue it
		set mail_link_id [db_exec_plsql queue_the_mail {
			begin
				:1 := acs_mail_queue_message.new (
					null,             -- p_mail_link_id
					:body_id,         -- p_body_id
					null,             -- p_context_id
					sysdate,          -- p_creation_date
					:user_id,  	  -- p_creation_user
					:ip_addr,         -- p_creation_ip
					'acs_mail_link'   -- p_object_type
					);
			end;
		}]

		db_dml outgoing_queue $sql_string
		ns_log notice "/intranet-spam/www/spam-send: Mailing contact '$to_addr' End"
	}



	#set email_string [join $email_list "<br>\n"]
	#set email_count [llength $email_list]

   } on_error {
	ad_return_error "[_ parties-extension.unable_to_send_mailshot]" "<pre>$errmsg</pre>"
	ad_script_abort
   }
}


acs_mail_process_queue