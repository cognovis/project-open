<master>
<property name="title">@page_title@</property>
<property name="context_bar">#intranet-search-pg.Advanced_Search#</property>

<form method=GET action=search>


<table width=100%>
<tr>
  <td width="70%">

	<center>

	<table>
	<tr>
	  <td colspan=1 align=center>
	    <%= [im_logo] %>
	  </td>
	</tr>
	<tr>
	  <td>
	    <input type=text name=q size=40 maxlength=256 value="@q@">
	  </td>
	  <td>
	  </td>
	</tr>
	<tr>
	  <td colspan=1 align=center>
	    <input type=submit value="#intranet-search-pg.Search#" name=t>
	  </td>
	</tr>
	</table>

	</center>

  </td>
  <td>

	#intranet-search-pg.Search_for_sepcific_object_types#
	<table>
	@objects_html;noquote@
	</table>
  </td>
</tr>
</table>

	
</form>
