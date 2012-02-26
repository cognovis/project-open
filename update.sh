#!/bin/bash


# Main directories
./git-update etc master >update.log 2>&1
./git-update tcl master >>update.log 2>&1
./git-update www master >>update.log 2>&1
./git-update bin master >>update.log 2>&1

# ACS Core 5.7 version
./git-update acs-content-repository oacs-5-7 >>update.log 2>&1
./git-update acs-reference oacs-5-7 >>update.log 2>&1
./git-update intermedia-driver oacs-5-7 >>update.log 2>&1
./git-update search oacs-5-7 >>update.log 2>&1
./git-update acs-admin oacs-5-7 >>update.log 2>&1
./git-update acs-core-docs oacs-5-7 >>update.log 2>&1
./git-update acs-service-contract oacs-5-7 >>update.log 2>&1
./git-update notifications oacs-5-7 >>update.log 2>&1
./git-update tsearch2-driver oacs-5-7 >>update.log 2>&1
./git-update acs-api-browser oacs-5-7 >>update.log 2>&1
./git-update acs-kernel oacs-5-7 >>update.log 2>&1
./git-update acs-subsite oacs-5-7 >>update.log 2>&1
./git-update openacs-default-theme oacs-5-7 >>update.log 2>&1
./git-update acs-authentication oacs-5-7 >>update.log 2>&1
./git-update acs-lang oacs-5-7 >>update.log 2>&1
./git-update acs-tcl oacs-5-7 >>update.log 2>&1
./git-update ref-countries oacs-5-7 >>update.log 2>&1
./git-update acs-automated-testing oacs-5-7 >>update.log 2>&1
./git-update acs-mail-lite oacs-5-7 >>update.log 2>&1
./git-update acs-templating oacs-5-7 >>update.log 2>&1
./git-update ref-language oacs-5-7 >>update.log 2>&1
./git-update acs-bootstrap-installer oacs-5-7 >>update.log 2>&1
./git-update acs-messaging oacs-5-7 >>update.log 2>&1
./git-update acs-translations oacs-5-7 >>update.log 2>&1
./git-update ref-timezones oacs-5-7 >>update.log 2>&1

# Additional packages from openacs >>update.log 2>&1
./git-update acs-datetime master >>update.log 2>&1
./git-update acs-developer-support master >>update.log 2>&1
./git-update acs-events master >>update.log 2>&1
./git-update attachments master >>update.log 2>&1
./git-update file-storage master >>update.log 2>&1
./git-update calendar master >>update.log 2>&1
./git-update categories master >>update.log 2>&1
./git-update faq master >>update.log 2>&1
./git-update general-comments master >>update.log 2>&1
./git-update mail-tracking master >>update.log 2>&1
./git-update xowiki master >>update.log 2>&1
./git-update oacs-dav master >>update.log 2>&1
./git-update rss-support master >>update.log 2>&1
./git-update views >>update.log 2>&1
./git-update xml-rpc master >>update.log 2>&1
./git-update xotcl-core master >>update.log 2>&1


# ]project-open[ repository
./git-update acs-workflow master >>update.log 2>&1
./git-update auth-ldap-adldapsearch master >>update.log 2>&1
./git-update wiki master >>update.log 2>&1
./git-update workflow master >>update.log 2>&1
./git-update acs-mail master >>update.log 2>&1
./git-update bug-tracker master >>update.log 2>&1
./git-update cms master >>update.log 2>&1
./git-update diagram master >>update.log 2>&1
./git-update intranet-big-brother master >>update.log 2>&1
./git-update intranet-bug-tracker master >>update.log 2>&1
./git-update intranet-calendar master >>update.log 2>&1
./git-update intranet-calendar-holidays master >>update.log 2>&1
./git-update intranet-confdb master >>update.log 2>&1
./git-update intranet-contacts master >>update.log 2>&1
./git-update intranet-core master >>update.log 2>&1
./git-update intranet-cost master >>update.log 2>&1
./git-update intranet-cvs-integration master >>update.log 2>&1
./git-update intranet-dw-light master >>update.log 2>&1
./git-update intranet-dynfield master >>update.log 2>&1
./git-update intranet-exchange-rate master >>update.log 2>&1
./git-update intranet-expenses master >>update.log 2>&1
./git-update intranet-expenses-workflow master >>update.log 2>&1
./git-update intranet-filestorage master >>update.log 2>&1
./git-update intranet-forum master >>update.log 2>&1
./git-update intranet-ganttproject master >>update.log 2>&1
./git-update intranet-helpdesk master >>update.log 2>&1
./git-update intranet-hr master >>update.log 2>&1
./git-update intranet-idea-management master >>update.log 2>&1
./git-update intranet-invoices master >>update.log 2>&1
./git-update intranet-invoices-templates master >>update.log 2>&1
./git-update intranet-mail-import master >>update.log 2>&1
./git-update intranet-material master >>update.log 2>&1
./git-update intranet-milestone master >>update.log 2>&1
./git-update intranet-nagios master >>update.log 2>&1
./git-update intranet-notes master >>update.log 2>&1
./git-update intranet-notes-tutorial master >>update.log 2>&1
./git-update intranet-payments master >>update.log 2>&1
./git-update intranet-release-mgmt master >>update.log 2>&1
./git-update intranet-reporting master >>update.log 2>&1
./git-update intranet-reporting-indicators master >>update.log 2>&1
./git-update intranet-reporting-tutorial master >>update.log 2>&1
./git-update intranet-resource-management master >>update.log 2>&1
./git-update intranet-rest master >>update.log 2>&1
./git-update intranet-riskmanagement master >>update.log 2>&1
./git-update intranet-rss-reader master >>update.log 2>&1
./git-update intranet-sencha master >>update.log 2>&1
./git-update intranet-sencha-ticket-tracker master >>update.log 2>&1
./git-update intranet-search-pg master >>update.log 2>&1
./git-update intranet-search-pg-files master >>update.log 2>&1
./git-update intranet-security-update-client master >>update.log 2>&1
./git-update intranet-soap-lite-server master >>update.log 2>&1
./git-update intranet-sysconfig master >>update.log 2>&1
./git-update intranet-simple-survey master >>update.log 2>&1
./git-update intranet-timesheet2 master >>update.log 2>&1
./git-update intranet-timesheet2-invoices master >>update.log 2>&1
./git-update intranet-timesheet2-task-popup master >>update.log 2>&1
./git-update intranet-timesheet2-tasks master >>update.log 2>&1
./git-update intranet-timesheet2-workflow master >>update.log 2>&1
./git-update intranet-tinytm master >>update.log 2>&1
./git-update intranet-trans-invoices master >>update.log 2>&1
./git-update intranet-trans-project-wizard master >>update.log 2>&1
./git-update intranet-translation master >>update.log 2>&1
./git-update intranet-ubl master >>update.log 2>&1
./git-update intranet-update-client master >>update.log 2>&1
./git-update intranet-wiki master >>update.log 2>&1
./git-update intranet-workflow master >>update.log 2>&1
./git-update intranet-xmlrpc master >>update.log 2>&1
./git-update simple-survey master >>update.log 2>&1

./github-update intranet-planning >>update.log 2>&1
./github-update intranet-overtime >>update.log 2>&1
./github-update intranet-reporting-openoffice >>update.log 2>&1