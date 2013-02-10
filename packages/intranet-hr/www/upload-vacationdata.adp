<!-- packages/intranet-hr/www/upload-vacationdata.adp -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="/packages/intranet-core/www/master">
<property name="title">@page_title@</property>


<h1>Import Employee Data "Vacation Balance" and "Vacation Days per Year"</h1>

<p>Import requires CSV file with the structure created by "Vacation Export":</p> 
<br>

<ul>
<li>Employee Id</li>
<li>Employee Name</li>
<li>Vacation Days per Year (current)</li>
<li>Vacation Balance (current)</li>
<li>Vacation Days taken last Year</li>
<li>Vacation Balance(new)</li>
<li>Vacation Days per Year(new)</li>
</ul>
</br>
<p>Only attributes "Vacation Balance (new)" and "Vacation Days per Year (new)" are updated. 
All other columns are ignored.</p>
</br>
</br>
@page_body;noquote@
