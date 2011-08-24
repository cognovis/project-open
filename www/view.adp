<master>
<property name="title">@page_title@</property>
<property name="main_navbar_label"></property>

<h1>@page_title@</h1>

<table border=0>
	  <tr class=rowtitle> 
	    <td class=rowtitle>Key</td>
	    <td class=rowtitle>Value</td>
	  </tr>
	  <tr>
	    <td>#intranet-audit.Object_ID#</td>
	    <td>@object_id@</td>
	  </tr>
	  <tr>
	    <td>#intranet-audit.Status#</td>
	    <td>@audit_object_status@</td>
	  </tr>
	  <tr>
	    <td>#intranet-audit.Audit_User#</td>
	    <td><a href=@audit_user_url;noquote@>@audit_user_name@</a></td>
	  </tr>
	  <tr>
	    <td>#intranet-audit.Audit_IP#</td>
	    <td><a href=@audit_host_url;noquote@>@audit_ip@</a></td>
	  </tr>
	  <tr>
	    <td>#intranet-audit.Audit_Action#</td>
	    <td>@audit_action@</td>
	  </tr>
	  <tr>
	    <td>#intranet-audit.Audit_Date#</td>
	    <td>@audit_date_pretty@</td>
	  </tr>
	  <tr>
	    <td>#intranet-audit.Audit_Diff#</td>
	    <td>@audit_diff;noquote@</td>
	  </tr>
	  <tr> 
	    <td colspan=2><a href=@return_url;noquote@>#intranet-audit.Return_to_last_page#</td>
	  </tr>
</table>

<h1>#intranet-audit.Changed_Fields#</h1>
<table border=0>
	  <tr class=rowtitle> 
	    <td class=rowtitle>Key</td>
	    <td class=rowtitle>Value</td>
	    <td class=rowtitle>Last Value</td>
	  </tr>
@changed_fields_html;noquote@
</table>

