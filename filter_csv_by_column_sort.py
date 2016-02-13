#!/usr/bin/python

import os,sys,csv

if not os.path.isfile(sys.argv[1]):
	print "File not found %s" % sys.argv[1]
	exit(1)

if os.path.exists(sys.argv[2]):
        print "File already exist %s" % sys.argv[2]
        exit(1)

infile=csv.DictReader(open(sys.argv[1], "rb"))

tfields = []
trow = {}
tdata = []

try:
        for cf in sys.argv[3].split(','):
		tfields.append(cf)
        csort=sys.argv[4]
except:
	i=0
	for field in infile.fieldnames:
		print "%i) %s" % (i,field)
		i += 1
	choose = raw_input('Choose fileds [for sample 1,10,15]: ')
	for cf in choose.split(','):
		tfields.append(infile.fieldnames[int(cf)])
	choose = raw_input('Sort by [filed number]: ')
	csort=infile.fieldnames[int(choose)]

for srow in infile:
	tdata.append ( dict ([ (tfield, srow [tfield]) for tfield in tfields ]) )

tdata.sort(key=lambda col: col[csort] )

outfile=csv.DictWriter(open(sys.argv[2],"w"),fieldnames=tfields,quoting=csv.QUOTE_ALL)
outfile.writerow(dict((fn,fn) for fn in outfile.fieldnames))
for row in tdata:
	outfile.writerow(row)
