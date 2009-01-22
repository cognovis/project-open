ad_library {

	Dealing with relationships
	
    @creation-date 2008-08-18
    @author  (malte.sussdorff@cognovis.de)
    @cvs-id 
}

::xotcl::Class create ::im::dynfield::Rel_Types \
    -superclass ::xo::db::Class \
    -parameter {
        object_type_one
        role_one
        pretty_name_one
        {min_n_rels_one "0"}
        {max_n_rels_one ""}
        object_type_two
        role_two
        pretty_name_two
        {min_n_rels_two "0"}
        {max_n_rels_two ""}
    } -ad_doc {
        ::im::dynfield::Rel_Types is a meta class for interfacing with dynfield enabled acs_object_types for rels.
    }


::im::dynfield::Rel_Types ad_instproc rel_options {} {
    Return a list of possible relationship_types an object of this class can have
} {
    set object_type [my object_type]
    return [db_list rel_types "select rel_type from acs_rel_types where object_type_one = :object_type or object_type_two = :object_type"]
}

::im::dynfield::Rel_Types ad_proc get_instance_from_db {
    -rel_type
} {
    Create an instance of a rel_type
} {
    set r [::im::dynfield::Rel_Types create ::$rel_type]
    $r db_1row dbq..get_instance "select object_type_one,role_one, acs_rel_type__role_pretty_name(role_one) as pretty_name_one,min_n_rels_one,max_n_rels_one,object_type_two, role_two, acs_rel_type__role_pretty_name(role_two) as pretty_name_two,min_n_rels_two,max_n_rels_two from acs_rel_types where rel_type = '$rel_type'"
    $r set object_type $rel_type
    $r set object_id $id
    $r destroy_on_cleanup
    $r initialize_loaded_object
    return $r
}

::im::dynfield::Rel_Types ad_instproc save_new {} {
    Save the new relation
} {    
    # First generate the object_type
    next    
    
    # Then insert the relationship type
    foreach attribute [list object_type object_type_one role_one min_n_rels_one max_n_rels_one object_type_two role_two min_n_rels_two max_n_rels_two] {
        set $attribute [my $attribute]
    }
    db_dml insert "insert into acs_rel_types (rel_type,object_type_one, role_one,min_n_rels_one, max_n_rels_one, object_type_two, role_two,min_n_rels_two, max_n_rels_two) values (:object_type,:object_type_one,:role_one, :min_n_rels_one,:max_n_rels_one,:object_type_two,:role_two,:min_n_rels_two,:max_n_rels_two)"
    
    set pretty_name [db_string pretty "select pretty_name from acs_object_types where object_type = :object_type" -default $object_type]
    
    set object_type_category "$pretty_name"
    ns_log Notice "OBJECT:: $object_type_category"
    # Then update the type_category
    db_dml update "update acs_object_types set type_category_type = :object_type_category where object_type = :object_type"	
    
    # Create a new category for this list with the same name
    db_string newcat "select im_category_new(nextval('im_categories_seq')::integer,:object_type, :object_type_category)"
    
}

