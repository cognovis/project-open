You need to have properly installed openoffice-headless and jodconverter package in ubuntu.

Then copy openoffice.sh to /etc/init.d/openoffice. Make sure it starts correctly by issuing

sudo chmod 755 /etc/init.d/openoffice
sudo /etc/init.d/openoffice start

Then check jodconverter works

/usr/bin/jodconverter /projop_path/packages/intranet-invoices-templates/odt/template.en.odt /tmp/invoice.pdf

If there is an invoice.pdf in /tmp you are good to go and use this package from now on.
