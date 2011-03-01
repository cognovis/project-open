  <div style="float: left;">
    <div>
      <multiple name="categories">
        <h2>@categories.tree_name@</h2>
        <ul>
          <group column="tree_id">
            <if @categories.category_id@ eq @cat@><li><b>@categories.pad;noquote@@categories.category_name@ <if @categories.count@ gt 0>(@categories.count@)</if></b></li></if>
            <else>
              <if @categories.count@ gt 0 or @categories.child_sum@ gt 0>
                <li>@categories.pad;noquote@<if @categories.count@ gt 0><a href="?cat=@categories.category_id@" rel="nofollow">@categories.category_name@</a> (@categories.count@)</if><else>@categories.category_name@</else>
                </li>
              </if>
            </else>
          </group>
        </ul>
      </multiple>
    </div>
    <div>
      <if @cat@ not nil><include src="/packages/categories/lib/contributions" orderby="@orderby@" category="@cat@" root_node_id="@node_id@"></if>
    </div>
  </div>
