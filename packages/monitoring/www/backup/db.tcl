ad_page_contract {
    Backup dos arquivos

} { }
   


#####
#
# Mostra barra de prograseo
#
#####


ad_progress_bar_begin \
    -title "Executamdo Backup do Banco de Dados..." \
    -message_1 "Aguarde, isto pode demorar ..." \
    -message_2 "Ao Final voc�ser�redirecionado para a p�ina de backup."

#Executa backup do banco de dados

set dest "[acs_root_dir]/packages/monitoring/www/backup"
    
if [catch {


#ns_log notice "pg_dump -f $dest/db.dmp coptec_comunidades"
# pega base do config.tcl: set [db_get_database]
set database_name [db_get_database]

[exec  pg_dump -O -f $dest/db.dmp $database_name ]
} errmsg] {
	set msg "Mensagem do DUMP: $errmsg"
	
} else {
        set msg "Dump completado"
}



#zipa conteudo

if [catch {
[exec gzip -9 $dest/db.dmp]
} errmsg] {
	append msg "Mensagem do GZIP: $errmsg"
} else {
        append msg "Arquivo compactado com sucesso"
}



#renomeia arquivo

if [catch {
if [file exists $dest/db.dmp.gz] {
   set date [ns_fmttime [ns_time] "%Y-%m-%d_%H-%M-%S"]
   file rename  $dest/db.dmp.gz $dest/$database_name-$date-db.gz
}

} errmsg] {
	append msg "Mensagem do rename: $errmsg"
} else {
        append msg "Arquivo renomeado com sucesso"
}

ns_log notice "$msg"

#####
#
# Feito
#
#####

ad_progress_bar_end -url index


