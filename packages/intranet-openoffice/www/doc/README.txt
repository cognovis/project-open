# Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see
# <http://www.gnu.org/licenses/>.
#

You need to have properly installed openoffice-headless and jodconverter package in ubuntu.

Then copy openoffice.sh to /etc/init.d/openoffice. Make sure it starts correctly by issuing

sudo chmod 755 /etc/init.d/openoffice
sudo /etc/init.d/openoffice start

Then check jodconverter works

/usr/bin/jodconverter /projop_path/packages/intranet-invoices-templates/odt/template.en.odt /tmp/invoice.pdf

If there is an invoice.pdf in /tmp you are good to go and use this package from now on.
