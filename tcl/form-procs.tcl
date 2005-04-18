namespace eval content {
    # namespace import seems to prevent content:: procs from being recognized
    # namespace import ::template::query ::template::form ::template::element
}


ad_proc -private content::query_form_metadata { 
    {datasource_name rows} 
    {datasource_type multirow}
    {extra_where {}} 
    {extra_orderby {}}
} {
    Helper proc: query out all the information neccessary to create
    a custom form element based on stored metadata
    Requires the variable content_type to be set in the calling frame
} {
    # query for all attribute widget param values associated with a content 
    #   the 3 nvl subqueries are necessary because we cannot outer join
    #   to more than one table without doing multiple subqueries (which is
    #   even less efficient than this way)

    set query [db_map attributes_query_1] 
    
    if { ![template::util::is_nil extra_where] } {      
        append query [db_map attributes_query_extra_where]
    }

    append query "
    order by
      attributes.tree_level, attributes.sort_order desc, 
      attributes.attribute_id, params.param_id"
    
    if { ![template::util::is_nil extra_orderby] } {
        append query ", $extra_orderby"
    }  
    if [string equal $datasource_type multirow] {
        uplevel "db_multirow $datasource_name get_form_metadata \{$query\}"
    } else {
        uplevel "set $datasource_name [db_list_of_lists get_form_metadata {}]"
    }

}

ad_proc -private content::assemble_form_element { 
    datasource_ref the_attribute_name start_row {db {}}
} {

    Process the query and assemble the "element create..." statement
    PRE:  uber-query has been run
    POST: html_params, code_params set; returns the index of the next
    available row

} {

    upvar "${datasource_ref}:rowcount" rowcount
    upvar code_params code_params
    upvar content_type content_type
    upvar opts opts

    set code_params   [list]
    set html_params   [list]

    # Process the results of the query. 
    for { set i $start_row } { $i <= $rowcount  } { incr i } {
        upvar "${datasource_ref}:${i}" q_row

        if { ![string equal $q_row(attribute_name) $the_attribute_name] } {
            break
        }

        template::util::array_to_vars q_row

        content::get_revision_create_element
    }
    set last_row $i

    # All the neccessary variables should still be set
    get_element_default_params

    # eval the last "element create" string
    if { [llength $html_params] } {
        # widget has html parameters
        lappend code_params -html $html_params
    }

    # Append any other parameters directly to the element create statement
    foreach name {content_type revision_id item_id} {
        if { [info exists opts($name)] } {
            unset opts($name)
        }
    }
    foreach name [array names opts] {
        lappend code_params "-${name}" $opts($name)
    }

    return $last_row
}


ad_proc -public content::create_form_element {
    form_name attribute_name args
} {

    Create a form widget based on the given attribute. Query parameters
    out of the database, override them with the passed-in parameters
    if they exist.
    If the -revision_id flag exists, fills in the value of the attribute from 
    the database, based on the given revision_id.
    If the -content_type flag exists, uses the attribute for the given content
    type (without inheritance). 
    If the -item_id flag is present, the live revision for the item will be 
    used.
    If the -item_id and the -revision_id flags are missing, the -content_type
    flag must be specified.
    Example: 
    content::create_form_element my_form width -revision_id $image_id -size 10
    This call will create an element representing the width attribute
    of the image type, with the textbox size set to 10 characters,
    and query the current value of the attribute out of the database.

} {
    template::util::get_opts $args

    # Get the revision id if the item id is specified, or if
    # it is passed in directly
    if { ![template::util::is_nil opts(revision_id)] } {
        set revision_id $opts(revision_id)
        
    } elseif { ![template::util::is_nil opts(item_id)] } {
        
        set item_id $opts(item_id)
        set revision_id [db_string get_revision_id ""]
    }

    if { [info exists opts(content_type)] } {
        # The type is known: use it
        set content_type $opts(content_type)
    } else {
        
        # Figure out the type based on revision_id
        if { ![info exists revision_id] } {
            template::request error invalid_element_flags "
         No revision_id, item_id or content_type specified in 
         content::create_form_element for attribute ${form_name}:${attribute_name}"
            return
        }
        
        set content_type [db_string get_content_type ""]
    }

    # Run the gigantic uber-query. This is somewhat wasteful; should
    # be replaced by 2 smaller queries: one for the attribute_id, one
    # for parameter types and values.
    query_form_metadata params multirow "attribute_name = :attribute_name"
    
    if { ${params:rowcount} < 1} {
        error "No widgets are registered for ${content_type}.${attribute_name}"
    }

    template::util::array_to_vars "params:1"
    assemble_form_element params $attribute_name 1

    # If the -revision_id switch exists, look up the existing value for the
    # element
    if { ![template::util::is_nil revision_id] && [lsearch $code_params "-value"] < 0 } {
        
        # Handle custom datatypes... Basically, this is done so that
        # the date widget will work :-/
        # In the future, upgrade the date widget and use acs_object.get_attribute

        switch $datatype {
            date {
                set what [db_map cfe_attribute_name_to_char]
            }

            default {
                set what [db_map cfe_attribute_name]
            }
        }
        
        set element [db_string get_element_value ""]

        lappend code_params -value $element_value -values [list $element_value]
    }

    set form_element "template::element create $form_name $attribute_name $code_params"
    if { ![string equal $is_required t] } {
        append form_element " -optional"
    }

    eval $form_element
}  


ad_proc -public content::get_revision_form { 
    content_type item_id form_name {show_sections t} {element_override {}}
} {

    generate a form based on metadata

} {

    # Convert overrides to an array
    array set overrides $element_override

    set last_type ""
    set last_attribute_name ""
    set new_section_p 1

    set code_params [list]
    set html_params [list]
    
    # Perform a gigantic query to retreive all metadata
    query_form_metadata

    # Process the results and create the elements
    for { set i 1 } { $i <= ${rows:rowcount} } { incr i } {
        upvar 0 "rows:${i}" row 
        template::util::array_to_vars row

        # make a new section in the form for each type in the content type hierarchy
        if { $new_section_p == 1 && [string equal $show_sections t]} {
            # put attributes for each supertype in their own section
	    template::form section $form_name $last_type
        }

        # check if attributes should be placed in a new content type section
        if { ! [string equal $type_label $last_type] } {
            set new_section_p 1
        } else {
            set new_section_p 0
        }


        # if the attribute is new
        if { ![string equal $last_attribute_name $attribute_name] } {

            # if this is a new attribute and it isn't the first attribute ( $i != 1 ), 
            #   then evaluate the current "element create" string, and reset the params lists
            if { $i != 1 } {

                if { [llength $html_params] } {
                    # widget has html parameters
                    lappend code_params -html $html_params
                }
                set form_element \
                    "template::element create $form_name $last_attribute_name $code_params"
                ns_log debug "content::get_revision_form: CREATING"
		ns_log debug "content::get_revision_form:   attribute : $last_attribute_name"
		ns_log debug "content::get_revision_form:   type_label: $last_type"
                eval $form_element
                
                set code_params [list]
                set html_params [list]
            }


            # start a new "element create" string
            get_element_default_params
        }

        # evaluate the param
        get_revision_create_element
        if { [info exists overrides($last_attribute_name)] } {
            set code_params [concat $code_params $overrides($last_attribute_name)]
	}

        set last_attribute_name $attribute_name
	set last_type $type_label
    }
    

    # eval the last "element create" string
    if { [llength $html_params] } {
        # widget has html parameters
        lappend code_params -html $html_params
    }

    set form_element "template::element create $form_name $last_attribute_name $code_params"
    ns_log debug "content::get_revision_form:   ELEMENT CREATE: $form_element"
    eval $form_element


    # add some default form elements
    eval template::element create $form_name content_type \
        -widget hidden -datatype keyword -value $content_type

    if { ![string equal $item_id ""] } {
        eval template::element create $form_name item_id \
            -widget hidden -datatype integer -value $item_id
    }
}


