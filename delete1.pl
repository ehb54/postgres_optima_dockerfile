#!/usr/bin/perl

$id = shift;

die "row must be provided\n" if !$id;

$cmd = qq/psql -U auc_admin -d AUC_DATA_DB -c 'select "DataId" from "AUC_schema"."AbsorbanceScanData" order by "DataId" limit 1 offset $id';/;

print "$cmd\n";
@res = `$cmd 2>&1`;

grep chomp, @res;
print join "\n", @res;
print "\n";

$res[2] =~ s/(^\s+|\s+$)//g;
    
$cmd = qq/psql -U auc_admin -d AUC_DATA_DB -c 'select * from "AUC_schema"."AbsorbanceScanData" where "DataId" = $res[2]'/;

print "$cmd\n";

$cmd = qq/psql -U auc_admin -d AUC_DATA_DB -c 'delete from "AUC_schema"."AbsorbanceScanData" where "DataId" = $res[2]'/;

print "$cmd\n";
    
