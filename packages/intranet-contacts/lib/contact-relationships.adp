  <if @rels:rowcount@ gt 0>
    <multiple name="rels">
      <h3 class="contact-title">@rels.relationship@</h3>
      <dl class="attribute-values">
	<group column="relationship">
	  <dd class="attribute-value">
	    <strong>
	      <a href="@rels.contact_url@">@rels.contact@</a>
	    </strong><font size=-2>[@rels.creation_date@]</font>
	  </dd>
	  <group column="rel_id">
	    <if @rels.attribute@ not nil>
	      <dt class="attribute-name">@rels.attribute@:</dt>
	      <dd class="attribute-value">@rels.value;noquote@</dd>
	    </if>
	  </group>
	</group>
	<if @rels.relation_url@ ne "">
	<dd class="attribute-value"><a href="@rels.relation_url@" class="add-new-rel">#intranet-contacts.lt_Add_new_relsrelations#</a></dd></if>
      </dl>
  </multiple>
  </if>
