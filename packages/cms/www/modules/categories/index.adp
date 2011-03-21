<master src="../../master">
<property name="title">Subject Categories</property>

<if @info.is_leaf@ ne t or @original_id@ nil>
  <script language=javascript>
    top.treeFrame.setCurrentFolder('@mount_point@', '@original_id@', '@parent_id@');
  </script> 
</if>

<table width=95% cellspacing=0 cellpadding=4>
<tr><td class=large><b>
  <if @original_id@ ne 0 and @original_id@ not nil> 
    Subject @what@ - @info.heading@
  </if>
  <else>Subject Keywords</else></b>
</td>
<td align=right class=small>
  <include src="../../bookmark" 
           mount_point="@mount_point;noquote@" 
           id="@id;noquote@">&nbsp;<tt><b>@info.path;noquote@</b></tt></td>
</tr>
</table>
<br>

<h3>@info.heading@</h3>

<p>@info.description@</p>

<if @items:rowcount@ gt 0>

<table bgcolor=#6699CC cellspacing=0 cellpadding=4 border=0 width="95%">
<tr bgcolor="#FFFFFF">
  <td align=left><b>Subject Keywords</b></td>
  <td align=right>&nbsp;</td>
</tr>

<tr>
<td colspan=2>

<table bgcolor="#99CCFF" cellspacing=0 cellpadding=2 border=0 width="100%">

<tr bgcolor="#99CCFF">
  <th>&nbsp;</th>
  <th>&nbsp;</th>
  <td>&nbsp;&nbsp;&nbsp;</td>
  <th>Heading</th>
  <td>&nbsp;&nbsp;&nbsp;</td>
  <th>Assigned Items</th>
</tr>

<multiple name=items>

  <if @items.rownum@ odd><tr bgcolor=#ffffff></if>
  <else><tr bgcolor="#dddddd"></else>

    <td nowrap height=12>
      <include src="../../bookmark" 
               mount_point="@mount_point;noquote@" 
               id="@items.keyword_id;noquote@">
    </td>
    <td>
      <a href="index?id=@items.keyword_id@&mount_point=@mount_point@&parent_id=@id@">
      <if @items.is_leaf@ eq t>
        <img src="../../resources/Page24.gif" border=0>
      </if>
      <else>
        <img src="../../resources/Open24.gif" border=0>      
      </else>
      </a>
    </td>
    <td>&nbsp;&nbsp;&nbsp;</td>
    <td><a href="index?id=@items.keyword_id@&mount_point=@mount_point@&parent_id=@id@">
        @items.heading@</a></td>
    <td>&nbsp;&nbsp;&nbsp;</td>
    <td align=center>@items.item_count@</td> 
  </tr>

</multiple>  

</table>
</td></tr></table>

</if>
<else>
 <i>No subcategories</i>
</else>

<br>
<hr>

<if @original_id@ not nil>

  <a href="edit?id=@id@&@passthrough@"><img 
    src="../../resources/Edit24.gif" width=24 height=24 border=0></a>
  <a href="edit?id=@id@&@passthrough@">Edit</a> this @what@ <br>

  <if @info.is_leaf@ eq t>
    <a href="delete?id=@id@&@passthrough@"><img 
	src="../../resources/Delete24.gif" width=24 height=24 border=0></a>
    <a href="delete?id=@id@&@passthrough@">Delete</a> this @what@ <br>
  </if>

</if>

<a href="create?parent_id=@original_id@&mount_point=@mount_point@">
  <img src="../../resources/Open24.gif" width=24 height=24 border=0>
  Create a new keyword
</a> 
within this category.<br>

<a href="move?target_id=@original_id@&mount_point=@mount_point@">
  <img src="../../resources/Copy24.gif" width=24 height=24 border=0>
  Move
</a>
marked keywords into this category.<br>

<p>
<p>
<p>
&nbsp;

<script language=JavaScript>
  set_marks('@mount_point@', '@img_checked@');
</script>





