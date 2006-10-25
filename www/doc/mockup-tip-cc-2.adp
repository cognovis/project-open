<master>
  <property name="title">@page_title;noquote@</property>
  <property name="context">@context;noquote@</property>
<h3 style="margin-top: 24px; border-top: 1px solid black">Properties</h3>
<formtemplate id="task"></formtemplate>
<h3 style="margin-top: 24px; border-top: 1px solid black">Enabled If</h3>
<listtemplate name="depends"></listtemplate>
AND <select>
<option>Depose Salesperson</option>
<option>Depose Customer</option>
<option>Respond to Deposition</option>
<option>Respond to Deposition</option>
<option>Intervene</option>
<option>Intervene</option>
<option>Respond to Intervention</option>
<option>Respond to Intervention</option>
<option>Deliver Report to Secretary</option>
<option>Deliver Report to Secretary</option>
<option>Get info from Salesperson's Lawyer</option>
<option>Get info from Customer's Lawyer</option>
<option>Respond to Customer's Lawyer</option>
<option>Respond to Salesperson's Lawyer</option>
<option>Submit Final Report</option>
<option>Submit Final Report</option>
</select> 
<select>
<option>Completed</option>
<option>Not Completed</option>
</select>
<input type="submit" value="Add Condition">
<h3 style="margin-top: 24px; border-top: 1px solid black">Automation</h3>
<formtemplate id="agent"></formtemplate>
<formtemplate id="task2"></formtemplate>
<p>Still missing:
<ul>
<li>put placeholders into description
<li>max number of completions
<li>