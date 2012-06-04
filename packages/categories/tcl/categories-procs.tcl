ad_library {
    Procs for the site-wide categorization package.

    @author Timo Hentschel (timo@timohentschel.de)

    @creation-date 16 April 2003
    @cvs-id $Id$
}


namespace eval category {}

ad_proc -public category::add {
    {-category_id ""}
    -tree_id:required
    -parent_id:required
    -name:required
    {-locale ""}
    {-description ""}
    {-deprecated_p "f"}
    {-user_id ""}
    {-creation_ip ""}
    -noflush:boolean
} {
    Insert a new category. The same translation will be added in the default
    language if it's in a different language.

    @option category_id category_id of the category to be inserted.
    @option locale locale of the language. [ad_conn locale] used by default.
    @option name category name.
    @option description description of the category.
    @option deprecated_p is category deprecated?
    @option tree_id tree_id of the category the category should be added.
    @option parent_id id of the parent category. "" if top level category.
    @option user_id user that adds the category. [ad_conn user_id] used by default.
    @option creation_ip ip-address of the user that adds the category. [ad_conn peeraddr] used by default.
    @option noflush defer calling category_tree::flush_cache (which if adding multiple categories to 
                    a large tree can be very expensive).  note that if you set this flag you must
                    call category_tree::flush_cache once the adds are complete.
    @return category_id
    @author Timo Hentschel (timo@timohentschel.de)
} {
    if {$user_id eq ""} {
        set user_id [ad_conn user_id]
    }
    if {$creation_ip eq ""} {
        set creation_ip [ad_conn peeraddr]
    }
    if {$locale eq ""} {
        set locale [ad_conn locale]
    }
    db_transaction {
        set category_id [db_exec_plsql insert_category ""]
        set translations [list $locale $name]
        set default_locale [parameter::get -parameter DefaultLocale -default en_US]
        if {$locale != $default_locale} {
            lappend translations $default_locale $name
            db_exec_plsql insert_default_category ""
        }
        if {!$noflush_p} {
            category_tree::flush_cache $tree_id
        }
        # JCD: avoid doing a query and set the translation cache directly
        # flush_translation_cache $category_id
        nsv_set categories $category_id [list $tree_id $translations]
    }
    return $category_id
}

ad_proc -public category::update {
    -category_id:required
    -name:required
    {-locale ""}
    {-description ""}
    {-user_id ""}
    {-modifying_ip ""}
} {
    Updates/inserts a category translation.

    @option category_id category_id of the category to be updated.
    @option locale locale of the language. [ad_conn locale] used by default.
    @option name category name.
    @option description description of the category.
    @option user_id user that updates the category. [ad_conn user_id] used by default.
    @option modifying_ip ip-address of the user that updates the category. [ad_conn peeraddr] used by default.
    @author Timo Hentschel (timo@timohentschel.de)
} {
    if {$user_id eq ""} {
        set user_id [ad_conn user_id]
    }
    if {$modifying_ip eq ""} {
        set modifying_ip [ad_conn peeraddr]
    }
    if {$locale eq ""} {
        set locale [ad_conn locale]
    }
    db_transaction {
        if {![db_0or1row check_category_existence ""]} {
    	db_exec_plsql insert_category_translation ""
        } else {
    	db_exec_plsql update_category_translation ""
        }
        flush_translation_cache $category_id
    }
}

ad_proc -public category::delete {
    -batch_mode:boolean
    category_id
} {
    Deletes a category.
    category_tree::flush_cache should be used afterwards.

    @option batch_mode Indicates that the cache for category translations
                       should not be flushed. Useful when deleting several
                       categories at once.
                       Don't forget to call reset_translation_cache
    @param category_id category_id of the category to be deleted.
    @see category::reset_translation_cache
    @see category_tree::flush_cache
    @author Timo Hentschel (timo@timohentschel.de)
} {
    db_exec_plsql delete_category ""
    if {!$batch_mode_p} {
        flush_translation_cache $category_id
    }
}

ad_proc -public category::change_parent {
    -category_id:required
    -tree_id:required
    {-parent_id [db_null]}
} {
    Changes parent category of a category.
    @option category_id category_id whose parent should change.
    @option tree_id tree_id of the category tree.
    @option parent_id new parent category_id.
    @author Timo Hentschel (timo@timohentschel.de)
} {
    db_exec_plsql change_parent_category ""
    category_tree::flush_cache $tree_id
}

