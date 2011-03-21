# /packages/intranet-reporting-tutorial/www/trans-tasks-adhoc-01.tcl
#
# Copyright (c) 2003-2007 ]project-open[
#
# All rights reserved.
# Please see http://www.project-open.com/ for licensing.


# ------------------------------------------------------------
# Translation Tasks AdHoc Tutorial Report 
#
# This report contains:
#
# - Page Title, Bread Crums and Help
# - Report SQL (base)
#


# ------------------------------------------------------------
# Page Title, Bread Crums and Help
#
# We always need a "page_title".
# The "context_bar" defines the "bread crums" at the top of the
# page that allow a user to return to the home page and to
# navigate the site.
#
# Every reports should contain a "help_text" that explains in
# detail what exactly is shown. Reports can get very messy and
# it can become very difficult to interpret the data shown.
#

set page_title "Forum-AdHoc-01 Tutorial Report"
set context_bar [im_context_bar $page_title]
set help "
        <b>Translation Tasks AdHoc 01 Tutorial Report</b>:<br>
	Shows the different languages translated per month.
"



# ------------------------------------------------------------
# Define the report

set col_titles {"ProjectNr" "Name" "Units" "Source" "Target" "Trans" "Edit" "Proof" "Other"}

set content [im_ad_hoc_query -format html -col_titles $col_titles "

	select
		p.project_nr,
		t.task_name,
		t.task_units,
		im_category_from_id(t.source_language_id) as source_language,
		im_category_from_id(t.target_language_id) as target_language,
		im_name_from_user_id(t.trans_id) as trans,
		im_name_from_user_id(t.edit_id) as edit,
		im_name_from_user_id(t.proof_id) as proof,
		im_name_from_user_id(t.other_id) as other
	from
		im_trans_tasks t,
		im_projects p
	where
		t.project_id = p.project_id
	order by
		p.project_nr

"]



#                  Table "public.im_trans_tasks"
#          Column         |           Type           | Modifiers
# ------------------------+--------------------------+-----------
#  task_id                | integer                  | not null
#  project_id             | integer                  | not null
#  target_language_id     | integer                  |
#  task_name              | character varying(1000)  |
#  task_filename          | character varying(1000)  |
#  task_type_id           | integer                  | not null
#  task_status_id         | integer                  | not null
#  description            | character varying(4000)  |
#  source_language_id     | integer                  | not null
#  task_units             | numeric(12,1)            |
#  billable_units         | numeric(12,1)            |
#  task_uom_id            | integer                  | not null
#  invoice_id             | integer                  |
#  quote_id               | integer                  |
#  match_x                | numeric(12,0)            |
#  match_rep              | numeric(12,0)            |
#  match100               | numeric(12,0)            |
#  match95                | numeric(12,0)            |
#  match85                | numeric(12,0)            |
#  match75                | numeric(12,0)            |
#  match50                | numeric(12,0)            |
#  match0                 | numeric(12,0)            |
#  trans_id               | integer                  |
#  edit_id                | integer                  |
#  proof_id               | integer                  |
#  other_id               | integer                  |
#  end_date               | timestamp with time zone |
#  tm_integration_type_id | integer                  |
