# /tcl/cassandracle-defs.tcl

ad_library {
    Routines used by Cassandracle (the Oracle monitoring part of /admin/monitoring)

    @cvs-id $Id: cassandracle-procs.tcl,v 1.1.1.2 2006/08/24 14:41:36 alessandrol Exp $
}

proc cassandracle_header { page_title } {
    return [ad_header $page_title]
}

proc cassandracle_footer {} {
    return [ad_footer]
}

proc cassandracle_format_data_type_column {column_data} {

    # the column_data argument must be a Tcl list 
    # whose elements are the data_type, data_scale, data_precision,
    # and data_length values as obtained from Oracle's data
    # dictionary view DBA_TAB_COLUMNS

    # create a list of column names 
    set column_names [list data_type data_scale data_precision data_length]

    # create a variable for each member of the list and
    # set its value to the corresponding data dictionary value
    set i 0
    foreach column_name $column_names {
	set $column_name [lindex $column_data $i]
	incr i
    }

    # the default is to return only the data_type value
    # (ignoring scale, precision, etc.). But for some
    # datatypes, we do additional procesing of length, 
    # scale, or precision
    #
    # I do various nested ifs, each of which
    # returns a formatted data string

    # NUMBER ---------------------------------------------

    if {$data_type=="NUMBER"} {

	# if there is no data_scale, 
	# then must be a float
	if {$data_scale==""} {
	    return "NUMBER"
	}

	# all integers have data_scale of zero
	if {$data_scale=="0"} {

	    # normal integers have no value for
	    # precision, so we should not confuse 
	    # the user with precision
	    if {$data_precision==""} {
		return "INTEGER"
	    }

	    # but we should return the precision
	    # for non-standard integers which have it
	    if {!$data_precision==""} {
		return "NUMBER($data_precision)"
	    }

	}

	# not an integer, and not a float, 
	# so return precision and scale

	return "NUMBER(${data_precision},${data_scale})"

    }

    # character types  -----------------------------------------
    #
    # Native Oracle includes the just first four, but the reamining are
    # suported via mapping. We just export what is in dba_tab_columns
    # along with the length, after a regular expression check for CHAR
    #
    # CHAR
    # NCHAR
    # NVARCHAR2
    # VARCHAR2
    # --------
    # VARCHAR 
    # CHARACTER
    # CHARACTER VARYING
    # CHAR VARYING
    # NATIONAL CHARACTER
    # NATIONAL CHAR
    # NATIONAL CHARACTER VARYING
    # NATIONAL CHAR VARYING
    # NCHAR VARYING
    # LONG VARCHAR

    if {[regexp "CHAR" $data_type]} {
	# trying to keep Tcl from thinking I have an array
	set ret_val "$data_type"
	append ret_val "(" 
	append ret_val $data_length
	append ret_val ")"
	return $ret_val
    }

    # -------------------------------------------------
    # not a NUMBER, nor *CHAR*, so we just return datatype
    # this misses the following ANSI and DB2 types that
    # could probably use precision and scale output
    #
    # NUMERIC(p,s) 
    # DECIMAL(p,s)
    # FLOAT(b)
    

    return $data_type
}

proc book_link_to_amazon {isbn {click_ref "photonetA"}} {
    return "http://www.amazon.com/exec/obidos/ISBN=${isbn}/${click_ref}/ "
}

proc annotated_archive_reference {page_number} {
    return "<blockquote><font size=-1>Source: 
<a href=\"[book_link_to_amazon 0078825369]\"><cite>Oracle SQL &amp; PL/SQL Annotated Archives</cite></a> 
by Kevin Loney and Rachel Carmichael, page $page_number.
</font>
</blockquote>
"
}

