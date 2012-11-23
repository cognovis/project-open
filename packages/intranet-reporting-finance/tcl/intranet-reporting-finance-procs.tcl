# /packages/intranet-reporting-finance/tcl/intranet-reporting-finance-procs.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Finance Reporting Component Library
    @author frank.bergmann@project-open.com
}

# -------------------------------------------------------
# Package Procs
# -------------------------------------------------------

ad_proc -public im_package_reporting_finance_id {} {
    Returns the package id of the intranet-reporting-finance module
} {
    return [util_memoize "im_package_reporting_finance_id_helper"]
}

ad_proc -private im_package_reporting_finance_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-reporting-finance'
    } -default 0]
}


# ------------------------------------------------------------
# Find out all fields per object type
# -------------------------------------------------------

ad_proc im_dynfield_object_attributes_for_select {
     -object_type:required
} {
    Returns a list {key1 value1 key2 value2 ...} of attributes
    and pretty_names for object.
    The result is meant to be appended to the select list of
    a report with custom fields
} {
    set dynfield_sql "
        select
                aa.attribute_name,
                aa.pretty_name,
                ot.pretty_name as object_type_pretty_name,
                w.deref_plpgsql_function
        from
                acs_attributes aa
                RIGHT OUTER JOIN
                        im_dynfield_attributes fa
                        ON (aa.attribute_id = fa.acs_attribute_id)
                LEFT OUTER JOIN
                        (select * from im_dynfield_layout where page_url = '') la
                        ON (fa.attribute_id = la.attribute_id)
                LEFT OUTER JOIN
                        user_tab_columns c
                        ON (c.table_name = upper(aa.table_name) and c.column_name = upper(aa.attribute_name)),
                im_dynfield_widgets w,
                acs_object_types ot
        where
                aa.object_type = :object_type
                and fa.widget_name = w.widget_name
                and aa.object_type = ot.object_type
        order by
                la.pos_y, la.pos_x, aa.attribute_name
    "

    set field_options [list]
    db_foreach dynfield_fields $dynfield_sql {
        lappend field_options "${attribute_name}_deref"
        lappend field_options "$object_type_pretty_name - $pretty_name"
    }

    return $field_options
}



ad_proc im_dynfield_object_attributes_derefs {
    -object_type:required
    {-prefix ""}
} {
    Returns a list list of dereferentiation "SELECT" statements.
} {
    set dynfield_sql "
        select
                aa.attribute_name,
                aa.pretty_name,
                ot.pretty_name as object_type_pretty_name,
                w.deref_plpgsql_function
        from
                acs_attributes aa
                RIGHT OUTER JOIN
                        im_dynfield_attributes fa
                        ON (aa.attribute_id = fa.acs_attribute_id)
                LEFT OUTER JOIN
                        (select * from im_dynfield_layout where page_url = '') la
                        ON (fa.attribute_id = la.attribute_id)
                LEFT OUTER JOIN
                        user_tab_columns c
                        ON (c.table_name = upper(aa.table_name) and c.column_name = upper(aa.attribute_name)),
                im_dynfield_widgets w,
                acs_object_types ot
        where
                aa.object_type = :object_type
                and fa.widget_name = w.widget_name
                and aa.object_type = ot.object_type
        order by
                la.pos_y, la.pos_x, aa.attribute_name
    "

    set deref_list [list]
    db_foreach dynfield_fields $dynfield_sql {
        lappend deref_list "${deref_plpgsql_function}($prefix$attribute_name) as ${attribute_name}_deref"
    }
    return $deref_list
}


