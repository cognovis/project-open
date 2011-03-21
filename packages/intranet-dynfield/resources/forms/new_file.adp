<div class="standard-form">

<!-- section delimiter -->
<div class="standard-form-row"><div class="standard-form-section">#intranet-dynfield.Section#</div></div>

<!-- hidden fields -->
<noparse><formwidget id="date_last_changed"></noparse>


<!-- manadatory fields -->
 <div class="standard-form-row">
    <div class="standard-form-label" style="width: 20%">
	<div class="standard-form-label-text-mandatory">
	    <label for="title"><noparse><formlabel id="title"></noparse></label>
        </div>
	<div class="standard-form-label-mandatory">*</div>
    </div>
    
    <div class="standard-form-text">
	  <noparse><formwidget id="title"></noparse>
<!-- error message -->
          <formerror id="title">
             <div class="standard-form-error" style="color:#ff0000">\@formerror.title;noquote@</div>
          </formerror>
<!-- help text -->
          <div class="standard-form-help-text">

              <noparse><formhelptext id="title">
	<img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0">
		</formhelptext></noparse>
          </div>
        </div>
     </div>
 </div>

<!-- normal fields -->
 <div class="standard-form-row">
    <div class="standard-form-label" style="width: 20%">
	<div class="standard-form-label-text">
            <label for="ppsn_or_bsn"><noparse><formlabel id="ppsn_or_bsn"></noparse></label>
        </div>
    </div>
     
    <div class="standard-form-text">
          <noparse><formwidget id="ppsn_or_bsn"></noparse>
<!-- error message -->
	  <formerror id="ppsn_or_bsn">
            <div class="standard-form-error" style="color:#ff0000">\@formerror.ppsn_or_bsn;noquote@</div>
          </formerror>
<!-- help text -->
          <div class="standard-form-help-text">
	     <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0">
	     <noparse><formhelp id="ppsn_or_bsn"></noparse>
          </div>
       </div>
    </div>
 </div>


