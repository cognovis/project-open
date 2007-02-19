<if @trees:rowcount@ gt 0>
  <multiple name=trees>
    @trees.tree_name@:
    <select name="@name@"<if @trees.assign_single_p@ eq f> multiple</if>>
    <if @trees.assign_single_p@ eq t and @trees.require_category_p@ eq f><option value=""></if>
    <group column=tree_id>
      <option value="@trees.category_id@"<if @trees.selected_p@ eq 1> selected</if>>@trees.indent;noquote@@trees.category_name@
    </group>
    </select>
  </multiple>
</if>
