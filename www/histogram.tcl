
# Called as a component

if {![info exists component_name]} { set component_name "Undefined Component" }
if {![info exists cube_name]} { set  cube_name "finance" }
if {![info exists start_date]} { set start_date "" }
if {![info exists end_date]} { set end_date "" }
if {![info exists cost_type_id]} { set cost_type_id "3700" }
if {![info exists top_vars]} { set top_vars "year" }
if {![info exists left_vars]} { set left_vars "customer_name" }
if {![info exists return_url]} { set return_url ""}

set bar_width 10
set bar_distance 14

set status_html ""

set sql "
	select	count(*) as cnt,
		im_category_from_id(project_status_id) as project_status
	from	im_projects p
	group by project_status_id
"
set max_count [db_string max_count "select max(cnt) from ($sql) t"]
set num_entries [db_string numcount "select count(*) from ($sql) t"]

set count 0
db_foreach project_status $sql {

    set bar_text "$project_status: $cnt "
    if {1 == $cnt} { append bar_text "Project" } else { append bar_text "Projects" }

    append status_html "
	new Bar(
		D1.ScreenX(0), D1.ScreenY($count)-24, D1.ScreenX($max_count), D1.ScreenY($count)-8,
		\"\", \"$bar_text\", \"#000000\", \"$bar_text\",
		\"\", \"\", \"\", \"left\"
	);
	new Bar(
		D1.ScreenX(0), D1.ScreenY($count)-8, D1.ScreenX($cnt), D1.ScreenY($count)+8,
		\"#0080FF\", \"\", \"#000000\", \"$bar_text\", \"\"
	);
    "
    incr count
}


set histogram_html "
<SCRIPT Language=JavaScript src=/resources/diagram/diagram/diagram.js></SCRIPT>
<div style='border:2px solid blue; position:relative; top:0px; height:350px; width:550px;'>
<SCRIPT Language=JavaScript>
document.open();
var D1=new Diagram();
_BFont=\"font-family:Verdana;font-weight:normal;font-size:8pt;line-height:10pt;\";
D1.SetFrame(50, 50, 500, 300);
D1.SetBorder(0, $max_count*1.1, 0, $num_entries);
D1.XScale=1;
D1.YScale=0;
D1.SetText(\"\",\"\", \"<B>Current Projects</B>\");
D1.Draw(\"#FFFFFF\", \"#004080\", false,\"Click on a bar to get the phone number\");
$status_html
</SCRIPT>
</div>
"
