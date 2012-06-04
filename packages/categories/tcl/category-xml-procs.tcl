ad_library {
    Procedures for importing/exporting category trees from/to XML documents.

    @author Tom Ayles (tom@beatniq.net)
    @creation-date 2003-12-02
    @cvs-id $Id$
}

namespace eval ::category_tree::xml {}

ad_proc -public ::category_tree::xml::import_from_file {
    {-site_wide:boolean}
    file
} {
    Imports a category tree from a given file.
} {
    if {![file exists $file] || ![file readable $file]} {
        error {Cannot open file for reading}
    }

    return [import -site_wide=$site_wide_p [::tDOM::xmlReadFile $file]]
}

ad_proc -public ::category_tree::xml::import {
    {-site_wide:boolean}
    xml
} {
    Imports a category tree from an XML representation.

    @param xml A string containing the source XML to import from
    @return The category tree identifier
    @author Tom Ayles (tom@beatniq.net)
} {
    # recode site_wide_p to DB-style boolean
    if {$site_wide_p} { set site_wide_p t } else { set site_wide_p f }

    set doc [dom parse $xml]
    if [catch {set root [$doc documentElement]} err] {
        error "Error parsing XML: $err"
    }

    set tree_id 0

    db_transaction {
        foreach translation [$root selectNodes {translation}] {
            if [catch {set locale [$translation getAttribute locale]}] {
                error "Required attribute 'locale' not found"
            }
            if [catch {set name [[$translation selectNodes {name}] text]}] {
                error "Required element 'name' not found"
            }
            if [catch {set description \
                           [[$translation selectNodes {description}] text]}] {
                set description {}
            }
            if {$tree_id} {
                # tree initialised, add translation
                category_tree::update \
                    -tree_id $tree_id \
                    -name $name \
                    -description $description \
                    -locale $locale
            } else {
                # initialise tree
                set tree_id [category_tree::add \
                                 -site_wide_p $site_wide_p \
                                 -name $name \
                                 -description $description \
                                 -locale $locale]
            }
        }

        foreach category [$root selectNodes {category}] {
            add_category -tree_id $tree_id -parent_id {} $category
        }
    }
    
    $doc delete

    return $tree_id
}

ad_proc -private ::category_tree::xml::add_category {
    {-tree_id:required}
    {-parent_id:required}
    node
} {
    Imports one category.
} {
    set category_id 0
    
    # do translations
    foreach translation [$node selectNodes {translation}] {
        if [catch {set locale [$translation getAttribute locale]}] {
            error "Required attribute 'locale' not found"
        }
        if [catch {set name [[$translation selectNodes {name}] text]}] {
            error "Required element 'name' not found"
        }
        if [catch {set description \
                       [[$translation selectNodes {description}] text]}] {
            set description {}
        }

        if {$category_id} {
            # category exists, add translation
            category::update \
                -category_id $category_id \
                -locale $locale \
                -name $name \
                -description $description
        } else {
            # create category
            set category_id [category::add \
                                 -tree_id $tree_id \
                                 -parent_id $parent_id \
                                 -locale $locale \
                                 -name $name \
                                 -description $description]
        }
    }
    
    # do children
    foreach child [$node selectNodes {category}] {
        add_category -tree_id $tree_id -parent_id $category_id $child
    }
}
