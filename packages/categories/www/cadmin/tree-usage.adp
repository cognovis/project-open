<master src="master">
<property name="page_title">@page_title;noquote@</property>
<property name="context_bar">@context_bar;noquote@</property>
<property name="locale">@locale;noquote@</property>

<p>
<table>
  <tr><th>#categories.Tree_Name#</th><td>@tree_name@</td></tr>
  <tr><th>#categories.Description#</th><td> @tree_description@</td></tr>
</table>
</p>

<multiple name=modules>
  <b>@modules.package@:</b><ul>
  <group column=package>
    </ul><if @modules.object_name@ ne @modules.instance_name@>@modules.instance_name@</if><ul>
    <group column=package_id>
      <li><a href="/o/@modules.object_id@">@modules.object_name@</a>
          <a href="@unmap_url@" class="button">#categories.unmap#</a></li>
    </group>
  </group>
  </ul>
</multiple>
<if @instances_without_permission@ gt 0>
  #categories.lt_There_are_instances_w#
</if>
<if @modules:rowcount@ eq 0 and @instances_without_permission@ eq 0>
  #categories.lt_This_tree_is_not_used#
</if>

