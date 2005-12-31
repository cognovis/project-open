# /www/survsimp/admin/index.tcl
ad_page_contract {
    This page is the main table of contents for navigation page 
    for simple survey module administrator

    @author philg@mit.edu
    @author nstrug@arsdigita.com
    @creation-date 3rd October, 2000
    @cvs-id $Id$
} {

}

set context [list "Survey Admin"]

set package_id [ad_conn package_id]

# bounce the user if they don't have permission to admin surveys
ad_require_permission $package_id survsimp_admin_survey

set disabled_header_written_p 0

db_multirow surveys select_surveys "select survey_id, name, enabled_p
from survsimp_surveys
where package_id= :package_id
order by enabled_p desc, upper(name)"
