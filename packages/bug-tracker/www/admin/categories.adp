<master src="../../lib/master">
<property name="title">@page_title;noquote@</property>
<property name="context_bar">@context_bar;noquote@</property>


<blockquote>

<table cellspacing="1" cellpadding="3" class="bt_listing">
  <tr class="bt_listing_header">
    <th class="bt_listing">Category Type</th>
    <th class="bt_listing">Category</th>
    <th class="bt_listing"># @pretty_names.Bugs@</th>
    <th class="bt_listing">Default</th>
    <th class="bt_listing">Edit</th>
    <th class="bt_listing">Delete</th>
  </tr>
  <if @categories:rowcount@ gt 0>
    <multiple name="categories">
      <tr class="bt_listing_spacer">
        <td class="bt_listing" colspan="6">
          &nbsp;
        </td>
      </tr>
      <tr class="bt_listing_subheader">
        <td class="bt_listing">
          @categories.parent_heading@
        </td>
        <td class="bt_listing">
          &nbsp;
        </td>
        <td class="bt_listing">&nbsp;</td>
        <td class="bt_listing">&nbsp;</td>
        <td class="bt_listing" align="center">
          <if @categories.type_edit_url@ not nil>
            <a href="@categories.type_edit_url@"><img src="../graphics/Edit16.gif" width="16" height="16" border="0" alt="Edit"></a>
          </if>
        </td>
        <td class="bt_listing" align="center">
          <if @categories.type_delete_url@ not nil>
            <a href="@categories.type_delete_url@"><img src="../graphics/Delete16.gif" width="16" height="16" border="0" alt="Delete"></a>
          </if>
        </td>
      </tr>

      <if @categories.child_id@ not nil>
        <group column="parent_id">
          <if @categories.rownum@ odd>
            <tr class="bt_listing_odd">
          </if>
          <else>
            <tr class="bt_listing_even">
          </else>
            <td>&nbsp;</td>
            <td class="bt_listing">
              <if @categories.default_p@ true><b></if>
              @categories.child_heading@
              <if @categories.default_p@ true></b></if>
            </td>
            <td class="bt_listing">
              <if @categories.num_bugs@ gt 0>
                <a href="@categories.bugs_url@">@categories.num_bugs@ <if @categories.num_bugs@ eq 1>@pretty_names.bug@</if><else>@pretty_names.bugs@</else></a>
              </if>
              <else>
                &nbsp;
              </else>
            </td>
            <td class="bt_listing" align="center">
              <if @categories.default_p@ true><b>*</b></if>
              <if @categories.set_default_url@ not nil><a href="@categories.set_default_url@">set</a></if>
            </td>
            <td class="bt_listing" align="center">
              <if @categories.edit_url@ not nil>
                <a href="@categories.edit_url@"><img src="../graphics/Edit16.gif" width="16" height="16" border="0" alt="Edit"></a>
              </if>
            </td>
            <td class="bt_listing" align="center">
              <if @categories.delete_url@ not nil>
                <a href="@categories.delete_url@"><img src="../graphics/Delete16.gif" width="16" height="16" border="0" alt="Delete"></a>
              </if>
            </td>
          </tr>
        </group>
      </if>

      <else>
        <tr class="bt_listing_even">
          <td class="bt_listing">&nbsp;</td>
          <td class="bt_listing" colspan="5">
            <i>No categories of this type.</i>
          </td>
        </tr>
      </else>

      <tr class="bt_listing_even">
        <td class="bt_listing">&nbsp;</td>
        <td class="bt_listing">
          <b>&raquo;</b>
          <a href="@categories.new_url@">Add category</a>
        </td>
          <td class="bt_listing">&nbsp;</td>
        <td class="bt_listing">&nbsp;</td>
        <td class="bt_listing">&nbsp;</td>
        <td class="bt_listing">&nbsp;</td>
      </tr>
    </multiple>
  </if>
  <else>
  </else>


  <tr class="bt_listing_spacer">
    <td class="bt_listing" colspan="6">
      &nbsp;
    </td>
  </tr>
  <tr class="bt_listing_even">
    <td class="bt_listing" colspan="6">
      <b>&raquo;</b>
      <a href="@type_new_url@">Create new category type</a>
    </td>
  </tr>

</table>

<p class="bt">
  <b>&raquo;</b>
  <a href="@default_setup_url@">Use default setup</a>
</p>

</blockquote>
