<master src="/packages/intranet-contacts/lib/contacts-master" />
<property name="focus">party_ae.first_names</property>

<formtemplate id="contact"></formtemplate>

<br>

<if "" ne @found_user_id@>
<h2>Exact User Match</h2>
<p>
We have found an exact match for user @found_user_name@ (@found_user_email@).
</p>
<br>
</if>


<if @search_results_p@>
    <p>
    <listtemplate name="contact_list"></listtemplate>
    </p>
</if>
