function <%=$form_id%>_update_target_select() {

    console.log("Start 'update_target_select'");

    var xmlHttp1;
    // get value from first request 
    try {
	// Firefox, Opera 8.0+, Safari
	xmlHttp1=new XMLHttpRequest();
    }
    catch (e) {
	// Internet Explorer
	try {
	    xmlHttp1=new ActiveXObject("Msxml2.XMLHTTP");
	}
	catch (e) {
	    try {
		xmlHttp1=new ActiveXObject("Microsoft.XMLHTTP");
	    }
	    catch (e) {
		alert("Your browser does not support AJAX!");
		return false;
	    }
	}
    }

    xmlHttp1.onreadystatechange = function() {
	console.log("now in 'onreadystatechange'");	

	if(xmlHttp1.readyState==4) {
	    // Removing acual options
	    for (i = oForm.<%=$target_form_element_name%>.options.length-1; i >= 0; i--) { 
		oForm.<%=$target_form_element_name%>.remove(i); 
	    }

	    // setting new options (XML) 
	    var xml_options = xmlHttp1.responseText;
	    $(xml_options).find('select_item').each(function(){
		var title = $(this).find('title').text();
		var values = $(this).find('value').text();
		 $("#<%=$form_id%> select[name=<%=$target_form_element_name%>]").append("<option value='"+ $.trim(values) +"'>"+ title +"</option>");
	    });

	    // todo: setting new option (json)

	    // remove this: 
	    // var opts1 = res1.split("|");
	    // for (i=0; i < opts1.length; i = i+2) {
	    //	var newOpt = new Option(opts1[i+1], opts1[i], false, true);
	    //	newOpt.value = $.trim(newOpt.value);	
	    //	oForm.cost_object_category_id.options[oForm.<%=$target_form_element_name%>.options.length] = newOpt;
	    // }
	}
    }

    // Get the current value of the source element
    // var oForm = document.getElementById('<%=$source_form_element_name%>');
    // var oForm = document.forms['<%=$form_id%>'].elements['<%=$source_form_element_name'%>];
    var oForm = document.forms['<%=$form_id%>'];
    // Set JS var named "<%=source_form_element_name%>_value"
    var <%=$source_form_element_name%>_value = oForm.elements["<%=$source_form_element_name%>"].options[oForm.elements["<%=$source_form_element_name%>"].selectedIndex].value;

    xmlHttp1.open(<%=$request_str%>);
    xmlHttp1.send(null);
}


jQuery().ready(function(){
	// Check if source_select has a value
	var oForm = document.forms['<%=$form_id%>'];
	var <%=$source_form_element_name%>_value = oForm.elements["<%=$source_form_element_name%>"].options[oForm.elements["<%=$source_form_element_name%>"].selectedIndex].value;
	console.log("jQuery.ready - Found <%=$source_form_element_name%>_value:%", <%=$source_form_element_name%>_value);
	if ( <%=$source_form_element_name%>_value != null && <%=$source_form_element_name%>_value != "" ) {
		 console.log("Setting target select");
		// found value, updating target 
		<%=$form_id%>_update_target_select();
	}

	// Create "Listener" for source element 
	console.log("Setting Listener for doc id <%=$source_form_element_name%>");
	// $('#<%=$source_form_element_name%>').change(<%=$form_id%>_update_target_select);
	$("#<%=$form_id%> select[name=<%=$source_form_element_name%>]").change(<%=$form_id%>_update_target_select);
});

