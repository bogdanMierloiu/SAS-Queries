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

proc sql;
   create table CONTOR_CLEAN as
   select C.devloc,
          C.equnr,
          C.sparte,
          C.matnr_desc,
          case
              when index(upcase(C.matnr_desc),'MONO')>0 then 1
              when index(upcase(C.matnr_desc),'TRI')>0 then 3
              else 1
          end as complexitate_instalatie,
          input(put(C.datab, z8.), yymmdd8.) as datab_d format=date9.,
          input(put(C.datbi, z8.), yymmdd8.) as datbi_d format=date9.
   from LASRLIB.CONTOR C
   where C.devloc is not null
     and C.datab is not null
     and C.datbi is not null
     and C.gertyptxtl = 'contor';
quit;

proc sql;
   create table CONTOR_CLEAN_FILT as
   select *
   from CONTOR_CLEAN
   where today() between datab_d and datbi_d
   and (index(matnr_desc,'MONO')>0
      or index(matnr_desc,'TRI')>0);
quit;

proc sql;
   create view CONTOR_FINAL as
   select a.*
   from CONTOR_CLEAN_FILT a
   inner join (
       select devloc,
              max(complexitate_instalatie) as max_complexitate_instalatie
       from CONTOR_CLEAN_FILT
       group by devloc
   ) b
   on a.devloc = b.devloc
  and a.complexitate_instalatie = b.max_complexitate_instalatie;
quit;


/* Drop existing table */
%vdb_dt(LASRLIB.CONTOR_GOLD);

data LASRLIB.CONTOR_GOLD ();
	set CONTOR_FINAL (  );
run;

/* VERIFICARI DUPLICATE */
proc sql;
  /* grupăm pe cheie și numărăm câte rânduri ies */
  create table contor_dup as
  select
      devloc,
      count(*) as nr_randuri
  from LASRLIB.CONTOR_GOLD
  group by devloc
  having nr_randuri > 1;
quit;

/* vezi primele cazuri cu probleme */
proc print data=contor_dup (obs=20);
run;

/* dacă vrei detaliu pe un punct anume (ex. unde ai mai multe rânduri) */
proc sql;
  select *
  from LASRLIB.CONTOR_GOLD
  where devloc in (select devloc from contor_dup)
  order by devloc;
quit;


/* Synchronize table registration */
%registerTable(
     LIBRARY=%nrstr(/Shared Data/SAS Visual Analytics/Public/Visual Analytics Public LASR)
   , REPOSID=%str(A5QI2HZ4)
   , TABLEID=%str(A5QI2HZ4.BJ00001G)
   );