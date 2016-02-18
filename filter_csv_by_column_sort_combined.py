#!/usr/bin/python

import os,sys,csv,resource,gc

if len(sys.argv)<3:
	print "Usage for interactive mode:\n\t%s source_file destination_file" % (sys.argv[0])
	print "Usage for batch mode:\n\t%s source_file destination_file columns [sort_clumn]" % (sys.argv[0])
	print "\there:\n\t\tcolumns\t\t- columns, separated by comma, for sample: domainName,contactEmail\n\t\tsort_column\t- optional, by default will be set to first selected column"
	exit (0)

if not os.path.isdir(sys.argv[1]):
	print "Error: directry not found %s" % sys.argv[1]
	exit(1)

if not os.path.isdir(sys.argv[2]):
        print "Error: directry not found %s" % sys.argv[2]
        exit(1)

tfields = []
tdata = []
max_memsize = (50 * 1024)
step_memsize = 256
last_memsize = 0

if len(sys.argv)==5:
        for cf in sys.argv[3].split(','):
		tfields.append(cf)
        csort=sys.argv[4]
elif len(sys.argv)==4:
        for cf in sys.argv[3].split(','):
                tfields.append(cf)
	csort=tfields[0]
else:
	print "Error: wrong number of arguments"
	exit (1)

for tld in [d for d in os.listdir(sys.argv[1]) if os.path.isdir(sys.argv[1])]:
	sys.stdout.write("Processing "+tld)
	sys.stdout.flush()
	if os.path.exists(sys.argv[2]+"/"+tld+".csv"):
		print " - skipped"
		continue
	del tdata[:]
	chunk = 0
	file_count=0
	for cfile in [f for f in os.listdir(sys.argv[1]+"/"+tld) if f.endswith(".csv")]:
		#sys.stdout.write('.')
		#sys.stdout.flush()
		current_memsize=int(resource.getrusage(resource.RUSAGE_SELF).ru_maxrss/1024)
		print (str(file_count) + " mem: " + str(current_memsize) +" Mb")
		with open(sys.argv[1]+"/"+tld+"/"+cfile, "rb") as wfile:
			for srow in csv.DictReader(wfile):
				tdata.append ( dict ([ (tfield, srow [tfield]) for tfield in tfields ]) )
		if current_memsize > max_memsize and current_memsize > last_memsize: 
			chunk +=1
			print "Writing chunk "+ str(chunk)
			tdata.sort(key=lambda col: col[csort] )
			with open(sys.argv[2]+"/"+tld+"-"+str(chunk)+".csv","w") as ofile:
				outfile=csv.DictWriter(ofile,fieldnames=tfields,quoting=csv.QUOTE_ALL)
				outfile.writerow(dict((fn,fn) for fn in outfile.fieldnames))
				for row in tdata:
					outfile.writerow(row)
			del tdata[:]
			last_memsize=int(resource.getrusage(resource.RUSAGE_SELF).ru_maxrss/1024)+step_memsize
			gc.collect()
		file_count += 1
	sys.stdout.write('*')
	sys.stdout.flush()
	tdata.sort(key=lambda col: col[csort] )
        sys.stdout.write('+')
        sys.stdout.flush()
	outfile=csv.DictWriter(open(sys.argv[2]+"/"+tld+".csv","w"),fieldnames=tfields,quoting=csv.QUOTE_ALL)
	outfile.writerow(dict((fn,fn) for fn in outfile.fieldnames))
	for row in tdata:
		outfile.writerow(row)
	print "done"
