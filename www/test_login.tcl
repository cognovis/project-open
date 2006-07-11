# /packages/xml-rpc/www/test_login.tcl
ad_page_contract {
    @author Frank Bergann (frank.bergmann@project-open.com)
    @creation-date 2006-07-02
    @cvs-id $Id$
} {
}

set email "sysadmin@tigerpond.com"
set pass "sys.admin"

set error ""
set result ""
set token ""
set info ""
catch {
    set login_result [xmlrpc::remote_call http://172.26.0.3:30038/RPC2 sqlapi.login -string $email -string $pass]
    set status [lindex $login_result 0]
    set token [lindex $login_result 1]
} result
append error "$result\n"

catch {
    set query_results [xmlrpc::remote_call http://172.26.0.3:30038/RPC2 sqlapi.select \
		  -string $email \
		  -string $token \
		  -string im_project \
		  -int 9718 \
    ]
} result

array set query_result $query_results

ad_return_complaint 1 $query_result(project_name)


append error "$result\n"




ad_return_complaint 1 "<pre>token=$token\ninfo=$info\nerror=$error</pre>"

