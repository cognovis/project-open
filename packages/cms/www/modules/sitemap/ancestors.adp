

<table border=0 cellpadding=0 cellspacing=0 width="95%">
<tr>
  <!-- display the ancestor tree -->
  <td align=left nowrap>
    <b>
    <font size=-1>
    <multiple name=context>
      <if @context.is_folder@ eq "t">
	<a href="../sitemap/index?id=@context.parent_id@&mount_point=@mount_point@">
  	  <img src="../../resources/folder.gif" border=0>
          @context.title@
        </a>
      </if>
      <else>
      	<a href="../items/index?item_id=@context.parent_id@&mount_point=@mount_point@">
	  <img src="../../resources/generic-item16.gif" border=0>
	  @context.title@
        </a>
      </else>
      <if @context.rownum@ lt @context:rowcount@> : </if>
    </multiple>
    </font>
    </b>
  </td>

  <!-- display the path, possibly linking to it -->
  <td align=right valign=center nowrap>
    
    <include src="../../bookmark" 
             mount_point="@mount_point;noquote@" 
             id="@item_id;noquote@">
    &nbsp;
    <b><tt>
    <if @preview_p@ eq t>
      <a target="preview" href="@preview_path@">@display_path@</a>
    </if>
    <else>@display_path@</else>
    </tt></b>
  </td>

</tr>
</table>

<script language=JavaScript>
  set_marks('@mount_point@', '../../resources/checked');
</script>
