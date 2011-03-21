ad_page_contract { 
    @author iuri sampaio (iuri.sampaio@gmail.com)
} {
    {-return_url ""}
    {project_id ""}
    {customer_id ""}
    {invoice_id "0"}
}

set cost_type_id [im_cost_type_estimation]
set material_type_id 9015
set cost_type [im_category_from_id $cost_type_id]
set page_title "[_ intranet-invoices.Edit_cost_type]"
set sub_navbar [im_costs_navbar "none" "/intranet/invoices/index" "" "" [list]] 

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"

set task_sum_html ""
set ctr 1


if {$invoice_id eq "0"} {
    if {$project_id eq ""} {
	ad_return_error "Error" "ERROR. You cant call this without a project_id"
    }
} else {

    set old_project_id 0
    set colspan 6
    set vat_colspan 6
    set target_language_id ""
    db_foreach invoice_item "" {

	append task_sum_html "
	<tr $bgcolor([expr $ctr % 2])> 
          <td>
	    <input type=text name=item_name.$ctr size=40 value='[ns_quotehtml $item_name]'>
	  </td>
  	  <td align=right>
            [im_material_select -max_option_len 100 -restrict_to_type_id $material_type_id item_material_id.$ctr $item_material_id]
	  </td> 
 	  <td align=right>
	    <nobr><input type=text name=item_units.$ctr size=4 value='$item_units'> [im_category_select "Intranet UoM" "item_uom_id.$ctr" $item_uom_id]</nobr>
	  </td>
          <td align=right>
	    <nobr><input type=text name=item_rate.$ctr size=7 value='$price_per_unit'>[im_currency_select item_currency.$ctr $currency]</nobr>
	  </td>
	"
	incr ctr
    }
 
}


# start formatting the list of sums with the header...

# Invoice currency
set default_currency  [parameter::get_from_package_key -parameter DefaultCurrency -package_key "intranet-cost" -default 0]

for {set i 0} {$i < 9} {incr i} { 

    append task_sum_html "
	<tr $bgcolor([expr $ctr % 2])>
	  <td>
	    <input type=text name=item_name.$ctr size=40>
	  </td>
  	  <td align=right>
 	      [im_material_select -max_option_len 100 -restrict_to_type_id $material_type_id item_material_id.$ctr ""]
	  </td> 
 	  <td align=right>
	    <nobr><input type=text name=item_units.$ctr size=4> [im_category_select "Intranet UoM" "item_uom_id.$ctr"]</nobr>
	  </td>
          <td align=right>
	    <nobr><input type=text name=item_rate.$ctr size=7>[im_currency_select item_currency.$ctr $default_currency]</nobr>
	  </td>
	</tr>
    "
    incr ctr
}
	
