ad_page_contract {
    Backup dos arquivos

} { }
   


#####
#
# Mostra barra de prograseo
#
#####


ad_progress_bar_begin \
    -title "Executando Backup de Arquivos..." \
    -message_1 "Aguarde, isto pode demorar ..." \
    -message_2 "Ao Final voc�ser�redirecionado para a p�ina de backup."

#Compacta diretorio, orig e o diretorio raiz para tirar o backup
set orig "[acs_root_dir]"
set dest "[acs_root_dir]/packages/monitoring/www/backup"
    
if [catch {
[exec nice tar -cf $dest/files.tar --exclude=*.gz --exclude=*.dmp --exclude=*.tar  $orig  ]
} errmsg] {
	set msg "Mensagem do TAR: $errmsg"
	
} else {
        set msg "Arquivo copiado com sucesso"
}


#zipa conteudo

if [catch {
[exec nice gzip -9 $dest/files.tar]
} errmsg] {
	append msg "Mensagem do GZIP: $errmsg"
} else {
        append msg "Arquivo compactado com sucesso"
}



#renomeia arquivo  [ns_info server]

set servername [ns_info server]

if [catch {
if [file exists $dest/files.tar.gz] {
   set date [ns_fmttime [ns_time] "%Y-%m-%d_%H-%M-%S"]
   file rename  $dest/files.tar.gz $dest/$servername-$date-files.tar.gz
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



