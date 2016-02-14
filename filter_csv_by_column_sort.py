#!/usr/bin/python

import os,sys,csv

if len(sys.argv)<3:
	print "Usage for interactive mode:\n\t%s source_file destination_file" % (sys.argv[0])
	print "Usage for batch mode:\n\t%s source_file destination_file columns [sort_clumn]" % (sys.argv[0])
	print "\there:\n\t\tcolumns\t\t- columns, separated by comma, for sample: domainName,contactEmail\n\t\tsort_column\t- optional, by default will be set to first selected column"
	exit (0)

if not os.path.isfile(sys.argv[1]):
	print "Error: File not found %s" % sys.argv[1]
	exit(1)

if os.path.exists(sys.argv[2]):
        print "Error: File already exist %s" % sys.argv[2]
        exit(1)
if not os.path.isdir(os.path.dirname(sys.argv[2])):
	print "Error: Destinatin path not exist %s" % os.path.dirname(sys.argv[2])
	exit (1)

infile=csv.DictReader(open(sys.argv[1], "rb"))

tfields = []
tdata = []

if len(sys.argv)==5:
        for cf in sys.argv[3].split(','):
		tfields.append(cf)
        csort=sys.argv[4]
elif len(sys.argv)==4:
        for cf in sys.argv[3].split(','):
                tfields.append(cf)
	csort=tfields[0]
elif len(sys.argv)==3:
	i=0
	for field in infile.fieldnames:
		print "%i) %s" % (i,field)
		i += 1
	choose = raw_input('Choose fileds [for sample 1,10,15]: ')
	for cf in choose.split(','):
		tfields.append(infile.fieldnames[int(cf)])
	choose = raw_input('Sort by [filed number]: ')
	csort=infile.fieldnames[int(choose)]
else:
	print "Error: wrong number of arguments"
	exit (1)

for srow in infile:
	tdata.append ( dict ([ (tfield, srow [tfield]) for tfield in tfields ]) )

tdata.sort(key=lambda col: col[csort] )

outfile=csv.DictWriter(open(sys.argv[2],"w"),fieldnames=tfields,quoting=csv.QUOTE_ALL)
outfile.writerow(dict((fn,fn) for fn in outfile.fieldnames))
for row in tdata:
	outfile.writerow(row)
