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
	create view TEMP_LASR_VIEW_197 as
    SELECT
        CONTOR.devloc length=8 format=BEST12. AS devloc,
        CONTOR.equnr length=8 format=BEST12. AS equnr,
        CONTOR.sparte length=8 format=BEST12. AS sparte,
        /* Tip CONTOR Simplificat */CASE
            WHEN Index(UpCase(CONTOR.matnr_desc),
            'MONO') > 0 THEN 1
            WHEN Index(UpCase(CONTOR.matnr_desc),
            'TRI') > 0 THEN 3
            ELSE -1END length=8 format=NLNUMI6. AS complexitate_instalatie length=8 format=NLNUMI6. AS complexitate_instalatie
        FROM
            LASRLIB.CONTOR CONTOR
        WHERE
            CONTOR.gertyptxtl = 'contor'
            AND (
                UPCASE(CONTOR.matnr_desc) LIKE '%MONO%'
                OR UPCASE(CONTOR.matnr_desc) LIKE '%TRI%'
            )
            AND CONTOR.devloc IS NOT NULL
            AND CONTOR.sparte = 1;
quit;
/* Drop existing table */
%vdb_dt(LASRLIB.CONTOR_GOLD);
data LASRLIB.CONTOR_GOLD (   partition=(devloc)  );
	set TEMP_LASR_VIEW_197 (  );
run;

/* Synchronize table registration */
%registerTable(
     LIBRARY=%nrstr(/Shared Data/SAS Visual Analytics/Public/Visual Analytics Public LASR)
   , REPOSID=%str(A5QI2HZ4)
   , TABLEID=%str(A5QI2HZ4.BJ00001G)
   );