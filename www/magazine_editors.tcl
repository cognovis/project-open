ad_page_contract {
	testing reports	
} {

}

set user_id [ad_maybe_redirect_for_registration]
set page_title "Magazine Editors Report"
set context_bar [im_context_bar $page_title]
set context ""
set today [db_string today "select to_char(sysdate, 'YYYYMMDD.HHmm') from dual"]

set row_class "rowtitle"

# ------------------------------------------------------------
# Define the report - SQL, counters, headers and footers 
#

set sql "
	select	*,
		coalesce(person_language, company_language) as language,
		coalesce(person_sector, company_sector) as sector
	from (
		-- select persons, together with their company
	    	select 
			im_category_from_id(p.language_id) as person_language,
			im_category_from_id(c.language_id) as company_language,
			pa.email,
			p.person_id,
			im_name_from_user_id(p.person_id) as person_name,
			im_category_from_id(p.business_sector_id) as person_sector,
			c.company_id,
			c.company_name,
			im_category_from_id(c.business_sector_id) as company_sector,
			im_category_from_id(c.abc_prio_id) as abc,
			uc.note
		    from
			group_member_map m,
			parties pa,
			persons p
			LEFT OUTER JOIN (
				select	r.object_id_two as person_id,
					c.*
				from	acs_rels r,
					im_companies c
				where	r.object_id_one = c.company_id
			) c ON (p.person_id = c.person_id)
			LEFT OUTER JOIN users_contact uc ON p.person_id = uc.user_id
		    where
			m.group_id = 5372
			and m.member_id = p.person_id
			and pa.party_id = p.person_id
			and (p.spam_frequency_id is null OR p.spam_frequency_id != 11130)
 	UNION
		-- include companies without members
	    	select 
			NULL as person_language,
			im_category_from_id(c.language_id) as person_language,
			NULL as email,
			0 as person_id,
			NULL as person_name,
			im_category_from_id(c.business_sector_id) as person_sector,
			c.company_id,
			c.company_name,
			im_category_from_id(c.business_sector_id) as company_sector,
			im_category_from_id(c.abc_prio_id) as abc,
			NULL as note
		from
			im_companies c
		where
			c.company_type_id in ([join [im_sub_categories 10026] ","])
			and c.company_id not in (
				select distinct
					c.company_id
				from	acs_rels r,
					persons p,
					im_companies c,
					group_member_map m
				where	r.object_id_two = p.person_id
					and r.object_id_one = c.company_id
					and m.member_id = p.person_id
					and m.group_id = 5372
			)
    ) t
    order by
	sector,
	language,
	company_name,
	person_id
"

set report_def [list \
    group_by sector \
    header {"<b>$sector</b>" "" "" "" "" "" "" "" ""} \
    content [list  \
	group_by language \
	header {"<b>$sector</b>" "<b>$language</b>" "" "" "" "" "" ""} \
	content [list  \
	    header {
		"$sector"
		"$language"
		"$abc"
		"<a href=/intranet/companies/new?company_id=$company_id>$company_name</a>"
		"<a href=mailto:$email>$email</a>" 
		"<a href=/intranet/users/view?user_id=$person_id>$person_name</a>"
		"$note"
	    } \
	    content {} \
        ] \
    ] \
    footer {"" "" "" "" "" "" "" "" ""} \
]

# Global header/footer
set header0 {"Sector" "Lang" "A" "Company" "Email" "Name" "Person<br>Note"}
set footer0 {"" "" "" "" "" "" "" "" ""}

set counters [list]


# ------------------------------------------------------------
# Start formatting the page
#

ad_return_top_of_page "
[im_header]
[im_navbar]
<H1>$page_title</H1>
<table border=0 cellspacing=1 cellpadding=1>\n"

im_report_render_row \
    -row $header0 \
    -row_class rowtitle \
    -row_class "rowtitle" \
    -cell_class "rowtitle"


set footer_array_list [list]
set last_value_list [list]
db_foreach sql $sql {

    im_report_display_footer \
	-group_def $report_def \
        -footer_array_list $footer_array_list \
	-last_value_array_list $last_value_list

    im_report_update_counters -counters $counters

    set last_value_list [im_report_render_header \
	-group_def $report_def \
	-last_value_array_list $last_value_list \
    ]

    set footer_array_list [im_report_render_footer \
	-group_def $report_def \
	-last_value_array_list $last_value_list \
    ]

}

im_report_display_footer \
    -group_def $report_def \
    -footer_array_list $footer_array_list \
    -last_value_array_list $last_value_list \
    -display_all_footers_p 1

im_report_render_row \
    -row $footer0 \
    -row_class rowtitle \
    -row_class "rowtitle" \
    -cell_class "rowtitle"

ns_write "</table>\n[im_footer]\n"
