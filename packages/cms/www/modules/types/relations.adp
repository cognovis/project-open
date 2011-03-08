<!-- Display relation types -->

<table cellspacing=0 cellpadding=4 border=0 width="95%">
<tr>
  <th align=left>Registered Item Relation Types</th>
</tr>
<tr bgcolor="#6699CC"><td>
<table cellspacing=0 cellpadding=4 border=0 width="100%">

<if @rel_types:rowcount@ eq 0>
  <tr bgcolor="#99CCFF">
    <td>
      <em>There are no item relation types registered to this 
	  content type.</em>
    </td>
  </tr>
</if>
<else>

  <tr bgcolor="#99CCFF">
    <th align=left>Related Object Type</th>
    <th align=left>Relation Tag</th>
    <th align=left>Min Relations</th>
    <th align=left>Max Relations</th>
    <th align=left>&nbsp;</th>
  </tr>

  <multiple name="rel_types">
  <if @rel_types.rownum@ odd><tr bgcolor="#FFFFFF"></if>
  <else><tr bgcolor="#EEEEEE"></else>
    <td>@rel_types.pretty_name@</td>
    <td>@rel_types.relation_tag@</td>
    <td align=center>
      <if @rel_types.min_n@ nil>0</if>
      <else>@rel_types.min_n@</else>
    </td>
    <td align=center>
      <if @rel_types.max_n@ nil>-</if>
      <else>@rel_types.max_n@</else>
    </td>
    <td align=right>
      <if @user_permissions.cm_write@ eq t>
        <a href="relation-unregister?rel_type=item_rel&content_type=@type@&target_type=@rel_types.target_type@&relation_tag=@rel_types.relation_tag@">Unregister</a>
      </if>
      <else>&nbsp;</else>
    </td>
  </tr>
  </multiple>


</else>
</table>
</td></tr>

<if @user_permissions.cm_write@ eq t>
  <tr>
    <td>
      <a href="relation-register?rel_type=item_rel&content_type=@type@">
        Register a new item relation type</a>
    </td>
  </tr>
</if>
</table>
<p>



<!-- display child relation types -->

<table cellspacing=0 cellpadding=4 border=0 width="95%">
<tr>
  <th align=left>Registered Child Relation Types</th>
</tr>
<tr bgcolor="#6699CC"><td>
<table cellspacing=0 cellpadding=4 border=0 width="100%">

<if @child_types:rowcount@ eq 0>
  <tr bgcolor="#99CCFF">
    <td>
      <em>There are no child relation types registered to this 
          content type.</em>
    </td>
  </tr>
</if>
<else>

  <tr bgcolor="#99CCFF">
    <th align=left>Child Type</th>
    <th align=left>Relation Tag</th>
    <th align=left>Min Relations</th>
    <th align=left>Max Relations</th>
    <th align=left>&nbsp;</th>
  </tr>

  <multiple name="child_types">
  <if @child_types.rownum@ odd><tr bgcolor="#FFFFFF"></if>
  <else><tr bgcolor="#EEEEEE"></else>
    <td>@child_types.pretty_name@</td>
    <td>@child_types.relation_tag@</td>
    <td align=center>
      <if @child_types.min_n@ nil>0</if>
      <else>@child_types.min_n@</else>
    </td>
    <td align=center>
      <if @child_types.max_n@ nil>-</if>
      <else>@child_types.max_n@</else>
    </td>
    <td align=right>
      <if @user_permissions.cm_write@ eq t>
        <a href="relation-unregister?rel_type=child_rel&content_type=@type@&target_type=@child_types.child_type@&relation_tag=@child_types.relation_tag@">Unregister</a>
      </if>
      <else>&nbsp;</else>
    </td>
  </tr>
  </multiple>


</else>
</table>
</td></tr>
<if @user_permissions.cm_write@ eq t>
  <tr>
    <td>
      <a href="relation-register?rel_type=child_rel&content_type=@type@">
        Register a new child relation type</a>
    </td>
  </tr>
</if>
</table>
<p>
