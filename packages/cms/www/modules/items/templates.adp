<a name="templates">

<table bgcolor=#6699CC cellspacing=0 cellpadding=4 border=0 width="95%">

<tr bgcolor="#FFFFFF">
  <td align=left><b>Registered Templates</b></td>
  <td align=right>&nbsp;</td>
</tr>

<tr><td colspan=2>
<table bgcolor=#6699CC cellspacing=0 cellpadding=2 border=0 width="100%">

  <tr><th align=left colspan=6>
    Templates Registered to @iteminfo.name@
  </th></tr>
  <tr bgcolor="#99CCFF">
  <if @registered_templates:rowcount@ eq 0>
    <td colspan=6>
      <em>No templates registered to this content item.</em>
    </td>
  </if>
  <else>
    <th width=25% align=left nowrap>Name</th>
    <td width="5%">&nbsp;&nbsp;&nbsp;</td>
    <th width=20% align=left nowrap>Context</th>
    <td width="5%">&nbsp;&nbsp;&nbsp;</td>
    <th width=10% align=left nowrap>&nbsp;</th>
    <th width=35% align=left nowrap>&nbsp;</th>
  </else>
  </tr>

  <multiple name=registered_templates>
    <if @registered_templates.rownum@ odd><tr bgcolor="#FFFFFF"></if>
    <else><tr bgcolor="#EEEEEE"></else>
      <td>@registered_templates.path@</td>
      <td>&nbsp;&nbsp;&nbsp;</td>
      <td>@registered_templates.use_context@</td>
      <td>&nbsp;&nbsp;&nbsp;</td>
      <td>&nbsp;&nbsp;&nbsp;</td>
      <td>
        <if @user_permissions.cm_write@ eq t 
	  and @registered_templates.can_read_template@ eq t>
          <a href="template-unregister?item_id=@item_id@&template_id=@registered_templates.template_id@&context=@registered_templates.use_context@">
            Unregister
          </a>
        </if><else>&nbsp;</else>
      </td>
    </tr>
  </multiple>

</table>
</td></tr>

<tr><td colspan=2>
<table bgcolor=#6699CC cellspacing=0 cellpadding=2 border=0 width="100%">

  <tr><th align=left colspan=6>
      Templates Registered to @iteminfo.pretty_name@
  </th></tr>
  <tr bgcolor="#99CCFF">
  <if @type_templates:rowcount@ eq 0>
    <td colspan=6>
      <em>No templates registered to this content type.</em>
    </td>
  </if>
  <else>

    <th width="25%">Name</th>
    <td width="5%">&nbsp;&nbsp;&nbsp;</td>
    <th width="20%">Context</th>
    <td width="5%">&nbsp;&nbsp;&nbsp;</td>
    <th width="10%">&nbsp</th>
    <th width="35%">&nbsp</th>
  </else>
  </tr>
  
  <multiple name=type_templates>
    <if @type_templates.rownum@ odd><tr bgcolor="#ffffff"></if>
    <else><tr bgcolor="#EEEEEE"></else>
      <td>@type_templates.path@</td>
      <td>&nbsp;&nbsp;&nbsp;</td>
      <td>@type_templates.use_context@</td>
      <td>&nbsp;&nbsp;&nbsp;</td>
      <td>
        <if @type_templates.is_default@ eq "t">Default</if>
        <else>
          <if @type_templates.can_read_template@ eq t
	     and @can_set_default_template@ eq t>
            <a href="../types/set-default-template?template_id=@type_templates.template_id@&context=@type_templates.use_context@&content_type=@content_type@&return_url=@return_url@">
	      Make default
            </a>
          </if><else>&nbsp;</else>
        </else>
      </td>

      <td>
        <if @type_templates.already_registered_p@ eq 1>Registered</if>
        <else>
          <if @user_permissions.cm_write@ eq t 
	    and @type_templates.can_read_template@ eq t 
            and @registered_templates:rowcount@ eq 0>
            <a href="template-register?item_id=@item_id@&template_id=@type_templates.template_id@&context=@type_templates.use_context@">
              Register template to this item
            </a>
          </if><else>&nbsp;</else>
        </else>
      </td>

    </tr>
  </multiple>

</table>


</td></tr>
</table>
