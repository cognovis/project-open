# /www/survsimp/admin/description-edit-2.tcl
ad_page_contract {
    Updates database with the new description
    information and return user to the main survey page.

    @param survey_id       survey which description we're updating
    @param desc_html       is the description html or plain text
    @param description     text of survey description
    @param checked_p       confirmation flag

    @author jsc@arsdigita.com
    @author nstrug@arsdigita.com
    @creation-date   February 16, 2000
    @cvs-id $Id$
} {
    survey_id:integer
    desc_html:notnull
    description:html
    {checked_p "f"}
}

ad_require_permission $survey_id survsimp_modify_survey

set exception_count 0
set exception_text ""

if { [empty_string_p $description] } {
    incr exception_count
    append exception_text "<li>You didn't enter a description for this survey.\n"
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    ad_script_abort
}

if {$checked_p == "f"} {
    set context [list [list "one?[export_url_vars survey_id]" "Administer Survey"] "Confirm Description"]

    switch $desc_html {
	"t" {
	}
	
	"pre" {
	    regsub "\[ \012\015\]+\$" $description {} description
	    set description "<pre>[ns_quotehtml $description]</pre>"
	    set desc_html  "t"
	}

	default {
	    set description "[util_convert_plaintext_to_html $description]"
	}
    }

} else {
 

    db_dml survsimp_update_description "update survsimp_surveys 
      set description = :description,
          description_html_p = :desc_html
          where survey_id = :survey_id"

    db_release_unused_handles
    ad_returnredirect "one?[export_url_vars survey_id]"
    ad_script_abort
}


