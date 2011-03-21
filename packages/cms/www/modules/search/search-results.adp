<master src="../../master">
<property name="title">Search Results</property>

<script language=javascript>
  top.treeFrame.setCurrentFolder('@mount_point@', '@id@', '@parent_id@');
</script> 

<if @sql_query@ not nil>

<if @results:rowcount@ gt 0>

<table bgcolor=#6699CC cellspacing=0 cellpadding=4 border=0 width="100%">
<tr bgcolor="#FFFFFF">
  <td align=left><b>Search Results</b></td>
</tr>


<tr>
<td>

  <table bgcolor=#99CCFF cellspacing=0 cellpadding=5 border=0 width="100%">

  <tr bgcolor="#99CCFF">
    <th>#</th>
    <th>&nbsp;</th>
    <th>Score</th>
    <th>Title</th>
    <th>Path</th>
    <th>Revision</th>
    <th>Content Type</th>
    <th>Mime Type</th>
  </tr>

  <multiple name=results>

    <if @results.rownum@ odd><tr bgcolor=#ffffff></if>
    <else><tr bgcolor="#dddddd"></else>

      <td>@results.offset@</td>
      <td><a href="javascript:mark('@package_url@', '@mount_point@', @results.item_id@, '@clipboardfloats_p@')">
	<img src="../../resources/@results.bookmark@24.gif" width=24 height=24 
	     border=0 name="mark@results.item_id@"></a></td>
      <td>@results.search_score@</td>
      <td>@results.title@</td>
      <td><a href="../items/index?item_id=@results.item_id@&mount_point=sitemap">
	  @results.item_path@</a></td>
      <td><a href="../items/revision?revision_id=@results.revision_id@">
	  @results.pretty_date@</a></td>
      <td>@results.pretty_type@</td>
      <td>@results.pretty_mime_type@</td>

    </tr>

  </multiple>

  </table>
</td></tr>
<tr bgcolor=#FFFFFF><td>

  <table bgcolor="#FFFFFF" border=0 cellpadding=5 cellspacing=0 width="100%">

    <tr>
    <td align=left width="33%">
      <if @prev_row@ gt 0>
	<a href="search-results?@passthrough@&start_row=@prev_row@">
	&lt;&lt; Previous @rows_per_page@ results</a>
      </if><else>&nbsp;</else>
    </td> 
    <td align=center width="33%" >
      <if @pages:rowcount@ gt 0>
	Pages:       
	<multiple name=pages>
	  <if @pages.label@ ne @current_page@>
	    <a href="@pages.url@">@pages.label@</a>
	  </if>
	  <else>@pages.label@</else>
	</multiple>
      </if>
      <else>&nbsp;</else>   
    </td>
    <td align=right width="33%">
      <if @next_row@ le @total_results@>
	<a href="search-results?@passthrough@&start_row=@next_row@">
	Next @rows_per_page@ results &gt;&gt;</a>
      </if><else>&nbsp;</else>
    </td>      
    </tr>
  </table>
</td></tr>

</table>

</if>
<else>
  <i>No matches found</i>
</else>
  
</if>
<else>
  Your query has expired. Please return to the search page and repeat your search.
</else>  
