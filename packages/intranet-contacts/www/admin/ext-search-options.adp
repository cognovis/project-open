<master>
<property name="title">@page_title;noquote@</property>
<property name="context">@context;noquote@</property>

<if @search_id@ nil>
    <ul>
	<li><a href="search-list">Set Default Attributes or Extended options.</a>
    </ul>
    <br>
    <h3>Create New Extended Search Option:</h3>
    <formtemplate id="add_option"></formtemplate>
</if>

<br>
<if @edit_p@ eq "f"> 
    <if @search_id@ nil>
       <h3>#intranet-contacts.Stored_extended#:</h3>
    <listtemplate name="ext_options"></listtemplate>
    </if>
    <else>
       <if @ext_options:rowcount@ not eq 0>
           <h3>#intranet-contacts.Stored_extended_default#:</h3>
           <listtemplate name="ext_options"></listtemplate>
           <br> 
       </if>
       <if @def_ext_options:rowcount@ not eq 0>
           <h3>#intranet-contacts.Remove_default_options#:</h3>
           <listtemplate name="def_ext_options"></listtemplate>
       </if>
       <a href="../?search_id=@search_id@">#intranet-contacts.Go_to_search_results#</a>
       <a href="search-list">#intranet-contacts.Search_List#</a>
    </else>
</if>

