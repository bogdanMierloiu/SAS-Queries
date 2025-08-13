/** QUERY **/

%LET VDB_GRIDHOST=va.cpt-dev.eonsn.ro;
%LET VDB_GRIDINSTALLLOC=/opt/TKGrid;
options set=GRIDHOST="va.cpt-dev.eonsn.ro";
options set=GRIDINSTALLLOC="/opt/TKGrid";
options validvarname=any validmemname=extend;

/* Register Table Macro */
%macro registertable( REPOSITORY=Foundation, REPOSID=, LIBRARY=, TABLE=, FOLDER=, TABLEID=, PREFIX= );

/* Mask special characters */

   %let REPOSITORY=%superq(REPOSITORY);
   %let LIBRARY   =%superq(LIBRARY);
   %let FOLDER    =%superq(FOLDER);
   %let TABLE     =%superq(TABLE);

   %let REPOSARG=%str(REPNAME="&REPOSITORY.");
   %if ("&REPOSID." ne "") %THEN %LET REPOSARG=%str(REPID="&REPOSID.");

   %if ("&TABLEID." ne "") %THEN %LET SELECTOBJ=%str(&TABLEID.);
   %else                         %LET SELECTOBJ=&TABLE.;

   %if ("&FOLDER." ne "") %THEN
      %PUT INFO: Registering &FOLDER./&SELECTOBJ. to &LIBRARY. library.;
   %else
      %PUT INFO: Registering &SELECTOBJ. to &LIBRARY. library.;

   proc metalib;
      omr (
         library="&LIBRARY."
         %str(&REPOSARG.)
          );
      %if ("&TABLEID." eq "") %THEN %DO;
         %if ("&FOLDER." ne "") %THEN %DO;
            folder="&FOLDER.";
         %end;
      %end;
      %if ("&PREFIX." ne "") %THEN %DO;
         prefix="&PREFIX.";
      %end;
      select ("&SELECTOBJ.");
   run;
   quit;

%mend;

LIBNAME LASRLIB SASIOLA  TAG=VAPUBLIC  PORT=10031 HOST="va.cpt-dev.eonsn.ro"  SIGNER="http://va.cpt-dev.eonsn.ro:7980/SASLASRAuthorization" ;

option DBIDIRECTEXEC;

proc sql noprint;
	create table TEMP_LASR_VIEW_0 as
	SELECT PB.probabilitate_de_frauda, COUNT(*) AS nr_clienti,
			AVG(CI.complexitate_instalatie) AS avg_complexitate_instalatie
	FROM LASRLIB.PROBABILITATE PB
    INNER JOIN LASRLIB.LC LC
    	ON LC.vstelle = PB.NLC
 	INNER JOIN LASRLIB.COMPLEXITATE_INSTALATIE CI
 		ON LC.devloc = CI.devloc
	GROUP BY PB.probabilitate_de_frauda
	;
quit;
/* Drop existing table */
%vdb_dt(LASRLIB.CASES_PUBLISH);
data LASRLIB.CASES_PUBLISH (    );
	set TEMP_LASR_VIEW_0 (  );
run;


/* Apelează macro-ul pentru înregistrare */
%registerTable(
    LIBRARY=%nrstr(/Shared Data/SAS Visual Analytics/Public/Visual Analytics Public LASR),
    REPOSID=%str(A5QI2HZ4),
    FOLDER=%nrstr(/Shared Data/SAS Visual Analytics/Public/LASR),
    TABLE=CASES_PUBLISH
);