<if @template_exists@ eq f>
  This template has no revisions yet
</if>
<else>
  <if @body_exists@ eq f>
    This template has no body yet
  </if>
  <else>

  <if @assets:rowcount@ eq 0>
    This template contains no assets
  </if>
  <else>

<table cellpadding=0 cellspacing=0 border=1 width=100% bgcolor=#ffffff>
<tr><td>

<table cellpadding=2 cellspacing=0 border=0 width=100% bgcolor=#ffffff>
<tr bgcolor=#99CCFF>

      <td align=right>#</td><td>&nbsp;&nbsp;</td>
      <td align=left>Source Filename</td><td>&nbsp;&nbsp;</td>
      <td align=left>Width</td><td>&nbsp;&nbsp;</td>
      <td align=left>Height</td><td>&nbsp;&nbsp;</td>
      <td align=left>Alt Text</td><td>&nbsp;&nbsp;</td>
      <td align=left>Exists ?</td><td>&nbsp;&nbsp;</td>
      <td align=left>Title</td><td>&nbsp;&nbsp;</td>
      <td align=left>Publish Status</td><td>&nbsp;&nbsp;</td>

</tr>  

<multiple name="assets">
  <tr>
    <td nowrap align=right>@assets.rownum@</td><td>&nbsp;</td>
    <td nowrap align=left>@assets.src@</td><td>&nbsp;</td>

    <td nowrap align=right>
      <if @assets.auto_width@ eq t>
        <i>@assets.width@</i>
      </if>
      <else>@assets.width@</else>
    </td>
    <td>&nbsp;</td>
    <td nowrap align=right>
      <if @assets.auto_height@ eq t>
        <i>@assets.height@</i>
      </if>
      <else>@assets.height@</else>
    </td>
    <td>&nbsp;</td>

    <td align=left>@assets.alt@</td><td>&nbsp;</td>
    <td align=left nowrap>
      <if @assets.exists_some@ eq 0>
        <font color=red><b>No</b></font>
      </if>
      <else>
        <if @assets.missing_some@ eq 0>
          <font color=green><b>Yes</b></font>
        </if>
        <else>
          @assets.missing_files@
        </else>
      </else>
    </td>
    <td>&nbsp;</td>
    <if @assets.item_id@ not nil and @assets.item_id@ ne "-"> 
      <td nowrap align=left>
        <a href="../items/index?item_id=@assets.item_id@">@assets.title@</a>
      </td>
      <td>&nbsp;</td>      
      <td nowrap align=left>@assets.status@</td><td>&nbsp;</td>      
    </if>
    <else>
      <td colspan=4 align=left>
        <font color=gray size=-2><i>Not managed by CMS</i></font>
      </td>
    </else>
  </tr>
</multiple>

</table>

</td></tr>
</table>
   
    </else>
  </else>
</else>