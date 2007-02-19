ad_library {
    Procs for the site-wide categorization package.

    @author Timo Hentschel (timo@timohentschel.de)

    @creation-date 16 April 2003
    @cvs-id $Id:
}

namespace eval category_tree {

    ad_proc -public get_data {
        tree_id
        {locale ""}
    } {
        Get category tree name, description and other data.

        @param tree_id category tree to get the data of.
        @param locale language in which to get the name and description.
        @return array: tree_name description site_wide_p
        @author Timo Hentschel (timo@timohentschel.de)
    } {
        db_1row get_tree_data "" -column_array tree

        util_unlist [get_translation $tree_id $locale] tree(tree_name) tree(description)
        return [array get tree]
    }

    ad_proc -public map {
        -tree_id:required
        -object_id:required
        {-subtree_category_id ""}
        {-assign_single_p f}
        {-require_category_p f}
    } {
        Map a category tree to a package (or other object).

        @option tree_id category tree to be mapped.
        @option object_id object to map the category tree to.
        @option subtree_category_id category_id of the subtree to be mapped.
                If not provided, the whole category tree will be mapped.
        @option assign_single_p shows if the user will be allowed to assign multiple
                categories to objects or only a single one in this subtree.
        @option require_category_p shows if the user will have to assign at least one
                category to objects.
        @author Timo Hentschel (timo@timohentschel.de)
    } {
        db_exec_plsql map_tree ""
    }

    ad_proc -public unmap {
        -tree_id:required
        -object_id:required
    } {
        Unmap a category tree from a package (or other object)
        Note: This will not delete existing categorizations of objects.

        @option tree_id category tree to be unmapped.
        @option object_id object to unmap the category tree from.
        @author Timo Hentschel (timo@timohentschel.de)
    } {
        db_exec_plsql unmap_tree ""
    }

    ad_proc -public edit_mapping {
        -tree_id:required
        -object_id:required
        {-assign_single_p f}
        {-require_category_p f}
    } {
        Edit the parameters of a mapped category tree.

        @option tree_id mapped category tree.
        @option object_id object the category tree is mapped to.
        @option assign_single_p shows if the user will be allowed to assign multiple
                categories to objects or only a single one in this subtree.
        @option require_category_p shows if the user will have to assign at least one
                category to objects.
        @author Timo Hentschel (timo@timohentschel.de)
    } {
        db_dml edit_mapping ""
    }

    ad_proc -public copy {
        -source_tree:required
        -dest_tree:required
    } {
        Copies a category tree into another category tree.

        @option source_tree tree_id of the category tree to copy.
        @option dest_tree tree_id of the category tree to copy into.
        @author Timo Hentschel (timo@timohentschel.de)
    } {
        set creation_user [ad_conn user_id]
        set creation_ip [ad_conn peeraddr]
        db_exec_plsql copy_tree ""
        flush_cache $dest_tree
        flush_translation_cache $dest_tree
        category::reset_translation_cache
    }

    ad_proc -public add {
        {-tree_id ""}
        -name:required
        {-description ""}
        {-site_wide_p "f"}
        {-locale ""}
        {-user_id ""}
        {-creation_ip ""}
        {-context_id ""}
    } {
        Insert a new category tree. The same translation will be added in the default
        language if it's in a different language.

        @option tree_id tree_id of the category tree to be inserted.
        @option locale locale of the language. [ad_conn locale] used by default.
        @option name tree name.
        @option description description of the category tree.
        @option user_id user that adds the category tree. [ad_conn user_id] used by default.
        @option creation_ip ip-address of the user that adds the category tree. [ad_conn peeraddr] used by default.
        @option context_id context_id of the category tree. [ad_conn package_id] used by default.
        @return tree_id
        @author Timo Hentschel (timo@timohentschel.de)
    } {
        if {[empty_string_p $user_id]} {
            set user_id [ad_conn user_id]
        }
        if {[empty_string_p $creation_ip]} {
            set creation_ip [ad_conn peeraddr]
        }
        if {[empty_string_p $locale]} {
            set locale [ad_conn locale]
        }
        if {[empty_string_p $context_id]} {
            set context_id [ad_conn package_id]
        }
        db_transaction {
            set tree_id [db_exec_plsql insert_tree ""]

            set default_locale [ad_parameter DefaultLocale acs-lang "en_US"]
            if {$locale != $default_locale} {
                db_exec_plsql insert_default_tree ""
            }
        }
        flush_translation_cache $tree_id
        return $tree_id
    }

