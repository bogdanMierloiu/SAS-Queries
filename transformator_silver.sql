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
	create view TEMP_LASR_VIEW_182 as
    SELECT
        TRANSFORMATOR.devloc length=8 format=BEST12. AS devloc,
        TRANSFORMATOR.wgruppe,
        /* Extrage toate caracterele până la primul digit */
       	Substr(TRANSFORMATOR.wgruppe, 1, AnyDigit(TRANSFORMATOR.wgruppe) - 1)  length=20 AS tip,
        COMPRESS(TRANSFORMATOR.wgruppe,
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ') length=8 AS numere_doar,
        Input(Scan(CALCULATED numere_doar,
        1,
        '/'),
        BEST.)  length=8 AS val_primar,
        /* Valoare secundară procesată cu replace */Input(    CASE
            WHEN Scan(CALCULATED numere_doar,
            2,
            '/') = '00' THEN '.0'
            WHEN Scan(CALCULATED numere_doar,
            2,
            '/') = '0' THEN '.'
            WHEN SUBSTR(Scan(CALCULATED numere_doar,
            2,
            '/'),
            1,
            1) = '0'
            AND LENGTH(Scan(CALCULATED numere_doar,
            2,
            '/')) > 1        THEN CATS('0.',
            SUBSTR(Scan(CALCULATED numere_doar,
            2,
            '/'),
            2))
            ELSE Scan(CALCULATED numere_doar,
            2,
            '/')
        END,
        BEST.) length=8 AS val_secundar,
        /* Raport transformare individual */ CASE
            WHEN CALCULATED val_secundar NOT IN (0,
            .)      THEN CALCULATED val_primar / CALCULATED val_secundar
            ELSE .
        END length=8 AS raport_transformare
    FROM
        LASRLIB.TRANSFORMATOR TRANSFORMATOR
    WHERE
        TRANSFORMATOR.gertyptxtl = 'transformat'
        AND CALCULATED raport_transformare > 0
        AND CALCULATED raport_transformare IS NOT NULL;

  create view AGGREGATE_UNIQUE_RT as
  SELECT DISTINCT src.devloc, src.wgruppe, src.raport_transformare
  FROM TEMP_LASR_VIEW_182 src;

  create view MULTIPLY_VALUES as
  SELECT aur.devloc, EXP(SUM(LOG(aur.raport_transformare))) AS raport_transformare
  FROM AGGREGATE_UNIQUE_RT aur
  GROUP BY aur.devloc;

quit;

/* Drop existing table */
%vdb_dt(LASRLIB.TRANSFORMATOR_SILVER);
data LASRLIB.TRANSFORMATOR_SILVER (   partition=(devloc)  );
	set MULTIPLY_VALUES (  );
run;


/* Synchronize table registration */
%registerTable(
     LIBRARY=%nrstr(/Shared Data/SAS Visual Analytics/Public/Visual Analytics Public LASR)
   , REPOSID=%str(A5QI2HZ4)
   , TABLEID=%str(A5QI2HZ4.BJ00001H)
   );