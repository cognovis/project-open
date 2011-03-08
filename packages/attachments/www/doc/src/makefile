# $Id: makefile,v 1.1 2002/11/12 22:14:15 arjun Exp $

TARGET=index
SOURCES=attachments.apt

$(TARGET):	html

html:
	aptconvert -toc -pi html strict yes ../$(TARGET).html $(SOURCES)

htmlclean:
	rm -rf ../$(TARGET)*.html ../apt_*.gif ../*.css

clean:	htmlclean

distclean:	clean
