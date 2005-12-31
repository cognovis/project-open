ad_page_contract {

    Lists all the enabled surveys
    a user is eligable to complete.

    @author  philg@mit.edu
    @author  nstrug@arsdigita.com
    @creation-date    28th September 2000
    @cvs-id  $Id$
} {

} -properties {
    surveys:multirow
}

set package_id [ad_conn package_id]

set context [list "Surveys"]

set user_id [ad_maybe_redirect_for_registration]

db_multirow surveys survey_select {
    select survey_id, name
    from survsimp_surveys, acs_objects
    where object_id = survey_id
    and context_id = :package_id
    and acs_permission.permission_p(object_id, :user_id, 'survsimp_take_survey') = 't'
    and enabled_p = 't'
    order by upper(name)
}

db_release_unused_handles

ad_return_template

