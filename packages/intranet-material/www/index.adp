<!-- packages/intranet-forum/www/index.adp -->
<!-- @author Juanjo Ruiz (juanjoruizx@yahoo.es) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="../../intranet-core/www/admin/master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="admin_navbar_label">admin_materials</property>



<table border=0 cellpadding=0 cellspacing=0>
<tr>
  <td> <!-- TD for the left hand filter HTML -->

	<form method="get" action='index'>
	<%= [export_form_vars material_group_id material_start_idx material_order_by material_how_many material_view_name] %>
	@filter_html;noquote@
	</form>

  </td> <!-- end of left hand filter TD -->
  <td>&nbsp;</td>
  <td valign=top width='30%'>
    <table border=0 cellpadding=0 cellspacing=0>
    <tr>
      <td class=rowtitle align=center>
        #intranet-core.Admin_Links#
      </td>
    </tr>
    <tr>
      <td>
        @admin_html;noquote@
      </td>
    </tr>
    </table>
  </td>
</tr>
</table>

<br>

@material_content;noquote@
