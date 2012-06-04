ad_library {

    Procs which may be invoked using similarly named elements in an
    install.xml file.

    @creation-date 2005-02-10
    @author Lee Denison (lee@thaum.net)
    @cvs-id $Id$
}

namespace eval install {}
namespace eval install::xml {}
namespace eval install::xml::action {}

ad_proc -public install::xml::action::load-categories { node } {
    Load categories from a file.
} {
    set src [apm_required_attribute_value $node src]
    set site_wide_p [apm_attribute_value -default 0 $node site-wide-p]
    set format [apm_attribute_value -default "simple" $node format]
    set id [apm_attribute_value -default "" $node id]

    switch -exact $format {
        simple {
            set tree_id [category_tree::xml::import_from_file \
                -site_wide=[template::util::is_true $site_wide_p] \
                [acs_root_dir]$src]
        }
        default {
            error "Unsupported format."
        }
    }

    if {$id ne "" } {
        set ::install::xml::ids($id) $tree_id
    }
}

ad_proc -public install::xml::action::map-category-tree { node } {
    Maps a category tree to a specified object.
} {
    set tree_id [apm_attribute_value -default "" $node tree-id]
    set object_id [apm_attribute_value -default "" $node object-id]

    set tree_ids [list]
    if {$tree_id eq ""} {
        set trees_node [lindex [xml_node_get_children_by_name $node trees] 0]
        set trees [xml_node_get_children $trees_node]

        foreach tree_node $trees {
            lappend tree_ids [apm_invoke_install_proc \
                -type object_id \
                -node $tree_node]
        }
    } else {
        lappend tree_ids [install::xml::util::get_id $tree_id]
    }

    set object_ids [list]
    if {$object_id eq ""} {
        set objects_node [lindex [xml_node_get_children_by_name $node objects] 0]
        set objects [xml_node_get_children $objects_node]

        foreach object_node $objects {
            lappend object_ids [apm_invoke_install_proc \
                -type object_id \
                -node $object_node]
        }
    } else {
        lappend object_ids [install::xml::util::get_id $object_id]
    }

    foreach tree_id $tree_ids {
        if {[acs_object_type $tree_id] eq "category"} {
            set subtree_category_id $tree_id
            set tree_id [category::get_tree $subtree_category_id]
        } else {
            set subtree_category_id {}
        }

        foreach object_id $object_ids {
            category_tree::map -tree_id $tree_id \
                -object_id $object_id \
                -subtree_category_id $subtree_category_id
        }
    }
}
