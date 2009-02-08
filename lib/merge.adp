<if @display_contacts@ false>
<master src="contact-master" />
<property name="party_id">@party_id@</property>
</if>
<else>
<master src="contacts-master" />
</else>

<property name="context">@context@</property>
<property name="title">@title@</property>

<if @display_contacts@ true>


<table width="100%">
  <tr>
    <td colspan="2" align="center">
	<form name="merge_contacts" method="get">
	<input type="hidden" name="merge_party_id" value="@merge_party_id@" />
        <h2>Which contact overwrites (i.e. takes priority if info conflicts)?</h2>
    </td>
  </tr>
  <tr>
    <td align="center" style="background-color: #CCF;">

        <if @party_type@ eq user and @merge_party_type@ ne user>
          <input type="radio" name="bogusprimary" value="party_id" checked="checked" disabled />
          <input type="hidden" name="primary" value="party_id" />
        </if> 
        <elseif @party_type@ ne user and @merge_party_type@ eq user>
          <input type="radio" name="bogusprimary" value="party_id" disabled />
        </elseif>
        <else>
          <input type="radio" name="primary" value="party_id" />
        </else>
    </td>
    <td align="center" style="background-color: #FCC;">
        <if @merge_party_type@ eq user and @party_type@ ne user>
          <input type="radio" name="bogusprimary" value="party_id" checked="checked" disabled />
          <input type="hidden" name="primary" value="merge_party_id" />
        </if> 
        <elseif @merge_party_type@ ne user and @party_type@ eq user>
          <input type="radio" name="bogusprimary" value="party_id" disabled />
        </elseif>
        <else>
          <input type="radio" name="primary" value="merge_party_id" />
        </else>
    </td>
  </tr>
  <tr>
    <td colspan="2" align="center" style="padding: 2em;">
      <input type="submit" name="formbutton:ok" value="  Merge contacts and permanently delete the one that is not selected " />
      </form>
    </td>
  </tr>
  <tr>
    <td valign="top" width="50%" style="padding: 1em; background-color: #CCF;"> 
      <if @party_type@ eq user>
        <h3 style="color: #F00;">This is a user (Last Login: @party_last_login@)</h2>
        <h3 style="color: #F00;">Be careful! If this contact is not selected to overwrite the user account will be deleted, which could be very confusing to that user if they expect to be able to login with this email address.</h3>
      </if>
      <else>
      <if @merge_party_type@ eq user>
        <h3 style="color: #F00;">This is a person</h3>
        <h3 style="color: #F00;">When merging a person and a user the user must overwrite the person.</h3>
      </if>
      </else>
      <h2>@party_link;noquote@</h2>
      <include src="/packages/intranet-contacts/lib/contact-attributes" party_id="@party_id@" />
      <include src="/packages/intranet-contacts/lib/contact-relationships" party_id="@party_id@" />
      <include src="/packages/intranet-contacts/lib/searches" party_id="@party_id@" />
      <include src="/packages/intranet-contacts/lib/history" party_id="@party_id@" truncate_len="380" limit="5" hide_form_p="t" />
    </td>
    <td valign="top" width="50%" style="padding: 1em; background-color: #FCC;"> 
      <if @merge_party_type@ eq user>
      <h3 style="color: #F00;">This is a user (Last Login: @merge_party_last_login@)</h2>
      <h3 style="color: #F00;">Be careful! If this contact is not selected to overwrite the user account will be deleted, which could be very confusing to that user if they expect to be able to login with this email address.</h3>
      </if>
      <else>
      <if @party_type@ eq user>
        <h3 style="color: #F00;">This is a person</h3>
        <h3 style="color: #F00;">When merging a person and a user the user must overwrite the person.</h3>
      </if>
      </else>
      <h2>@merge_party_link;noquote@</h2>
      <include src="/packages/intranet-contacts/lib/contact-attributes" party_id="@merge_party_id@" />
      <include src="/packages/intranet-contacts/lib/contact-relationships" party_id="@merge_party_id@" />
      <include src="/packages/intranet-contacts/lib/searches" party_id="@merge_party_id@" />
      <include src="/packages/intranet-contacts/lib/history" party_id="@merge_party_id@" truncate_len="380" limit="5" hide_form_p="t" />
    </td>
  </tr>
</table>

</if>
<else>
	<formtemplate id="merge_contacts"></formtemplate>
</else>
