<master src="master">
<property name="page_title">@page_title;noquote@</property>
<property name="context_bar">@context_bar;noquote@</property>
<property name="locale">@locale;noquote@</property>

<p>
<table>
  <tr><th>Tree Name</th><td>@tree_name@</td></tr>
  <tr><th>Description</th><td> @tree_description@</td></tr>
</table>
</p>

<multiple name=modules>
  <b>@modules.package@:</b><ul>
  <group column=package>
    </ul><if @modules.object_name@ ne @modules.instance_name@>@modules.instance_name@</if><ul>
    <group column=package_id>
      <li><a href="/o/@modules.object_id@">@modules.object_name@</a>
          <a href="@unmap_url@" class="button">unmap</a></li>
    </group>
  </group>
  </ul>
</multiple>
<if @instances_without_permission@ gt 0>
  There are @instances_without_permission@ more uses of this tree, but you
  don't have the permission to see them.
</if>
<if @modules:rowcount@ eq 0 and @instances_without_permission@ eq 0>
  This tree is not used.
</if>
