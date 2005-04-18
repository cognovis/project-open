<master src="../../master">
<property name="title">Search Results</property>

<h3>Search Results</h3>

<if @results:rowcount@ gt 0>
  <ul>
    <multiple name=results>
    <li>
      <a href="@return_url@?@result_id_ref@=@results.user_id@@extra_url@">
       @results.name@</a> 
       <if @results.screen_name@ not nil>( a.k.a. &quot;@results.screen_name@&quot; )</if>
       <if @results.email@ not nil>, <a href="mailto:@results.email@">@results.email@</a></if>
    </li>
    </multiple>
  </ul>
</if>
<else>
  <i>No users found</i>
</else>


       