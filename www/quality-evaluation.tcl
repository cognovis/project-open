# /www/intranet/quality/quality-evaluation.tcl

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    @author Guillermo Belcic Bardaji
    @cvs-id 
} {
    task_id:integer,notnull
}
# ---------------------------------------------------------------
# 2. Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set user_id [ad_get_user_id]
set todays_date [lindex [split [ns_localsqltimestamp] " "] 0]
set page_title "Quality"
set context_bar [ad_context_bar_ws $page_title]

set current_user_id [ad_maybe_redirect_for_registration]

db_1row current "
select first_names, last_name
from users
where user_id = $current_user_id
"
set current_user "$first_names $last_name"

db_0or1row task_evaliation {
select
	t.task_name,
	u.user_name as translator_name,
	t.task_units as words,
	c.group_name as customer_name,
	p.manager_name,
	im_category_from_id (t.source_language_id) as source_language,
	im_category_from_id (t.target_language_id) as target_language
from
	im_tasks t,
	( select g.group_name
	 from 	user_groups g,
         	im_projects p,
         	im_tasks t
	 where 	g.group_id = p.customer_id
         	and p.group_id = t.project_id
         	and t.task_id = :task_id
  	) c,
	( select u.first_names||' '||u.last_name as manager_name
    	 from 	im_projects p,
         	users u,
         	im_tasks t
   	 where 	u.user_id = p.project_lead_id
	        and p.group_id = t.project_id
        	and t.task_id = :task_id
	) p,
	( select u.first_names||' '||u.last_name as user_name
    	 from 	users u,
         	im_tasks t
   	 where 	u.user_id = t.trans_id
         	and t.task_id = :task_id
  	) u
where
	t.task_id = :task_id
}


set table_body_html "
<table border=0 cellspacing=0 cellpadding=0>
  <tr class=roweven> 
    <td><strong>Source Language</strong></td>
    <td><input name=source_language type=text [export_form_value source_language] disabled></td>
    <td colspan=2></td>
    <td ><div align=right><strong>Date</strong></div></td> 
    <td><input name=date type=text value=$todays_date disabled></td>
  </tr>
  <tr align=left valign=top class=roweven> 
    <td colspan=2> <strong>Target Language</strong> 
                   <input name=target_language type=text [export_form_value target_language] disabled>
    </td>
    <td colspan=2  >&nbsp; </td>
    <td align=right><strong>Reviewer Name</strong></td>
    <td><input name=reviwer_name type=text [export_form_value current_user] disabled></td>
  </tr>
  <tr align=left valign=top  > 
     <td colspan=5>&nbsp;</td>
     <td>&nbsp;</td>
  </tr>
  <tr align=left valign=middle  > 
    <td class=roweven><strong>Client Name </strong></td>
    <td class=roweven> <input name=customer_name type=text [export_form_value customer_name] disabled></td>
    <td colspan=2>&nbsp;</td>
    <td class=roweven><strong>Project Number</strong></td>
    <td class=roweven><input name=project_number type=text disabled></td>
    <td rowspan=7>&nbsp;</td>
  </tr>
  <tr align=left valign=middle  > 
    <td class=roweven><strong>Translator Name</strong></td>
    <td class=roweven><input name=trans_name type=text [export_form_value translator_name] disabled></td>
    <td colspan=2>&nbsp;</td>
    <td class=roweven><strong>Project Manager</strong></td>
    <td class=roweven><input name=manager_name type=text [export_form_value manager_name] disabled></td>
  </tr>
  <tr align=left valign=middle  > 
    <td colspan=4>&nbsp;</td>
  </tr>
  <tr align=left valign=middle  > 
    <td class=roweven><strong>Sample size</strong></td>
    <td class=roweven><input name=sample_size type=text></td>
    <td colspan=2 >&nbsp;</td>
  </tr>
  <tr align=left valign=middle  > 
    <td colspan=4>&nbsp;</td>
  </tr>
</table>
<table>
<tr align=left valign=middle> 
  <td colspan=2  class=roweven><strong>Error Category</strong></td>
  <td  class=roweven><strong>Minor</strong></td>
  <td  class=roweven><strong>Mayor</strong></td>
  <td  class=roweven><strong>Critical</strong></td>
</tr>
<tr align=left valign=middle  > 
  <td colspan=2>Mistranslation</td>
  <td><input name=mistranslation.minor type=text size=10></td>
  <td><input name=mistranslation.major type=text size=10></td>
  <td><input name=mistranslation.critical type=text size=10></td>
</tr>
<tr align=left valign=middle  > 
  <td colspan=2>Accuracy</td>
  <td><input name=accuracy.minor type=text size=10></td>
  <td><input name=accuracy.major type=text size=10></td>
  <td><input name=accuracy.critical type=text size=10></td>
</tr>
<tr align=left valign=middle  > 
  <td colspan=2>Terminology</td>
  <td><input name=terminology.minor type=text size=10></td>
  <td><input name=terminology.major type=text size=10></td>
  <td><input name=terminology.critical type=text size=10></td>
</tr>
<tr align=left valign=middle  > 
  <td colspan=2>Language</td>
  <td><input name=language.minor type=text size=10></td>
  <td><input name=language.major type=text size=10></td>
  <td><input name=language.critical type=text size=10></td>
</tr>
<tr align=left valign=middle  > 
  <td colspan=2>Style</td>
  <td><input name=style.minor type=text size=10></td>
  <td><input name=style.major type=text size=10></td>
  <td><input name=style.critical type=text size=10></td>
</tr>
<tr align=left valign=middle  > 
  <td colspan=2>Country</td>
  <td><input name=country.minor type=text size=10></td>
  <td><input name=country.major type=text size=10></td>
  <td><input name=country.critical type=text size=10></td>
</tr>
<tr align=left valign=middle  > 
  <td colspan=2>Consistency</td>
  <td><input name=consistency.minor type=text size=10></td>
  <td><input name=consistency.major type=text size=10></td>
  <td><input name=consistency.critical type=text size=10></td>
</tr>
<tr align=left valign=middle  > 
  <td colspan=2>&nbsp;</td>
  <td>&nbsp;</td>
  <td>&nbsp;</td>
  <td>&nbsp;</td>
  <td>&nbsp;</td>
</tr>
</table>
"


set page_body "
<form action=quality-evaluation-2.tcl method=GET>
[export_form_vars task_id return_url]
$table_body_html
<input type=submit value=Evaluate name=evaluation>
</form>
"


db_release_unused_handles

doc_return  200 text/html [im_return_template]
