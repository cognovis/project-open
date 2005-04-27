<table width="100%" cellspacing="0" cellpadding="0" border="0">
  <tr>
    <td bgcolor="#cccccc" colspan="2">
      <table width="100%" cellspacing="1" cellpadding="2" border="0">
        <tr>
          <td colspan="5" bgcolor="#ccccff">
            <table width="100%" cellspacing="0" cellpadding="0" border="0">
              <tr>
                <th width="20%">&nbsp;</th>
                <th>Journal</th>
                <td width="20%" align="right">
                  <if @comment_link@ eq 1>[ <a href="comment-add?case_id=@case_id@">comment</a> ]</if>
                  <if @comment_link@ ne 1>&nbsp;</if>
                </td>
              </tr>
            </table>
          </td>
        </tr>
        <if @journal:rowcount@ eq 0>
          <tr bgcolor="#ffffe4">
            <td>
              <em>No actions yet.</em>
            </td>
          </tr>
        </if>
        <if @journal:rowcount@ ne 0>
          <tr bgcolor="#ffffe4">
            <th align="left">Action</th>
            <th align="left">Date</th>
            <th align="left">User</th>
            <th align="left">Output</th>
            <th align="left">Comment</th>
          </tr>
        </if>
        <multiple name="journal">
          <tr bgcolor="#eeeeee">
            <td>@journal.action_pretty@</td>
            <td>@journal.creation_date_pretty@</td>
            <td><a href="/shared/community-member?user_id=@journal.creation_user@">@journal.creation_user_name@</a></td>
            <td>
              <if @journal.attribute_pretty_name@ nil>&nbsp;</if>
              <if @journal.attribute_pretty_name@ not nil>
                <group column="journal_id">
                  @journal.attribute_pretty_name@: @journal.attribute_value@<br>
                </group>
              </if>
            </td>
            <td>
              <if @journal.msg@ nil>&nbsp;</if>
              <if @journal.msg@ not nil>@journal.msg@</if>
            </td>
          </tr>
        </multiple>
      </table>
    </td>
  </tr>
</table>
