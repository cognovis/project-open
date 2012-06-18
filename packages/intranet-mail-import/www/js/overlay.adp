<style>
	.yui-overlay { position:absolute;background:#ffffff; border:6px solid #666666 ;padding:5px;margin:10px;}
	.yui-overlay .bd { margin-top: 30px; }
	#overlay2 { visibility: hidden }
</style>

	<div id="content"></div>
	<div id="overlay2">
		<button id="hide2" style="float:right;">Close</button>
	</div>

<script type="text/javascript">
    YAHOO.namespace("mail_import.container");
    function interceptLink(e) {
        YAHOO.util.Event.preventDefault(e);

        var content = document.getElementById("content");
	var cr_item_id = this.id;        

        content.innerHTML = "";

        if (!YAHOO.mail_import.container.wait) {

            // Initialize the temporary Panel to display while waiting for external content to load

            YAHOO.mail_import.container.wait = 
                    new YAHOO.widget.Panel("wait",  
                                                    { width: "240px", 
                                                      fixedcenter: true, 
                                                      close: false, 
                                                      draggable: false, 
                                                      zindex:4,
                                                      modal: true,
                                                      visible: false
                                                    } 
                                                );
    
            YAHOO.mail_import.container.wait.setHeader("Loading, please wait...");
            YAHOO.mail_import.container.wait.setBody("<img src=\"http://us.i1.yimg.com/us.yimg.com/i/us/per/gr/gp/rel_interstitial_loading.gif\"/>");
            YAHOO.mail_import.container.wait.render(document.body);
        }

        // Define the callback object for Connection Manager that will set the body of our content area when the content has loaded

        var callback = {
            success : function(o) {
                YAHOO.mail_import.container.overlay2 = new YAHOO.widget.Overlay("overlay2", { fixedcenter:true, visible:false,width:"500px",height:"500px" } );
		YAHOO.mail_import.container.overlay2.setBody(o.responseText + "<br><iframe src='/intranet-mail-import/mail-view?content_item_id=" + cr_item_id  + "&view_mode=body' width='750px' height='600px' frameborder='0' scrolling='yes'></iframe>");
		// YAHOO.mail_import.container.overlay2.setFooter("<iframe src='/intranet-mail-import/mail-view?content_item_id=" + cr_item_id  + "&view_mode=body' width='px' height='800px'frameborder='0'></iframe>");
		YAHOO.mail_import.container.overlay2.render(document.body);
		YAHOO.util.Event.addListener("show2", "click", YAHOO.mail_import.container.overlay2.show, YAHOO.mail_import.container.overlay2, true);
		YAHOO.util.Event.addListener("hide2", "click", YAHOO.mail_import.container.overlay2.hide, YAHOO.mail_import.container.overlay2, true);
                YAHOO.mail_import.container.overlay2.show();
                YAHOO.mail_import.container.wait.hide();
            },
            failure : function(o) {
                content.innerHTML = o.responseText;
                content.style.visibility = "visible";
                content.innerHTML = "CONNECTION FAILED!";
                YAHOO.mail_import.container.wait.hide();
            }
        }
   
        // Show the Panel
        YAHOO.mail_import.container.wait.show();
        
        // Load the data
        var conn = YAHOO.util.Connect.asyncRequest("GET", "/intranet-mail-import/mail-view?content_item_id=" + this.id + "&view_mode=noBody", callback);

	// Hide overlay
	document.getElementById('overlay2').style.visibility = 'hidden'; 

    }

  
</script>