ad_proc -public category::phase_in { category_id } {
    Marks a category to be visible for categorizing new objects /
    update existing objects.
    Make sure to use category_tree::flush_cache afterwards.

    @param category_id category_id of the category to be phased in
    @see category::phase_out
    @see category_tree::flush_cache
    @author Timo Hentschel (timo@timohentschel.de)
} {
    db_exec_plsql phase_in ""
}

ad_proc -public category::phase_out { category_id } {
    Marks a category to be phasing out. That means this category and
    all its subcategories will no longer appear in the categorization
    widget to categorize new objects / update existing objects,
    but all existing categorizations will still remain valid.
    Make sure to use category_tree::flush_cache afterwards.

    @param category_id category_id of the category to be phased out
    @see category::phase_in
    @see category_tree::flush_cache
    @author Timo Hentschel (timo@timohentschel.de)
} {
    db_exec_plsql phase_out ""
}

ad_proc -public category::map_object {
    {-remove_old:boolean}
    -object_id:required
    category_id_list
} {
    Map an object to several categories.

    @option remove_old Modifier to be used when categorizing existing objects. Will make sure to delete all old categorizations.
    @option object_id object to be categorized.
    @param category_id_list tcl-list of category_ids to be mapped to the object.
    @author Timo Hentschel (timo@timohentschel.de)
} {
    db_transaction {
        # Remove any already mapped categories if we are updating
        if { $remove_old_p } {
    	db_dml remove_mapped_categories ""
        }

        foreach category_id $category_id_list {
	    if {$category_id ne ""} {
		db_dml insert_mapped_categories ""
	    }
        }

	# Adds categorizations to linked categories
	db_dml insert_linked_categories ""
    }
}

ad_proc -public category::get_mapped_categories { 
    {-tree_id {}}
    object_id 
} {
    Gets the list of categories mapped to an object. If tree_id is provided 
    return only the categories mapped from the given tree.

    @param object_id object of which we want to know the mapped categories.
    @return tcl-list of category_ids
    @author Timo Hentschel (timo@timohentschel.de)
} {
    if { $tree_id ne "" } {
        set result [db_list get_filtered ""]
    } else {
        set result [db_list get_mapped_categories ""]
    }

    return $result
}
ad_proc -public category::get_mapped_categories_multirow { 
    {-locale ""}
    {-multirow mapped_categories}
    object_id 
} {
    Returns multirow with: tree_id, tree_name, category_id, category_name 

    @param object_id object of which we want to know the mapped categories.
    @return multirow with tree and category information
    @author Peter Kreuzinger (peter.kreuzinger@wu-wien.ac.at)
} {
    if { $locale eq ""} {set locale [ad_conn locale]}
    upvar $multirow mapped_categories
    db_multirow mapped_categories select {}
}

ad_proc -public category::get_id { 
    name
    {locale en_US}
} {
    Gets the id of a category given a name.

    @param name the name of the category to retrieve
    @param locale the locale in which the name is supplied
    @return the category id or empty string it no category was found
    @author Lee Denison (lee@xarg.co.uk)
} {
    return [db_list get_category_id {}]
}

ad_proc -public category::reset_translation_cache { } {
    Reloads all category translations in the cache.
    @author Timo Hentschel (timo@timohentschel.de)
} {
    catch {nsv_unset categories}
    set category_id_old 0
    set tree_id_old 0
    db_foreach reset_translation_cache "" {
        if {$category_id != $category_id_old && $category_id_old != 0} {
	    nsv_set categories $category_id_old [list $tree_id_old [array get cat_lang]]
	    unset cat_lang
        }
        set category_id_old $category_id
	set tree_id_old $tree_id
        set cat_lang($locale) $name
    }
    if {$category_id_old != 0} {
        nsv_set categories $category_id [list $tree_id [array get cat_lang]]
    }
}

ad_proc -public category::flush_translation_cache { category_id } {
    Flushes category translation cache of one category.

    @param category_id category to be flushed.
    @author Timo Hentschel (timo@timohentschel.de)
} {
    db_foreach flush_translation_cache "" {
        set cat_lang($locale) $name
    }
    if {[info exists cat_lang]} {
        nsv_set categories $category_id [list $tree_id [array get cat_lang]]
    } else {
        nsv_set categories $category_id ""
    }
}