ad_proc -public content::get_element_default_params {} {

    PRE: requires datatype, widget, attribute_label, is_required code_params
    to be set in the calling frame
    
    POST: appends the list of params neccessary to create a new element to code_params

} {

    uplevel {
        lappend code_params -datatype $datatype -widget $widget \
            -label $attribute_label 
        if { [string equal $is_required "f"] } {
            lappend code_params -optional
        }
    }
}

ad_proc content::get_revision_create_element {} {

    PRE:  requires the following variables to be set in the uplevel scope:
    db, code_params, html_params, 
    attribute_id, attribute_name, datatype, is_html,
    param_source, param_type, value
    POST: adds params to the 'element create' command

} {
    upvar __sql sql
    set sql [db_map get_enum_1]
    
    uplevel {
        if { ![string equal $attribute_name {}] } {
            
            if { [string equal $is_html "t"] } {
                lappend html_params $param $value
            } else {
                
                # if datatype is enumeration, then query acs_enum_values table to
                # build the option list
                if { [string equal $datatype "enumeration"] } {

                    set options [db_list_of_list get_enum_values $__sql]
                    lappend code_params -options $options
                }
                
                # if param_source is not 'literal' then 
                # eval or query for the parameter value(s)

                if { ![string equal $param_source ""] } {
                    if { [string equal $param_source "eval"] } {
                        set source [eval $value]
                    } elseif { [string equal $param_source "query"] } {
                        switch $param_type {
                            onevalue {
                                set source [db_string revision_create_get_value $value]
                            }
                            onelist {
                                set source [db_list revision_create_get_value $value]
                            }
                            multilist {
                                set source [db_list_of_lists revision_create_get_value $value]
                            }
                            default {
                                error "invalid param_type"
                            }
                        }
                    } else {
                        set source $value
                    }
                    lappend code_params "-$param" $source
                }
            }
        }
    }
}


