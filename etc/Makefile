HTTPD_CONF=/etc/httpd/conf
DOC_ROOT=/var/www/html

all: create_db $(HTTPD_CONF)/httpd.conf $(DOC_ROOT)/autohandler $(DOC_ROOT)/menu/menu.mc $(DOC_ROOT)/javascript/dhtml_func.js

clean: clean_db clean_httpd

create_db:
	mysqladmin -f create web_index

$(HTTPD_CONF)/httpd.conf: httpd.conf.mason trick
	cp $(HTTPD_CONF)/httpd.conf $(HTTPD_CONF)/httpd.conf.old.index && \
	cat httpd.conf.mason >> $(HTTPD_CONF)/httpd.conf

$(DOC_ROOT)/autohandler: autohandler
	cp autohandler $(DOC_ROOT)

$(DOC_ROOT)/menu/menu.mc: menu.mc
	mkdir  $(DOC_ROOT)/menu && \
	cp menu.mc $(DOC_ROOT)/menu/ && \
	cp menu_format.mc $(DOC_ROOT)/menu/

$(DOC_ROOT)/javascript/dhtml_func.js: ../Javascript/dhtml_func.js
	mkdir $(DOC_ROOT)/javascript && \
	cp ../Javascript/dhtml_func.js $(DOC_ROOT)/javascript

clean_db:
	mysqladmin -f drop web_index

clean_httpd:
	cp -f $(HTTPD_CONF)/httpd.conf.old.index $(HTTPD_CONF)httpd.conf && \
	rm -rf $(DOC_ROOT)/autohandler $(DOC_ROOT)/menu $(DOC_ROOT)/javascript && \
	touch trick

trick:
	touch trick