ad_proc -public category::get_name {
    category_id
    {locale ""}
} {
    Gets the category name in the specified language, if available.
    Use default language otherwise.

    @param category_id  category_id or list of category_id's for which to get the name. 
    @param locale       language in which to get the name. [ad_conn locale] used by default.
    @return list of names corresponding to the list of category_id's supplied.
    @author Timo Hentschel (timo@timohentschel.de)
} {
    if {$locale eq ""} {
        set locale [ad_conn locale]
    }
    if { [catch { array set cat_lang [lindex [nsv_get categories $category_id] 1] }] } {
        return {}
    }
    if { ![catch { set name $cat_lang($locale) }] } {
        # exact match: found name for this locale
        return $name
    }

    # try default locale for this language
    set language [lindex [split $locale "_"] 0]
    set locale [lang::util::default_locale_from_lang $language]
    if { ![catch { set name $cat_lang($locale) }] } {
        # exact match: found name for this default language locale
        return $name
    }
    
    # Trying system locale for package (or site-wide)
    set locale [lang::system::locale]
    if { ![catch { set name $cat_lang($locale) }] } {
        return $name
    }

    # Trying site-wide system locale
    set locale [lang::system::locale -site_wide]
    if { ![catch { set name $cat_lang($locale) }] } {
        return $name
    }

    # Resort to en_US
    if { ![catch { set name $cat_lang([parameter::get -parameter DefaultLocale -default en_US]) }] } {
        return $name
    } 

    # tried default locale, but nothing found
    return {}
}

ad_proc -public category::get_names {
    category_ids
    {locale ""}
} {
    Gets the category name in the specified language, if available.
    Use default language otherwise.

    @param category_id  category_id or list of category_id's for which to get the name. 
    @param locale       language in which to get the name. [ad_conn locale] used by default.
    @return list of names corresponding to the list of category_id's supplied.
    @author Timo Hentschel (timo@timohentschel.de)
} {
    set result [list]
    foreach category_id $category_ids {
        lappend result [category::get_name $category_id $locale]
    }
    return $result
}
ad_proc -public category::get_children {
    -category_id:required
} {
    Returns the category ids of the direct children of the given category

    @param category_id  category_id 
    @return list of category ids of the children of the supplied category_id
    @author Peter Kreuzinger (peter.kreuzinger@wu-wien.ac.at)
} {
    return [db_list get_children_ids ""]
}                

ad_proc -public category::count_children {
    {-category_id:required}
} {
    counts all direct sub categories
} {
    return [db_string select {}]
}
                                             
ad_proc -public category::get_parent {
    -category_id:required
} {
    Returns the category id of the parent category

    @param category_id  category_id 
    @return category id of the parent category
    @author Peter Kreuzinger (peter.kreuzinger@wu-wien.ac.at)
} {
    set result [db_list get_parent_id ""]
    if {$result eq "{}"} {set result 0}
    return $result
}                
    
ad_proc -public category::get_tree {
    category_id
} {
    Gets the tree_id of the given category.

    @param category_id  category_id or list of category_id's for which to get the tree_id.
    @return tree_id of the tree the category belongs to.
    @author Timo Hentschel (timo@timohentschel.de)
} {
    if { [catch { set tree_id [lindex [nsv_get categories $category_id] 0] }] } {
	# category not found
        return {}
    }
    return $tree_id
}

ad_proc -public category::get_data {
    category_id
    {locale ""}
} {
    Gets the category name and the tree name in the specified language, if available.
    Use default language otherwise.

    @param category_id  category_id to get the names.
    @param locale       language in which to get the names. [ad_conn locale] used by default.
    @return list of category_id, category_name, tree_id and tree_name.
    @author Timo Hentschel (timo@timohentschel.de)
} {
    set tree_id [category::get_tree $category_id]
    if {$tree_id eq ""} {
	# category not found
	return
    }
    return [list $category_id [category::get_name $category_id $locale] $tree_id [category_tree::get_name $tree_id $locale]]
}

