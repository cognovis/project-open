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
    select * from (
	    	select 
			im_category_from_id(p.language_id) as person_language,
			pa.email,
			p.person_id,
			im_name_from_user_id(p.person_id) as person_name,
			p.business_sector_id as person_sector_id,
			im_category_from_id(p.business_sector_id) as person_sector,
			c.company_id,
			c.company_name,
			c.business_sector_id as company_sector_id,
			im_category_from_id(c.business_sector_id) as company_sector,
			im_category_from_id(c.abc_prio_id) as abc
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
		
		    where
			m.group_id = 5372
			and m.member_id = p.person_id
			and pa.party_id = p.person_id
			and (p.spam_frequency_id is null OR p.spam_frequency_id != 11130)
 	UNION
	    	select 
			'' as person_language,
			'' as email,
			0 as person_id,
			'' as person_name,
			c.business_sector_id as person_sector_id,
			im_category_from_id(c.business_sector_id) as person_sector,
			c.company_id,
			c.company_name,
			c.business_sector_id as company_sector_id,
			im_category_from_id(c.business_sector_id) as company_sector,
			im_category_from_id(c.abc_prio_id) as abc
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
	person_language,
	person_sector,
	person_id,
	company_name
"

set report_def [list \
    group_by person_language \
    header {"<b>$person_language</b>" "" "" "" "" "" "" "" ""} \
    content [list  \
	group_by company_sector \
	header {"" "<b>$company_sector</b> $company_sector_id" "" "" "" "" "" "" ""} \
	content [list  \
	    header {
		"$person_language"
		"$person_sector $person_sector_id"
		"<a href=mailto:$email>$email</a>" 
		"<a href=/intranet/users/view?user_id=$person_id>$person_name</a>"
		""
		$person_sector 
		"$abc"
		"<a href=/intranet/companies/view?company_id=$company_id>$company_name</a>"
		$company_sector} \
	    content {} \
        ] \
    ] \
    footer {"" "" "" "" "" "" "" "" ""} \
]

# Global header/footer
set header0 {"Lang" "Sector" "Email" "First" "Last" "Sector" "A" "Company" "Sector"}
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
