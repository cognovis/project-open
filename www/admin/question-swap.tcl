ad_page_contract {

  Swaps two sort keys for a survey, sort_key and sort_key - 1.

  @param  survey_id  survey we're acting upon
  @param  sort_key   integer determining position of question which is
                     about to be replaced with previous one

  @author nstrug@arsdigita.com

  @cvs-id $Id$

} {

  survey_id:integer,notnull
  sort_key:integer,notnull
  
}

ad_require_permission $survey_id survsimp_modify_survey

set next_sort_key [expr { $sort_key - 1 }]

db_transaction {
    db_dml swap_sort_keys "update survsimp_questions
set sort_key = decode(sort_key, :sort_key, :next_sort_key, :next_sort_key, :sort_key)
where survey_id = :survey_id
and sort_key in (:sort_key, :next_sort_key)"

    ad_returnredirect "one?[export_url_vars survey_id]"

} on_error {

    ad_return_error "Database error" "A database error occured while trying
to swap your questions. Here's the error:
<pre>
$errmsg
</pre>
"
}
