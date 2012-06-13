ad_page_contract {

    Process response from edit-logic.tcl

    @param  logic_id    id of logic record to update
    @param  survey_id   id of survey to return to
    @param  logic       new value for logic

    @author Nick Strugnell (nstrug@arsdigita.com)
    @creation-date September 14, 2000
    @cvs-id $Id$
} {

    logic_id:integer,notnull
    survey_id:integer,notnull
    logic:allhtml,notnull

}

ad_require_permission $survey_id survsimp_modify_survey

db_dml update_logic "update survsimp_logic
set logic = empty_clob()
where logic_id = :logic_id
returning logic into :1" -clobs [list $logic]

db_release_unused_handles
ad_returnredirect "one?survey_id=$survey_id"
