<master>
<property name="context">@context;noquote@</property>
<property name="title">@title@</property>


<p>
<a href="relationship-ae" class="button">#intranet-contacts.lt_Define_a_new_relation#</a>
<a href="roles" class="button">#intranet-contacts.View_all_roles#</a>
</p>
<p>#intranet-contacts.lt_Currently_the_system_# </p>



<dl>

  <if @rel_types:rowcount@ eq 0>
    <dt><em>#intranet-contacts.none#</em></dt>
      
  </if>
  <else>
  
  <multiple name="rel_types">
    <dt><strong>@rel_types.primary_type_pretty@ -> @rel_types.secondary_type_pretty@</strong></dt>
    <dl>
      <ul>
        <group column=sort_two>
        <li>@rel_types.primary_role_pretty@ -> @rel_types.secondary_role_pretty@ <a href="@rel_types.rel_form_url@" class="button">#intranet-contacts.Attributes#</a></li>
        </group>
      </ul>
    </dl>
  </multiple>

  </else>

</dl>



