# packages/intranet-dynfield/tcl/intranet-dynfield-procs.tcl
ad_library {

  Support procs for the intranet-dynfield package

  @author Matthew Geddert openacs@geddert.com
  @author Juanjo Ruiz juanjoruizx@yahoo.es
  @creation-date 2004-09-28

  @vss $Workfile: intranet-dynfield-procs.tcl $ $Revision$ $Date$

}

ad_proc -public im_dynfield_storage_type_id_value { } { return 10007 }
ad_proc -public im_dynfield_storage_type_id_multimap { } { return 10005 }


namespace eval im_dynfield::util {}


# Add render_label element to get element labels in dynamic forms (works with flextag-init)
namespace eval template::element {}

ad_proc -private template::element::render_label { form_id element_id tag_attributes } {
    Render the -label text

    @param form_id	The identifier of the form containing the element.
    @param element_id     The unique identifier of the element within the form.
    @param tag_attributes Reserved for future use.
} {
  get_reference

  return $element(label)
}


ad_proc -public im_dynfield::type_category_for_object_type {
    -object_type:required
} {
    Get the category for the type_id of a given object_type
} {
    switch $object_type {
	im_project		{ set category_type "Intranet Project Type" }
	im_ticket		{ set category_type "Intranet Ticket Type" }
	im_company		{ set category_type "Intranet Project Type" }
	im_office		{ set category_type "Intranet Office Type" }
	user			{ set category_type "Intranet Project Type" }
	im_freelance_rfq	{ set category_type "Intranet Freelance RFQ Type" }
	im_freelance_rfq_answer	{ set category_type "Intranet Freelance RFQ Answer Type" }
	im_user_absence		{ set category_type "Intranet Absence Type" }
	im_expense		{ set category_type "Intranet Cost Type" }
	im_expense_bundle	{ set category_type "Intranet Cost Type" }
	default			{ set category_type "" }
    }
    return $category_type
}


ad_proc -public im_dynfield::status_category_for_object_type {
    -object_type:required
} {
    Get the category for the status_id of a given object_type
} {
    switch $object_type {
	im_project		{ set category_status "Intranet Project Status" }
	im_ticket		{ set category_status "Intranet Ticket Status" }
	im_company		{ set category_status "Intranet Project Status" }
	im_office		{ set category_status "Intranet Office Status" }
	user			{ set category_status "Intranet Project Status" }
	im_freelance_rfq	{ set category_status "Intranet Freelance RFQ Status" }
	im_freelance_rfq_answer	{ set category_status "Intranet Freelance RFQ Answer Status" }
	im_user_absence		{ set category_status "Intranet Absence Status" }
	im_expense		{ set category_status "Intranet Cost Status" }
	im_expense_bundle	{ set category_status "Intranet Cost Status" }
	default			{ set category_status "" }
    }
    return $category_status
}



namespace eval im_dynfield::attribute {}

ad_proc -public im_dynfield::attribute::get {
    -im_dynfield_attribute_id:required
    -array:required
} {
    Get the info on an im_dynfield_attribute
} {
    upvar 1 $array row
    db_1row select_attribute_info {} -column_array row
}

ad_proc -public im_dynfield::attribute::flush {
    -im_dynfield_attribute_id:required
} {
    Get the info on an im_dynfield_attribute
} {
    im_dynfield::attribute::get -im_dynfield_attribute_id $im_dynfield_attribute_id -array attribute_info

    set object_type $attribute_info(object_type)
    set attribute_name $attribute_info(attribute_name)
    im_dynfield::attribute::widget_flush -im_dynfield_attribute_id $im_dynfield_attribute_id
    im_dynfield::attribute::exists_p_flush -object_type $object_type -attribute_name $attribute_name
    im_dynfield::attribute::get_im_dynfield_attribute_id_flush -object_type $object_type -attribute_name  $attribute_name
    im_dynfield::attribute::name_flush -im_dynfield_attribute_id $im_dynfield_attribute_id
    im_dynfield::attribute::storage_type_flush -im_dynfield_attribute_id $im_dynfield_attribute_id

}


ad_proc -public im_dynfield::attribute::widget {
    -im_dynfield_attribute_id:required
    {-required:boolean}
} {
    @return an ad_form encoded attribute widget
} {
    set attribute_widget [im_dynfield::attribute::widget_cached -im_dynfield_attribute_id $im_dynfield_attribute_id]

    if { [string is false $required_p] } {
	# we need to add the optional flag
	set optional_attribute_widget ""
	set i "0"
	while { $i < [llength $attribute_widget] } {
	    if { $i == "0" } {
		# it is the first element in the list, so we add optional
		lappend optional_attribute_widget "[lindex $attribute_widget $i],optional"
	    } else {
		# this is not the first element in the list so we simple add
		# it back to the list
		lappend optional_attribute_widget [lindex $attribute_widget $i]
	    }
	    incr i
	}
	set attribute_widget $optional_attribute_widget
    }

    return $attribute_widget
}

ad_proc -private im_dynfield::attribute::widget_not_cached { 
    -im_dynfield_attribute_id:required
} {
    Returns an ad_form encoded attribute widget list, as used by other procs.
    @see im_dynfield::attribute::widget_cached
} {
    db_1row select_attribute {}

    set attribute_widget "${attribute_name}:${datatype}(${widget})"

    lappend attribute_widget [list "label" "\#${pretty_name}\#"]

    if { [exists_and_not_null parameters] } {
	# the parameters are already stored in list format
	# in the database so we just add them to the list
	append attribute_widget " ${parameters}"
    }

    if { $storage_type == "im_dynfield_options" } {
	set options {}
	db_foreach select_options {} {
	    lappend options [list [_ $option] [lindex $option_id]]
	}
	 lappend attribute_widget [list "options" $options]
    }
    return $attribute_widget
}

ad_proc -private im_dynfield::attribute::widget_cached {
    -im_dynfield_attribute_id:required
} {
    Returns an ad_form encoded attribute widget list, as used by other procs. Cached.
    @see im_dynfield::attribute::widget_not_cached
} {
    return [util_memoize [list im_dynfield::attribute::widget_not_cached -im_dynfield_attribute_id $im_dynfield_attribute_id]]
}


ad_proc -private im_dynfield::attribute::widget_flush {
    -im_dynfield_attribute_id:required
} {
    Returns an ad_form encoded attribute widget list, as used by other procs. Flush.
    @see im_dynfield::attribute::widget_not_cached
} {
    return [util_memoize_flush [list im_dynfield::attribute::widget_not_cached -im_dynfield_attribute_id $im_dynfield_attribute_id]]
}


