ad_library {

	Callback implementations for label printing
	
    @creation-date 2008-03-19
    @author  (malte.sussdorff@cognovis.de)
    @cvs-id 
}


ad_proc -public -callback contact::label -impl avery5160 {
    {-request:required}
    {-for ""}
} {
} {
    switch $request {
	ad_form_option {
	    return [list "Avery 5160 (1in x 2.5in, 30 per sheet)" avery5160]
	}
	template {
	    switch $for {
		"avery5160" {
		    return {<template pageSize="(8.5in, 11in)"
			leftMargin="0in"
			rightMargin="0in"
			topMargin="0in"
			bottomMargin="0in"
			title="Avery 5160"
			author="Avery 5160"
			allowSplitting="0"
			showBoundary="0"
			>
			<!-- showBoundary means that we will be able to see the            -->
			<!-- limits of frames                                              -->
			<pageTemplate id="main">
			<pageGraphics>
			</pageGraphics>
			<frame id="label01" x1="0.25in" y1="9.30in" width="2.50in" height="1.00in"/>
			<frame id="label02" x1="0.25in" y1="8.30in" width="2.50in" height="1.00in"/>
			<frame id="label03" x1="0.25in" y1="7.30in" width="2.50in" height="1.00in"/>
			<frame id="label04" x1="0.25in" y1="6.30in" width="2.50in" height="1.00in"/>
			<frame id="label05" x1="0.25in" y1="5.30in" width="2.50in" height="1.00in"/>
			<frame id="label06" x1="0.25in" y1="4.30in" width="2.50in" height="1.00in"/>
			<frame id="label07" x1="0.25in" y1="3.30in" width="2.50in" height="1.00in"/>
			<frame id="label08" x1="0.25in" y1="2.30in" width="2.50in" height="1.00in"/>
			<frame id="label09" x1="0.25in" y1="1.30in" width="2.50in" height="1.00in"/>
			<frame id="label10" x1="0.25in" y1="0.30in" width="2.50in" height="1.00in"/>
			<frame id="label11" x1="3.00in" y1="9.30in" width="2.50in" height="1.00in"/>
			<frame id="label12" x1="3.00in" y1="8.30in" width="2.50in" height="1.00in"/>
			<frame id="label13" x1="3.00in" y1="7.30in" width="2.50in" height="1.00in"/>
			<frame id="label14" x1="3.00in" y1="6.30in" width="2.50in" height="1.00in"/>
			<frame id="label15" x1="3.00in" y1="5.30in" width="2.50in" height="1.00in"/>
			<frame id="label16" x1="3.00in" y1="4.30in" width="2.50in" height="1.00in"/>
			<frame id="label17" x1="3.00in" y1="3.30in" width="2.50in" height="1.00in"/>
			<frame id="label18" x1="3.00in" y1="2.30in" width="2.50in" height="1.00in"/>
			<frame id="label19" x1="3.00in" y1="1.30in" width="2.50in" height="1.00in"/>
			<frame id="label20" x1="3.00in" y1="0.30in" width="2.50in" height="1.00in"/>
			<frame id="label21" x1="5.75in" y1="9.30in" width="2.50in" height="1.00in"/>
			<frame id="label22" x1="5.75in" y1="8.30in" width="2.50in" height="1.00in"/>
			<frame id="label23" x1="5.75in" y1="7.30in" width="2.50in" height="1.00in"/>
			<frame id="label24" x1="5.75in" y1="6.30in" width="2.50in" height="1.00in"/>
			<frame id="label25" x1="5.75in" y1="5.30in" width="2.50in" height="1.00in"/>
			<frame id="label26" x1="5.75in" y1="4.30in" width="2.50in" height="1.00in"/>
			<frame id="label27" x1="5.75in" y1="3.30in" width="2.50in" height="1.00in"/>
			<frame id="label28" x1="5.75in" y1="2.30in" width="2.50in" height="1.00in"/>
			<frame id="label29" x1="5.75in" y1="1.30in" width="2.50in" height="1.00in"/>
			<frame id="label30" x1="5.75in" y1="0.30in" width="2.50in" height="1.00in"/>
			</pageTemplate>
			</template>
			<stylesheet>
			<paraStyle name="name"
			fontName="Helvetica"
			fontSize="9"
			alignment="CENTER"
			/>
			<paraStyle name="address"
			fontName="Helvetica"
			fontSize="9"
			alignment="CENTER"
			/>
			</stylesheet>
		    }
		}
		"brother" {
		    return {<template pageSize="(3.95in, 1.8in)"
			leftMargin="0in"
			rightMargin="0in"
			topMargin="0in"
			bottomMargin="0in"
			title="Brother"
			author="Brother"
			allowSplitting="0"
			showBoundary="0"
			>
			<!-- showBoundary means that we will be able to see the            -->
			<!-- limits of frames                                              -->
			<pageTemplate id="main">
			<pageGraphics>
			</pageGraphics>
			<frame id="label01" x1="0.25in" y1="0.1in" width="3.6in" height="1.7in"/>
			</pageTemplate>
			</template>
			<stylesheet>
			<paraStyle name="name"
			fontName="Helvetica"
			fontSize="11"
                        leading="15"
			alignment="LEFT"
			/>
			<paraStyle name="header"
			fontName="Helvetica-BoldOblique"
			fontSize="6.5"
                        leading="20"
			alignment="LEFT"
			/>
			<paraStyle name="address"
			fontName="Helvetica"
			fontSize="11"
                        leading="15"
			alignment="LEFT"
			/>
			</stylesheet>
		    }
		}

	    }
	}
    }

}

