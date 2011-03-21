<master>
<property name="&doc">doc</property>
<property name="context">@context;noquote@</property>

<p>#attachments.lt_You_are_attaching_a_d#</p>

<p>#attachments.lt_To_attach_a_file_alre#</p>

<if @write_permission_p@ eq 1>
#attachments.attach_new#
      &nbsp;
      <a href="@file_add_url@">#attachments.File#</a>
      &nbsp;&nbsp;|&nbsp;&nbsp;
      <a href="@simple_add_url@">#attachments.URL#</a>
</if>


<div class="attach-fs-bar">
      <ul class="compact">
        <if @fs_context:rowcount@ not nil>
          #file-storage.Folder#:&nbsp;
          <multiple name="fs_context">
            <li>
              <if @fs_context.url@ not nil>
                <a href="@fs_context.url@">@fs_context.label@</a> @separator@
              </if>
              <else>
                @fs_context.label@
              </else>
            </li>
          </multiple>
        </if>
      </ul>
</div>

<if @contents:rowcount@ gt 0>
  <table width="95%" class="list-table">
    <thead>
      <tr class="list-header">
        <th>#attachments.Type#</th>
        <th>#attachments.Name#</th>
        <th>#attachments.Action#</th>
        <th>#attachments.Size#</th>
        <th>#attachments.Last_Modified#</th>
      </tr>
    </thead>
<tbody>
<multiple name="contents">
<if @contents.rownum@ odd>
    <tr class="odd">
</if>
<else>
    <tr class="even">
</else>
    <if @contents.type@ eq "folder">
      <td>
        <img src="graphics/folder.gif" alt="#file-storage.Folder#">
        #file-storage.folder_type_pretty_name#
      </td>
      <td>
        <a href="@contents.name_url@">@contents.name@</a>
      </td>
      <td>&nbsp;</td>
      <td>
        #attachments.lt_contentscontent_size_#<if @contents.content_size@ ne 1>s</if>
      </td>
      <td>@contents.last_modified@</td>
    </if>
    <else>
      <td>
        <img src="graphics/file.gif" alt="@contents.type@">
        @contents.type@
      </td>
      <if @contents.type@ eq "url">
        <td>@contents.name@</td>
        <td>
          <a href="@contents.action_url@" class="button">#attachments.Choose#</a>
        </td>
        <td>&nbsp;</td>
      </if>
      <else>
        <td>
          <if @contents.title@ eq nil>@contents.name@</if>
          <else>@contents.title@</else>
        </td>
        <td>
          <a href="@contents.action_url@" class="button">#attachments.Choose#</a>
        </td>
        <td>#attachments.lt_contentscontent_size__1#<if @contents.content_size@ ne 1>s</if></td>
      </else>
      <td>@contents.last_modified@</td>
    </else>
    </tr>
  </multiple>
  </tbody>
  </table>
</if>
<else>
  <p><em>#attachments.lt_Folder_folder_name_is#</em></p>
</else>

