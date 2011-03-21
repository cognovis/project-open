# /packages/intranet-reporting-tutorial/www/forum-adhoc-01.tcl
#
# Copyright (c) 2003-2007 ]project-open[
#
# All rights reserved.
# Please see http://www.project-open.com/ for licensing.


# ------------------------------------------------------------
# Forum-AdHoc-01 Tutorial Contents
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
# Every reports should contain a "help_text" that explains in
# detail what exactly is shown. Reports can get very messy and
# it can become very difficult to interpret the data shown.
#

set page_title "Forum-AdHoc-01 Tutorial Report"
set context_bar [im_context_bar $page_title]
set help "
	<b>Forum-AdHoc-01 Tutorial Report</b>:<br>
	Shows the contents of all forum topics in the system.<br>
	Does not include the replies to forum entries.
"



# ------------------------------------------------------------
# Define the report

set content [im_ad_hoc_query -format html "

	select
		to_char(posting_date, 'YYYY-MM-DD') as posting_date,
		im_category_from_id(topic_type_id) as topic_type,
		im_category_from_id(topic_status_id) as topic_status,
		im_name_from_user_id(owner_id) as owner_name,
		im_email_from_user_id(owner_id) as owner_email,
		subject,
		message
	from
		im_forum_topics
	where
		parent_id is null
	order by
		topic_id

"]