    ad_proc -public update {
        -tree_id:required
        -name:required
        {-description ""}
        {-site_wide_p "f"}
        {-locale ""}
        {-user_id ""}
        {-modifying_ip ""}
    } {
        Updates / inserts a category tree translation.

        @option tree_id tree_id of the category tree to be updated.
        @option locale locale of the language. [ad_conn locale] used by default.
        @option name tree name.
        @option description description of the category tree.
        @option user_id user that adds the category tree. [ad_conn user_id] used by default.
        @option modifying_ip ip-address of the user that updated the category tree. [ad_conn peeraddr] used by default.
        @author Timo Hentschel (timo@timohentschel.de)
    } {
        if {[empty_string_p $user_id]} {
            set user_id [ad_conn user_id]
        }
        if {[empty_string_p $modifying_ip]} {
            set modifying_ip [ad_conn peeraddr]
        }
        if {[empty_string_p $locale]} {
            set locale [ad_conn locale]
        }
        db_transaction {
            if {![db_0or1row check_tree_existence ""]} {
                db_exec_plsql insert_tree_translation ""
            } else {
                db_exec_plsql update_tree_translation ""
            }
        }
        flush_translation_cache $tree_id
    }

    ad_proc -public delete { tree_id } {
        Deletes a category tree.

        @param tree_id category tree to be deleted.
        @author Timo Hentschel (timo@timohentschel.de)
    } {
        db_exec_plsql delete_tree ""
        flush_cache $tree_id
        flush_translation_cache $tree_id
        category::reset_translation_cache
    }

    ad_proc -public get_mapped_trees { object_id } {
        Get the category trees mapped to an object.

        @param object_id object to get the mapped category trees.
        @return tcl list of lists: tree_id tree_name subtree_category_id
                    assign_single_p require_category_p
        @author Timo Hentschel (timo@timohentschel.de)
    } {
        set result [list]

        db_foreach get_mapped_trees "" {
            lappend result [list $tree_id [get_name $tree_id] $subtree_category_id $assign_single_p $require_category_p]
        }

        return $result
    }

    ad_proc -public get_mapped_trees_from_object_list { object_id_list } {
        Get the category trees mapped to a list of objects.

        @param object_id_list list of object to get the mapped category trees.
        @return tcl list of lists: tree_id tree_name subtree_category_id
                    assign_single_p require_category_p
        @author Jade Rubick (jader@bread.com)
    } {
        set result [list]

        db_foreach get_mapped_trees_from_object_list "" {
            lappend result [list $tree_id [get_name $tree_id] $subtree_category_id $assign_single_p $require_category_p]
        }

        return $result
    }

    ad_proc -public get_tree {
        -all:boolean
        {-subtree_id ""}
        tree_id
        {locale ""}
    } {
        Get all categories of a category tree from the cache.

        @option all Indicates that phased_out categories should be included.
        @option subtree_id Return only categories of the given subtree.
        @param tree_id category tree to get the categories of.
        @param locale language in which to get the categories. [ad_conn locale] used by default.
        @return tcl list of lists: category_id category_name deprecated_p level
        @author Timo Hentschel (timo@timohentschel.de)
    } {
        if {[catch {set tree [nsv_get category_trees $tree_id]}]} {
            return
        }
        set result ""
        if {[empty_string_p $subtree_id]} {
            foreach category $tree {
                util_unlist $category category_id deprecated_p level
                if {$all_p || $deprecated_p == "f"} {
                    lappend result [list $category_id [category::get_name $category_id $locale] $deprecated_p $level]
                }
            }
        } else {
            set in_subtree_p 0
            set subtree_level 0
            foreach category $tree {
                util_unlist $category category_id deprecated_p level
                if {$level == $subtree_level} {
                    set in_subtree_p 0
                }
                if {$in_subtree_p && $deprecated_p == "f"} {
                    lappend result [list $category_id [category::get_name $category_id $locale] $deprecated_p [expr $level - $subtree_level]]
                }
                if {$category_id == $subtree_id} {
                    set in_subtree_p 1
                    set subtree_level $level
                }
            }
        }

        return $result
    }

    ad_proc -public usage { tree_id } {
        Gets all package instances using a category tree.

        @param tree_id category tree to get the using packages for.
        @return tcl list of lists: package_pretty_plural object_id object_name package_id instance_name read_p
        @author Timo Hentschel (timo@timohentschel.de)  
    } {
        set user_id [ad_conn user_id]

        return [db_list_of_lists category_tree_usage ""]
    }

