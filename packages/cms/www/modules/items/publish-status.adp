
<table cellspacing=0 cellpadding=2 border=0 width=95% bgcolor="#BBBBBB">
<tr bgcolor="#FFFFFF">
  <th align=left>Publishing Status</th>
  <td align=right>
    <if @user_permissions.cm_item_workflow@ eq t>
      [<a href="status-edit?item_id=@item_id@">Edit</a>]
    </if>
    <else>&nbsp;</else>
  </td>
</tr>

<tr bgcolor="#BBBBBB">
<td colspan=2>
  <table cellspacing=0 cellpadding=4 border=2 width="100%">
  <tr bgcolor="#DDDDDD">
    <th align=left>@message@</th>
  </tr>


  <tr bgcolor="#EEEEEE">
    <td>
      <b>This item is 
      <if @is_publishable@ eq f><font color="red">NOT</font></if> 
      in a publishable state<if @is_publishable@ eq f>:</if><else>.</else></b>

  <if @is_publishable@ eq f>
  <ul>


  <!-- Revision status -->

  <if @live_revision@ nil>
    <li>This item has no live revision.
  </if>


  <!-- workflow status -->

  <if @unfinished_workflow_exists@ eq t>
    <li>This item's publishing workflow is still active.
  </if>

  
  <!-- child rel status -->


  <if @unpublishable_child_types@ gt 0>

    <li>This item requires the following number of child items:
      <ul>
      <multiple name="child_types">
      <if @child_types.is_fulfilled@ eq f>
        <li>@child_types.difference@ @child_types.direction@ 
	@child_types.relation_tag@ 
	<if @child_types.difference@ eq 1>@child_types.child_type_pretty@</if>
        <else>@child_types.child_type_plural@</else>
	<br>
      </if>
      </multiple>
      </ul>
  </if>



  <!-- item rel status -->

  <if @unpublishable_rel_types@ gt 0>

    <li>This item requires the following number of related items:
      <ul>
      <multiple name="rel_types">
      <if @rel_types.is_fulfilled@ eq f>
        <li>@rel_types.difference@ @rel_types.direction@ 
	@rel_types.relation_tag@ 
	<if @rel_types.difference@ eq 1>@rel_types.target_type_pretty@</if>
        <else>@rel_types.target_type_plural@</else>
	<br>
      </if>
      </multiple>
      </ul>
  </if>







  </ul>
  </if>
  </td></tr>
</table>

</td></tr></table>
