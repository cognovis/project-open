<master src="/packages/intranet-contacts/lib/contacts-master">
<property name="party_id">@party_id@</property>

<include src="/packages/intranet-contacts/lib/changes" party_id="@party_id@" revision_id=@revision_id@>

<if @revision_id@ not nil>
    <table>
  	<tr>
	    <td>
	        <h3>#intranet-contacts.Preview#</h3> 
	    </td>
	</tr>
    	<tr>
	    <td width="50%">
    	        <include src="/packages/intranet-contacts/lib/contact-attributes" party_id="@party_id@" revision_id="@revision_id@">
    	    </td>
        </tr>
    </table>
</if>