ad_library {
    ]project-open[ specific extension for acs-workflow.

    I guess that these extensions are not reall ]project-open[ specific,
    but mainly reference the issue of integration with other packages.

    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 2006-03-16
    @cvs-id $Id$
}

ad_proc -public wf_workflow_list_options {
    {-include_empty 0}
    {-min_case_count 0}
} {
    Returns a list of workflows that satisfy certain conditions
} {
    set min_count_where ""
    if {$min_case_count > 0} { set min_count_where "and count(c.case_id) > 0\n" }
    set options [db_list_of_lists project_options "
            select
                   t.pretty_name,
                   w.workflow_key,
                   count(c.case_id) as num_cases,
                   0 as num_unassigned_tasks
            from   wf_workflows w left outer join wf_cases c
                     on (w.workflow_key = c.workflow_key and c.state = 'active'),
                   acs_object_types t
            where  w.workflow_key = t.object_type
                   $min_count_where
            group  by w.workflow_key, t.pretty_name
            order  by t.pretty_name
    "]
    if {$include_empty} { set options [linsert $options "" { "" "" }] }
    return $options
}
