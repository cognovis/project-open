
# Return the current date
doc_return 200 "text/html" [db_string date "select to_char(now(), 'YYYY-MM-HH HH24:MI') from dual"]
