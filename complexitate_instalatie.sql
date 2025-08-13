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

/* Drop existing table */
%vdb_dt(LASRLIB.COMPLEXITATE_INSTALATIE);

proc sql noprint;
	CREATE TABLE LASRLIB.COMPLEXITATE_INSTALATIE AS
    /* Contoare */
    SELECT
        devloc,
        complexitate_instalatie AS complexitate_instalatie,
        'CONTOR' AS sursa_complexitate length=15
    FROM LASRLIB.CONTOR_GOLD
    WHERE complexitate_instalatie IS NOT NULL

    UNION ALL

    /* Transformatoare */
    SELECT
        devloc,
        complexitate_instalatie AS complexitate_instalatie,
        'TRANSFORMATOR' AS sursa_complexitate
    FROM LASRLIB.TRANSFORMATOR_GOLD
    WHERE complexitate_instalatie IS NOT NULL

    ORDER BY devloc, sursa_complexitate;
quit;

/* 6. Înregistrare în metadata (pentru a fi vizibilă în UI) */
%macro registertable(REPOSITORY=Foundation, REPOSID=, LIBRARY=, TABLE=, FOLDER=, TABLEID=, PREFIX=);
    %let REPOSITORY=%superq(REPOSITORY);
    %let LIBRARY=%superq(LIBRARY);
    %let FOLDER=%superq(FOLDER);
    %let TABLE=%superq(TABLE);

    %let REPOSARG=%str(REPNAME="&REPOSITORY.");
    %if ("&REPOSID." ne "") %THEN %LET REPOSARG=%str(REPID="&REPOSID.");

    %if ("&TABLEID." ne "") %THEN %LET SELECTOBJ=%str(&TABLEID.);
    %else %LET SELECTOBJ=&TABLE.;

    %PUT INFO: Înregistrare tabel &TABLE. în biblioteca &LIBRARY.;

    proc metalib;
        omr (library="&LIBRARY." %str(&REPOSARG.));
        %if ("&FOLDER." ne "") %THEN %DO;
            folder="&FOLDER.";
        %end;
        %if ("&PREFIX." ne "") %THEN %DO;
            prefix="&PREFIX.";
        %end;
        select ("&SELECTOBJ.");
    run;
    quit;
%mend;

/* Apelează macro-ul pentru înregistrare */
%registerTable(
    LIBRARY=%nrstr(/Shared Data/SAS Visual Analytics/Public/Visual Analytics Public LASR),
    REPOSID=%str(A5QI2HZ4),
    FOLDER=%nrstr(/Shared Data/SAS Visual Analytics/Public/LASR),
    TABLE=COMPLEXITATE_INSTALATIE
);