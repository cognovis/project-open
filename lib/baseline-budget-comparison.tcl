ad_page_contract {
    Shows a comparison of basic financial figures
    between the baseline and the current project
} {

}

# parameters from calling page:
# baseline_id

set date_format "YYYY-MM-DD"


db_1row baseline_current_info "
	select	p.project_id as main_project_id,
		p.project_budget as current_project_budget,
		p.project_budget_currency as current_project_budget_currency,
		p.project_budget_hours as current_budget_hours,
		to_char(p.start_date, :date_format) as current_start_date,
		to_char(p.end_date, :date_format) as current_end_date
	from	im_projects p,
		im_baselines b
	where	b.baseline_project_id = p.project_id and
		b.baseline_id = :baseline_id
"


db_1row baseline_baseline_info "
	select	pa.project_budget as baseline_project_budget,
		pa.project_budget_currency as baseline_project_budget_currency,
		pa.project_budget_hours as baseline_budget_hours,
		to_char(pa.start_date, :date_format) as baseline_start_date,
		to_char(pa.end_date, :date_format) as baseline_end_date
	from	im_audits a,
		im_projects_audit pa
	where	a.audit_object_id = :main_project_id and
		a.audit_id = pa.audit_id
"

set undef [lang::message::lookup "" intranet-baseline.Undef "<undef>"]
if {"" == $baseline_project_budget} { set baseline_project_budget $undef }
if {"" == $current_project_budget} { set current_project_budget $undef }

if {"" == $baseline_budget_hours} { set baseline_budget_hours $undef }
if {"" == $current_budget_hours} { set current_budget_hours $undef }


