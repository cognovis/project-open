<div class="standard-form">

<!-- section delimiter -->
<div class="standard-form-row"><div class="standard-form-section">#intranet-dynfield.Section#</div></div>

<!-- hidden fields -->
<div><noparse><formwidget id="_hidden_field_"></noparse></div>


<!-- manadatory fields -->
 <div class="required-form-row">
    <label for="_mandatory_field_" class="form-label">
	<noparse><formlabel id="_mandatory_field_"></noparse><span>*</span>
    </label>

    <noparse><formwidget id="_mandatory_field_"></noparse>
    <!-- error message -->
       <formerror id="_mandatory_field_">
	  <div class="standard-form-row">
             <span class="form-label"> </span>
             <div class="standard-form-error" style="color:#ff0000">\@formerror._mandatory_field_;noquote@</div>
          </div>
       </formerror>
    <!-- help text -->
       <div class="standard-form-row">
	  <span class="form-label"> </span>
          <div class="standard-form-help-text">	     
	    <noparse><formhelptext id="_mandatory_field_">
	      <img src=\"/shared/images/info.gif\" width=\"12\" height=\"9\" alt=\"\[i\]\" title=\"Help text\" border=\"0\"/>
            </formhelptext></noparse>
          </div>
       </div>
 </div>

<!-- normal fields -->
 <div class="standard-form-row">
    <label for="_normal_field_" class="form-label"><noparse><formlabel id="_normal_field_"></noparse></label>     
    <noparse><formwidget id="_normal_field_"></noparse>
<!-- error message -->
       <formerror id="_normal_field_">
	  <div class="standard-form-row">
             <span class="form-label"> </span>
	     <div class="standard-form-error" style="color:#ff0000">\@formerror._normal_field_;noquote@</div>
	  </div>
       </formerror>
<!-- help text -->
    <div class="standard-form-row">
       <span class="form-label"> </span>
         <div class="standard-form-help-text">
            <noparse><formhelptext id="_normal_field_">
              <img src=\"/shared/images/info.gif\" width=\"12\" height=\"9\" alt=\"\[i\]\" title=\"Help text\" border=\"0\"/>
            </formhelptext></noparse>
         </div>
    </div>
 </div>


<!-- radio and checkbox -->
 <div class="standard-form-row">
     <label class="form-label"> <noparse><formlabel id="_radio_field_"></noparse> </label>
  <noparse>
   <formgroup id="_radio_field_">
      <div class="standard-form-text">
	    \@formgroup.widget;noquote@
            \@formgroup.label;noquote@
      </div>
   </formgroup>
  </noparse>
</div> 

