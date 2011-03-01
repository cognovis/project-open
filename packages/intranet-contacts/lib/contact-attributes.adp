    <if @attributes:rowcount@ gt 0>
   <table class="attribute-values">
    <multiple name="attributes">
     <tr>
       	<td colspan="2" align="left"><h3 class="contact-title">@attributes.section@</h3></td>
     </tr>
	  <group column="section">
 	     <tr>
	 	<td align="right" valign="top" class="attribute">@attributes.attribute@:</td>
		<td align="left" valign="top" class="value">@attributes.value;noquote@</td>
	    </tr>
	  </group>

      </multiple>
      </table>
    </if>
  
