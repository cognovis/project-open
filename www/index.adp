<!-- packages/intranet-freelance-rfqs/www/index.adp -->
<!-- @author Frank Bergmann (frank.bergmann@project-open.com) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">freelance_rfqs</property>

<br>
@project_menu;noquote@

<h2>Available RFQs</h2>

<if @project_id@ eq "">
<table cellspacing=0 cellpadding=1>
	<tr class=rowtitle>
	  <td class=rowtitle align=center>#intranet-freelance-rfqs.Filter_RFQs#</td>
	</tr>
	<tr>
	  <td><formtemplate id="rfq_filters"></formtemplate></td>
	</tr>
</table>
</if>


<table border=0 cellpadding=0 cellspacing=0>
<tr>
  <td> <!-- TD for the left hand filter HTML -->

	<listtemplate name="rfqs_list"></listtemplate>

  </td> <!-- end of left hand filter TD -->
  <td>&nbsp;</td>
  <td valign=top width='30%'>
<!--
    <table border=0 cellpadding=0 cellspacing=0>
    <tr>
      <td class=rowtitle align=center>
        #intranet-core.Admin_Links#
      </td>
    </tr>
    <tr>
      <td>
	@admin_links;noquote@
      </td>
    </tr>
    </table>
  </td>
-->
</tr>
</table>

