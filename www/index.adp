<!-- packages/intranet-confdb/www/index.adp -->
<!-- @author Frank Bergmann (frank.bergmann@project-open.com) -->
<master src="../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">conf_items</property>

<br>
<table border=0 cellpadding=0 cellspacing=0>
<tr>
  <td>
	    <table border=0 cellpadding=0 cellspacing=0>
	    <tr>
	      <td class=rowtitle align=center>
<%= [lang::message::lookup "" intranet-confdb.Filter_Conf_Items "Filter Conf Items"] %>
	      </td>
	    </tr>
	    <tr>
	      <td><formtemplate id=@form_id@></formtemplate></td>
	    </tr>
	    </table>
  </td>
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
		@admin_links;noquote@
	      </td>
	    </tr>
	    </table>
  </td>
</tr>
</table>

<listtemplate name="@list_id@"></listtemplate>

