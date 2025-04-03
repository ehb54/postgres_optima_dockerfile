#!/usr/bin/perl

sub sql_cmd {
    my $sql = shift;
    my $nullstdout = shift;

    $sql =~ s/"/\\"/g;

    $cmd = qq/psql -U auc_admin -d AUC_DATA_DB -c "$sql"/;
    $cmd .= " > /dev/null" if $nullstdout;

    print "cmd : $cmd\n" if $debug;
    my @res = `$cmd`;
    return @res;
}

## get all tables

@res = sql_cmd( "SELECT * FROM pg_catalog.pg_tables WHERE schemaname='AUC_schema'" );
@res  = grep /^\s+AUC_schema /, @res;

@schemas = ();

while ( my $l = shift @res ) {
    my @l = split '\|', $l;
    my $schema = $l[1];
    $schema  =~ s/(^\s+|\s+$)//g;
    push @schemas, $schema;
}

## display counts, might have errors here

for my $schema ( @schemas ) {
    if ( $skip{$schema} ) {
	print "skipping $schema\n";
	next;
    }
    print "checking schema $schema\n";
    my @res = sql_cmd( "SELECT count(*) FROM \"AUC_schema\".\"$schema\"" );
    my $count = $res[2];
    $count  =~ s/(^\s+|\s+$)//g;
    print "$schema records $count\n";
}

## if count(*) fails, need to:
## based upon https://stackoverflow.com/questions/62422298/postgresql-pg-dump-for-invalid-page-in-block-database-does-not-work-properly
### set zero_damaged_pages = on;
### vacuum full "AUC_schema"."table";
### reindex table "AUC_schema"."table";

## now see if we can dump each table

## skip if already done
## e.g. $skip{BaseInterferenceScanParameters}++;

for my $schema ( @schemas ) {
    if ( $skip{$schema} ) {
	print "skipping $schema\n";
	next;
    }
    print "dumping $schema to /dev/null\n";
    my @res = sql_cmd( "SELECT * FROM \"AUC_schema\".\"$schema\"", 1 );
}

## now if there are any more tables needing fixing, bad rows need to be found and deleted.
## this is based upon https://gist.github.com/supix/80f9a6111dc954cf38ee99b9dedf187a
## that reference is not quite right, the proper procedure:
## find the primary key of the table with issues
### e.g. from psql # \d+ "AUC_schema"."CellParameters";
### find the PRIMARY KEY under Indexes, in this case
### Indexes:
###   CellParameters_pkey1" PRIMARY KEY, btree ("CellParamId")
### the primary key is "CellParamID".
## find the offsets of all bad records
### for this we will need the count of the records and then run something like (under a bash shell), with seq below setting the range of rows, determined by the count(*) from the table, (n.b. the order by differs from the gist)
###  rm -f /opt/badnums /opt/goodnums  ; for j in `seq 0 386520`; {  ( psql -U auc_admin -d AUC_DATA_DB -c "SELECT * FROM  \"AUC_schema\".\"CellParameters\" order by \"CellParamId\" LIMIT 1 offset $j" >/dev/null && echo $j >> /opt/goodnums ) || echo $j >> /opt/badnums; }
### this above finds every row and puts the bad rows in /opt/badnums
### n.b. the numbers are not the keys but their order, so now we need to map these back.
### an example is in delete1.pl which is setup for the AbsorbanceScanData table
### delete1.pl only prints the last to commands, these need to be run, the first should report the error again, if not, don't run the 2nd one!
### n.b. you must run these in reverse numerical order order to the sequence from /opt/badnums!
### otherwise the position in the ordered list will change and you will not find the right record to delete