ad_proc -public category::get_objects { 
    -category_id
    {-object_type ""}
    {-content_type ""}
    {-include_children:boolean}
} {
    Returns a list of objects which are mapped to this category_id
    
    @param category_id CategoryID of the category we want to get the objects for
    @param object_type Limit the search for objects of this object type
    @param content_type Limit the search for objects of this content_type
    @param include_children Include child categories' objects as well. Not yet implemented
    
    @author malte ()
    @creation-date Wed May 30 06:28:25 CEST 2007
} {
    set join_clause ""
    set where_clause ""
    if {$content_type ne ""} {
        set join_clause ", cr_items i"
        set where_clause "and i.item_id = com.object_id and i.content_type = :content_type"
    } elseif {$object_type ne ""} {
        set join_clause ", acs_objects o"
        set where_clause "and o.object_id = com.object_id and o.object_type = :object_type"        
    }
    return [db_list get_objects {}]
}

ad_proc -public category::get_id_by_object_title {
	title
} {
    Gets the id of a category given an object title (object_type=category).
    This is highly useful as the category object title will not change if you change the
    name (label) of the category, so you can access the category even if the label has changed
    
    @param title object title of the category to retrieve
    @return the category id or empty string it no category was found
	@author Peter Kreuzinger (peter.kreuzinger@wu-wien.ac.at)
} {
	return [db_string get_category_id {} -default ""]
}

ad_proc -public category::get_object_context { object_id } {
    Returns the object name and url to be used in a context bar.

    @param object_id object_id to get the name of.
    @author Timo Hentschel (timo@timohentschel.de)
} {
    set object_name [db_string object_name ""]
    return [list "/o/$object_id" $object_name]
}

ad_proc -deprecated category::indent_html { indent_width } {
    Creates a series of &nbsp; to indent subcatories in html output.

    @param indent_width width of the html indent.
    @author Timo Hentschel (timo@timohentschel.de)

    use string repeat "&nbsp;" $i
} {
    set indent_string ""
    for { set i 0 } { $i < $indent_width } { incr i } {
        append indent_string "&nbsp;"
    }

    return $indent_string
}

ad_proc -private category::context_bar { tree_id locale object_id {ctx_id ""}} {
    Creates the standard context bar

    @param tree_id
    @param locale
    @param object_id
    @author Timo Hentschel (timo@timohentschel.de)
} {
    if {$ctx_id eq ""} {unset ctx_id}
    if {$object_id ne ""} {
	set context_bar [list [category::get_object_context $object_id] [list [export_vars -no_empty -base object-map {locale object_id ctx_id}] [_ categories.cadmin]]]
    } else {
	set context_bar [list [list ".?[export_vars -no_empty {locale ctx_id}]" [_ categories.cadmin]]]
    }
    lappend context_bar [list [export_vars -no_empty -base tree-view {tree_id locale object_id ctx_id}] [category_tree::get_name $tree_id $locale]]

    return $context_bar
}

ad_proc category::pageurl { object_id } {
    Returns the page that displays a category.
    To be used by the AcsObject.PageUrl service contract.

    @param object_id category to be displayed.
    @author Timo Hentschel (timo@timohentschel.de)
} {
    db_1row get_tree_id_for_pageurl ""
    return "categories-browse?tree_ids=$tree_id&category_ids=$object_id"
}

ad_proc -private category::after_install {} {
    Callback to be called after package installation.
    Adds the service contract implementations.

    @author Timo Hentschel (timo@timohentschel.de)
} {
    acs_sc::impl::new -contract_name AcsObject -name category_idhandler -pretty_name "Category tree handler" -owner categories
    acs_sc::impl::alias::new -contract_name AcsObject -impl_name category_idhandler -operation PageUrl -alias category::pageurl
    acs_sc::impl::binding::new -contract_name AcsObject -impl_name category_idhandler

    acs_sc::impl::new -contract_name AcsObject -name category_tree_idhandler -pretty_name "Category tree handler" -owner categories
    acs_sc::impl::alias::new -contract_name AcsObject -impl_name category_tree_idhandler -operation PageUrl -alias category_tree::pageurl
    acs_sc::impl::binding::new -contract_name AcsObject -impl_name category_tree_idhandler
}

ad_proc -private category::before_uninstall {} {
    Callback to be called before package uninstallation.
    Removes the service contract implementations.

    @author Timo Hentschel (timo@timohentschel.de)
} {
    # shouldn't we first delete the bindings?
    acs_sc::impl::delete -contract_name AcsObject -impl_name category_idhandler
    acs_sc::impl::delete -contract_name AcsObject -impl_name category_tree_idhandler
}
