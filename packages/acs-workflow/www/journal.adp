



        <div class="component">
                <table width="100%">
                <tr>
                <td>
                <div class="component_header_rounded" >
                        <div class="component_header">
                                <div class="component_title">Journal</div>
                                      <div class="component_icons"></div>
                                </div>
                        </div>
                </td>
                </tr>
                <tr>
                <td>
                        <div class="component_body">

<table width="100%">
  <tr>
    <td colspan="2">
      <table width="100%">
        <tr>
          <td colspan="5">
            <table width="100%">
              <tr>
                <th width="20%">&nbsp;</th>
                <th></th>
                <td width="20%" align="right">
                  <if @comment_link@ eq 1>[ <a href="@workflow_url;noquote@comment-add?case_id=@case_id@&return_url=@return_url;noquote@">comment</a> ]</if>
                  <if @comment_link@ ne 1>&nbsp;</if>
                </td>
              </tr>
            </table>
          </td>
        </tr>
        <if @journal:rowcount@ eq 0>
          <tr>
            <td>
              <em>No actions yet.</em>
            </td>
          </tr>
        </if>
	</table>
      <table width="100%">

        <if @journal:rowcount@ ne 0>
          <tr>
<if @show_action_p@>
            <th align="left">Action</th>
</if>
            <th align="left">Date</th>
            <th align="left">User</th>
            <th align="left">Comment</th>
            <th align="left">Output</th>
          </tr>
        </if>
        <multiple name="journal">
          <tr>
<if @show_action_p@>
            <td>@journal.action_pretty@</td>
</if>
            <td>@journal.creation_date_pretty@</td>

            <td><a href="/shared/community-member?user_id=@journal.creation_user@">@journal.creation_user_name@</a></td>

            <td>
              <if @journal.msg@ nil>&nbsp;</if>
              <if @journal.msg@ not nil>@journal.msg@</if>
            </td>

            <td>
              <if @journal.attribute_pretty_name@ nil>&nbsp;</if>
              <if @journal.attribute_pretty_name@ not nil>
                <group column="journal_id">
                  @journal.attribute_pretty_name@: @journal.attribute_value@<br>
                </group>
              </if>
            </td>
          </tr>
        </multiple>
      </table>
    </td>
  </tr>
</table>



                        </div>
                </td></tr>
                </table>
        </div>