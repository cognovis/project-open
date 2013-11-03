# $Id$

TARGET=index
SOURCES=attachments.apt

$(TARGET):	html

html:
	aptconvert -toc -pi html strict yes ../$(TARGET).html $(SOURCES)

htmlclean:
	rm -rf ../$(TARGET)*.html ../apt_*.gif ../*.css

clean:	htmlclean

distclean:	clean
