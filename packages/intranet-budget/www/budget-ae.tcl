ad_page_contract { 
    @author iuri sampaio (iuri.sampaio@gmail.com)
} {
    {cost_type_id}
    {budget_id ""}
    {return_url ""}
    project_id:integer,optional
}

set cost_type [im_category_from_id $cost_type_id]


if {![exists_and_not_null cost_id]} {
    set page_title "[_ intranet-budget.New_Budget]"
} else {
    set page_title "[_ intranet-budget.Edit_Budget]"
}

set sub_navbar [im_costs_navbar "none" "/intranet-budget/" "" "" [list]] 


# Budget Status
set cost_status_select [im_cost_status_select "cost_status_id"]



# Table for the financial budget

set default_currency [parameter::get_from_package_key -parameter DefaultCurrency -package_key "intranet-cost" -default 0]
set amount_element_html ""

for {set i 0} {$i < 9} {incr i} { 
    if {[expr $i % 2] eq 0} {
        set bgcolor " class=roweven"
    } else { 
        set bgcolor " class=rowodd"
    }

    set currency_html [im_currency_select item_currency.$i $default_currency]
    set cost_type_select [im_cost_type_select "cost_type_select${i}"]

    append amount_element_html "
<tr $bgcolor>
  <td>
    <input type=text name=amount_description.$i size=120>
  </td>
    <td align=right>
     [im_category_select_helper -super_category_id $cost_type_id "Intranet Cost Type" cost_type.$i]
  </td> 
  <td align=right>
    <nobr><input type=text name=amount.$i size=7></nobr>
  </td>
</tr>
    "
}

# Table for the hour budget
set hour_element_html ""

for {set i 0} {$i < 9} {incr i} { 
    if {[expr $i % 2] eq 0} {
        set bgcolor " class=roweven"
    } else { 
        set bgcolor " class=rowodd"
    }

    set currency_html [im_currency_select item_currency.$i $default_currency]
    set cost_type_select [im_cost_type_select "cost_type_select${i}"]

    append hour_element_html "
<tr $bgcolor>
  <td>
    <input type=text name=hours_description.$i size=120>
  </td>
    <td align=right>
     [im_cost_center_select -department_only_p 1 department.$i]
  </td> 
  <td align=right>
    <nobr><input type=text name=hours.$i size=7></nobr>
  </td>
</tr>
    "
}