    ad_proc -public reset_cache { } {
        Reloads all category tree hierarchies in the cache.
        @author Timo Hentschel (timo@timohentschel.de)
    } {
        catch {nsv_unset category_trees}
        set tree_id_old 0
        set cur_level 1
        set stack [list]
        set invalid_p ""
        set tree [list]
        db_foreach reset_cache "" {
            if {$tree_id != $tree_id_old && $tree_id_old != 0} {
                nsv_set category_trees $tree_id_old $tree
                set cur_level 1
                set stack [list]
                set invalid_p ""
                set tree [list]
            }
            set tree_id_old $tree_id
            lappend tree [list $category_id [ad_decode "$invalid_p$deprecated_p" "" f t] $cur_level]
            if { [expr $right_ind - $left_ind] > 1} {
                incr cur_level 1
                set invalid_p "$invalid_p$deprecated_p"
                set stack [linsert $stack 0 [list $right_ind $invalid_p]]
            } else {
                incr right_ind 1
                while {$right_ind == [lindex [lindex $stack 0] 0] && $cur_level > 0} {
                    incr cur_level -1
                    incr right_ind 1
                    set stack [lrange $stack 1 end]
                }
                set invalid_p [lindex [lindex $stack 0] 1]
            }
        }
        if {$tree_id_old != 0} {
            nsv_set category_trees $tree_id $tree
        }
    }

    ad_proc -public flush_cache { tree_id } {
        Flushes category tree hierarchy cache of one category tree.

        @param tree_id category tree to be flushed.
        @author Timo Hentschel (timo@timohentschel.de)
    } {
        set cur_level 1
        set stack [list]
        set invalid_p ""
        set tree [list]
        db_foreach flush_cache "" {
            lappend tree [list $category_id [ad_decode "$invalid_p$deprecated_p" "" f t] $cur_level]
            if { [expr $right_ind - $left_ind] > 1} {
                incr cur_level 1
                set invalid_p "$invalid_p$deprecated_p"
                set stack [linsert $stack 0 [list $right_ind $invalid_p]]
            } else {
                incr right_ind 1
                while {$right_ind == [lindex [lindex $stack 0] 0] && $cur_level > 0} {
                    incr cur_level -1
                    incr right_ind 1
                    set stack [lrange $stack 1 end]
                }
                set invalid_p [lindex [lindex $stack 0] 1]
            }
        }
        if {[info exists category_id]} {
            nsv_set category_trees $tree_id $tree
        } else {
            nsv_set category_trees $tree_id ""
        }
    }

    ad_proc -public reset_translation_cache { } {
        Reloads all category tree translations in the cache.
        @author Timo Hentschel (timo@timohentschel.de)
    } {
        catch {nsv_unset category_tree_translations}
        set tree_id_old 0
        db_foreach reset_translation_cache "" {
            if {$tree_id != $tree_id_old && $tree_id_old != 0} {
                nsv_set category_tree_translations $tree_id_old [array get tree_lang]
                unset tree_lang
            }
            set tree_id_old $tree_id
            set tree_lang($locale) [list $name $description]
        }
        if {$tree_id_old != 0} {
            nsv_set category_tree_translations $tree_id [array get tree_lang]
        }
    }

    ad_proc -public flush_translation_cache { tree_id } {
        Flushes category tree translation cache of one category tree.

        @param tree_id category tree to be flushed.
        @author Timo Hentschel (timo@timohentschel.de)
    } {
        db_foreach flush_translation_cache "" {
            set tree_lang($locale) [list $name $description]
        }
        if {[info exists tree_lang]} {
            nsv_set category_tree_translations $tree_id [array get tree_lang]
        } else {
            nsv_set category_tree_translations $tree_id ""
        }
    }

    ad_proc -public get_translation {
        tree_id
        {locale ""}
    } {
        Gets the category tree name and description in the given language, if available.
        Uses the default language otherwise.

        @param tree_id category tree to get the name and description of.
        @param locale language in which to get the name and description. [ad_conn locale] used by default.
        @return tcl-list: name description
        @author Timo Hentschel (timo@timohentschel.de)
    } {
        if {[empty_string_p $locale]} {
            set locale [ad_conn locale]
        }
        if {[catch {array set tree_lang [nsv_get category_tree_translations $tree_id]}]} {
            return
        }
        if {![catch {set names $tree_lang($locale)}]} {
            # exact match: found name for this locale
            return $names
        }
        if {![catch {set names $tree_lang([ad_parameter DefaultLocale acs-lang "en_US"])}]} {
            # default locale found
            return $names
        }
        # tried default locale, but nothing found
        return
    }

    ad_proc -public get_name {
        tree_id
        {locale ""}
    } {
        Gets the category tree name in the given language, if available.
        Uses the default language otherwise.

        @param tree_id category tree to get the name of.
        @param locale language in which to get the name. [ad_conn locale] used by default.
        @author Timo Hentschel (timo@timohentschel.de)
    } {
        return [lindex [get_translation $tree_id] 0]
    }

    ad_proc pageurl { object_id } {
        Returns the page that displays a category tree
        To be used by the AcsObject.PageUrl service contract.

        @param object_id category tree to be displayed.
        @author Timo Hentschel (timo@timohentschel.de)
    } {
        return "categories-browse?tree_ids=$object_id"
    }
}