ad_proc -public -callback contact::label -impl brother {
    {-request:required}
    {-for ""}
} {
} {
    switch $request {
	ad_form_option {
	    return [list "Brother Etiketten (29mm x 90mm)" brother]
	}
	template {
	    switch $for {
		"brother" {
		    return {<template pageSize="(0.29cm, 0.9cm)"
			leftMargin="0in"
			rightMargin="0in"
			topMargin="0in"
			bottomMargin="0in"
			title="Brother"
			author="Brother"
			allowSplitting="0"
			showBoundary="0"
			>
			<!-- showBoundary means that we will be able to see the            -->
			<!-- limits of frames                                              -->
			<pageTemplate id="main">
			<pageGraphics>
			</pageGraphics>
			<frame id="label01" x1="0.05cm" y1="0.05cm" width="0.8cm" height="0.2cm"/>
			</pageTemplate>
			</template>
			<stylesheet>
			<paraStyle name="name"
			fontName="Helvetica"
			fontSize="9"
			alignment="LEFT"
			/>
			<paraStyle name="address"
			fontName="Helvetica"
			fontSize="9"
			alignment="LEFT"
			/>
			</stylesheet>
		    }
		}

	    }
	}
    }

}

ad_proc -public -callback contact::envelope -impl envelope10 {
    {-request:required}
    {-for ""}
} {
} {
    switch $request {
	ad_form_option {
	    return [list "Envelope \#10 (9.5in x 4.125in)" envelope10]
	}
	template {
	    if { $for == "envelope10" } {
		return {
<template pageSize="(9.5in, 4.125in)"
          leftMargin="0in"
          rightMargin="0in"
          topMargin="0in"
          bottomMargin="0in"
          title="Envelope \#10"
          author="$author"
          allowSplitting="0"
          showBoundary="0"
          >
          <!-- showBoundary means that we will be able to see the            -->
          <!-- limits of frames                                              -->
    <pageTemplate id="main">
        <pageGraphics>
        </pageGraphics>
        <frame id="label01" x1="5.5in" y1=".5in" width="3in" height="1.5in"/>
    </pageTemplate>
</template>
<stylesheet>
    <paraStyle name="name"
      fontName="Helvetica"
      fontSize="12"
      leading="15"
      alignment="LEFT"
    />
    <paraStyle name="address"
      fontName="Helvetica"
      fontSize="12"
      leading="15"
      alignment="LEFT"
    />
</stylesheet>
}
	    }
	}
    }

}