ad_proc -public content::process_revision_form { form_name content_type item_id {db{}} } {

    perform the appropriate DML based on metadata

} {

    template::form get_values $form_name title description mime_type

    # create the basic revision
    set revision_id [db_exec_plsql new_content_revision "
             begin
	     :1 := content_revision.new(
                 title         => :title,
                 description   => :description,
                 mime_type     => :mime_type,
                 text          => ' ',
                 item_id       => content_symlink.resolve(:item_id),
                 creation_ip   => '[ns_conn peeraddr]',
                 creation_user => [User::getID]
             );
        end;"]


    # query for extended attribute tables

    set last_table ""
    set last_id_column ""
    db_multirow rows get_extended_attributes ""

    for { set i 1 } { $i <= ${rows:rowcount} } { incr i } {
        upvar 0 "rows:${i}" row
        template::util::array_to_vars row

        ns_log debug "content::process_revision_form: attribute_name $attribute_name"
        ns_log debug "content::process_revision_form: table_name $table_name"
        
        if { ![string equal $last_table $table_name] } {
            if { $i != 1 } {                
                content::process_revision_form_dml
            }
            set columns [list]
            set values [list]
        }
        
        # fetch the value of the attribute from the form
        if { ![template::util::is_nil attribute_name] } {
            set $attribute_name [template::element::get_value \
                                     $form_name $attribute_name]

            lappend columns $attribute_name

            # If the attribute is a date, get the date
            if { [string equal $datatype date] } {
                set $attribute_name \
                    [template::util::date::get_property sql_date [set $attribute_name]]
                # Can't use bind vars because this will be a to_date call
                lappend values "[set $attribute_name]"
            } else {
                lappend values ":$attribute_name"
            }
        }
        set last_table $table_name
        set last_id_column $id_column
    }

    content::process_revision_form_dml

    return $revision_id
}

ad_proc -public content::process_revision_form_dml {} {

    helper function for process_revision_form
    PRE: the following variables must be set in the uplevel scope:
    columns, values, last_table

} {

    upvar last_table __last_table
    upvar columns __columns
    upvar values __values
    upvar __sql sql
    set sql [db_map insert_revision_form]
    
    uplevel {

        if { ! [string equal $last_table {}] } {
            lappend columns $last_id_column
            lappend values ":revision_id"

            db_dml insert_revision_form $__sql
        }
    }
}


ad_proc -public content::insert_element_data { 
    form_name content_type exclusion_list id_value \
        {suffix ""} {extra_where ""}
} {

    Perform an insert for some form, adding all attributes of a 
    specific type
    exclusion_list is a list of all object types for which the elements
    are NOT to be inserted
    id_value is the revision_id

} {

    set sql_exclusion [template::util::tcl_to_sql_list $exclusion_list]
    set id_value_ref id_value

    set query [db_map ied_get_objects_tree]
    
    if { ![template::util::is_nil extra_where] } {
	append query [db_map ied_get_objects_tree_extra_where]
    }

    append query [db_map ied_get_objects_tree_order_by]

    ns_log debug "content::insert_element_data: $query"
    
    set last_table ""
    set last_id_column ""
    db_multirow rows insert_element_data $query

    for { set i 1 } { $i <= ${rows:rowcount} } { incr i } {
        upvar 0 "rows:${i}" row
        template::util::array_to_vars row

        ns_log debug "content::insert_element_data: attribute_name $attribute_name"
        ns_log debug "content::insert_element_data: table_name $table_name"
        
        if { ![string equal $last_table $table_name] } {
            if { $i != 1 } {                
                content::process_insert_statement
            }
            set columns [list]
            set values [list]
        }
        
        # fetch the value of the attribute from the form
        if { ![template::util::is_nil attribute_name] } {

            set $attribute_name [template::element::get_value \
                                     $form_name "${attribute_name}${suffix}"]

            lappend columns $attribute_name

            # If the attribute is a date, get the date
            if { [string equal $datatype date] } {
                set $attribute_name \
                    [template::util::date::get_property sql_date [set $attribute_name]]
                # Can't use bind vars because this will be a to_date call
                lappend values "[set $attribute_name]"
            } else {
                lappend values ":$attribute_name"
            }
        }
        set last_table $table_name
        set last_id_column $id_column
    }

    content::process_insert_statement

}

ad_proc -public content::process_insert_statement {} {

    helper function for process_revision_form
    PRE: the following variables must be set in the uplevel scope:
    columns, values, last_table, id_value_ref

} {
    upvar last_table __last_table
    upvar columns __columns
    upvar values __values
    upvar __sql sql
    set sql [db_map process_insert_statement]
    
    uplevel {

        if { ! [string equal $last_table {}] } {
            lappend columns $last_id_column
            lappend values ":$id_value_ref"

	    db_dml process_insert_statement $__sql
        }
    }
}

ad_proc -public content::assemble_passthrough { args } {

    Assemble a passthrough list out of variables

} {
    set result [list]
    foreach varname $args {
        upvar $varname var
        lappend result [list $varname $var]
    }
    return $result
}

ad_proc -public content::url_passthrough { passthrough } {

    Convert passthrough to a URL fragment

} {

    set extra_url ""
    foreach pair $passthrough {
        append extra_url "&[lindex $pair 0]=[lindex $pair 1]"
    }    
    return $extra_url
}

ad_proc -public content::assemble_url { base_url args } {

    Assemble a URL out of component parts

} {
    set result $base_url
    if { [string first $base_url "?"] == -1 } {
        set joiner "?"
    } else {
        set joiner "&"
    }
    foreach fragment $args {
        set fragment [string trimleft $fragment "&?"]
        if { ![string equal $fragment {}] } {
            append result $joiner $fragment
            set joiner "&"
        }
    }
    return $result
}  

#################################################################

# @namespace content

# Procedures for generating and processing content content creation
# and editing forms..

ad_proc -public content::new_item { form_name { storage_type text } { tmpfile "" } {prefix {StArT}} } {

    Create a new item, including the initial revision, based on a valid
    form submission.

    @param form_name Name of the form from which to obtain item
    attributes, as well as attributes of the initial revision.  The form
    should include an item_id, name and revision_id.

    @param storage_type Method for storing content.  Can be one of content_text,
    content_lob, content_file.  This is an openacs extension for allowing the 
    storage of content in the file-system.

    @param tmpfile Name of the temporary file containing the content to
    upload for the initial revision.

    @param prefix A prefix to remove from the form when looking up attributes

    @see content::add_revision

} {
    # Here we walk the item prefixes and create them all, unless the content_prefixes var 
    # does not exist or we are already handling the form
    ns_log Warning "content::new_item: handling prefix $prefix"
    if {[string equal "StArT" $prefix]} { 
        if {[template::element exists $form_name content_prefixes]} { 
            foreach prefix [template::element get_value $form_name content_prefixes] { 
                lappend item_id [content::new_item $form_name $storage_type $tmpfile $prefix]
            }
            return $item_id
        } else { 
            set prefix {}
        }
    }
    
    if { [template::element exists $form_name ${prefix}item_id] } {
        set item_id [template::element get_value $form_name ${prefix}item_id]
        set exists [db_string item_id_exists "select count(*) from cr_items where item_id = :item_id"]
    } else { 
        set exists 0
    } 

    # If the item does not already exist build the call to create it.
    if { !$exists } { 
        array set defaults [list item_id "" locale "" parent_id "" content_type "content_revision"]

        foreach param { item_id name locale parent_id content_type } {
            
            if { [template::element exists $form_name $prefix$param] } {
                set $param [template::element get_value $form_name $prefix$param]

                if { ! [string equal [set $param] {}] } {
                    # include the parameter if it is not null
                    # this for the oracle version, for postgres we just 
                    # set param variables...
                    lappend params "$param => :$param"
                }
            } else {
                set $param $defaults($param)
            }
        }

        lappend params "creation_user => [User::getID]"
        lappend params "creation_ip   => '[ns_conn peeraddr]'"
        lappend params "storage_type => :storage_type"

        # Use the correct relation tag, if specified
        if { [template::element exists $form_name ${prefix}relation_tag] } {
            set relation_tag [template::element get_value $form_name ${prefix}relation_tag]
            lappend params "relation_tag => :relation_tag"
        } else { 
            set relation_tag {}
        }
    }

    db_transaction {
        if {!$exists} { 
            set item_id [db_exec_plsql get_item_id  "
                     begin 
                       :1 := content_item.new( [join $params ","] );
                     end;"]
        }
        add_revision $form_name $tmpfile $prefix [expr !$exists]
    }

    # flush the sitemap folder listing cache
    #if { [template::element exists $form_name parent_id] } {
    #    set parent_id [template::element get_value $form_name parent_id]
    #    if { $parent_id == [cm::modules::sitemap::getRootFolderID] } {
    #      set parent_id ""
    #    }
    #    cms_folder::flush sitemap $parent_id
    #}

    return $item_id
}


ad_proc -public content::add_revision { form_name { tmpfile "" } {prefix {}} {new_p 1}} {

    Create a new revision for an existing item based on a valid form
    submission.  Queries for attribute names and inserts a row into the
    attribute input view for the appropriate content type.  Inserts the
    contents of a file into the content column of the cr_revisions table
    for the revision as well.  

    @param form_name Name of the form from which to obtain attribute
    values.  The form should include an item_id and revision_id.

    @param tmpfile Name of the temporary file containing the content to
    upload.

    @param prefix A prefix to prepend when looking up attributes in the form data
    
    @param new_p Whether the revision is attached to a new cr_item or if previousrevision exist
} {
    ns_log Debug "content::add_revision: $form_name $tmpfile $prefix $new_p"
    # initialize an ns_set to hold bind values
    set bind_vars [ns_set create]

    # get the item_id and revision_id and content_method
    foreach var {item_id revision_id content_method} {
        set $var [template::element get_values $form_name ${prefix}$var]
    } 
    ns_set put $bind_vars item_id $item_id
    ns_set put $bind_vars revision_id $revision_id

    # query for content_type and table_name
    db_1row addrev_get_content_type "" -column_array info

    set insert_statement [attribute_insert_statement \
                              $info(content_type) $info(table_name) $bind_vars $form_name $prefix $new_p]

    # if content exists, prepare it for insertion
    if { [template::element exists $form_name ${prefix}content] } {
        set filename [template::element get_value $form_name ${prefix}content]
        set tmpfile [prepare_content_file $form_name]
    } else { 
        set filename ""
    }

    add_revision_dml $insert_statement $bind_vars $tmpfile $filename

    # flush folder listing for item's parent because title may have changed
    #template::query parent_id onevalue "
    #  select parent_id from cr_items where item_id = :item_id" 
    #
    # if { $parent_id == [cm::modules::sitemap::getRootFolderID] } {
    #    set parent_id ""
    #}
    #cms_folder::flush sitemap $parent_id
}


ad_proc -private content::attribute_insert_statement { 
    content_type table_name bind_vars form_name {prefix {}} {new_p 1}
} {

    Prepare the insert statement into the attribute input view for a new
    revision (see the content repository documentation for details about
    the view).

    @param content_type The content type of the item for which a new
                        revision is being prepared.

    @param table_name The storage table of the content type.

    @param bind_vars The name of an ns_set in which to store the
                     attribute values for the revision.  (Typically
                     duplicates the contents of [ns_getform])
    
    @param form_name The name of the ATS form object used to process the
                     submission.

} {
    # get creation_user and creation_ip
    set creation_user [User::getID]
    set creation_ip [ns_conn peeraddr]
    ns_set put $bind_vars creation_user $creation_user
    ns_set put $bind_vars creation_ip $creation_ip


    # initialize the column and value list 
    set columns [list item_id revision_id creation_user creation_ip]
    set values [list :item_id :revision_id :creation_user :creation_ip]
    set default_columns [list] 
    set default_values [list]
    set missing_columns [list]

    # query for attribute names and datatypes
    foreach attribute [get_attributes $content_type attribute_name datatype default_value ancestor] { 

        foreach {attribute_name datatype default_value ancestor} $attribute { break }

        # get the form value
        if { [template::element exists $form_name $prefix$attribute_name] } {

            set value [template::element get_value $form_name $prefix$attribute_name]

            # Convert dates to linear "YYYY MM DD HH24 MI SS" format
            if { [string equal $datatype date] } {
                set value [template::util::date get_property linear_date $value]
                foreach i {1 2} { 
                    if {[string equal [lindex $value $i] "00"]} { 
                        set value [lreplace $value $i $i 01]
                    }
                }
            }
            
            if { ! [string equal $value {} ] } {
                ns_set put $bind_vars $attribute_name $value

                lappend columns $attribute_name
                lappend values [get_sql_value $attribute_name $datatype]
            }
        } elseif { ![string equal $ancestor "acs_object"] 
                   && ( ![string equal $ancestor "cr_revision"] 
                        || [lsearch -exact {revision_id item_id publish_date} $attribute_name] == -1) } { 
            # We preserve attributes not in the form and not "special" like acs_object and some of cr_revision.
            lappend missing_columns $attribute_name
            if {$new_p && ![string equal $default_value {}]} { 
                ns_set put $bind_vars $attribute_name $default_value
                
                lappend default_columns $attribute_name
                lappend default_values [get_sql_value $attribute_name $datatype]
            }
        } 
    }
    
    if {$new_p} { 
        set insert_statement "insert into ${table_name}i ( [join [concat $columns $default_columns] ", "] )\nvalues ( [join [concat $values $default_values] ", "] )"
    } else { 
        set insert_statement "insert into ${table_name}i ( [join [concat $columns $missing_columns] ", "] )\nselect [join [concat $values $missing_columns] ", "]\nfrom ${table_name}i\nwhere revision_id = content_item.get_latest_revision(:item_id)"
    }

    return $insert_statement
}


ad_proc -private content::add_revision_dml { statement bind_vars tmpfile filename } {

    Perform the DML to insert a revision into the appropriate input view.

    @param statement The DML for the insert statement, specifying a bind
    variable for each column value.

    @param bind_vars An ns_set containing the values for all bind variables.

    @param tmpfile The server-side name of the file containing the body of the 
    revision to upload into the content BLOB column of cr_revisions.

    @param filename The client-side name of the file containing the body of 
    the revision to upload into the content BLOB column of cr_revisions

    @see content::add_revision

} {
    db_transaction {

        db_dml add_revision $statement -bind $bind_vars 

        if { ![string equal $tmpfile {}] } {

            set revision_id [ns_set get $bind_vars revision_id]
            upload_content $revision_id $tmpfile $filename
            
        } 
    }
}


ad_proc -public content::upload_content { revision_id tmpfile filename } {

    @private upload_content

    Inserts content into the database from an uploaded file.
    Does automatic mime_type updating
    Parses text/html content and removes <body></body> tags

    @param db A db handle

    @param revision_id The revision to which the content belongs

    @param tmpfile The server-side name of the file containing the body of the 
    revision to upload into the content BLOB column of cr_revisions.

    @param filename The client-side name of the file containing the body of 
    the revision to upload into the content BLOB column of cr_revisions


} {

    # if it is HTML then strip out the body
    set mime_type [ns_guesstype $filename]
    ns_log debug "content::upload_content: guessed mime_type: $mime_type, filename = $filename"
    if { [string equal $mime_type text/html] } {
        set text [template::util::read_file $tmpfile]
        if { [regexp {<body[^>]*>(.*?)</body>} $text x body] } {
            set fd [open $tmpfile w]
            puts $fd $body
            close $fd
        }
    }

    db_1row get_storage_type {select 
        storage_type, item_id 
        from 
        cr_items 
        where 
        item_id = (select 
                   item_id 
                   from 
                   cr_revisions 
                   where revision_id = :revision_id)}

    if {[string equal $storage_type file]} {
        set file_path [cr_create_content_file $item_id $revision_id $tmpfile]
        set file_size [file size $tmpfile]
        db_dml upload_file_revision {}
    } elseif {[string equal $storage_type text]} {
        # upload the file into the revision content
        db_dml upload_text_revision "update cr_revisions 
             set content = empty_blob(), 
             content_length = '[file size $tmpfile]' 
             where revision_id = :revision_id
             returning content into :1" -blob_files [list $tmpfile]

    } else {
        # upload the file into the revision content
        db_dml upload_revision "update cr_revisions 
             set content = empty_blob(), 
             content_length = '[file size $tmpfile]' 
             where revision_id = :revision_id
             returning content into :1" -blob_files [list $tmpfile]
    }

    # this seems to abort the transaction even with the catch.

    # update mime_type to match the file 
    #     if { [catch {db_dml update_mime_type "
    #       update cr_revisions 
    #         set mime_type = :mime_type 
    #         where revision_id = :revision_id"} errmsg] } {
    # 	#  if it fails, use user submitted mime_type
    # 	ns_log debug "form-procs - add_revision_dml - using user mime_type 
    # 	  instead of guessed mime type = $mime_type"
    #     }

    # delete the tempfile
    ns_unlink $tmpfile
}


ad_proc -private content::get_sql_value { name datatype } {

    Return the sql statement for a column value in an insert or update
    statement, using a bind variable for the actual value and wrapping it
    in a conversion function where appropriate.  

    @param name The name of the column and bind variable (they should be
                                                          the same).

    @param datatype The datatype of the column.


} {

    switch $datatype {
        date { set wrapper [db_map string_to_timestamp] }
        default { set wrapper ":$name" }
    }

    return $wrapper
}


ad_proc -private content::prepare_content_file { form_name } {

    Looks for an element named "content" in a form and prepares a
    temporarily file in UTF-8 for uploading to the content repository.
    Checks for a query variable named "content.tmpfile" to distinguish
    between file uploads and text entry.  If the type of the file is
    text, then ensures that is in UTF-8.  Does nothing if the uploaded
    file is in binary format.

    @param form_name  The name of the form object in which content was submitted.

    @return The path of the temporary file containing the content, or an empty
    string if the form does not include a content element or the value
    of the element is null.

} {  
    
    if { ! [template::element exists $form_name content] } { return "" }

    template::form get_values $form_name content

    # check for content.tmpfile
    set tmpfile [ns_queryget content.tmpfile]
    set is_text 0

    if { ! [string equal $tmpfile {}] } {

        # check for a text file based on the extension (not ideal)
        if { [regexp {\.(htm|html|txt)$} $content] } {
            ns_log debug "content::prepare_content_file: converting text file $content to UTF-8."
            set content [template::util::read_file $tmpfile]
            set is_text 1
        }

    } else {
        
        # no temporary file so content contains text
        set is_text 1
    }

    if { $is_text && ! [string equal $content {}] } {
        set tmpfile [string_to_file $content]
    }

    return $tmpfile
}


ad_proc -private content::string_to_file { s } {

    Write a string in UTF-8 encoding to of temp file so it can be
    uploaded into a BLOB (which is blind to character encodings).
    Returns the name of the temp file.

    @param s The string to write to the file.

} {

    set tmp_file [ns_tmpnam]

    set fd [open $tmp_file w]

    fconfigure $fd -encoding utf-8

    puts $fd $s
    
    close $fd

    return $tmp_file
}

# Form preparation procs

namespace eval content {

    variable columns
    set columns [list object_type sort_order attribute_name param_type \
                     param_source value \
                     pretty_name widget param param_is_required widget_is_required \
                     is_html default_value datatype]
}


ad_proc -public content::new_item_form { args } {

    Adds elements to an ATS form object for creating an item and its
    initial revision.  If the form does not already exist, creates the
    form object and sets its enctype to multipart/form-data to allow for
    text entries greater than 4000 characters.

    @option form_name    	 The name of the ATS form object.  Defaults to 
                                 "new_item".
    @option content_type 	 The content_type of the item.  Defaults to
                                 "content_revision".
    @option content_method       The method to use for uploading the content body.
                                 Valid values are "no_content", "text_entry", and "file_upload".
                                 If the content type allows text, defaults to
                                 text entry, otherwise defaults to file upload.
    @option parent_id    	 The item ID of the parent.  Defaults to null (Parent
                                                                               is the root folder).
    @option name         	 The default name of the item.  Default is an empty 
                                 string (User must supply name).
    @option attributes   	 A list of attribute names for which to create form
                                 elements.
    @option action       	 The URL to which the form should redirect following
                                 a successful form submission.
    @option prefix       	 a text prefix for the form variables added to the form
                                 primarily intended to allow multiple content items in the 
                                 same form.
    @option section              a section name for the form.
    @option exclude              a list of object attributes to exclude from the form
    @option hidden               a list of attributes to hide but leave in form
    @option item_id              an item_id from which to draw the parameters
    @option revision_id          a revision_id from which to draw the parameters 
                                 (defaults to the latest revision of item_id if item_id is provided)
} {

    array set opts [list form_name new_item content_type content_revision \
                        parent_id {} name {} content_method {} section {} prefix {} \
                        exclude {} hidden {} relation {} item_id {} revision_id {}]

    template::util::get_opts $args

    if { ! [template::form exists $opts(form_name)] } {
        template::form create $opts(form_name) \
            -html { enctype multipart/form-data }
    }

    set name $opts(name)
    set form_name $opts(form_name)

    if {![string equal {} $opts(section)] } { 
        template::form section $form_name $opts(section)
    } else { 
        set id $opts(form_name)
        template::form::get_reference
        set opts(section) $form_properties(section)
    } 
    
    # If we are handling a new request and were passed an item_id 
    # get the revision_id if not provided

    if { [template::form is_request $opts(form_name)] 
         && ![string equal $opts(item_id) {}]} {
        set item_id $opts(item_id)
        
        # we have to get name so get it and revision_id which might be overridden by the passed in data.
        if {[db_0or1row latest_revision "select name, latest_revision as revision_id from cr_items where item_id = :item_id"]} { 
            if {[string equal $opts(revision_id) {}]} { 
                set opts(revision_id) $revision_id
            } 
        } 
    }

    if { [string equal {} $opts(item_id)] } { 
        # Only add all this junk for 
        # new items.

        if {[lsearch $opts(exclude) name] == -1} { 
            if {[lsearch $opts(hidden) name] == -1} { 
                template::element create $opts(form_name) "$opts(prefix)name" \
                    -datatype filename \
                    -html { maxlength 400 } \
                    -widget text \
                    -label Name
            } else { 
                template::element create $opts(form_name) "$opts(prefix)name" \
                    -datatype filename \
                    -widget hidden \
                    -sign
            }
        }

        if {[lsearch $opts(exclude) parent_id] == -1} { 
            template::element create $opts(form_name) "$opts(prefix)parent_id" \
                -datatype integer \
                -widget hidden \
                -optional \
                -sign
            # ATS doesn't like "-value -100" so use set_value to get around it
            template::element set_value $opts(form_name)  "$opts(prefix)parent_id" $opts(parent_id)
        }

        if {[lsearch $opts(exclude) relation_tag] == -1 && ![string equal {} $opts(relation)]}  { 
            template::element create $opts(form_name) "$opts(prefix)relation_tag" \
                -datatype text \
                -widget hidden \
                -optional \
                -value $opts(relation)
        }

        if {[lsearch $opts(exclude) parent_id] == -1} { 
            template::element create $opts(form_name) "$opts(prefix)content_type" \
                -datatype keyword \
                -widget hidden \
                -value $opts(content_type) \
                -sign
        }
    }

    add_revision_form -form_name $opts(form_name) \
        -content_type $opts(content_type) \
        -content_method $opts(content_method) \
        -prefix $opts(prefix) \
        -exclude $opts(exclude) \
        -item_id $opts(item_id) \
        -revision_id $opts(revision_id) \
        -hidden $opts(hidden) \
        -section $opts(section)

    if { [template::form is_request $opts(form_name)] } {
        if {[template::util::is_nil item_id]} { 
            set item_id [get_object_id]

            template::element set_properties $opts(form_name) "$opts(prefix)item_id" -value $item_id

            if { [template::util::is_nil name] } {
                template::element set_value $opts(form_name) "$opts(prefix)name" "item$item_id"
            } else {
                template::element set_value $opts(form_name) "$opts(prefix)name" $name
            }
        }
    }

    if { [info exists opts(action)] && \
             [template::form is_valid $opts(form_name)] } {
        new_item $opts(form_name)
        template::forward $opts(action)
    }
}


ad_proc -public content::add_revision_form { args } {

    Adds elements to an ATS form object for adding a revision to an
    existing item.  If the item already exists, element values default a
    previous revision (the latest one by default).  If the form does not
    already exist, creates the form object and sets its enctype to
    multipart/form-data to allow for text entries greater than 4000
    characters.

    @option form_name      The name of the ATS form object.  Defaults to 
                           "new_item".
    @option content_type   The content_type of the item.  Defaults to
                           "content_revision".
    @option content_method The method to use for uploading the content body.
                           If the content type is text, defaults to
                           text entry, otherwise defaults to file upload.
    @option item_id        The item ID of the revision.  Defaults to null 
                           (item_id must be set by the calling code).
    @option revision_id    The revision ID from which to draw default values.  
                           Defaults to the latest revision
    @option attributes     A list of attribute names for which to create form
                           elements.
    @option action         The URL to which the form should redirect following
                           a successful form submission.
    @option prefix         a text prefix for the form variables added to the form
                           primarily intended to allow multiple content items in the 
                           same form.
    @option section        a section name for the added form elements.
    @option exclude              a list of object attributes to exclude from the form
    @option hidden               a list of attributes to hide but leave in form
} {

    array set opts [list form_name add_revision content_type content_revision \
                        item_id {} content_method {} revision_id {} section {} prefix {} \
                        hidden {} exclude {}]
    template::util::get_opts $args

    if { [string equal $opts(content_method) {}] } {
        set opts(content_method) [get_default_content_method $opts(content_type)]
    }

    if { ! [template::form exists $opts(form_name)] } {
        template::form create $opts(form_name) \
            -html { enctype multipart/form-data }
    }

    if { ! [template::element exists $opts(form_name) "$opts(prefix)item_id"] } {
        template::element create $opts(form_name) "$opts(prefix)item_id" \
            -datatype integer \
            -widget hidden \
            -section $opts(section) \
            -value $opts(item_id) \
            -sign 
            
    }

    if { ! [template::element exists $opts(form_name) "$opts(prefix)revision_id"] } {
        template::element create $opts(form_name) "$opts(prefix)revision_id" \
            -datatype integer \
            -section $opts(section) \
            -widget hidden \
            -optional \
            -sign
    }

    set attributes [add_attribute_elements $opts(form_name) $opts(content_type) {} $opts(prefix) $opts(section) $opts(exclude) $opts(hidden)]

    ns_log debug "content::add_revision_form: content method $opts(content_method)"

    add_content_element $opts(form_name) $opts(content_method) $opts(prefix)

    if { [template::form is_request $opts(form_name)]} {

        # set revision_id [get_object_id]

        # template::element set_properties $opts(form_name) "$opts(prefix)revision_id" -value $revision_id

        if { [string equal $opts(revision_id) {}] } {
            set opts(revision_id) [get_latest_revision $opts(item_id)]
        }

        if { ! [string equal $opts(revision_id) {}] } {
            set_attribute_values $opts(form_name) $opts(content_type) \
                $opts(revision_id) $attributes $opts(prefix)
        }

        # if the content_method is text_entry, then retrieve the latest
        # content from the database.
        set revision_id $opts(revision_id)
        if { ![template::util::is_nil revision_id] } {
            if { [string equal $opts(content_method) text_entry] } {
                set_content_value $opts(form_name) $opts(revision_id) 
            }
        }
    }

    if { [info exists opts(action)] && [template::form is_valid $opts(form_name)] } {

        set tmpfile [prepare_content_file $opts(form_name)]

        # JCD: need to check if this should be a new_p or not.  
        add_revision $opts(form_name) $tmpfile $prefix 1
        template::forward $opts(action)
    }
}


ad_proc -public content::add_attribute_elements { 
    form_name content_type { revision_id "" } {prefix {}} {section {}} {exclude {}} {hidden {}}
} {
    
    Add form elements to an ATS form object for all attributes of a
    content type.

    @param form_name   	 The name of the ATS form object to which objects
                         should be added.
    @param content_type	 The content type keyword for which attribute
                         widgets should be added.
    @param revision_id   The revision from which default values should be
                         queried
    @param prefix        a prefix for the form variables.
    @param section       a section name
   
    @option exclude              a list of object attributes to exclude from the form
    @option hidden               a list of attributes to hide but leave in form

    @return The list of attributes that were added.
} {

    # query for attributes in the appropriate order
    set attribute_list [get_attributes $content_type object_type attribute_name]

    # get a lookup of object_types
    foreach row $attribute_list { 
        set type_lookup([lindex $row 0]) 1 
    }

    set attribute_data [eval get_type_attribute_params [array names type_lookup]]

    set attribute_names [list]
    array set attributes_by_type $attribute_data

    foreach row $attribute_list { 

        set object_type [lindex $row 0]
        set attribute_name [lindex $row 1]

        if {[lsearch $exclude $attribute_name] == -1} { 
            
            # look up attribute
            if { ! [info exists attributes_by_type($object_type)] } { continue }

            array set attributes $attributes_by_type($object_type)
            
            if { ! [info exists attributes($attribute_name)] } { continue }
            
            # JCD: check if the widget is on the hidden list.
            if { [lsearch $hidden $attribute_name] == -1} { 
                set hidden_p 0
            } else { 
                set hidden_p 1
            }
            
            add_attribute_element $form_name $content_type $attribute_name \
                $attributes($attribute_name) $prefix $section $hidden_p

            lappend attribute_names $attribute_name
        }
    }

    if { ![template::util::is_nil revision_id] } {
        if { [template::form is_request $form_name] } {

            # set default values for attribute elements
            set_attribute_values $form_name \
                $content_type $revision_id $attribute_names $prefix
        }
    }

    return $attribute_names
}


ad_proc -public content::add_attribute_element { 
    form_name content_type attribute { attribute_data "" } {prefix {}} {section {}} {hidden_p 0}
} {

    Add a form element (possibly a compound widget) to an ATS form object.
    for entering or editing an attribute value.

    @param form_name 	   The name of the ATS form object to which the element
                           should be added.
    @param content_type    The content type keyword to which this attribute
                           belongs.
    @param attribute 	   The name of the attribute, as represented in the
                           attribute_name column of the acs_attributes table.
    @param attribute_data  Optional nested list of parameter data for the
                           the attribute (generated by get_attribute_params).
    @param prefix          The element name prefix
    @param section         The attribute section
    @param hidden          boolean whether to hide the element
} {

    variable columns

    set command [list "template::element" create $form_name "$prefix$attribute"]

    if { [string equal $attribute_data {}] } {
        set attribute_data [get_attribute_params $content_type $attribute]
    }

    array set is_html $attribute_data

    # if there is a false entry for is_html, compile element options
    if { [info exists is_html(f)] } {

        foreach values $is_html(f) {

            template::util::list_to_array $values param $columns
            lappend command -$param(param) \
                [get_widget_param_value param $content_type]
        }
    }

    # if there is a true entry for is_html, compile html options
    if { [info exists is_html(t)] } {

        foreach values $is_html(t) {

            template::util::list_to_array $values param $columns
            lappend html_params $param(param) \
                [get_widget_param_value param $content_type]
        }
        lappend command -html $html_params
    }

    # if there is a null entry for is_html, the widget has no parameters
    set null {{}}
    set null2 {}
    if { [info exists is_html($null)] || [info exists is_html($null2)] } {

        set values [lindex $is_html($null) 0]
        template::util::list_to_array $values param $columns
    }


    # special case - the search widget
    #if { [string equal $param(widget) search] } {
    #    set param(datatype) search
    #}

    if { $hidden_p } { 
        set param(widget) hidden 
    } 

    # use any set of values for label and optional flag
    lappend command -label $param(pretty_name) -widget $param(widget) \
        -datatype $param(datatype) -section $section
    
    # changed from widget_is_required to param_is_required (OpenACS - DanW)
    if { [string equal $param(param_is_required) f] } {
        lappend command -optional
    }

    # ns_log debug "content::add_attribute_element: command = $command"

    eval $command
}


ad_proc -public content::add_content_element { 
    form_name
    content_method 
    { prefix {}}
    { section "Content" } 
} {

    Adds a content input element to an ATS form object.

    @param form_name      The name of the form to which the object should be
                          added.
    @param content_method One of no_content, text_entry or file_upload
    @param section        A section name for the added elements
    @param prefix         A prefix for the form element name
} {
    ns_log debug "content::add_content_element: content method $content_method"

    template::element create $form_name "${prefix}content_method" \
        -datatype keyword \
        -widget hidden \
        -value $content_method

    switch $content_method {
        text_entry {

            template::form section $form_name $section
            template::element create $form_name "${prefix}content" \
                -widget textarea \
                -label {} \
                -datatype text \
                -html { cols 80 rows 20 wrap physical } 

            if { [template::element exists $form_name "${prefix}mime_type"]
                 && [template::element exists $form_name "${prefix}content_type"] } {
                
                set content_type \
                    [template::element get_value $form_name "${prefix}content_type"]
                
                # change mime types select widget to only allow text MIME types
                set text_mime_types [db_list_of_lists get_text_mime_types ""]
                
                template::element set_properties $form_name "${prefix}mime_type" \
                    -options $text_mime_types
            }


        }

        file_upload {

            template::form section $form_name $section
            template::element create $form_name "${prefix}content" \
                -widget file \
                -label "Upload Content" \
                -datatype text

        }
    }
}


ad_proc content::add_child_relation_element { form_name args } {

    Add a select box listing all valid child relation tags.
    The form must contain a parent_id element and a content_type element.
    If the elements do not exist, or if there are no valid relation tags,
    this proc does nothing. 
    
    @param form_name  The name of the form 
    
    @option section {<i>none</i>} If present, creates a new form section
    for the element. 
    
    @option label {Child relation tag} The label for the element


} {
    
    # Process parameters

    template::util::get_opts $args

    if { ![template::util::is_nil opts(label)] } {
        set label $opts(label)
    } else {
        set label "Child relation tag"
    }

    # Check form elements

    if { [template::element exists $form_name content_type] } {
        set content_type [template::element get_value $form_name content_type]
    } else {
        return
    }

    if { [template::element exists $form_name parent_id] } {
        set parent_id [template::element get_value $form_name parent_id]
    } else {
        return
    }

    # Get the parent type. If the parent is not an item, abort
    set parent_type [db_string get_parent_type ""]

    if { [template::util::is_nil parent_type] } {
        return
    }

    # Get a multilist of all valid relation tags
    set options [db_list_of_lists get_all_valid_relation_tags ""]

    if { [template::util::is_nil options] } {  
        return
    }

    # Create the section, if specified
    if { ![template::util::is_nil opts(section)] } {
        set parent_title [db_string get_parent_title ""]

        if { ![template::util::is_nil parent_title] } {
            template::form section $form_name "Relationship to $parent_title"
        }
    }

    # Create the element
    set options [concat [list [list "(Default)" ""]] $options]

    template::element create $form_name relation_tag -label $label \
        -datatype text -widget select -options $options -optional
}


ad_proc -private content::get_widget_param_value { 
    array_ref {content_type content_revision}
} {

    Utility procedure to return the value of a widget parameter

    @param array_ref     The name of an array in the calling frame
    containing parameter data selected from the form 
    metadata.
    @param content_type  The current content type; defaults to content_revision

} {

    upvar $array_ref param
    set value ""

    # a datatype of enumeration is a special case 

    if { [string equal $param(datatype) enumeration] } {

        set value [get_attribute_enum_values $param(attribute_id)]

    } else {

        switch $param(param_source) {

            eval {
                set value [eval $param(value)]
            }
            query {
                #set content_type content_revision
                set item_id {}
                if [catch {
                    switch $param(param_type) {
                        
                        onevalue {
                            set value [db_string set_content_values $param(value)]
                        }
                        onelist {
                            set value [db_list set_content_values $param(value)]
                        }
                        multilist {
                            set value [db_list_of_lists set_content_values $param(value)]
                        }             
                    }
                }] {
                    set value ""
                }
            }
            default {
                set value $param(value)
                if { [template::util::is_nil value] } {
                    set value $param(default_value)
                }
            }
        }
        # end switch
    }

    return $value
}


ad_proc -private content::get_type_attribute_params { args } {

    Query for attribute form metadata

    @param args Any number of object types

    @return A list of attribute parameters nested by object_type, attribute_name
    and the is_html flag.  For attributes with no parameters,
    there is a single entry with is_html as null.

} {

    variable columns

    foreach object_type $args {
        lappend in_list [ns_dbquotevalue $object_type]
    }

    
    template::query gtap_get_attribute_data attribute_data nestedlist "
    select
      [join $columns ","]
    from
      cm_attribute_widget_param_ext x
    where
      object_type in ( [join $in_list ","] )
  " -groupby { object_type attribute_name is_html }

    return $attribute_data
}


ad_proc -private content::get_attribute_params { content_type attribute_name } {

    Query for parameters associated with a particular attribute

    @param content_type      The content type keyword to which this attribute
    belongs.
    @param attribute_name	   The name of the attribute, as represented in the
    attribute_name column of the acs_attributes table.

} {

    variable columns

    template::query gap_get_attribute_data attribute_data nestedlist "
    select
      [join $columns ","]
    from
      cm_attribute_widget_param_ext
    where
      object_type = :content_type
    and
      attribute_name = :attribute_name
  " -groupby { is_html }

    return $attribute_data
}


ad_proc -private content::set_attribute_values {
    form_name content_type revision_id attributes 
    {prefix {}}
} { 

    Set the default values for attribute elements in ATS form object
    based on a previous revision

    @param form_name         The name of the ATS form object containing
    the attribute elements.
    @param content_type      The type of item being revised in the form.
    @param revision_id       The revision ID from where to get the default values
    @param attributes        The list of attributes whose values should be set.

} {

    if { [llength $attributes] == 0 } {
        set attributes [get_attributes $content_type]
    }

    # Assemble the list of columns to query, handling dates
    # correctly 

    set columns [list]
    set attr_types [list]  
    foreach attr $attributes {
        if { [template::element exists $form_name "$prefix$attr"] } {
            set datatype [template::element get_property $form_name "$prefix$attr" datatype]
            if { [string equal $datatype date] } {
                lappend columns [db_map timestamp_to_string]
            } else {
                lappend columns $attr
            }
            
            lappend attr_types [list $attr $datatype]
        }
    }
    
    # Query for values from a previous revision

    db_0or1row get_previous_version_values "" -column_array values

    # Set the form values, handling dates with the date acquire function
    foreach pair $attr_types {
        set element_name [lindex $pair 0]
        set datatype [lindex $pair 1]
        
        if { [info exists values($element_name)] } {

            if { [string equal $datatype date] } {
                set value [template::util::date acquire \
                               sql_date $values($element_name)]
            } else {
                set value $values($element_name)
            }
            
            template::element set_properties $form_name $prefix$element_name \
                -value $value -values [list $value]
        }
    }
    
}


ad_proc -private content::set_content_value { form_name revision_id } {

    Set the default value for the content text area in an ATS form object
    based on a previous revision

    @param form_name         The name of the ATS form object containing
    the content element.
    @param revision_id       The revision ID of the content to revise

} {

    set content [get_content_value $revision_id]

    template::element set_properties $form_name content -value $content
}


ad_proc -private content::get_default_content_method { content_type } {

    Gets the content input method most appropriate for an content type,
    based on the MIME types that are registered for that content type.

    @param content_type  The content type for which an input method is needed.

} {

    set is_text [db_string count_mime_type ""]

    if { $is_text > 0 } {
        set content_method text_entry
    } else {
        set content_method file_upload
    }

    return $content_method
}

# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# Procedure wrappers for basic ACS Object and Content Repository queries 
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *


ad_proc -private content::get_type_info { object_type ref args } {

    Return specified columns from the acs_object_types table.

    @param object_type Object type key for which info is required.
    @param ref         If no further arguments, name of the column value to
    return.  If further arguments are specified, name of 
    the array in which to store info in the calling
    @param args        Column names to query.

} {

    if { [llength $args] == 0 } {

        set info [db_string get_type_info_1 ""]

        return $info

    } else {
        uplevel 1 "db_0or1row get_type_info_2 {} -column_array $ref"
    }
}


ad_proc -public content::get_object_id {} {

    Grab an object ID for creating a new ACS object.

} {

    return [db_string nextval "select acs_object_id_seq.nextval from dual"]
}


ad_proc -private content::get_attributes { content_type args } {

    Returns columns from the acs_attributes table for all attributes
    associated with a content type.

    @param content_type The name of the content type (ACS Object Type)
    for which to obtain the list of attributes.
    @param args Names of columns to query.  If no columns are specified,
    returns a simple list of attribute names.

} {

    if { [llength $args] == 0 } {
        set args [list attribute_name]
    }

    ### RBM: FIX ME (aD left this note. Probably should be fixed).
    ### HACK ! What the hell is "ldap dn" ?
    ### JCD: Someone at some point had "ldap dn" as and acs_datatype.
    ### which was a very bad idea since datatypes are assumed to 
    ### be one token in a number of places.  I removed the 
    ### code in the query that excluded "ldap dn" from the returned attrs.

    if { [llength $args] == 1 } {
        set type onelist
        set attributes [db_list ga_get_attributes ""]
    } else {
        set type multilist
        set attributes [db_list_of_lists ga_get_attributes ""]
    }

    return $attributes
}


ad_proc -public content::get_attribute_enum_values { attribute_id } {

    Returns a list of { pretty_name enum_value } for an attribute of
    datatype enumeration.

    @param attribute_id   The primary key of the attribute as in the
    attribute_id column of the acs_attributes table.

} {

    set enum [db_list_of_lists gaev_get_enum_values ""]

    return $enum
}

ad_proc -public content::get_latest_revision { item_id } {

    Get the ID of the latest revision for the specified content item.

    @param item_id  The ID of the content item.

} {

    set latest_revision [db_string glr_get_latest_revision ""]

    return $latest_revision
}


ad_proc -public content::add_basic_revision { item_id revision_id title args } {

    Create a basic new revision using the content_revision PL/SQL API.

    @param item_id
    @param revision_id
    @param title

    @option description
    @option mime_type
    @option text
    @option tmpfile

} {

    template::util::get_opts $args

    set creation_ip [ns_conn peeraddr]
    set creation_user [User::getID]

    set param_sql ""
    array set defaults [list description "" mime_type "text/plain" text " "]
    foreach param { description mime_type text } {

        if { [info exists opts($param)] } {
            set $param $opts($param)
            append param_sql ", $param => :$param"
        } else {
            set $param $defaults($param)
        }
    }

    db_transaction {

        set revision_id [db_exec_plsql basic_get_revision_id "begin :1 := content_revision.new(
               item_id       => content_symlink.resolve(:item_id),
               revision_id   => :revision_id,
               title         => :title,
               creation_ip   => :creation_ip,
               creation_user => :creation_user $param_sql); end;"]

        if { [info exists opts(tmpfile)] } {

            update_content_from_file $revision_id $opts(tmpfile)
        }
    }
}


ad_proc -private content::update_content_from_file { revision_id tmpfile } {

    Update the BLOB column of a revision with the contents of a file

    @param revision_id The object ID of the revision to update.
    @param tmpfile     The name of a temporary file containing the content.
    The file is deleted following the update.

} {

    db_1row get_storage_type {select 
        storage_type, item_id 
        from 
        cr_items 
        where 
        item_id = (select 
                   item_id 
                   from 
                   cr_revisions 
                   where revision_id = :revision_id)}

    if {[string equal $storage_type file]} {
        db_dml upload_file_revision "
                             update cr_revisions 
                             set filename = '[cr_create_content_file $item_id $revision_id $tmpfile]',
                             content_length = [file size $tmpfile]
                             where revision_id = :revision_id"
    } elseif {[string equal $storage_type text]} {
        # upload the file into the revision content
        db_dml upload_text_revision "update cr_revisions 
             set content = empty_blob(),
             content_length = [file size $tmpfile] where 
             revision_id = :revision_id
             returning content into :1" -blob_files [list $tmpfile]

    } else {
        # upload the file into the revision content
        db_dml upload_revision "update cr_revisions 
             set content = empty_blob(),
             content_length = [file size $tmpfile]
             where revision_id = :revision_id
             returning content into :1" -blob_files [list $tmpfile]
    }

    # delete the tempfile
    ns_unlink $tmpfile
}



ad_proc -public content::copy_content { revision_id_src revision_id_dest } {

    Update the BLOB column of one revision with the content of another revision

    @param revision_id_src  The object ID of the revision with the content to be 
    copied.

    @param revision_id_dest  The object ID of the revision to be updated.
    copied.

} {

    db_transaction {

        # copy the content from the source to the target
        db_exec_plsql cc_copy_content {
            begin
            content_revision.content_copy (
                                           revision_id      => :revision_id_src,
                                           revision_id_dest => :revision_id_dest
                                           );
            end;
        }
        
        # fetch the mime_type of the source revision
        set mime_type [db_string cc_get_mime_type ""]

        # copy the mime_type to the destination revision
        db_dml cc_update_cr_revisions ""
    }

}


ad_proc -public content::add_content { form_name revision_id } {

    Update the BLOB column of a revision with content submitted in a form

    @param revision_id  The object ID of the revision to be updated.

} {
    
    # if content exists, prepare it for insertion
    if { [template::element exists $form_name content] } {
        set filename [template::element get_value $form_name content]
        set tmpfile [prepare_content_file $form_name]
    } else { 
        set filename ""
        set tmpfile ""
    }

    if { ![string equal $tmpfile {}] } {
        db_transaction {
            upload_content $revision_id $tmpfile $filename
        }
    } 
}

ad_proc -public content::validate_name { form_name } {

    Make sure that name is unique for the folder

    @param form_name The name of the form (containing name and parent_id)
    @return 0 if there are items with the same name, 1 otherwise

} {
    set name [template::element get_value $form_name name] 
    set parent_id [template::element get_value $form_name parent_id]

    if { [template::util::is_nil parent_id] } {
        set same_name_count [db_string vn_same_name_count1 ""]
    } else {
        set same_name_count [db_string vn_same_name_count2 ""]
    }

    if { $same_name_count > 0 } {
        return 0
    } else {
        return 1
    }
}
