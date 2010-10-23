ad_page_contract {
    Update sort order

    @author Timo Hentschel (timo@timohentschel.de)
    @author Lars Pind (lars@collaboraid.biz)
    @cvs-id $Id:
} {
    tree_id:integer
    sort_key:array
    {locale ""}
    object_id:integer,optional
    ctx_id:integer,optional
}

permission::require_permission -object_id $tree_id -privilege category_tree_write

array set tree [category_tree::get_data $tree_id $locale]

db_transaction {

    set count 0
    db_foreach get_tree "" {
        incr count 10
        if {$parent_id eq ""} {
            # need this as an anchor for toplevel categories
            set parent_id -1
        }
        if {[info exists sort_key($category_id)]} {
            lappend child($parent_id) [list $sort_key($category_id) $category_id 0 0]
        } else {
            lappend child($parent_id) [list $count $category_id 0 0]
        }
    }
    set last_ind [expr {($count / 5) + 1}]

    set count 1
    set stack [list]
    set done_list [list]
    # put toplevel categories on stack
    if {[info exists child(-1)]} {
        set stack [lsort -integer -index 0 $child(-1)]
    }

    while {[llength $stack] > 0} {
        set next [lindex $stack 0]
        set act_category [lindex $next 1]
        set stack [lrange $stack 1 end]
        if {[lindex $next 2]>0} {
            ## the children of this parent are done, so this category is also done
            lappend done_list [list $act_category [lindex $next 2] $count]
        } elseif {[info exists child($act_category)]} {
            ## put category and all children back on stack
            set next [lreplace $next 2 2 $count]
            set stack [linsert $stack 0 $next]
            set stack [concat [lsort -integer -index 0 $child($act_category)] $stack]
        } else {
            ## this category has no children, so it is done
            lappend done_list [list $act_category $count [expr {$count + 1}]]
            incr count 1
        }
        incr count 1
    }

    if {$count == $last_ind} {
        # we do this so that there is no conflict in the old left_inds and the new ones
        db_dml reset_category_index ""

        foreach category $done_list {
            util_unlist $category category_id left_ind right_ind
            db_dml update_category_index ""
        }
    }
    category_tree::flush_cache $tree_id
}

if {$count != $last_ind} {
    ad_return_complaint 1 "Error during update: $done_list"
    return
}

ad_returnredirect [export_vars -no_empty -base tree-view {tree_id locale object_id ctx_id}]
