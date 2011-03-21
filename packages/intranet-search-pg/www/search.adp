<master>
<property name="title">@page_title@</property>
<property name="context">@context;noquote@</property>

<br>
<form method=GET action=search>

<center>
<table>
<tr>
  <td>
<!--    <%= [im_logo] %>  -->
  </td>
  <td>
    <input type=text name=q size=31 maxlength=256 value="@query@">
    <input type=submit value="#intranet-search-pg.Search#" name=t>
  </td>
  <td>

	<table>
	<tr><td colspan=2>Search for specific object types:</td></tr>
	<tr valign=top>
	  <td align=center>
		<table cellspacing=0 cellpadding=0>
		@objects_html;noquote@
		</table>
	  </td>
	  <td>
		<table cellspacing=0 cellpadding=0>
		<tr>
		  <td><input type=checkbox name='include_deleted_p' value="1"></td>
		  <td>#intranet-search-pg.Include_Deleted#</td>
		</tr>
		</table>
	  </td>
	</tr>
	</table>

  </td>
</tr>
</table>
</center>

</form>


<table width=100% border=0 cellpadding=0 cellspacing=0>
<tr>
  <td bgcolor=#fff height=1 >
  </td>
</tr>
</table>

<table width=100% border=0 cellpadding=0 cellspacing=0 bgcolor=#e5ecf9>
<tr>
  <td bgcolor=#e5ecf9 nowrap>
  <font size=+1>&nbsp;<b>
    Intranet Results
  </b></font>&nbsp;
</td>
<td bgcolor=#e5ecf9 align=right nowrap>
  <font size=-1>
    #intranet-search-pg.Results#
    <b>@offset;noquote@</b> - <b><%= [expr $offset + $results_per_page] %></b> 

<if @count@ eq @limit@>
    #intranet-search-pg.of_more_then#
</if>
<else>
    #intranet-search-pg.of_about# 
</else>

    <b>@num_results;noquote@</b>.
    #intranet-search-pg.Search_took#
    <b>@elapsed@</b> #intranet-search-pg.seconds#
  </font>
</td>
</tr>
</table>

<br>

<if @count@ eq 0>
  <font size="+1">#intranet-search-pg.lt_No_pages_were_found_c#: &quot;<b>@query@</b>&quot;</font>.
  <br><br>#intranet-search-pg.Suggestions#
  <ul>
    <li>#intranet-search-pg.lt_Make_sure_all_words_a#
    <li>#intranet-search-pg.lt_Try_different_keyword#
    <li>#intranet-search-pg.lt_Try_more_general_keyw#
    <if @nquery@ gt 2>
      <li>#intranet-search-pg.Try_fewer_keywords#
    </if>
  </ul>
</if>

<else>

  <table>
  @result_html;noquote@
  </table>

  <br clear=all>

</else>


<center>
<h3>Result Page: @result_page_html;noquote@</h3>
<center>


<table width=100% border=0 cellpadding=0 cellspacing=0>
<tr>
  <td bgcolor=#ffffff>
  </td>
</tr>
</table>

<table width=100% border=0 cellpadding=0 cellspacing=0 bgcolor=#e5ecf9>
<tr>
  <td bgcolor=#e5ecf9 colspan=99>&nbsp;</td>
</tr>
<tr>
  <td bgcolor=#e5ecf9 align=center>
  <form method=GET action=search>
  <table>
    <tr>
      <td>
        <input type=text name=q size=31 maxlength=256 value="@query@">
        <input type=submit value="#intranet-search-pg.Search#" name=t>
      </td>
    </tr>
  </table>
  </form>
  </td>
</tr>
<tr>
  <td bgcolor=#e5ecf9 colspan=99>&nbsp;</td>
</tr>
</table>

<table width=100% border=0 cellpadding=0 cellspacing=0>
<tr>
  <td bgcolor=#ffffff>
  </td>
</tr>
</table>


<if @from_result_page@ lt @to_result_page@>
  <center>

    <small>#intranet-search-pg.Result_page#</small>

    <if @from_result_page@ lt @current_result_page@>
      <small><a href=@url_previous@><font color=0000cc><b>#intranet-search-pg.Previous#</b></font></a></small>
    </if>

    
    <if @current_result_page@ lt @to_result_page@>
	<small><a href=@url_next@><font color=0000cc><b>#intranet-search-pg.Next#</b></font></a></small>
    </if>
  </center>
</if>
