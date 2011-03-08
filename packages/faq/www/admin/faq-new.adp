<master>
<property name="context">@context;noquote@</property>
<property name="title">@title;noquote@</property>
<property name="focus">faq.faq_name</property>

<h1>Create an FAQ:</h1>
  
<form action="@action@" name="faq" class="margin-form">
  <div><input type="hidden" name="faq_id" value="@faq_id@"></div>
  <fieldset>
    <div class="form-item-wrapper">
      <div class="form-label">
        <label for="faq_name">
          #faq.Name#
        </label>
      </div>
      <div class="form-widget">                  
        <input id="faq_name" name="faq_name" value="@faq_name@">
      </div>    
    </div>

    <div class="form-item-wrapper">
      <div class="form-label">
        <label for="separate_p">
          #faq.QA_on_Separate_Pages#
        </label>
      </div>
      <div class="form-widget">                  
        <select name="separate_p" id="separate_p">
          <option value="f">#faq.No#</option>
          <option value="t">#faq.Yes#</option>
        </select>
      </div>    
    </div>

    <div class="form-button">
      <input type="submit" value="@submit_label@">
    </div>
  </fieldset>
</form>
