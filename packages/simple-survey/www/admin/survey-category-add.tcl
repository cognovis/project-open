# /www/survsimp/admin/one-respondent.tcl
ad_page_contract {

    Inserts a category into the central categories table
    and maps it to this survey.

    @param  survey_id  which survey we'll assign category to
    @param  category   name of a category to be created and assigned to survey

    @cvs-id $Id$
} {

    survey_id:integer,notnull
    category:notnull

}




db_transaction {

  set category_id [db_string category_id_next_sequence "select 
  category_id_sequence.nextval from dual"]

  db_dml category_insert "insert into categories 
  (category_id, category,category_type)
  values (:category_id, :category, 'survsimp')" 

  set one_line_item_desc "Survey: [db_string survey_name "
  select name from survsimp_surveys where survey_id = :survey_id" ]"

  db_dml category_map_insert "insert into site_wide_category_map 
  (map_id, category_id,
  on_which_table, on_what_id, mapping_date, one_line_item_desc) 
  values (site_wide_cat_map_id_seq.nextval, :category_id, 'survsimp_surveys',
  :survey_id, sysdate, :one_line_item_desc)" 

}

db_release_unused_handles
ad_returnredirect "one?[export_url_vars survey_id]"

