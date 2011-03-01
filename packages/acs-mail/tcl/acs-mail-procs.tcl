ad_library {
    Utility procs for working with messages in acs-mail

    @author John Prevost <jmp@arsdigita.com>
    @creation-date 2001-01-11
    @cvs-id $Id: acs-mail-procs.tcl,v 1.4 2007/04/29 21:31:32 cvs Exp $
}

## Utility Functions ###################################################

# base64 encode a string

proc acs_mail_base64_encode {string} {
	if [nsv_get acs_mail ns_uuencode_works_p] {
		# ns_uuencode works - use it

		# split it into chunks of 48 chars and then encode it
		set length [string length $string]
		for { set i 0 } { [expr $i + 48 ] < $length } { incr i 48 } {
			append result "[ns_uuencode [string range $string $i [expr $i+47]]]\n"
		}
		append result [ns_uuencode [string range $string $i end]]
	} else {
		# ns_uuencode doesn't work - use the tcl version

		set i 0
		foreach char {A B C D E F G H I J K L M N O P Q R S T U V W X Y Z \
				a b c d e f g h i j k l m n o p q r s t u v w x y z \
				0 1 2 3 4 5 6 7 8 9 + /} {
			set base64_en($i) $char
			incr i
		}
    
		set result {}
		set state 0
		set length 0
		foreach {c} [split $string {}] {
			if { $length >= 60 } {
				append result "\n"
				set length 0
			}
			scan $c %c x
			switch [incr state] {
				1 {	append result $base64_en([expr {($x >>2) & 0x3F}]) }
				2 { append result \
						$base64_en([expr {(($old << 4) & 0x30) | (($x >> 4) & 0xF)}]) }
				3 { append result \
						$base64_en([expr {(($old << 2) & 0x3C) | (($x >> 6) & 0x3)}])
				append result $base64_en([expr {($x & 0x3F)}])
				incr length
				set state 0}
			}
			set old $x
			incr length
		}
		set x 0
		switch $state {
			0 { # OK }
			1 { append result $base64_en([expr {(($old << 4) & 0x30)}])== }
			2 { append result $base64_en([expr {(($old << 2) & 0x3C)}])=  }
		}
	}

    return $result
}

ad_proc -private acs_mail_set_content {
	{-body_id:required}
	{-header_subject ""}
	{-creation_user ""}
	{-creation_ip ""}
    {-content:required}
    {-content_type:required}
    {-nls_language}
    {-searchable_p}
} {
    Create a cr_item, cr_revision and set it live.  Utility function.
} {
    if ![info exists nls_language] {
        set nls_language [db_null]
    }
    if ![info exists searchable_p] {
        set searchable_p "f"
    }

    set item_id [db_exec_plsql insert_new_content "
 		begin
		  return content_item__new(
		    varchar 'acs-mail message $body_id',  -- new__name
		    null,                     -- new__parent_id
		    null,                     -- new__item_id
		    null,                     -- new__locale
		    now(),                    -- new__creation_date
		    :creation_user,           -- new__creation_user
		    null,                     -- new__context_id
		    :creation_ip,             -- new__creation_ip
		    'content_item',           -- new__item_subtype
		    'content_revision',       -- new__content_type
		    :header_subject,          -- new__title
		    null,                     -- new__description
		    :content_type,            -- new__mime_type
		    :nls_language,            -- new__nls_language
		    :content,                 -- new__text
		    'text'                    -- new__storage_type
	      );
		end;"
	]
	
	set revision_id [db_exec_plsql get_latest_revision "
	    begin
		  return content_item__get_latest_revision ( :item_id );
	    end;"
	]

	db_exec_plsql set_live_revision "select content_item__set_live_revision(:revision_id)"

    return $item_id
}

ad_proc -private acs_mail_set_content_file {
	{-body_id:required}
	{-header_subject ""}
	{-creation_user ""}
	{-creation_ip ""}
    {-content_file:required}
    {-content_type:required}
    {-nls_language}
    {-searchable_p}
} {
    Set the acs_contents info for an object.  Utility function.
} {
    if ![info exists nls_language] {
        set nls_language [db_null]
    }
    if ![info exists searchable_p] {
        set searchable_p "t"
    }

    set item_id [db_exec_plsql insert_new_content "
 		begin
		  return content_item__new(
		    varchar 'acs-mail message $body_id', -- new__name
		    null,                     -- new__parent_id
		    null,                     -- new__item_id
		    null,                     -- new__locale
		    now(),                    -- new__creation_date
		    :creation_user,           -- new__creation_user
		    null,                     -- new__context_id
		    :creation_ip,             -- new__creation_ip
		    'content_item',           -- new__item_subtype
		    'content_revision',       -- new__content_type
		    :header_subject,          -- new__title
		    null,                     -- new__description
		    :content_type,            -- new__mime_type
		    :nls_language,            -- new__nls_language
		    null,                     -- new__text
		    'file'                    -- new__storage_type
	      );
		end;"
	]
	
	set revision_id [db_exec_plsql get_latest_revision "
	    begin
		  return content_item__get_latest_revision ( :item_id );
	    end;"
	]

	db_exec_plsql set_live_revision "select content_item__set_live_revision(:revision_id)"

	db_dml update_content {
        update cr_revisions
            set content = empty_blob()
            where revision_id = :revision_id
            returning content into :1
    } -blob_files [list $content_file]
		
	return $item_id
		
}

ad_proc -private acs_mail_uuencode_file {
	file_path
} {
	Base64 encode binary content from a file
} {
	set fd [open "$file_path" r]
	fconfigure $fd -encoding binary
	set file_input [read $fd]
	close $fd

	return [acs_mail_base64_encode $file_input]
}


ad_proc -private acs_mail_encode_content {
    content_item_id
} {
    ns_log Debug "acs-mail: encode: starting $content_item_id"
    # What sort of content do we have?
    if ![acs_mail_multipart_p $content_item_id] {

	ns_log Debug "acs-mail: encode: one part $content_item_id"
        # Easy as pie.
        # Let's get the data.

	# vinodk: first get the latest revision
	set revision_id [db_exec_plsql get_latest_revision "
	      begin
		    return content_item__get_latest_revision ( :content_item_id );
	      end;"
	]
	
	set storage_type [db_string get_storage_type "
		select storage_type 
		from cr_items 
		where item_id = :content_item_id
	"]
		
	if [db_0or1row acs_mail_body_to_mime_get_content_simple {
		select content, mime_type as v_content_type
		from cr_revisions
		where revision_id = :revision_id
	}] {
	    if [string equal $storage_type text] {
		ns_log Debug "acs-mail: encode: one part hit $content_item_id"
		return [list $v_content_type $content]
	    } else {
		# this content is in the file system or a blob
		ns_log Debug "acs-mail: encode: binary content $content_item_id"

		if  [string equal $storage_type file] {
		    ns_log Debug "acs-mail: encode: file $content_item_id"
		    set encoded_content [acs_mail_uuencode_file [cr_fs_path]$content]
		} else {
		    ns_log Debug "acs-mail: encode: lob $content_item_id"
		    # Blob. Now we need to decide if this is binary
		    # so we can uuencode it if necessary.
		    # We'll use the mime type to decide
		    
		    if { [string first "text" $v_content_type] == 0 } {
			ns_log Debug "acs-mail: encode: plain content"
			set encoded_content "$content"
		    } else {
			# binary content - copy the blob to temp file
			# that we will then uuencode
			set file [ns_tmpnam]
			db_blob_get_file copy_blob_to_file "
			    select r.content, i.storage_type 
			    from cr_revisions r, cr_items i 
			    where r.revision_id = $revision_id and
			          r.item_id = i.item_id " -file $file
			ns_log Debug "acs-mail: encode: binary content"
			set encoded_content [acs_mail_uuencode_file $file]
		    }
		}
		
		return [list $v_content_type $encoded_content]
	    }
	}

    } else {

	# This is a multipart item.
	# Harder.  Oops.
	ns_log Debug "acs-mail: encode: multipart $content_item_id"
	set boundary "=-=-="
	set contents {}
	# Get the component pieces
	set multipart_list [db_list_of_lists acs_mail_body_to_mime_get_contents {
		select mime_filename, mime_disposition, content_item_id as ci_id
		from acs_mail_multipart_parts
		where multipart_id = :content_item_id
		order by sequence_number
	}]
	
	if ![empty_string_p $multipart_list] {
	    foreach multipart_item $multipart_list {
		set mime_filename [lindex $multipart_item 0]
		set mime_disposition [lindex $multipart_item 1]
		set ci_id [lindex $multipart_item 2]
		
		if {[string equal "" $mime_disposition]} {
		    if {![string equal "" $mime_filename]} {
			set mime_disposition "attachment; filename=$mime_filename"
		    } else {
			set mime_disposition "inline"
		    }
		} else {
		    if {![string equal "" $mime_filename]} {
			set mime_disposition \
			    "$mime_disposition; filename=$mime_filename"
		    }
		}
		set content [acs_mail_encode_content $ci_id]
		while {[regexp -- "--$boundary--" $content]} {
		    set boundary "=$boundary"
		}
		lappend contents [list $mime_disposition $content]
	    }

	} else {

	    # Defaults
	    return {
		"text/plain; charset=us-ascii"
		"An OpenACS object was unable to be encoded here.\n"
	    }
	}
		
	set content_type \
	    "multipart/[acs_mail_multipart_type $content_item_id]; boundary=\"$boundary\""
	set content ""
	foreach {cont} $contents {
	    set c_disp [lindex $cont 0]
	    set c_type [lindex [lindex $cont 1] 0]
	    set c_cont [lindex [lindex $cont 1] 1]
	    append content "--$boundary\n"
	    append content "Content-Type: $c_type\n"
	    if { [string first "text" $c_type] != 0 } {
		# not a text item: therefore base64
		append content "Content-Transfer-Encoding: base64\n"
	    }
	    append content "Content-Disposition: $c_disp\n"
	    append content "\n"
	    append content $c_cont
	    append content "\n\n"
	}
	append content "--$boundary--\n"
	return [list $content_type $content]
    }
    
    # Defaults
    return {
	"text/plain; charset=us-ascii"
	"An OpenACS object was unable to be encoded here.\n"
    }
}

ad_proc -private acs_mail_body_to_output_format {
    {-body_id ""}
    {-link_id ""}
} {
    This will return the given mail body (or the mail body associated with the
    given link) as a properly MIME formatted message.

    Actually, the result will be in the form:

    [list $to $from $subject $body $extraheaders]

    so the info can easily be handed to ns_sendmail (for now.)
} {
    if [string equal $body_id ""] {
        db_1row acs_mail_body_to_mime_get_body {
            select body_id from acs_mail_links where mail_link_id = :link_id
        }
    }   
    db_1row acs_mail_body_to_mime_data {
        select header_message_id, header_reply_to, header_subject,
               header_from, header_to, content_item_id
            from acs_mail_bodies
            where body_id = :body_id
    }
    set headers [ns_set new]
    ns_set put $headers "Message-Id" "<$header_message_id>"
	# taking these out because they are redundant and 
	# could conflict with the values in acs_mail_queue_outgoing
#    if ![string equal $header_to ""] {
#        ns_set put $headers "To" $header_to
#    }
#    if ![string equal $header_from ""] {
#        ns_set put $headers "From" $header_from
#    }
    if ![string equal $header_reply_to ""] {
        ns_set put $headers "In-Reply-To" $header_reply_to
    }
    ns_set put $headers "MIME-Version" "1.0"
    set contents [acs_mail_encode_content $content_item_id]
    set content_type [lindex $contents 0]
    set content [lindex $contents 1]
    ns_set put $headers "Content-Type" "$content_type"
    ns_set put $headers "Content-Encoding" "7bit"

    db_foreach acs_mail_body_to_mime_headers {
        select header_name, header_content from acs_mail_body_headers
            where body_id = :body_id
    } {
        ns_set put $headers $header_name $header_content
    }

    return [list $header_to $header_from $header_subject $content $headers]
}

ad_proc -private acs_mail_process_queue {
} {
    Process the outgoing message queue.
} {
    db_foreach acs_message_send {
	select	message_id, 
		envelope_from,
		envelope_to
	from
		acs_mail_queue_outgoing
	LIMIT 700
    } {
        set to_send [acs_mail_body_to_output_format -link_id $message_id]
	set to_send_2 [list $envelope_to $envelope_from [lindex $to_send 2] [lindex $to_send 3] [lindex $to_send 4]]
	ns_log notice "acs_mail_process_queue: to_send_2=$to_send_2"

        if [catch {
            eval ns_sendmail $to_send_2
        } errMsg] {
            ns_log "Notice" "acs_mail_process_queue: failure: $errMsg"
        } else {
            db_dml acs_message_delete_sent {
                delete from acs_mail_queue_outgoing
                    where message_id = :message_id
                        and envelope_from = :envelope_from
                        and envelope_to = :envelope_to
            }
        }    
    }
    ns_log Debug "acs_mail_process_queue: cleaning up"
    # All done.  Delete dangling links.
    db_dml acs_message_cleanup_queue {
        delete from acs_mail_queue_messages
            where message_id not in
                    (select message_id from acs_mail_queue_outgoing)
                and message_id not in
                    (select message_id from acs_mail_queue_incoming)
    }
    ns_log Debug "acs_mail_process_queue: done cleaning up"
}

## Basic API ###########################################################

  ## acs_mail_content

ad_proc -private acs_mail_content_new {
	{-body_id:required}
    {-creation_user ""}
    {-creation_ip ""}
	{-header_subject ""}
    {-content}
    {-content_file}
    {-content_type ""}
} {
    Create a new CR item (to contain text/plain, or text/html,
    for example.)  If content is given, its text is used to make a
    content entry.  Otherwise, if content_file is given, that file is
    read to make a content entry.

    If there's a more specific way to make the object you want, best to
    use it.  This is for types of files that have no object types of their
    own.
} {
    if [info exists content] {
        set item_id [acs_mail_set_content -body_id $body_id \
				-header_subject $header_subject \
				-creation_user $creation_user -creation_ip $creation_ip \
				-content $content -content_type $content_type]
    } elseif [info exists content_file] {
        set item_id [acs_mail_set_content_file -body_id $body_id \
				-header_subject $header_subject \
				-creation_user $creation_user -creation_ip $creation_ip \
				-content_file $content_file -content_type $content_type]
    }

    return $item_id
}

  ## acs_mail_body

ad_proc -public acs_mail_body_new {
    {-body_id ""}
    {-body_reply_to ""}
    {-body_from ""}
    {-body_date ""}
    {-header_message_id ""}
    {-header_reply_to ""}
    {-header_subject ""}
    {-header_from ""}
    {-header_to ""}
    {-content_item_id ""}
    {-creation_user ""}
    {-creation_ip ""}
    {-content}
    {-content_file}
    {-content_type ""}
} {
    Create a new mail body object from whole cloth.
    If content or content_file is supplied, a content object will
    automatically be created and set as the content object for the new body.
} {
	set body_id [db_exec_plsql acs_mail_body_new {
        begin
            :1 := acs_mail_body.new (
                body_id => :body_id,
                body_reply_to => :body_reply_to,
                body_from => :body_from,
                body_date => :body_date,
                header_message_id => :header_message_id,
                header_reply_to => :header_reply_to,
                header_subject => :header_subject,
                header_from => :header_from,
                header_to => :header_to,
                content_item_id => :content_item_id,
                creation_user => :creation_user,
                creation_ip => :creation_ip
            );
        end;
    }]

    if {[info exists content]} {
        set content_item_id \
            [acs_mail_content_new -body_id $body_id \
                 -creation_user $creation_user -creation_ip $creation_ip \
				 -header_subject $header_subject \
                 -content $content -content_type $content_type]
    } elseif {[info exists content_file]} {
        set content_item_id \
            [acs_mail_content_new -body_id $body_id \
                 -creation_user $creation_user -creation_ip $creation_ip \
				 -header_subject $header_subject \
                 -content_file $content_file -content_type $content_type]
    }

	acs_mail_body_set_content_object -body_id $body_id \
			-content_item_id $content_item_id

    return $body_id
}

ad_proc -public acs_mail_body_p {
    {object_id}
} {
    Returns 1 if the argument is an ID for a valid acs_mail_body object.
} {
    return [string equal "t" [db_exec_plsql acs_mail_body_p {
        begin
            :1 := acs_mail_body.body_p (:object_id);
        end;
    }]]
}

ad_page_contract_filter acs_mail_body_id { name value } {
    Checks whether the value (assumed to be an integer) is the id
    of an already-existing acs_mail_body
} {
    # empty is okay (handled by notnull)
    if [empty_string_p $value] {
        return 1
    }
    if ![acs_mail_body_p $value] {
        ad_complain "$name does not refer to a valid OpenACS Mail body"
        return 0
    }
    return 1
}

ad_proc -public acs_mail_body_clone {
    {-old_body_id:required}
    {-body_id ""}
    {-creation_user ""}
    {-creation_ip ""}
} {
    Clone a mail body.  This is a very appropriate thing to do if you're
    going to make changes.  If you want changes to be shared between
    systems that share the message, change in place.  If you don't want
    them to be shared, clone first.
} {
    return [db_exec_plsql acs_mail_body_clone {
        begin
            :1 := acs_mail_body.clone (
                old_body_id => :old_body_id,
                body_id => :body_id,
                creation_user => :creation_user,
                creation_ip => :creation_ip
            );
        end;
    }]
}

ad_proc -public acs_mail_body_set_content_object {
    {-body_id:required}
    {-content_item_id:required}
} {
    Sets the content item of the given mail body.
} {
    db_exec_plsql acs_mail_body_set_content_object {
        begin
            :1 := acs_mail_body.set_content_object (
                body_id => :body_id,
                content_item_id => :content_item_id
            );
        end;
    }
}

  ## acs_mail_multipart

ad_proc -public acs_mail_multipart_new {
    {-multipart_id ""}
    {-multipart_kind:required}
    {-creation_user ""}
    {-creation_ip ""}
} {
    Create a new MIME multipart object.  The kind of multipart is required.
    The kinds of multiparts I currently know about are:

    mixed: attachments of various content_types which can either be inline
           or presented as files to save.

    alternative: multiple versions of one document, from which the best
           should be chosen.  This is how text + html mail is sent.

    signed: the first sub-part is a document.  The second is a digital
           signature in some format.
} {
    return [db_exec_plsql acs_mail_multipart_new {
        begin
            :1 := acs_mail_multipart.new (
                multipart_id => :multipart_id,
                multipart_kind => :multipart_kind,
                creation_user => :creation_user,
                creation_ip => :creation_ip
            );
        end;
    }]
}

ad_proc -public acs_mail_multipart_type {
    {object_id}
} {
    Returns the subtype of the multipart.
} {
    db_1row acs_mail_multipart_type {
	select multipart_kind from acs_mail_multiparts
	    where multipart_id = :object_id
    }
    return $multipart_kind;
}

ad_proc -public acs_mail_multipart_p {
    {object_id}
} {
    Returns 1 if the argument is an ID for a valid acs_mail_multipart object.
    Useful for determining whether a body's content is a multipart or a single
    content object.
} {
    return [string equal "t" [db_exec_plsql acs_mail_multipart_p {
        begin
            :1 := acs_mail_multipart.multipart_p (:object_id);
        end;
    }]]
}

ad_page_contract_filter acs_mail_multipart_id { name value } {
    Checks whether the value (assumed to be an integer) is the id
    of an already-existing acs_mail_multipart
} {
    # empty is okay (handled by notnull)
    if [empty_string_p $value] {
        return 1
    }
    if ![acs_mail_multipart_p $value] {
      ad_complain "$name does not refer to a valid OpenACS Mail multipart"
      return 0
    }
    return 1
}

ad_proc -public acs_mail_multipart_add_content {
    {-multipart_id:required}
    {-content_item_id:required}
} {
    Add a new item to a given multipart object at the end.
} {
    return [db_exec_plsql acs_mail_multipart_add_content {
        begin
            :1 = acs_mail_multipart.add_content (
                multipart_id => :multipart_id,
                content_item_id => :content_item_id
            );
        end;
    }]
}

  ## acs_mail_link

ad_proc -public acs_mail_link_new {
    {-mail_link_id ""}
    {-body_id}
    {-creation_user ""}
    {-creation_ip ""}
    {-context_id ""}
    {-content}
    {-content_item_id}
    {-content_file}
    {-content_type ""}
} {
    Create a new mail link object.  Strictly speaking, applications should
    subclass acs_mail_link and use their own types.  This is provided as
    a tool for prototyping.
} {
    if {[info exists body_id]} {
        # use it
    } elseif {[info exists content]} {
        set body_id [acs_mail_body_new -creation_user $creation_user \
                         -creation_ip $creation_ip -content $content \
                         -content_type $content_type]
    } elseif {[info exists content_file]} {
        set body_id [acs_mail_body_new -creation_user $creation_user \
                         -creation_ip $creation_ip -content_file $content \
                         -content_type $content_type]
    } elseif {[info exists content_item_id]} {
        set body_id [acs_mail_body_new -creation_user $creation_user \
                         -creation_ip $creation_ip \
						 -content_item_id $content_item_id]
    } else {
        # Uh oh...  Use a blank one, I guess.  Not so good.
        set body_id [acs_mail_body_new -creation_user $creation_user \
                         -creation_ip $creation_ip]
    }
    return [db_exec_plsql acs_mail_link_new {
        begin
            :1 := acs_mail_link.new (
                mail_link_id => :mail_link_id,
                body_id => :body_id,
                context_id => :context_id,
                creation_user => :creation_user,
                creation_ip => :creation_ip
            );
        end;
    }]
}

ad_proc -public acs_mail_link_get_body_id {
    {link_id}
} {
    Returns the object_id of the acs_mail_body for this mail link.
} {
    return [db_string acs_mail_link_get_body_id {
		select body_id from acs_mail_links where mail_link_id = :link_id
    }]
}

ad_proc -public acs_mail_link_p {
    {object_id}
} {
    Returns 1 if the argument is an ID for a valid acs_mail_link object.
} {
    return [string equal "t" [db_exec_plsql acs_mail_link_p {
        begin
            :1 := acs_mail_link.link_p (:object_id);
        end;
    }]]
}

ad_page_contract_filter acs_mail_link_id { name value } {
    Checks whether the value (assumed to be an integer) is the id
    of an already-existing acs_mail_link
} {
    # empty is okay (handled by notnull)
    if [empty_string_p $value] {
        return 1
    }
    if ![acs_mail_link_p $value] {
      ad_complain "$name does not refer to a valid OpenACS Mail link"
      return 0
    }
    return 1
}

