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
	create table TEMP_TABLE as
    SELECT
        TRANSFORMATOR_SILVER.devloc length=8 format=BEST12. AS devloc,
        3 * TRANSFORMATOR_SILVER.raport_transformare length=8 AS complexitate_instalatie
    FROM
        LASRLIB.TRANSFORMATOR_SILVER TRANSFORMATOR_SILVER
    WHERE
        TRANSFORMATOR_SILVER.raport_transformare > 0
        AND TRANSFORMATOR_SILVER.raport_transformare IS NOT NULL
    GROUP BY
    	TRANSFORMATOR_SILVER.devloc;

quit;
/* Drop existing table */
%vdb_dt(LASRLIB.TRANSFORMATOR_GOLD);

data LASRLIB.TRANSFORMATOR_GOLD(partition=(devloc));
    set TEMP_TABLE;
run;