ad_proc -private im_dynfield::attribute::exists_p {
    -object_type:required
    -attribute_name:required
} {
    Check if the intranet-dynfield attribute already exists.<br>
    Considers the case that intranet-dynfield got installed and deinstalled
    before, so it only considers attributes that exist in both
    acs_attributes and im_dynfield_attributes.

    @return 1 if the attribute_name exists for this object_type and 
	    0 if the attribute_name does not exist
} {
    set attribute_exists_p [db_string attribute_exists "
	select count(*) 
	from
		acs_attributes a,
		im_dynfield_attributes fa
	where
		a.attribute_id = fa.acs_attribute_id
		and a.object_type = :object_type
		and a.attribute_name = :attribute_name
    " -default 0]
    return $attribute_exists_p

#    set im_dynfield_attribute_id [im_dynfield::attribute::get_im_dynfield_attribute_id -object_type $object_type -attribute_name $attribute_name]
}


ad_proc -private im_dynfield::attribute::exists_p_flush {
    -object_type:required
    -attribute_name:required
} {
    
    does an attribute with this given attribute_name for this object type exists? Flush.

    @return im_dynfield_attribute_id if none exists then it returns blank
} {
    return [util_memoize_flush [list im_dynfield::attribute::get_im_dynfield_attribute_id_not_cached -object_type $object_type -attribute_name $attribute_name]]
}


ad_proc -private im_dynfield::attribute::get_im_dynfield_attribute_id {
    -object_type:required
    -attribute_name:required
} {
    
    return the im_dynfield_attribute_id for the given im_dynfield_attriubte_name belonging to this object_type. Cached.

    @return im_dynfield_attribute_id if none exists then it returns blank
} {

    return [util_memoize [list im_dynfield::attribute::get_im_dynfield_attribute_id_not_cached -object_type $object_type -attribute_name $attribute_name]]
}

ad_proc -private im_dynfield::attribute::get_im_dynfield_attribute_id_not_cached {
    -object_type:required
    -attribute_name:required
} {
    
    return the im_dynfield_attribute_id for the given im_dynfield_attriubte_name belonging to this object_type.

    @return im_dynfield_attribute_id if none exists then it returns blank
} {

    return [db_string get_im_dynfield_attribute_id {} -default {}]
}

ad_proc -private im_dynfield::attribute::get_im_dynfield_attribute_id_flush {
    -object_type:required
    -attribute_name:required
} {
    
    return the im_dynfield_attribute_id for the given im_dynfield_attriubte_name belonging to this object_type. Flush.

    @return im_dynfield_attribute_id if none exists then it returns blank
} {

    return [util_memoize_flush [list im_dynfield::attribute::get_im_dynfield_attribute_id_not_cached -object_type $object_type -attribute_name $attribute_name]]
}

ad_proc -public im_dynfield::attribute::new {
    {-im_dynfield_attribute_id ""}
    -object_type:required
    -attribute_name:required
    -pretty_name:required
    -pretty_plural:required
    {-default_value ""}
    {-description ""}
    -widget_name:required
    {-deprecated:boolean}
    {-context_id ""}
    {-no_complain:boolean}
    {-options}
} {
    create a new im_dynfield_attribute

    <p><dt><b>widget_name</b></dt><p>
    <dd>
       This should be a widget_name used by intranet-dynfield. All available widgets can be found at <a href="/intranet-dynfield/widgets">/intranet-dynfield/widgets</a>.
    </dd>
    </dl>


    @param context_id defaults to package_id
    @param no_complain silently ignore attributes that already exist.
    @param options a list of options for an im_dynfield_object that has the im_dynfield_options storage type the options will be ordered in the order of the list
    @return im_dynfield_attribute_id
} {

    switch $widget_name {
	textbox  { set widget_name "textbox_medium" }
	textarea { set widget_name "textarea_medium" }
	richtext { set widget_name "richtext_medium" }
	address  { set widget_name "postal_address" }
	phone    { set widget_name "telecom_number" }
    }
    im_dynfield::attribute::exists_p_flush -object_type $object_type -attribute_name $attribute_name
    if { [im_dynfield::attribute::exists_p -object_type $object_type -attribute_name $attribute_name] } {
	if { !$no_complain_p } {
	    error "Attribute $attribute_name Already Exists" "The attribute \"$attribute_name\" already exists for object_type \"$object_type\""
	} else {
	    return [im_dynfield::attribute::get_im_dynfield_attribute_id -object_type $object_type -attribute_name $attribute_name]
	}
    } else {
	set lang_key "intranet-dynfield.$object_type\:$attribute_name\:"
	set pretty_name_key "$lang_key\pretty_name"
	set pretty_plural_key "$lang_key\pretty_plural"
	# register lang messages
	_mr en $pretty_name_key $pretty_name
	_mr en $pretty_plural_key $pretty_plural
	
	set pretty_name $pretty_name_key
	set pretty_plural $pretty_plural_key
	

	if { [exists_and_not_null description] } {
	    set description_key "$lang_key\description"
	    # register lang messages
	    _mr en $description_key $description
	    set description $description_key
	}


	if { [empty_string_p $context_id] } {
	    set context_id [im_dynfield::package_id]
	}
	set extra_vars [ns_set create]
	oacs_util::vars_to_ns_set -ns_set $extra_vars -var_list {im_dynfield_attribute_id object_type attribute_name pretty_name pretty_plural default_value description widget_name deprecated_p context_id}
	set im_dynfield_attribute_id [package_instantiate_object -extra_vars $extra_vars im_dynfield_attribute]

	# now we define options for an attribute - if they are provided and the attribute accepts options
	if { [string equal [im_dynfield::attribute::storage_type -im_dynfield_attribute_id $im_dynfield_attribute_id] "im_dynfield_options"] && [exists_and_not_null options] } {
	    foreach { option } $options {
		im_dynfield::option::new -im_dynfield_attribute_id $im_dynfield_attribute_id -option $option
	    }
	}
	return $im_dynfield_attribute_id
    }
}


ad_proc -private im_dynfield::attribute::name_not_cached {
    -im_dynfield_attribute_id:required
} {
    get the name of an im_dynfield_attribute

    @return attribute_name

    @see im_dynfield::attribute::name
    @see im_dynfield::attribute::name_flush
} {
    return [db_string im_dynfield_attribute_name {}]
}


ad_proc -public im_dynfield::attribute::name {
    -im_dynfield_attribute_id:required
} {
    get the name of an im_dynfield_attribute. Cached.

    @return attribute pretty_name

    @see im_dynfield::attribute::name_not_cached
    @see im_dynfield::attribute::name_flush
} {
    return [util_memoize [list im_dynfield::attribute::name_not_cached -im_dynfield_attribute_id $im_dynfield_attribute_id]]
}


ad_proc -private im_dynfield::attribute::name_flush {
    -im_dynfield_attribute_id:required
} {
    Flush the storage_type of an im_dynfield_attribute.

    @return attribute pretty_name

    @see im_dynfield::attribute::name_not_cached
    @see im_dynfield::attribute::name_flush
} {
    util_memoize_flush [list im_dynfield::attribute::name_not_cached -im_dynfield_attribute_id $im_dynfield_attribute_id]
}


ad_proc -private im_dynfield::attribute::storage_type_not_cached { 
    -im_dynfield_attribute_id:required
} {
    get the storage_type of an im_dynfield_attribute

    @return storage_type

    @see im_dynfield::attribute::storage_type
    @see im_dynfield::attribute::storage_type_flush
} {
    return [db_string im_dynfield_attribute_storage_type {}]
}


ad_proc -public im_dynfield::attribute::storage_type {
    -im_dynfield_attribute_id:required
} {
    get the storage_type of an im_dynfield_attribute. Cached.

    @return attribute pretty_name

    @see im_dynfield::attribute::storage_type_not_cached
    @see im_dynfield::attribute::storage_type_flush
} {
    return [util_memoize [list im_dynfield::attribute::storage_type_not_cached -im_dynfield_attribute_id $im_dynfield_attribute_id]]
}


ad_proc -private im_dynfield::attribute::storage_type_flush {
    -im_dynfield_attribute_id:required
} {
    Flush the storage_type of a cached im_dynfield_attribute.

    @return attribute pretty_name

    @see im_dynfield::attribute::storage_type_not_cached
    @see im_dynfield::attribute::storage_type_flush
} {
    util_memoize_flush [list im_dynfield::attribute::storage_type_not_cached -im_dynfield_attribute_id $im_dynfield_attribute_id]
}

ad_proc -public im_dynfield::attribute::value {
    -object_id:required
    -im_dynfield_attribute_id:required
} {
    this code returns the cached attribute value for a specific im_dynfield_attribute
} {
    set attribute_values_and_ids [im_dynfield::object::attributes::list_format -object_id $object_id]
    set attribute_value ""
    foreach attribute_value_and_id $attribute_values_and_ids {
	if { [lindex $attribute_value_and_id 0] == $im_dynfield_attribute_id } {
	    set attribute_value [lindex $attribute_value_and_id 1]
	}
    }
    return $attribute_value 
}

ad_proc -public im_dynfield::attribute::value_from_name {
    -object_type:required
    -attribute_name:required
    -object_id:required
} {
    this code returns the cached attribute value for a specific im_dynfield_attribute
} {
    return [im_dynfield::attribute::value -object_id $object_id [im_dynfield::attribute::get_im_dynfield_attribute_id -object_type $object_type -attribute_name $attribute_name]]
}


namespace eval im_dynfield::attribute::value {}

ad_proc -public im_dynfield::attribute::value::new {
    -revision_id:required
    -im_dynfield_attribute_id:required
    -attribute_value:required
} {
    this code saves attributes input in a form
} {
    set storage_type [im_dynfield::attribute::storage_type -im_dynfield_attribute_id $im_dynfield_attribute_id]
    set option_map_id ""
    set address_id ""
    set number_id ""
    set time ""
    set value ""
    set value_mime_type ""

    switch $storage_type {

	im_dynfield_options {
	    # we need to loop through the values
	    # on the first option_map_id the option_map_id
	    # will be set.
	    foreach { option_id } $attribute_value {
		set option_map_id [im_dynfield::option::map -option_map_id $option_map_id -option_id $option_id]
	    }
	}

	time {
	    set value $attribute_value
	}

	value {
	    set value $attribute_value
	}

	value_with_mime_type {
	    set value	   [template::util::richtext::get_property contents $attribute_value]
	    set value_mime_type [template::util::richtext::get_property format $attribute_value]
	}
    }

    db_dml insert_attribute_value {}
}


ad_proc -public im_dynfield::attribute::value::superseed {
    -revision_id:required
    -im_dynfield_attribute_id:required
    -im_dynfield_object_id:required
} {
    superseed an attribute value
} {
    db_dml superseed_attribute_value {}
}

namespace eval im_dynfield::multirow {}

ad_proc -private im_dynfield::multirow::extend {
    -package_key:required
    -object_type:required
    -list_name:required
    -multirow:required
    -key:required
} {
    append im_dynfield_attribute_values to a multirow
} {
    set list_id [im_dynfield::list::get_list_id \
		     -package_key $package_key \
		     -object_type $object_type \
		     -list_name $list_name]


    # first we make sure all the attribute_values are efficiently cached
    # i.e. we only do one trip to the database, instead of one for
    # each object in the multirow
    set object_id_list ""
    template::multirow foreach $multirow {
	lappend object_id_list [set $key]
    }
    if { [exists_and_not_null object_id_list] } {
	im_dynfield::object::attribute::values_batch_process -object_id_list $object_id_list
    }

    # now we extend the multirow with the im_dynfield_attribute_names
    set im_dynfield_attribute_ids [im_dynfield::list::im_dynfield_attribute_ids -list_id $list_id]
    set im_dynfield_attribute_names {}
    foreach im_dynfield_attribute_id $im_dynfield_attribute_ids {
	set im_dynfield_attribute_name [im_dynfield::attribute::name -im_dynfield_attribute_id $im_dynfield_attribute_id]
	lappend im_dynfield_attribute_names $im_dynfield_attribute_name
	template::multirow extend $multirow $im_dynfield_attribute_name
    }

    # now we populate the multirow with im_dynfield_attribute_values
    template::multirow foreach $multirow {
	# first we set a null value for all im_dynfield_attribute_names
	# since the im_dynfield::object::attribute::values proc only
	# returns those im_dynfield_attribute_values that do not 
	# have a null value
	foreach im_dynfield_attribute_name im_dynfield_attribute_names {
	    set [set $im_dynfield_attribute_name] {}
	}
	im_dynfield::object::attribute::values -vars -object_id [set $key]
    }
}




namespace eval im_dynfield::object {}

namespace eval im_dynfield::object::attribute {}




ad_proc -private im_dynfield::object::attribute::value_memoize {
    -object_id:required
    -im_dynfield_attribute_id:required
    -attribute_value:required
} {
    memoize an im_dynfield::object::attribute::value
} {
    if { [string is true [util_memoize_cached_p [list im_dynfield::object::attribute::values_not_cached -object_id $object_id]]] } {
	array set $object_id [util_memoize [list im_dynfield::object::attribute::values_not_cached -object_id $object_id]]	
    }
    # if a value previously existed it will be superseeded
    set ${object_id}($im_dynfield_attribute_id) $attribute_value
    util_memoize_seed [list im_dynfield::object::attribute::values_not_cached -object_id $object_id] [array get ${object_id}]
}

ad_proc -public  im_dynfield::object::attribute::value {
    -object_id:required
    -im_dynfield_attribute_id:required
} {
} {
    im_dynfield::object::attribute::values -array $object_id -object_id $object_id
    if { [info exists ${object_id}($im_dynfield_attribute_id)] } {
	return ${object_id}($im_dynfield_attribute_id)
    } else {
	return {}
    }
}

ad_proc -public  im_dynfield::object::attribute::values {
    -object_id:required
    {-ids:boolean}
    {-vars:boolean}
    {-array ""}
} {
    @param ids - if specified we will return the im_dynfield_attribute_id instead of the attribute_name
    @param array - if specified the attribute values are returned in the given array
    @param vars - if sepecified the attribute values vars are returned to the calling environment

    if neither array nor vars are specified then a list is returned
} {
    set attribute_values_list [util_memoize [list im_dynfield::object::attribute::values_not_cached -object_id $object_id]]
    if { !$ids_p } {
	set attribute_values_list_with_names ""
	foreach { key value } $attribute_values_list {
	    lappend attribute_values_list_with_names [im_dynfield::attribute::name -im_dynfield_attribute_id $key]
	    lappend attribute_values_list_with_names $value
	}
	set attribute_values_list $attribute_values_list_with_names
    }
    if { [exists_and_not_null array] } {
	upvar $array row
	array set row $attribute_values_list
    } elseif { $vars_p } {
	set attribute_value_info [ns_set create]
	foreach { key value } $attribute_values_list {
	    ns_set put $attribute_value_info $key $value
	}
	# Now, set the variables in the caller's environment
	ad_ns_set_to_tcl_vars -level 2 $attribute_value_info
	ns_set free $attribute_value_info
    } else {
	return $attribute_values_list
    }
}


ad_proc -private im_dynfield::object::attribute::values_not_cached {
    -object_id:required
} {
} {
    im_dynfield::object::attribute::values_batch_process -object_id_list $object_id
    if { [string is true [util_memoize_cached_p [list im_dynfield::object::attribute::values_not_cached -object_id $object_id]]] } {
	return [util_memoize [list im_dynfield::object::attribute::values_not_cached -object_id $object_id]]	
    } else {
	return {}
    }
}


ad_proc -private im_dynfield::object::attribute::values_flush {
    -object_id:required
} {
} {
    return [util_memoize_flush [list im_dynfield::object::attribute::values_not_cached -object_id $object_id]]
}


ad_proc -private im_dynfield::object::attribute::values_batch_process {
    -object_id_list:required
} {
    @param object_ids a list of object_ids for which to save attributes in their respective caches.
    get these objects attribute values in a list format
} {
    set objects_to_cache ""
    foreach object_id_from_list $object_id_list {
	if { [string is false [util_memoize_cached_p [list im_dynfield::object::attribute::values -object_id $object_id_from_list]]] } {
	    lappend objects_to_cache $object_id_from_list
	}
    }
    if { [exists_and_not_null objects_to_cache] } {
	set sql_object_id_list [im_dynfield::util::sqlify_list -list $objects_to_cache]
	db_foreach get_attr_values "" {
	    switch [im_dynfield::attribute::storage_type -im_dynfield_attribute_id $im_dynfield_attribute_id] {
		telecom_number {
		    set attribute_value $telecom_number_string
		}
		postal_address {
		    set attribute_value $address_string
		}
		im_dynfield_options {
		    set attribute_value $options_string
		}
		time {
		    set attribute_value $time
		}
		value {
		    set attribute_value $value 
		}
		value_with_mime_type {
		    set attribute_value [list $value $value_mime_type] 
		}
	    }
	    set ${object_id}($im_dynfield_attribute_id) $attribute_value
	}
	foreach object_id_from_list $object_id_list {
	    util_memoize_seed [list im_dynfield::object::attribute::values_not_cached -object_id $object_id_from_list] [array get ${object_id_from_list}]
	}
    }
}



namespace eval im_dynfield::object::revision {}


ad_proc -public im_dynfield::object::revision::new {
    {-package_id ""}
    -object_id:required
} {
    create a new im_dynfield_object_revision

    @return revision_id
} {
    if { [empty_string_p $package_id] } {
	set package_id [im_dynfield::package_id]
    }
    set extra_vars [ns_set create]
    oacs_util::vars_to_ns_set -ns_set $extra_vars -var_list { object_id package_id }
    set revision_id [package_instantiate_object -extra_vars $extra_vars im_dynfield_object_revision]

    return $revision_id
}





namespace eval im_dynfield::list {}

ad_proc -public im_dynfield::list::get {
    -list_id:required
    -array:required
} {
    Get the info on an im_dynfield_attribute
} {
    upvar 1 $array row
    db_1row select_list_info {} -column_array row
}

ad_proc -private im_dynfield::list::im_dynfield_attribute_ids_not_cached {
    -list_id:required
} {
    Get a list of im_dynfield_attributes.

    @return list of im_dynfield_attribute_ids, in the correct order

    @see im_dynfield::list::im_dynfield_attribute_ids
    @see im_dynfield::list::im_dynfield_attribute_ids_flush
} {
    return [db_list im_dynfield_attribute_ids {}]
}

ad_proc -private im_dynfield::list::im_dynfield_attribute_ids {
    -list_id:required
} {
    get this lists im_dynfield_attribute_ids. Cached.

    @return list of im_dynfield_attribute_ids, in the correct order

    @see im_dynfield::list::im_dynfield_attribute_ids_not_cached
    @see im_dynfield::list::im_dynfield_attribute_ids_flush
} {
    return [util_memoize [list im_dynfield::list::im_dynfield_attribute_ids_not_cached -list_id $list_id]]
}

ad_proc -private im_dynfield::list::im_dynfield_attribute_ids_flush {
    -list_id:required
} {
    Flush this lists im_dynfield_attribute_ids cache.

    @return list of im_dynfield_attribute_ids, in the correct order

    @see im_dynfield::list::im_dynfield_attribute_ids_not_cached
    @see im_dynfield::list::im_dynfield_attribute_ids
} {
    return [util_memoize_flush [list im_dynfield::list::im_dynfield_attribute_ids_not_cached -list_id $list_id]]
}



ad_proc -private im_dynfield::list::exists_p {
    -package_key:required
    -object_type:required
    -list_name:required
} {
    does an intranet-dynfield list like this exist?

    @return 1 if the list exists for this object_type and package_key and 0 if the does not exist
} {
    set list_id [im_dynfield::list::get_list_id_not_cached -package_key $package_key -object_type $object_type -list_name $list_name]
    if { [exists_and_not_null list_id] } {
	return 1
    } else {
	return 0
    }
}

ad_proc -private im_dynfield::list::flush {
    -package_key:required
    -object_type:required
    -list_name:required
} {
    flush all inte info we have on an im_dynfield_list

    @return 1 if the list exists for this object_type and package_key and 0 if the does not exist
} {
    im_dynfield::list::im_dynfield_attribute_ids_flush -list_id [im_dynfield::list::get_list_id_not_cached -package_key $package_key -object_type $object_type -list_name $list_name]
    im_dynfield::list::get_list_id_flush -package_key $package_key -object_type $object_type -list_name $list_name
}

ad_proc -private im_dynfield::list::get_list_id {
    -package_key:required
    -object_type:required
    -list_name:required
} {
    
    return the list_id for the given parameters. Chached.

    @return list_id if none exists then it returns blank
} {
    return [util_memoize [list im_dynfield::list::get_list_id_not_cached -package_key $package_key -object_type $object_type -list_name $list_name]]
}


ad_proc -private im_dynfield::list::get_list_id_not_cached {
    -package_key:required
    -object_type:required
    -list_name:required
} {
    return the list_id for the given parameters

    @return list_id if none exists then it returns blank
} {

    return [db_string get_list_id {} -default {}]
}

ad_proc -private im_dynfield::list::get_list_id_flush {
    -package_key:required
    -object_type:required
    -list_name:required
} {
    
    flush the memorized list_id for the given parameters.

    @return list_id if none exists then it returns blank
} {
    return [util_memoize_flush [list im_dynfield::list::get_list_id_not_cached -package_key $package_key -object_type $object_type -list_name $list_name]]
}

ad_proc -public im_dynfield::list::new {
    {-list_id ""}
    -package_key:required
    -object_type:required
    -list_name:required
    -pretty_name:required
    {-description ""}
    {-description_mime_type "text/plain"}
    {-context_id ""}
} {
    create a new im_dynfield_group

    @return group_id
} {
    if { [empty_string_p $context_id] } {
	set context_id [im_dynfield::package_id]
    }
    if { ![exists_and_not_null description] } {
	set description_mime_type ""
    }
    set lang_key "intranet-dynfield.$package_key\:$object_type\:$list_name"
    _mr en $lang_key $pretty_name
    set pretty_name $lang_key

    if { [exists_and_not_null description] } {
	set lang_key "intranet-dynfield.$package_key\:$object_type\:$list_name\:description"
	_mr en $lang_key $description
	set description $lang_key
    }

    set extra_vars [ns_set create]
    oacs_util::vars_to_ns_set -ns_set $extra_vars -var_list { list_id package_key object_type list_name pretty_name description description_mime_type }
    set list_id [package_instantiate_object -extra_vars $extra_vars im_dynfield_list]

    return $list_id
}


namespace eval im_dynfield::list::attribute {}

ad_proc -public im_dynfield::list::attribute::map {
    -list_id:required
    -im_dynfield_attribute_id:required
    {-sort_order ""}
    {-required_p "f"}
    {-section_heading ""}
} {
    Map an intranet-dynfield option for an attribute to an option_map_id, if no value is supplied for option_map_id a new option_map_id will be created.

    @param sort_order if null then the attribute will be placed as the last attribute in this groups sort order

    @return option_map_id
} {
    if { ![exists_and_not_null sort_order] } {
	set sort_order [expr 1 + [db_string get_highest_sort_order {} -default "0"]]
    }
    return [db_exec_plsql im_dynfield_list_attribute_map {}]
}

ad_proc -public im_dynfield::list::attribute::unmap {
    -list_id:required
    -im_dynfield_attribute_id:required
} {
    Unmap an intranet-dynfield option from an intranet-dynfield list
} {
    db_dml im_dynfield_list_attribute_unmap {}
}

ad_proc -public im_dynfield::list::attribute::required {
    -list_id:required
    -im_dynfield_attribute_id:required
} {
    Specify and im_dynfield_attribute as required in an intranet-dynfield list
} {
    db_dml im_dynfield_list_attribute_required {}
}

ad_proc -public im_dynfield::list::attribute::optional {
    -list_id:required
    -im_dynfield_attribute_id:required
} {
    Specify and im_dynfield_attribute as optional in an intranet-dynfield list
} {
    db_dml im_dynfield_list_attribute_optional {}
}



namespace eval im_dynfield::util {}



ad_proc -public im_dynfield::util::sqlify_list {
    -list:required
} {
    set output_list {}
    foreach item $list {
	if { [exists_and_not_null output_list] } {
	    append output_list ", "
	}
	regsub -all {'} $item {''} item
	append output_list "'$item'"
    }
    return $output_list
}


######




namespace eval im_dynfield:: {}


ad_proc -public im_dynfield::attribute_load {
    -object_type:required
    -object_id:required
} {
    set intranet-dynfield attributes values
} {
    db_1row object_type_info "
	select \
		table_name,\
		id_column\
	from \
		acs_object_types \
	where \
		object_type = :object_type
    "
    
    set object_type_tables [list [list $table_name $id_column]]
    set ext_object_type_tables [db_list_of_lists "get ext object_type tables" "
	select \
		table_name,\
		id_column \
       from \
		acs_object_type_tables\
       where \
		object_type = :object_type\
		"]
    if {[llength $ext_object_type_tables] > 0} {
	set object_type_tables [concat $object_type_tables $ext_object_type_tables]
    }
    foreach table_info $object_type_tables {
	set t_name [lindex $table_info 0]
	set i_column [lindex $table_info 1]
	
	if {![db_0or1row "get values" "select
					     t.*
				       from $t_name t
				       where $i_column = :object_id"] } {
			db_foreach "get attrib" "select 
					   attribute_name 
					   from acs_attributes 
					   where object_type = :object_type
					   and table_name = :t_name" {
					       set $attribute_name ""
					   }
	}
   }
}

ad_proc -public im_dynfield::attribute_show {
    -object_type:required
    {-page_url ""}
    {-style ""}
    {-form_id "dummy_form"}
} {
    Show intranet-dynfield attributes.<p>
    There are three posible 'positioning' cases, you have to define each in the intranet-dynfield admin pages:
    <ul>
     <li>absolute: we just wrap the label-widget attribute in div's using one *-absolute adp file. 
		   It is up to the css to place these attributes.
     <li>relative: we sort the attributes and display them using an *-relative adp file.
     <li>adp: There is an specific adp_file to format this form, use it.
    </ul></p>

    @option object_type       The object_type attributes you want to add to the form

    @option page_url	  Which page_url (from the ones defined in intranet-dynfield admin pages) you want to use. 
			      Default the one defined in intranet-dynfield admin pages.

    @option style	     The adp file you want to use for the templating, full path '/web/server/package/...'.
			      This overwrite the defaults explained in the 'positioning' cases.
} {

    if { [empty_string_p $page_url] } {
	# get default page_url
	set page_url [db_string get_default_page "
	    select page_url
	    from im_dynfield_layout_pages
	    where object_type = :object_type
	    and default_p = 't'
	" -default ""]
    }
    
    set return_html_widgets ""
    
    # verify correctness of page_url if something wrong just ignore dynamic position
    if { [db_0or1row exists_page_url_p "
	select 1 from im_dynfield_layout_pages 
	where object_type = :object_type and page_url = :page_url"] 
    } {
	db_1row get_page_info {
	    select layout_type, table_width, table_height, adp_file 
	    from im_dynfield_layout_pages
	    where object_type = :object_type and page_url = :page_url
	} -column_array "page"
	set attrib_list [db_list_of_lists get_page_attributes {
	select attr.attribute_id,
		   attr.pretty_name,
		   attr.attribute_name,
		   flex.attribute_id as flex_attr_id,
		   flex.widget_name,
		   fl.class as class,
		   fl.sort_key
	from acs_attributes attr,
		 im_dynfield_attributes flex,
		 im_dynfield_layout fl
	where attr.object_type = :object_type 
	and attr.attribute_id = flex.acs_attribute_id
	and fl.attribute_id = flex.attribute_id
	and fl.page_url = :page_url
	and fl.object_type = :object_type
	order by fl.sort_key
	}]
    } else {	
	set attrib_list [db_list_of_lists  "get intranet-dynfield attributes" "select \
		attr.attribute_id,\
		attr.pretty_name,\
		attr.attribute_name,\
		flex.attribute_id as flex_attr_id,\
		flex.widget_name,\
		'' as class \
		from \
		acs_attributes attr,\
		im_dynfield_attributes flex \
		where \
		attr.object_type = :object_type \
		and attr.attribute_id = flex.acs_attribute_id"] 
    }

    set form_elements [list]
    foreach attrib $attrib_list {
	set attribute_id [lindex $attrib 0]
	set pretty_name [lindex $attrib 1]
	set attribute_name [lindex $attrib 2]
	set flex_attr_id [lindex $attrib 3]
	set widget_name [lindex $attrib 4]
	set class [lindex $attrib 5]

	db_1row "get widget info" "select storage_type,\
		acs_datatype,\
		widget,\
		parameters,\
		sql_datatype\
		from im_dynfield_widgets \
		where widget_name = :widget_name"


	# jruiz add positional parameter to html
	if { ![empty_string_p $class] } {
	    lappend parameters [list "class" $class]
	}


	# avila 20050208
	# copy from widget-examples
	# to be revised
	upvar $attribute_name value
	if {![info exists value]} { set value ""}

	# use the not used -help parameter (for dates) to manage the div wrappers in the adp
	set form_element "$attribute_name:${acs_datatype}(${widget}),optional {value \"$value\"} {html $parameters} {help $class}"
	if {$widget != "im_dynfield_hidden"} {
		append form_element " {label \"$pretty_name\"}"
	}
	
	if { [exists_and_not_null parameters] } {
	    append form_element " ${parameters}"
	}
	lappend form_elements $form_element
	
    }

    # if we do not have an specific style, find the corresponding from layout_type
    set tag_attributes [list]
    if { [empty_string_p $style] } {
	switch -- $page(layout_type) {
	    absolute {
		set adp_file [parameter::get_from_package_key -package_key intranet-dynfield -parameter absolute_template -default "default-absolute"]
		set cols 1
	    }
	    relative {
		set adp_file [parameter::get_from_package_key -package_key intranet-dynfield -parameter relative_template -default "default-relative"]
		#set cols "$page(table_width)" 
		#set headers "headers"
		#set title "title"
		#foreach varname {headers title cols} {
		#    lappend tag_attributes $varname [set $varname]
		#    set form_properties($varname) [set $varname]
		#}
	    }
	    adp {
		set adp_file $page(adp_file)
		set cols 1
	    }
	}
	set style "../../../intranet-dynfield/resources/forms/${adp_file}"
	#ns_log Notice "Style --------> ../../../intranet-dynfield/resources/forms/${adp_file}"
    }

    # Call ad_form to actually render the attributes.
    # Don't call ad_form if there is no associated attribute
    # to avoid a runtime error
    if {0 < [llength $form_elements]} {
	ad_form -name $form_id -form $form_elements -on_submit {}
	set return_html_widgets [list $form_id $style $cols]
   }

    return $return_html_widgets
    
}



ad_proc -public im_dynfield::search_sql_criteria_from_form {
    -form_id:required
    -object_type:required
} {
    This procedure generates a subquery SQL clause
    "(select object_id from ...)" that can be used
    by a main query clause either as a "where xxx_id in ..."
    or via a join in order to limit the number of object_ids
    to the ones that fit to the filter criteria.

    @param form_id:
   	    search form id
    @return:
		An array consisting of:
		where: A SQL phrase and
		bind_vars: a key-value paired list carrying the bind
			vars for the SQL phrase
} {
    # Get the list of all elements in the form
    set form_elements [template::form::get_elements $form_id]

    # Get the main table for the data type
    db_1row main_table "
	select
		table_name as main_table_name,
		id_column as main_id_column
	from
		acs_object_types
	where
		object_type = :object_type
    "

    set attributes_sql "
	select
		a.attribute_id,
		a.table_name as attribute_table_name,
		a.attribute_name,
		at.pretty_name,
		a.datatype,
		case when a.min_n_values = 0 then 'f' else 't' end as required_p,
		a.default_value,
		t.table_name as object_type_table_name,
		t.id_column as object_type_id_column,
		at.table_name as attribute_table,
		at.object_type as attr_object_type
	from
		acs_object_type_attributes a,
		im_dynfield_attributes aa,
		acs_attributes at,
		acs_object_types t
	where
		a.object_type = :object_type
		and t.object_type = a.ancestor_type
		and a.attribute_id = aa.acs_attribute_id
		and a.attribute_id = at.attribute_id
	order by
		attribute_id
    "

    set ext_table_sql "
	select distinct
		attribute_table_name as ext_table_name,
		object_type_id_column as ext_id_column
	from
		($attributes_sql) s
    "
    set ext_tables [list]
    set ext_table_join_where ""
    db_foreach ext_tables $ext_table_sql {
	if {$ext_table_name == ""} { continue }
	if {$ext_table_name == $main_table_name} { continue }

	lappend ext_tables $ext_table_name
	append ext_table_join_where "\tand $main_table_name.$main_id_column = $ext_table_name.$ext_id_column\n"
    }

    set bind_vars [ns_set create]
    set criteria [list]
    db_foreach attributes $attributes_sql {
	
	# Check whether the attribute is part of the form
	if {[lsearch $form_elements $attribute_name] >= 0} {
	    set value [template::element::get_value $form_id $attribute_name]
	    if {"" == $value} { continue }
	    ns_set put $bind_vars $attribute_name $value
	    lappend criteria "$attribute_table_name.$attribute_name = :$attribute_name"
	}
    }

    set where_clause [join $criteria " and\n            "]
    if { ![empty_string_p $where_clause] } {
	set where_clause " and $where_clause"
    }

    set sql "
	(select
		$main_id_column as object_id
	from	
		[join [concat [list $main_table_name] $ext_tables] ",\n\t"]
	where	1 = 1 $ext_table_join_where
		$where_clause
	)
    "

    # Skip empty where clause
    if {"" == $where_clause} {
	set sql "" 
    }

    set extra(where) $sql
    set extra(bind_vars) [util_ns_set_to_list -set $bind_vars]
    ns_set free $bind_vars

    return [array get extra]
}





ad_proc -public im_dynfield::create_clone_update_sql {
    -object_type:required
    -object_id:required
} {
    Returns an SQL update statement that can be executed in
    the context of an object clone() procedure in order to
    update dynfields from variables in memory, pulled out
    of the DB by a statement such as "select p.* from im_projects...".
} {
    # Get the main table for the data type
    db_1row main_table "
	select
		table_name as main_table_name,
		id_column as main_id_column
	from
		acs_object_types
	where
		object_type = :object_type
    "

    set attributes_sql "
	select
		a.attribute_id,
		a.table_name as attribute_table_name,
		a.attribute_name,
		at.pretty_name,
		a.datatype,
		case when a.min_n_values = 0 then 'f' else 't' end as required_p,
		a.default_value,
		t.table_name as object_type_table_name,
		t.id_column as object_type_id_column,
		at.table_name as attribute_table,
		at.object_type as attr_object_type
	from
		acs_object_type_attributes a,
		im_dynfield_attributes aa,
		acs_attributes at,
		acs_object_types t
	where
		a.object_type = :object_type
		and t.object_type = a.ancestor_type
		and a.attribute_id = aa.acs_attribute_id
		and a.attribute_id = at.attribute_id
	order by
		attribute_id
    "

    set sql "update $main_table_name set\n"
    set komma_required 0
    db_foreach attributes $attributes_sql {
	if {$komma_required} { append sql "," }
	append sql "\t$attribute_name = :$attribute_name\n"
	set komma_required 1
    }

    append sql "where $main_id_column = $object_id\n"

    return $sql
}



ad_proc -public im_dynfield::set_form_values_from_http {
    -form_id:required
} {
    Set the values of a form based on the values from "ns_conn form".
    This procedure is usefule when using an ad_form as a "filter"
    selector in P/O index ("report") pages, to pass the URL
    parameters to the form.

    @param form_id:
		search form id
    @return:
		nothing

} {
    ns_log Notice "im_dynfield::set_form_values_from_form: form_id=$form_id"
    
    set form_elements [template::form::get_elements $form_id]
    set form_vars [ns_conn form]
    
    if {"" == $form_vars} { 
	# There are no variables from HTTP - so there
	# are not values to be set...
	return "" 
    }

    foreach element $form_elements {

	# Only set the values for variables that are found in the
	# HTTP variable frame to avoid ambiguities
	set pos [ns_set find $form_vars $element]
	if {$pos >= 0} {
	   set value [ns_set get $form_vars $element]
	   template::element::set_value $form_id $element $value
	
	   ns_log Notice "set_form_values_from_http: request_form: $element = $value"
	}
    }
}


ad_proc -public im_dynfield::set_local_form_vars_from_http {
    -form_id:required
} {
    Set local variables to the values passed on in HTTP,
    so that we don't need to add all of them into the ad_header.
    @param form_id: search form id
    @return:	Form_vars that are also in the HTTP are set to the
		calling variable frame
} {
    ns_log Notice "im_dynfield::set_local_form_vars_form_http: form_id=$form_id"
    
    set form_elements [template::form::get_elements $form_id]
    set form_vars [ns_conn form]
    
    if {"" == $form_vars} { 
	# There are no variables from HTTP - so there
	# are not values to be set...
	return "" 
    }

    foreach element $form_elements {
	# Only set the values for variables that are found in the
	# HTTP variable frame to avoid ambiguities
	set pos [ns_set find $form_vars $element]
	if {$pos >= 0} {
	   set value [ns_set get $form_vars $element]

	   # Write the values to the calling stack frame
	   upvar $element $element
	   set $element $value
	}
	append debug " $element"
    }
}


ad_proc -public im_dynfield::attribute_store {
    -object_type:required
    -object_id:required
    -form_id:required
    {-user_id ""}
} {
    Store intranet-dynfield attributes.
    Basicly, the procedure copies all values of the form into
    local variables and then builds an update statement to update
    the object's main table with the local variables.

    Doesn't support "extension tables" yet (storing attributes in
    tables different from the main object's table).
} {
    # -------------------------------------------------
    # Defaults and setup
    # -------------------------------------------------

    if {"" == $user_id} { set user_id [ad_get_user_id] }
    set object_id_org $object_id
    ns_log Notice "im_dynfield::attribute_store: object_type=$object_type, object_id=$object_id_org, form_id=$form_id"

    # Get the list of all variables of the last form
    template::form get_values $form_id

    # Get object_type main table and column id
    db_1row get_main_table "
	select	table_name as main_table,
		id_column as main_table_id_column
	from	acs_object_types
	where 	object_type = :object_type
    "

    # -------------------------------------------------
    # Create the update SQL statement
    # -------------------------------------------------

    set attribute_sql "
	select	da.attribute_id as dynfield_attribute_id,
		*
	from	im_dynfield_attributes da,
		acs_attributes aa,
		im_dynfield_widgets dw
	where
		da.acs_attribute_id = aa.attribute_id
		and aa.object_type = :object_type
		and da.widget_name = dw.widget_name
		and 't' = acs_permission__permission_p(da.attribute_id, :user_id, 'write')
    "
    set update_lines [list]
    db_foreach attributes $attribute_sql {

	# Skip attributes that do not exists in (the partial) form.
	if {![template::element::exists $form_id $attribute_name]} { continue }

	# Empty table name? Ugly, but that's the main table then...
	if {[empty_string_p $table_name]} { set table_name $main_table }

	# Is this a multi-value field?
	set multiple_p [template::element::get_property $form_id $attribute_name multiple_p]
	if {[empty_string_p $multiple_p]} { set multiple_p 0 }	
	if {$storage_type_id == [im_dynfield_storage_type_id_multimap]} { set multiple_p 1 }

	if {!$multiple_p} {

	    # Special treatment for certain types of widgets
	    set widget_element [template::element::get_property $form_id $attribute_name widget]
	    switch $widget_element {
		date {
		    lappend update_lines "\n\t\t\t$attribute_name = [template::util::date::get_property sql_date [set $attribute_name]]"
		}
		default {
		    lappend update_lines "\n\t\t\t$attribute_name = :$attribute_name"
		}
	    }

	} else {

	    # Multi-value field. This must be a field with widget multi-select...
	    ad_return_complaint 1 "Storing multiple values not tested yet: $attribute_name"
	    db_transaction {
		db_dml "delete previous values" "
			delete from im_dynfield_attr_multi_value
			where object_id = :object_id_org 
			and attribute_id = :attribute_id
		"
		foreach val [template::element::get_values $form_id $attribute_name] {
		    db_dml "create multi value" "
			insert into im_dynfield_attr_multi_value (attribute_id,object_id,value) 
			values (:attribute_id,:object_id_org,:val)"
		}
	    }
	}
    }

    # Execute the update statement, assuming that all
    # variables will be available as local variables.
    if {[llength $update_lines] > 0} {
	set sql "
		update $main_table set[join $update_lines ","]
		where $main_table_id_column = :object_id_org
	"
	db_dml update_object $sql
    }
}







ad_proc -public im_dynfield::attribute_store_badbug {
    -object_type:required
    -object_id:required
    -form_id:required
    {-user_id ""}
} {
    store intranet-dynfield attributes 
} {
    if {"" == $user_id} { set user_id [ad_get_user_id] }
    ns_log Notice "im_dynfield::attribute_store: object_type=$object_type, object_id=$object_id, form_id=$form_id"

    # object_id may get destroyed with strange forms
    set object_id_param $object_id

    # Get the list of all variables of the last form
    template::form get_values $form_id
    
    # get object_type main table and column id
    db_1row get_main_table "
	select	table_name as main_table_name,
		id_column as main_id_column
	from	acs_object_types
	where 	object_type = :object_type
    "

    # get object_type extension tables
    set object_type_tables [db_list_of_lists ext_tables "
                select  table_name,
                        id_column
                from    acs_object_types
                where   object_type = :object_type
        UNION
                select  table_name,
                        id_column
                from    acs_object_type_tables
                where   object_type = :object_type
    "]
    ns_log Notice "im_dynfield::attribute_store: main_table=$main_table_name, object_type_tables=$object_type_tables"

    # The Insert piece: Check if values need to be inserted into extension tables.
    db_transaction {
    	foreach table_pair $object_type_tables {
	    set table_n [lindex $table_pair 0]
	    set column_i [lindex $table_pair 1]
		
	    # check if exists entry in tables
	    if {![db_string object_exists "
			select	count(*)
			from	$table_n
			where	$column_i =:object_id_param
	    "]} {

		# intranet-dynfield is not a method to create new objects
		# only is able to insert new rows in extensions tables.
		# In general, insert a row in a table is not enought 
		# to create a object, you may need a call plsql proc
		# (See documentation)

		if {$table_n == $main_table_name} {
		    # We would have to insert a new object - 
		    # not implmeneted yet
		    ad_return_error 1 "
	            Creating new objects not implmented yet:<br>
		    Please create the object first via an existing maintenance screen
		    before using the Intranet-Dynfield generic architecture to modify its fields
		    "
		    return
		}
			
		set cols_list [list]
		set values_list [list]

		# Get table columns. We can iterate through columns because they
		# must have the same names as the form variables and be unique.
		set table_columns [db_columns $table_n]

		foreach c $table_columns {

		    # get attribute value from form
		    if {$c != $column_i} {

			# this attribute exits in form
			if {[template::element::exists $form_id $c]} {  

			    ns_log Notice "im_dynfield::attribute_store: insert-logic: found column in form: table=$table_n, column=$c, widget=$widget_element"
			    set widget_element [template::element::get_property $form_id $c widget]
			    switch $widget_element {

				"checkbox" - "multiselect" - "category_tree" - "im_category_tree" {
				    set multiple_p [template::element::get_property $form_id $c multiple_p]
				    if {[empty_string_p $multiple_p]} {
					set multiple_p 0
				    }	
				    if {$multiple_p} {

					# get intranet-dynfield attribute_id
					db_1row "get flex attribute" "
						select attribute_id 
				    	  	from im_dynfield_attributes
				    	    	where acs_attribute_id = (
							select	attribute_id
				    	    		from	acs_attributes 
				    	    		where	object_type = :object_type
				    	    			and attribute_name = :c
						)
					"
					db_transaction {
					    db_dml "delete previous values" "
						delete from im_dynfield_attr_multi_value
				    		where	object_id = :object_id_param 
				    			and attribute_id = :attribute_id
					    "
				    				    				
					    foreach val [template::element::get_values $form_id $c] {
						db_dml "create multi value" "
							insert into im_dynfield_attr_multi_value (
								attribute_id,object_id,value
							) values (
								:attribute_id,:object_id_param,:val
						)"
						#ns_log notice "multi value created $c $attribute_id $object_id_param value $val"
					    }
					}
				    	
				    } else {

					if {[exists_and_not_null $c]} {
					    lappend cols_list $c	
					    lappend values_list :$c
					}	

				    }
				}

				"date" {
				    set value_str [template::util::date::get_property sql_date [set $c]]
				    #ns_log "notice" "$c ready for insert date [set $c]  $value_str"

				    # create a lists in order to generate
				    # insert query dynamicaly
				    if {[exists_and_not_null $c]} {
					lappend cols_list $c	
					lappend values_list $value_str
					
				    }
				} 
				default {
				    #set $c [ns_set get $form_vars $c]
				    set $c [set $c]

				    # create a lists in order to generate
				    # insert query dynamicaly
				    if {[exists_and_not_null $c]} {
					lappend cols_list $c	
					lappend values_list :$c
				    }
				}
			    }
			}
			
		    } else {

			# table primary key is object_id
			set $c $object_id_param
			
			# create a lists in order to generate
			# insert query dynamicaly
			if {[exists_and_not_null $c]} {
			    lappend cols_list $c	
			    lappend values_list :$c
			}
		    }

		}
		
		# build insert query for current table
		# fraber080116: is this ever executed?
		if {[llength $cols_list] > 0} {
		    set insert_query "insert into $table_n ([join $cols_list ","]) values ([join $values_list ","])"
		    ns_log Notice "im_dynfield::attribute_store: insert-logic: insert_query=$insert_query"
		    db_dml insert_row $insert_query
		}
		
	    }
		
	    # create update query for every table
	    # fraber 080116: does this make sense?
	    set update_sql($table_n) "update $table_n set"
	    set first($table_n) 1
	    set pk($table_n) "$column_i"
	    
	}
	
    }	

    
    ns_log Notice "im_dynfield::attribute_store: between loops: update_sql=[array get update_sql]"

    set attrib_list [db_list_of_lists get_page_attributes {
	select	attr.attribute_id,
		attr.attribute_name,
		attr.table_name as attribute_table
	from
		acs_attributes attr
	where
		attr.object_type = :object_type 
    }]

    # Build the update_list for all attributes except $id_column
    foreach attrib $attrib_list {
	set attribute_id [lindex $attrib 0]
	set attribute_name [lindex $attrib 1]

	set attribute_table [lindex $attrib 2]
	if {[empty_string_p $attribute_table]} {
	    set attribute_table $main_table_name
	}
	
	# Skip the index column - it doesn't need to be stored.
	if {[string equal $attribute_name $pk($attribute_table)]} { continue }
	
	# skip attributes that do not exists in form
	# maybe it's not present in this page
	if {![template::element::exists $form_id $attribute_name]} { continue }

	# Check for the storage type of the attribute.
	# The storage type is with the _widget_.
	set storage_type_id [db_string storage_type_id "
		select	storage_type_id
		from	im_dynfield_widgets idw,
			im_dynfield_attributes ida
		where	idw.widget_name = ida.widget_name
			and ida.acs_attribute_id = :attribute_id
        " -default 0]

	set multiple_p 0
	if {$storage_type_id == [im_dynfield_storage_type_id_multimap]} {
	    set multiple_p 1
	}


	set widget_element [template::element::get_property $form_id $attribute_name widget]
	switch $widget_element {

	    "checkbox" - "multiselect" - "category_tree" - "im_category_tree" {

		if {$multiple_p} {

		    # get intranet-dynfield attribute_id
		    db_1row "get flex attribute" "
			select attribute_id 
			from im_dynfield_attributes
			where acs_attribute_id = (
				select attribute_id
				from acs_attributes 
				where	object_type = :object_type
					and attribute_name = :attribute_name
			)
		    "
		    db_transaction {
			db_dml "delete previous values" "
				delete from im_dynfield_attr_multi_value
				where object_id = :object_id_param 
				and attribute_id = :attribute_id
			"
			foreach val [template::element::get_values $form_id $attribute_name] {
			    db_dml "create multi value" "
				insert into im_dynfield_attr_multi_value (
					attribute_id,object_id,value
				) values (
					:attribute_id,:object_id_param,:val
				)"
			}
		    }

		} else {

		    if {!$first($attribute_table)} { append update_sql($attribute_table) "," }
		    set value [set $attribute_name]
		    set $attribute_name $value
		    append update_sql($attribute_table) "\n\t$attribute_name = :$attribute_name"	
		    set first($attribute_table) 0

		}
	    }

	    "date" {
		if {!$first($attribute_table)} { append update_sql($attribute_table) "," }
		set value_str [template::util::date::get_property sql_date [set $attribute_name]]
		append update_sql($attribute_table) "\n\t$attribute_name = $value_str"	
		set first($attribute_table) 0
	    }

	    default {
		if {!$first($attribute_table)} { append update_sql($attribute_table) "," }

		# Get the value of the form variable from the HTTP form
		set value [set $attribute_name]

		# Store the attribute into the local variable frame
		# We take the detour through the local variable frame
		# (form ns_set -> local var frame -> sql statement)
		# in order to be able to use the ":var_name" notation
		# in the dynamically created SQL update statement.
		set $attribute_name $value

		# im_object_permission -object_id 624
		append update_sql($attribute_table) "\n\t$attribute_name = :$attribute_name"
		set first($attribute_table) 0
	    } 	
	}
	
    }

    ns_log Notice "im_dynfield::attribute_store: update_sql=[array get update_sql]"

    # execute update query for all tables
    db_transaction {
    	foreach table_pair $object_type_tables {

	    set table_n [lindex $table_pair 0]
	    set primary_key $pk($table_n)
	    append update_sql($table_n) "\nwhere $primary_key = :object_id_param\n"

	    # only if there is attributes to update 
	    # in current table
	    if {$first($table_n) == 0} {
		ns_log Notice "im_dynfield::attribute_store: update_query: $update_sql($table_n)"
		db_dml update_object $update_sql($table_n)
	    }
	}
    }
    
}








ad_proc -public im_dynfield::search_query {
    -object_type:required
    -form_id:required
    {-select_part ""}
    {-from_part ""}
    {-where_clause ""}
} {
    generate the search query using intranet-dynfield attributes for object_type
    
    @param object_type: the object type that you want to include attributes
    @param form_id: search form id
    @param select_part: string, comma separated, of NON intranet-dynfield attributes that you want to get from DB.
    	Format: the same as in sql query
    @param from_part string, comma separated, containing from tables for de query search. 
    	Format: the same as in sql query
    @param where_clause: Non intranet-dynfield search conditions
    
    @return: list of lists ready to convert in array <br/>
    	array elements:
    	<ul>
    	   <li><b>select</b>: string, comma separated, ready to use in sql query after SELECT</li>
    	   <li><b>from</b>: string, comma separated, ready to use in sql query after FROM</li>
    	   <li><b>where</b>: string, ready to use in sql query after WHERE</li>
    	   <li><b>list_elements</b>: intranet-dynfield attributes to append to list result elements </li>
    	   <li><b>list_orderby</b>: intranet-dynfield attributes to append to orderby result elements </li>
    	</ul>
} {
	
    # ------------------------------------------
    # Get the list of all variables of the last form
    # ------------------------------------------
    ns_log notice "************************************* start query search part **********************"    
    #set form_vars [ns_conn form]
    #template::form get_values $form_id
    
    # ------------------------------------------
    # proces from_list tables
    # ------------------------------------------
    
    
    set query_select_list [list]    
    set query_from_tables [list]
    
    set from_list [split $from_part ","]
    
    foreach from_table_item $from_list {
    	set table_name [string tolower [lindex $from_table_item 0]]
    	set table_alias [lindex $from_table_item 1]
    	if {[empty_string_p $table_alias]} {
    		set alias($table_name) $table_name
    	} else {
    		set alias($table_name) $table_alias
    	}
    	
    	# ------------------------------------------
	# add the table in
    	# ------------------------------------------
    	
    	lappend query_from_tables "$table_name $table_alias"
    	
    }
    
    # ------------------------------------------
    # get object_type main table and column id
    # ------------------------------------------
    
    db_1row "get main object_type table" "select table_name as main_table_name, \
	    id_column as main_id_column \
	    from acs_object_types \
	    where object_type = :object_type"
    set object_type_tables [list [list $main_table_name $main_id_column]]
    
    # ------------------------------------------
    # get object_type extension tables
    # ------------------------------------------
    
    set ext_object_type_tables [db_list_of_lists "get ext object_type tables" "select \
	    table_name,\
	    id_column \
	    from \
	    acs_object_type_tables\
	    where \
	    object_type = :object_type\
	    "]
    if {[llength $ext_object_type_tables] > 0} {
	set object_type_tables [concat $object_type_tables $ext_object_type_tables]
    }    
    
    # ------------------------------------------
    # for all tables related to object_type
    # create new row if not exists
    # ------------------------------------------
    if {[exists_and_not_null alias($main_table_name)]} {
    	set main_table_alias $alias($main_table_name)
    } else {
    	set main_table_alias "$main_table_name"
    }
    foreach table_pair $object_type_tables {
	set table_n [lindex $table_pair 0]
	set column_i [lindex $table_pair 1]

	# ------------------------------------------
	# add to from tables list if table_n not exists
	# ------------------------------------------
	if {![info exists alias($table_n)]} {
		set alias($table_n) "$table_n"
		set table_alias "$table_n"
		lappend query_from_tables "$table_n"
	} else {
		set table_alias $alias($table_n)
	}
		
	set pk($table_n) "$column_i"
	
	# ------------------------------------------
	# Join the current table to the query
	# ------------------------------------------
	if {$table_alias != $main_table_alias} {
		append where_clause " \n AND $table_alias.$column_i = $main_table_alias.$main_id_column"
	}
    }	
    
    set select_list [split $select_part ","]
    foreach select_item $select_list {
    	set attr [lindex $select_item 0]
    	set table_alias [lindex $select_item 1]
    	
    	lappend query_select_list "$attr"
    	
    	# ---------------------------------------------
    	# create this element to the result list
    	# ---------------------------------------------
    	
    	# its nescessary ???? maybe not
    	# if we must create element list we need to split attr in alias and attribute (alias.attribute)
    }

    set attrib_list [db_list_of_lists get_page_attributes {
	select attr.attribute_id,
	attr.attribute_name,
	attr.table_name as attribute_table,
	attr.pretty_name,
	wdgt.widget,
	wdgt.parameters,
	wdgt.storage_type
	from acs_attributes attr,
	im_dynfield_attributes flex,
	im_dynfield_widgets wdgt
	where attr.object_type = :object_type
	AND attr.attribute_id = flex.acs_attribute_id
	AND flex.widget_name = wdgt.widget_name
    }]
    
    # ------------------------------------------
    # Build the search query and the result list for all attributes 
    # ------------------------------------------
    
    foreach attrib $attrib_list {
	set attribute_id [lindex $attrib 0]
	set attribute_name [lindex $attrib 1]
	set attribute_table [lindex $attrib 2]
	set pretty_name [lindex $attrib 3]
	set widget [lindex $attrib 4]
	set parameters [lindex $attrib 5]
	
	if {[empty_string_p $attribute_table]} {
	    set attribute_table $main_table_name
	}
	
	set table_alias $alias($attribute_table)
	set column_i $pk($attribute_table)
	
	#-------------------------------------------
	# skip attributes that does not exists in form
	# maybe it's not present in this page
	#-------------------------------------------
	set multiple_p 0
	if {[template::element::exists $form_id $attribute_name]} { 

		set widget_element [template::element::get_property $form_id $attribute_name widget]
		set $attribute_name [template::element::get_value $form_id $attribute_name]
		ns_log notice "widget element -----> $widget_element"
		switch $widget_element {
			"checkbox" - "multiselect" - "category_tree"  - "im_category_tree" {

				ns_log notice "$widget_element -----> values [set $attribute_name]"
				set multiple_p [template::element::get_property $form_id $attribute_name multiple_p]
				if {[empty_string_p $multiple_p]} {
					set multiple_p 0
				}
				if {$multiple_p} {
					# -------------------------
					# get intranet-dynfield attribute_id
					# -------------------------
					db_1row "get flex attribute" "select attribute_id 
						from im_dynfield_attributes
						where acs_attribute_id = (select attribute_id
								  from acs_attributes 
								  where object_type = :object_type
								  and attribute_name = :attribute_name)"
					
					ns_log notice "***************** before search multi values [set $attribute_name]"
					append where_clause "\n\t AND ("
					set i 0
					foreach val [template::element::get_values $form_id $attribute_name] {
						if {![empty_string_p $val]} {
							if {$i>0} {
								append where_clause "\n\t OR "
							}
							append where_clause " $table_alias.$column_i in (select object_id
								from im_dynfield_attr_multi_value
								where attribute_id = '$attribute_id'
								and value = '$val')"
							incr i
						}	
					}
					# ---------------------------
					# if no value selected 
					# ---------------------------
					if {$i == 0} {
						append where_clause " 1=1 "
					}
					append where_clause "\n\t)"
					
	
				} else {
					if {![empty_string_p [set $attribute_name]]} {
						#set $attribute_name $value
						append where_clause "\n\t AND $table_alias.$attribute_name like '%[set $attribute_name]%' "
					}
				}
			    }
			"date" {
				set value_str [template::util::date::get_property sql_date [set $attribute_name]]
				if {$value_str != "NULL"} {
					append where_clause "\n\t AND $table_alias.$attribute_name = $value_str"	
				}
			}
			default {
				# ------------------------------------------
				# Get the value of the form variable from the HTTP form
				# ------------------------------------------
	
				#set value [ns_set get $form_vars $attribute_name]
				set value [set $attribute_name]
				# ------------------------------------------
				# Store the attribute into the local variable frame
				# We take the detour through the local variable frame
				# (form ns_set -> local var frame -> sql statement)
				# in order to be able to use the ":var_name" notation
				# in the dynamically created SQL update statement.
				# ------------------------------------------
				if {![empty_string_p [set $attribute_name]]} {
					#set $attribute_name $value
					append where_clause "\n\t AND $table_alias.$attribute_name like '%[set $attribute_name]%' "
				}
			} 	
		}
	
		#################################################
		
	} else {
		ns_log notice "***************** $attribute_name NOT EXISTS in $form_id ***********************"	
	}
	
	# ------------------------------------------
	# append this attriubute to the result list
	# ------------------------------------------
	
	
	switch $widget {
		"category_tree" {
			if {$multiple_p} {
				lappend query_select_list "im_dynfield_attribute.multimap_val_to_str($attribute_id, $table_alias.$column_i,'$widget') as $attribute_name"
			} else {
				lappend query_select_list "category.name($table_alias.$attribute_name) as $attribute_name"
			}
		}
		"generic_sql" {
			# -------------------------------------------
			# return default value
			# -------------------------------------------
			
			set generic_sql_return "$table_alias.$attribute_name"
			
			# -------------------------------------------
			# try to return pretty name of key
			# -------------------------------------------
			
			set custom_pos [lsearch $parameters "custom"]
			if {$custom_pos > -1} {
			    	set custom_value [lindex $parameters [expr $custom_pos + 1]]
			    	set sql_query [lindex $custom_value 1]
			    	#ns_log notice "sql_query $sql_query"
			    	
			    	set result [regexp -nocase {select ([^ , \" \"]+), ([^ \" \"]+) from ([^ \" \"]+)} $sql_query match key key_name table_key]
			    	if {$result} {
			    		# -------------------------------------------
			    		# create query to return pretty key name
			    		# -------------------------------------------
			    		set generic_sql_return " (SELECT $key_name 
			    					  FROM $table_key 
			    					  WHERE $key = $table_alias.$attribute_name) as $attribute_name "
			    	}
    			}
    			
    			lappend query_select_list $generic_sql_return
		}
		default {
			lappend query_select_list "$table_alias.$attribute_name"
		}
	}

	# -----------------------------------------------------------------
	# avila 20050405 disable add intranet-dynfield attributes to result screen
	# -----------------------------------------------------------------
	
	append elements_list  " $attribute_name { 
					label \"$pretty_name\"
					}"
	append orderby_list " $attribute_name {orderby $table_alias.$attribute_name}"
	
	
    }
      
    
    return [list [list "select" "[join $query_select_list ","]"] [list "from" "[join $query_from_tables ", \n"]"] \
	 [list "where" "$where_clause"] [list "list_elements" "$elements_list"] [list "list_orderby" "$orderby_list"]]
    
}




# ------------------------------------------------------------------
# DynFields per Subtype
# ------------------------------------------------------------------

ad_proc -public im_dynfield::dynfields_per_object_subtype {
    -object_type:required
} {
    Returns the list of dynfield_attributes for each subtype
} {
    return [util_memoize [list im_dynfield::dynfields_per_object_subtype_helper -object_type $object_type]]
}

ad_proc -public im_dynfield::dynfields_per_object_subtype_helper {
    -object_type:required
} {
    Returns the list of dynfield_attributes that are common to all 
    object subtypes
} {
    set type_category [im_dynfield::type_category_for_object_type -object_type $object_type]

    set mapping_sql "
	select distinct
		cat.category_id as type_id,
		m.attribute_id
	from	
		(select	category_id
		 from	im_categories
		 where	category_type = :type_category
		 	and enabled_p = 't'
		) cat
		LEFT OUTER JOIN (
			select	*
			from	im_dynfield_type_attribute_map
			where	display_mode in ('edit','display')
		) m on (cat.category_id = m.object_type_id)
    "
    db_foreach dynfield_mapping $mapping_sql {
        if {0 == $attribute_id} { continue }
    	set attribs [list]
	if {[info exists attrib_hash($type_id)]} { set attribs $attrib_hash($type_id) }
	lappend attribs $attribute_id
	set attrib_hash($type_id) $attribs
    }
    return [array get attrib_hash]
}


ad_proc -public im_dynfield::subtype_have_same_attributes_p {
    -object_type:required
} {
    Returns "1" if all object subtypes have the same list of dynfields.
    This routine is useful if we want to know if we have to redirect
    to the big-object-type-select page to select an object's subtype.
} {
    array set attrib_hash [im_dynfield::dynfields_per_object_subtype -object_type $object_type]
    set first_array_name [lindex [array names attrib_hash] 0]
    set first_array_name_attribs $attrib_hash($first_array_name)

    set same_p 1
    foreach name [array names attrib_hash] {
	set attribs $attrib_hash($name)
	if {$attribs != $first_array_name_attribs} { set same_p 0 }
    }
    return $same_p
}



ad_proc -public im_dynfield::append_attributes_to_form {
    {-object_subtype_id "" }
    -object_type:required
    -form_id:required
    {-object_id ""}
    {-search_p "0"}
    {-form_display_mode "edit" }
    {-advanced_filter_p 0}
} {
    Append intranet-dynfield attributes for object_type to an existing form.<p>
    @option object_type The object_type attributes you want to add to the form
    @option object_subtype_id Specifies the "subtype" of the objects (i.e. project_type_id)
    @option advanced_filter_p Tells us that the dynfields are used for an 
            "advanced filter" as oposed to a data form. Text fields dont make
            much sense here, so we'll skip them.
    @return Returns the number of added fields

    The code consists of two main parts:
    <ul>
    <li>Adding the the attributes to the forum and
    <li>Extracting the values of the attributes from a number of storage tables.
    </ul>

} {
    set debug 0
    if {$debug} { ns_log Notice "im_dynfield::append_attributes_to_form: object_type=$object_type, object_id=$object_id" }

    set user_id [ad_get_user_id]

    # ---------------------------- Create the Form --------------------------
    if {![template::form exists $form_id]} {
	if {$debug} { ns_log Notice "im_dynfield::append_attributes_to_form: creating the form" }
    	template::form create $form_id
    }
	
    if {![template::element::exists $form_id "object_type"]} {
	if {$debug} { ns_log Notice "im_dynfield::append_attributes_to_form: creating object_type=$object_type" }
    	template::element create $form_id "object_type" \
    			    -datatype text \
    			    -widget hidden \
    			    -value  $object_type
    }
    
    # object_id only necessary in edit mode
    if {[exists_and_not_null object_id]} {
    	if {![template::element::exists $form_id "object_id"]} {
	    if {$debug} { ns_log Notice "im_dynfield::append_attributes_to_form: creating object_id=$object_id" }
	    template::element create $form_id "object_id" \
		-datatype integer \
		-widget hidden \
		-value  $object_id
    	}
    }

    # Get display mode per attribute and object_type_id
    set sql "
       select	m.attribute_id,
                m.object_type_id as ot,
                m.display_mode as dm
        from
                im_dynfield_type_attribute_map m,
                im_dynfield_attributes a,
                acs_attributes aa
        where
                m.attribute_id = a.attribute_id
                and a.acs_attribute_id = aa.attribute_id
                and aa.object_type = :object_type
    "

    # Default: Set all field to form's display mode
    set default_display_mode $form_display_mode

    db_foreach attribute_table_map $sql {
	set key "$attribute_id.$ot"
	set display_mode_hash($key) $dm

	# Now we've got atleast one display mode configured:
	# Set the default to "none", so that no field is shown
	# except for the configured fields.
	set default_display_mode "none"

	ns_log Notice "append_attributes_to_form: display_mode($key) <= $dm"
    }

    # Disable the mechanism if the object_type_id hasn't been specified
    # (compatibility mode)
    if {"" == $object_subtype_id} { set default_display_mode "edit" }


    db_1row object_type_info "
        select
                t.table_name as object_type_table_name,
                t.id_column as object_type_id_column
        from
                acs_object_types t
        where
                t.object_type = :object_type
    "

    set extra_wheres [list "1=1"]
    if {$advanced_filter_p} {
	lappend extra_wheres "aw.widget in (
		'select', 'generic_sql', 
		'im_category_tree', 'im_cost_center_tree',
		'checkbox'
	)"
    }
    set extra_where [join $extra_wheres "\n\t\tand "]

    set attributes_sql "
	select a.attribute_id,
		aa.attribute_id as dynfield_attribute_id,
		a.table_name as attribute_table_name,
		tt.id_column as attribute_id_column,
		a.attribute_name,
		a.pretty_name,
		a.datatype, 
		case when a.min_n_values = 0 then 'f' else 't' end as required_p, 
		a.default_value, 
		aw.widget,
		aw.parameters,
		aw.storage_type_id,
		im_category_from_id(aw.storage_type_id) as storage_type
	from
		im_dynfield_attributes aa
		LEFT OUTER JOIN
			(select * from im_dynfield_layout where page_url = '') dl
			ON (aa.attribute_id = dl.attribute_id),
		im_dynfield_widgets aw,
		acs_attributes a 
		left outer join 
			acs_object_type_tables tt 
			on (tt.object_type = :object_type and tt.table_name = a.table_name)
	where 
		a.object_type = :object_type
		and a.attribute_id = aa.acs_attribute_id
		and aa.widget_name = aw.widget_name
		and $extra_where
	order by
		dl.pos_y,
		aa.attribute_id
    "

    set field_cnt 0
    db_foreach attributes $attributes_sql {

	# Check if the current user has the right to read and write on the dynfield
	set read_p [im_object_permission \
			-object_id $dynfield_attribute_id \
			-user_id $user_id \
			-privilege "read" \
	]
	set write_p [im_object_permission \
			-object_id $dynfield_attribute_id \
			-user_id $user_id \
			-privilege "write" \
	]
	if {!$read_p} { continue }

	set display_mode $default_display_mode
	set key "$dynfield_attribute_id.$object_subtype_id"
	if {[info exists display_mode_hash($key)]} { 
	    set display_mode $display_mode_hash($key) 
	}
	if {"edit" == $display_mode && "display" == $form_display_mode}  {
            set display_mode $form_display_mode
        }
	if {"edit" == $display_mode && !$write_p}  {
            set display_mode "display"
        }
	if {"none" == $display_mode} { continue }


	if {$debug} { ns_log Notice "im_dynfield::append_attributes_to_form: attribute_name=$attribute_name, datatype=$datatype, widget=$widget, storage_type_id=$storage_type_id" }

	# set optional all attributes if search mode
	if {$search_p} { set required_p "f" }

	# No help yet...
	set help ""

	# Might translate the datatype into one for which we have a
	# validator (e.g. a string datatype would change into text).
	set translated_datatype [attribute::translate_datatype $datatype]
	if {$datatype == "number"} {
	    set translated_datatype "float"
	} elseif {$datatype == "date"} {
	    set translated_datatype "date"
	}

	set parameter_list [lindex $parameters 0]

	# Find out if there is a "custom" parameter and extract its value
	# "Custom" is the parameter to pass-on widget parameters from the
	# DynField Maintenance page to certain form Widgets.
	# Example: "custom {sql {select ...}}" in the "generic_sql" widget.
	set custom_parameters ""
	set custom_pos [lsearch $parameter_list "custom"]
	if {$custom_pos >= 0} {
	    set custom_parameters [lindex $parameter_list [expr $custom_pos + 1]]
	}
	
	set html_parameters ""
	set html_pos [lsearch $parameter_list "html"]
	if {$html_pos >= 0} {
	    set html_parameters [lindex $parameter_list [expr $html_pos + 1]]
	}

        switch $widget {
	    checkbox - radio - select - multiselect - im_category_tree - category_tree {

		if {$debug} { ns_log Notice "im_dynfield::append_attributes_to_form: select-widgets: with options" }
		set option_list ""
		set options_pos [lsearch $parameter_list "options"]
		if {$options_pos >= 0} {
		    set option_list [lindex $parameter_list [expr $options_pos + 1]]
		}

		if { [string eq $required_p "f"] && ![string eq $widget "checkbox"]} {
		    set option_list [linsert $option_list -1 [list " [_ intranet-dynfield.no_value] " ""]]
    		}

    		if {![template::element::exists $form_id "$attribute_name"]} {
		    template::element create $form_id "$attribute_name" \
			-datatype "text" [ad_decode $required_p "f" "-optional" ""] \
			-widget $widget \
			-label "$pretty_name" \
			-options $option_list \
			-custom $custom_parameters \
			-html $html_parameters \
			-help $help \
			-mode $display_mode
		}
	    }

	    default {

		if {$debug} { ns_log Notice "im_dynfield::append_attributes_to_form: default: no options" }
		if {![template::element::exists $form_id "$attribute_name"]} {
		    template::element create $form_id "$attribute_name" \
			-datatype $translated_datatype [ad_decode $required_p f "-optional" ""] \
			-widget $widget \
			-label $pretty_name \
			-html $html_parameters \
			-custom $custom_parameters\
			-help $help \
			-mode $display_mode
		}
	    }
	}
	incr field_cnt
    }
	

    # That's all until here IF this is a new object. Otherwise, we'll need 
    # to retreive the object's values from several tables and from the multi-fields...
    #
    if { ![template::form is_request $form_id] } { return }
    if { ![info exists object_id]} { return }


    # Same loop as before...
    db_foreach attributes $attributes_sql {

	# Check if the current user has the right to read the dynfield
	if {![im_object_permission -object_id $dynfield_attribute_id -user_id $user_id]} { continue }

	set display_mode $default_display_mode
	set key "$dynfield_attribute_id.$object_subtype_id"
	if {[info exists display_mode_hash($key)]} { set display_mode $display_mode_hash($key) }
	if {"none" == $display_mode} { continue }


	switch $storage_type {
	    multimap {

		# "MultiMaps" (select with multiple values) are stored in a separate
		# "im_dynfield_attr_multi_value", because we can't store it like the
		# other attributes directly inside the object's table.
		ns_log Notice "im_dynfield::append_attributes_to_form: multipmap storage"
		template::element set_properties $form_id $attribute_name "multiple_p" "1"
		set value_list [db_list get_multiple_values "
			select	value 
			from	im_dynfield_attr_multi_value
			where	attribute_id = :dynfield_attribute_id
				and object_id = :object_id
		"]
		template::element::set_values $form_id $attribute_name $value_list

	    }

	    date {

		# ToDo: Remove this part. It's not used anymore. Dates are stored as
		# values in YYYY-MM-DD format
		ns_log Notice "im_dynfield::append_attributes_to_form: date storage"
		set value [template::util::date::get_property ansi [set $attribute_name]]
		set value_list [split $value "-"]			
		set value "[lindex $value_list 0] [lindex $value_list 1] [lindex $value_list 2]"
		template::element::set_value $form_id $attribute_name $value

	    }

	    value - default {

		# ToDo: slow. This piece issues N SQL statements, instead of constructing
		# a single SQL and issuing it once. Causes performance problems at BaselKB
		# for example.
		ns_log Notice "im_dynfield::append_attributes_to_form: value - default storage"
		set value [db_string get_single_value "
		    select	$attribute_name
		    from	$attribute_table_name
		    where	$attribute_id_column = :object_id
		" -default ""]
		template::element::set_value $form_id $attribute_name $value

	    }

	}
    }
    
    return $field_cnt
}


ad_proc -public im_dynfield::append_attributes_to_im_view {
    -object_type:required
    {-table_prefix "" }
} {
    Returns a list with two elements:

    Element 0: A list of PrettyNames, suitable to be appended to the
    "column_headers" list of a project-open im_view type of ListPage
    (such as ProjectListPage, CompanyListPage, ...)

    Element 1: A list of "display_tcl" expressions suitable to be appended 
    to the "column_vars" list of a project-open im_view ListPage.

    Element 2: A list of select expressions suitable to be included
    in a SQL select statement

    ToDo: Element 1 currently only contains works for columns of 
    storage type "table_column" and will only show the table value
    itself, instead of a value, depending on the "display" mode of
    the corresponding widet.

    table_prefix is a trick when your're trying to aggregate values
    of a joined object, such as the "im_company" in the case of
    im_invoices.
} {
    set current_user_id [ad_get_user_id]

    set attributes_sql "
	select	a.*,
		aa.attribute_id as dynfield_attribute_id,
		tt.id_column as attribute_id_column,
		t.table_name as object_type_table_name,
		t.id_column as object_type_id_column,
		aw.widget,
		aw.parameters,
		aw.storage_type_id,
		im_category_from_id(aw.storage_type_id) as storage_type
	from
		im_dynfield_attributes aa,
		im_dynfield_widgets aw,
		acs_object_types t,
		acs_attributes a
		left outer join
			acs_object_type_tables tt
			on (tt.object_type = :object_type and tt.table_name = a.table_name)
	where
		t.object_type = :object_type
		and a.object_type = t.object_type
		and a.attribute_id = aa.acs_attribute_id
		and aa.widget_name = aw.widget_name
		and im_object_permission_p(aa.attribute_id, :current_user_id, 'read') = 't'
    "

    set column_headers [list]
    set column_vars [list]
    set column_select [list]
    db_foreach dynfield_attributes $attributes_sql {
	lappend column_headers $pretty_name
	lappend column_vars "\$$attribute_name"
	lappend column_select "$table_prefix$attribute_name,"
    }

    return [list $column_headers $column_vars $column_select]
}


ad_proc -public im_dynfield::form {
    -object_type:required
    -form_id:required
    -object_id:required
    -return_url:required
    {-page_url ""}
} {
    Returns a fully formatted template, similar to ad_form.
    As a difference to ad_form, you don't need to specify the
    fields of the object, because they are defined dynamically
    in the intranet-dynfield database.
    Please see the Intranet-Dynfield documentation for more details.
} {
    if { [empty_string_p $page_url] } {
	# get default page_url
	set page_url [db_string get_default_page {
	    select page_url
	    from im_dynfield_layout_pages
	    where object_type = :object_type
	    and default_p = 't'
	} -default ""]
    }

    
    # verify correctness of page_url if something wrong just ignore dynamic position
    if { [db_0or1row exists_page_url_p "select 1 from im_dynfield_layout_pages
	where object_type = :object_type and page_url = :page_url"]
    } {
	set layout_page_p 1
    } else {
	set layout_page_p 0
    }

    db_1row object_type_info "
	select 
		pretty_name as object_type_pretty_name,
		table_name,
		id_column
	from 
		acs_object_types 
	where 
		object_type = :object_type
	"
    
    # check if this object_type involve more tables
    # get object_type tables tree
    set obj_type $object_type
    set object_type_tables [list]
    while {$obj_type != "acs_object"} {

	set obj_type_tables [db_list "get tables related to object_type" "
		select distinct table_name 
		from acs_attributes 
		where object_type = :obj_type 
		and table_name is not null
	"]
	db_1row "get obj_type table" "select table_name as t, supertype as obj_type \
	    from acs_object_types \
	    where object_type = :obj_type"
	lappend obj_type_tables $t
	foreach table $obj_type_tables {

	    if {[lsearch -exact $object_type_tables $table] == -1} {
		lappend object_type_tables $table
	    }
	}

    }

    foreach t_name $object_type_tables {
	# get the primary key for all tables related to object type
    
	db_1row "get table pk" "
	select COLUMN_NAME as c_id
	FROM ALL_CONS_COLUMNS \
	WHERE 
		TABLE_NAME = UPPER(:t_name) \
		AND CONSTRAINT_NAME = ( SELECT CONSTRAINT_NAME \
		FROM ALL_CONSTRAINTS \
		WHERE TABLE_NAME = UPPER(:t_name) \
		AND CONSTRAINT_TYPE = 'P')"
    
	lappend object_type_tables_colid_list [list $t_name $c_id]
    }

    # ------------------------------------------------------
    # Create the form
    # ------------------------------------------------------
    
    # Create a new blank form.
    #
    template::form create $form_id


    # ------------------------------------------------------
    # Retreive object information 
    # OR:
    # Setup form to create a new object
    # ------------------------------------------------------

    if { [template::form is_request $form_id] } {

	if {[info exists object_id]} {
	    # get values from all tables related to object_type
	    foreach table_pair $object_type_tables_colid_list {
		set table_n [lindex $table_pair 0]
		set column_i [lindex $table_pair 1]

		# We can use a wildcard ("p.*") to select all columns from 
		# the object or from its extension table in order to get
		# values that might be added for a specific customer
		db_1row info "
			select 	o.*
			from	$table_n o
			where	o.$column_i = :object_id
		"
	    }


	} else {
	    
	    # Setup the form with an id_column field in order to
	    # create a new object of the given type

	    set object_id [db_nextval "acs_object_id_seq"]
	}
    }


    # ------------------------------------------------------
    # Create form elements from the "im_dynfield_attributes" 
    # table
    # ------------------------------------------------------

    # The table "im_dynfield_attributes" contains the list of
    # "attributes" (= fields or columns) of an object.
    # We are going to add these fields to the current view/
    # edit template.
    #
    # There is a special treatment for attribute "parameters".
    # These parameters are are passed on to the TCL widget
    # that renders the specific attribute value.


    # Pull out all the attributes up the hierarchy from this object_type
    # to the $object_type object type
    set attributes_sql "
	select a.attribute_id,
	       a.table_name as attribute_table_name,
	       a.attribute_name,
	       at.pretty_name,
	       a.datatype, 
	       case when a.min_n_values = 0 then 'f' else 't' end as required_p, 
	       a.default_value, 
	       t.table_name as object_type_table_name, 
	       t.id_column as object_type_id_column,
	       aw.widget,
	       aw.parameters,
	       at.table_name as attribute_table,
	       at.object_type as attr_object_type
	  from
	  	acs_object_type_attributes a, 
	  	im_dynfield_attributes aa,
	  	im_dynfield_widgets aw,
	  	acs_attributes at,
		acs_object_types t
	 where 
	 	a.object_type = :object_type
	 	and t.object_type = a.ancestor_type 
	 	and a.attribute_id = aa.acs_attribute_id
	 	and a.attribute_id = at.attribute_id
	 	and aa.widget_name = aw.widget_name
	 order by 
	 	attribute_id
    "

    db_foreach attributes $attributes_sql {
	# Might translate the datatype into one for which we have a
	# validator (e.g. a string datatype would change into text).
	set translated_datatype [attribute::translate_datatype $datatype]
	    
	set parameter_list [lindex $parameters 0]

	# Find out if there is a "custom" parameter and extract its value
	set custom_parameters ""
	set custom_pos [lsearch $parameter_list "custom"]
	if {$custom_pos >= 0} {
	    set custom_parameters [lindex $parameter_list [expr $custom_pos + 1]]
	}

	set html_parameters ""
	if {[string equal [lindex $parameter_list 0] "html"]} {
	    set html_parameters [lindex $parameter_list 1]
	}


	set value $default_value
	if {[info exists $attribute_name]} {
	    set value [expr "\$$attribute_name"]
	}

	if { [string eq $widget "radio"] || [string eq $widget "select"] || [string eq $widget "multiselect"]} {

	    # For enumerations, we generate a list all the possible values
	    set option_list [db_list_of_lists select_enum_values {
		select enum.pretty_name, enum.enum_value
		from acs_enum_values enum
		where enum.attribute_id = :attribute_id 
		order by enum.sort_order
	    }]
	    	    
	    if { [string eq $required_p "f"] } {
		# This is not a required option list... offer a default
		lappend option_list [list " (no value) " ""]
	    }
	    template::element create $form_id "$attribute_name" \
		    -datatype "text" [ad_decode $required_p "f" "-optional" ""] \
		    -widget $widget \
		    -options $option_list \
		    -label "$pretty_name" \
		    -value $value \
		    -custom $custom_parameters
	} else {
	
	    # ToDo: Catch errors when the variable doesn't exist
	    # in order to create reasonable error messages with
	    # object, object_type, expected variable name and the
	    # list of currently existing variables.
		
	    template::element create $form_id "$attribute_name" \
		    -datatype $translated_datatype [ad_decode $required_p "f" "-optional" ""] \
		    -widget $widget \
		    -label $pretty_name \
		    -value  $value\
		    -html $html_parameters \
		    -custom $custom_parameters
	}
    }
    

    # ------------------------------------------------------
    # Execute this for a "request" (= this page creates a HTML form)
    # In this case we pass some more parameters on to the form
    # ------------------------------------------------------

    if { [template::form is_request $form_id] } {
	
	# A list of additional variables to export
	set export_var_list [list object_id object_type]

	foreach var $export_var_list {
	    template::element create $form_id $var \
		    -value [set $var] \
		    -datatype text \
		    -widget hidden
	}
    }


    # ------------------------------------------------------
    # Store values if the form was valid
    # ------------------------------------------------------

    if { [template::form is_valid $form_id] } {

	set object_exists [db_string object_exists "select count(*) from $table_name where $id_column=:object_id"]

	if {!$object_exists} {
	    # We would have to insert a new object - 
	    # not implmeneted yet
	    ad_return_complaint 1 "Creating new objects not implmented yet<br>
	    Please create the object first via an existing maintenance screen
	    before using the Intranet-Dynfield generic architecture to modify its fields"
	    return
	}

	# check if exist entry in all relates object_type tables
	foreach table_pair $object_type_tables_colid_list {
	    set table_n [lindex $table_pair 0]
	    set column_i [lindex $table_pair 1]
	    if {$table_n != $table_name} {
		set extension_exist [db_string object_exists "select count(*) from $table_n where $column_i=:object_id"]
		if {!$extension_exist} {
		    # todo : create it
		    # mandatory fields!!!!!!!
		}

	    }
	}


	# Build the update_list for all attributes except $id_column
	#
	# for all tables related to object_type
	foreach table_pair $object_type_tables_colid_list {
	    set table_n [lindex $table_pair 0]
	    set column_i [lindex $table_pair 1]
	    set update_sql($table_n) "update $table_n set"
	    set first($table_n) 1
	    set pk($table_n) "$column_i"
	}

	# Get the list of all variables of the last form
	set form_vars [ns_conn form]

	db_foreach attributes $attributes_sql {

	    if {[empty_string_p $attribute_table]} {
		db_1row "get attr object type table" "
		    select table_name as attribute_table \
		    from acs_object_types \
		    where object_type = :attr_object_type"
	    }
	    # Skip the index column - it doesn't need to be
	    # stored.
	    if {[string equal $attribute_name $pk($attribute_table)]} { continue }
	    if {!$first($attribute_table)} { append update_sql($attribute_table) "," }

	    # Get the value of the form variable from the HTTP form
	    set value [ns_set get $form_vars $attribute_name]

	    # Store the attribute into the local variable frame
	    # We take the detour through the local variable frame
	    # (form ns_set -> local var frame -> sql statement)
	    # in order to be able to use the ":var_name" notation
	    # in the dynamically created SQL update statement.
	    set $attribute_name $value

	    append update_sql($attribute_table) "\n\t$attribute_name = :$attribute_name"
	    set first($attribute_table) 0
	}

	foreach table_pair $object_type_tables_colid_list {
	    set table_n [lindex $table_pair 0]
	    append update_sql($table_n) "\nwhere $pk($table_n) = :object_id\n"
	    
	    db_transaction {
		if {$first($table_n) == 0} {
		    db_dml update_object $update_sql($table_n)
		}
	    }
	}

	# Add the original return_url as the last one in the list
	lappend return_url_list $return_url
	
	set return_url_stacked [subsite::util::return_url_stack $return_url_list]

	ad_returnredirect $return_url_stacked
	ad_script_abort
    }
}

ad_proc -public im_dynfield::attribute::delete {
    -im_dynfield_attribute_id:required
} {
    Delete an intranet-dynfield attribute, and all associated attribute values

    @param option_id
} {
    db_exec_plsql im_dynfield_attribute_delete {}
}

ad_proc -public im_dynfield::package_id {} {

    TODO: Get the INTRANET-DYNFIELD package ID, not the connection package_id
    Get the package_id of the intranet-dynfield instance

    @return package_id
} {
    return [ad_conn package_id]
}


# ------------------------------------------------------
# Not Tested!!
#
# The following procedures are just copied from the
# original AMS code and probably don't work.
# ------------------------------------------------------



namespace eval im_dynfield::ad_form {}

ad_proc -public im_dynfield::ad_form::save { 
    -package_key:required
    -object_type:required
    -list_name:required
    -form_name:required
    -object_id:required
} {
    this code saves attributes input in a form
} {

    set list_id [im_dynfield::list::get_list_id -package_key $package_key -object_type $object_type -list_name $list_name]

    im_dynfield::object::attribute::values -ids -array "oldvalues" -object_id $object_id
    set im_dynfield_attribute_ids [im_dynfield::list::im_dynfield_attribute_ids -list_id $list_id]
    set variables {}

    foreach im_dynfield_attribute_id $im_dynfield_attribute_ids {
	set storage_type     [im_dynfield::attribute::storage_type -im_dynfield_attribute_id $im_dynfield_attribute_id]
	set attribute_name   [im_dynfield::attribute::name -im_dynfield_attribute_id $im_dynfield_attribute_id]
	set attribute_value  [template::element::get_value $form_name $attribute_name]
	if { $storage_type == "im_dynfield_options" } {
	    # we always order the options_string in the order of the option_id
	    # when doing internal processing
	    set attribute_value [lsort [template::element::get_values $form_name $attribute_name]]
	}
	if { [info exists oldvalues($im_dynfield_attribute_id)] } {
	    if { $attribute_value != $oldvalues($im_dynfield_attribute_id) } {
		lappend variables $im_dynfield_attribute_id $attribute_value
	    }
	} else {
	    if { [exists_and_not_null attribute_value] } {
		lappend variables $im_dynfield_attribute_id $attribute_value
	    }
	}
    }
    if { [exists_and_not_null variables] } {

	db_transaction {
	    im_dynfield::object::attribute::values_flush -object_id $object_id
	    set revision_id   [im_dynfield::object::revision::new -object_id $object_id]
	    set im_dynfield_object_id [im_dynfield_object_id -object_id $object_id]
	    foreach { im_dynfield_attribute_id attribute_value } $variables {
		im_dynfield::attribute::value::superseed -revision_id $revision_id -im_dynfield_attribute_id $im_dynfield_attribute_id -im_dynfield_object_id $im_dynfield_object_id
		if { [exists_and_not_null attribute_value] } {
		    im_dynfield::attribute::value::new -revision_id $revision_id -im_dynfield_attribute_id $im_dynfield_attribute_id -attribute_value $attribute_value
		}
	    }
	}
    }
    im_dynfield::object::attribute::values -object_id $object_id
    return 1
}

ad_proc -public im_dynfield::ad_form::elements { 
    -package_key:required
    -object_type:required
    -list_name:required
    {-key ""}
} {
    this code saves retrieves ad_form elements
} {
    set list_id [im_dynfield::list::get_list_id -package_key $package_key -object_type $object_type -list_name $list_name]

    set element_list ""
    if { [exists_and_not_null key] } {
	lappend element_list "$key\:key"
    }
    db_foreach select_elements {} {
	if { $required_p } {
	    lappend element_list [im_dynfield::attribute::widget -im_dynfield_attribute_id $im_dynfield_attribute_id -required]
	} else {
	    lappend element_list [im_dynfield::attribute::widget -im_dynfield_attribute_id $im_dynfield_attribute_id]
	}
    }
    return $element_list
}



namespace eval im_dynfield::option {}

ad_proc -public im_dynfield::option::new {
    -im_dynfield_attribute_id:required
    -option:required
    {-locale ""}
    {-sort_order ""}
} {
    Create a new intranet-dynfield option for an attribute

    TODO validate that the attribute is in fact one that accepts options.<br>
    TODO auto input sort order if none is supplied<br>
    TODO validate that option from the the string input from im_dynfield::lang_key_encode is equal to a pre-existing intranet-dynfield message if it is we need conflict resolution.

    @param im_dynfield_attribute_id
    @param option This a pretty name option
    @param locale This is the locale the option name is in
    @param sort_order if null, this option will be sorted after last previously entered option for this attribute

    @return option_id    
} {

    set lang_key "intranet-dynfield.option:[im_dynfield::lang_key_encode -string $option]"
    _mr en $lang_key $option
    set option $lang_key

    return [db_exec_plsql im_dynfield_option_new {}]
}


ad_proc -public im_dynfield::option::delete {
    -option_id:required
} {
    Delete an intranet-dynfield option

    @param option_id
} {
    db_exec_plsql im_dynfield_option_delete {}
}


ad_proc -public im_dynfield::option::map {
    {-option_map_id ""}
    -option_id:required
} {
    Map an intranet-dynfield option for an attribute to an option_map_id, if no value is supplied for option_map_id a new option_map_id will be created.

    @param option_map_id
    @param option_id

    @return option_map_id
} {
    return [db_exec_plsql im_dynfield_option_map {}]
}


