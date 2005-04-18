<table bgcolor=#6699CC cellspacing=0 cellpadding=4 border=0 width="95%">
<tr bgcolor="#FFFFFF">
  <td align=left><b>Revisions</b></td>
  <td align=right>
    <if @user_permissions.cm_write@ eq t>
      Add revised content via 
      <include src="content-method-links" 
	item_id=@item_id;noquote@ 
	content_type=@content_type;noquote@>
    </if>
    <else>&nbsp;</else>
  </td>
</tr>


<tr>
<td colspan=2>

<table bgcolor=#99CCFF cellspacing=0 cellpadding=2 border=0 width="100%">
  <tr bgcolor="#99CCFF">
    <if @revisions:rowcount@ eq 0>
      <td colspan=3><em>No revisions.</em></td></if>
    <else>
      <th align=left nowrap>#</th>
      <td>&nbsp;&nbsp;&nbsp;</td>
      <th align=left nowrap>Title</th>
      <td>&nbsp;&nbsp;&nbsp;</td>
      <th align=left nowrap>Description</th>
      <td>&nbsp;&nbsp;&nbsp;</td>
      <th>&nbsp</th>
      <th>&nbsp</th>
    </else> 
  </tr>

  <multiple name=revisions>
    <if @revisions.rownum@ odd><tr bgcolor="#FFFFFF"></if>
    <else><tr bgcolor="#EEEEEE"></else>
      <td>
        <a href="revision?revision_id=@revisions.revision_id@">
          @revisions.revision_number@
        </a>
      </td>
      <td>&nbsp;&nbsp;&nbsp;</td>
      <td><if @revisions.title@ not nil>@revisions.title@</if><else>-</else></td>
      <td>&nbsp;&nbsp;&nbsp;</td>
      <td>
        <if @revisions.description not nil>@revisions.description@</if>
        <else>-</else>
      </td>
      <td>&nbsp;&nbsp;&nbsp;</td>
      <td>
        <if @revisions.revision_id@ ne @live_revision@>
          <if @is_publishable@ eq t>
            <if @user_permissions.cm_write@ eq t>
              <a href="publish?revision_id=@revisions.revision_id@&item_id=@item_id@">Make this revision live</a>
            </if><else>&nbsp;</else>
          </if>
          <else>
            &nbsp;
          </else>
        </if>
        <else>
          Live Revision
        </else>
      </td>
      <td align=right>
        <if @revisions.revision_id@ eq @live_revision@ and 
          @user_permissions.cm_write@ eq t>
          <a href="unpublish?item_id=@item_id@">
            <if @publish_status@ eq live>Unpublish</if>
            <else>Unset live revision</else>
          </a>
        </if>
        <else>&nbsp;</else>

      </td>

    </tr>
    </multiple>

</table>

</td></tr>
</table>

@pagination_html;noquote@

