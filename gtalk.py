#!/usr/bin/python

import sys,xmpp

login = 'info' # @gmail.com
pwd   = 'secret'

cnx = xmpp.Client('gmail.com',debug=[])
cnx.connect( server=('talk.google.com',5222) )

cnx.auth(login,pwd, 'botty')
cnx.send( xmpp.Message( sys.argv[1], sys.argv[3], "headline", sys.argv[2] ) )
