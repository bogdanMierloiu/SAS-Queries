/** RECREARE TABELA CONSUM_SILVER **/

/* 1. Setări inițiale */
%LET VDB_GRIDHOST=va.cpt-dev.eonsn.ro;
%LET VDB_GRIDINSTALLLOC=/opt/TKGrid;
options set=GRIDHOST="va.cpt-dev.eonsn.ro";
options set=GRIDINSTALLLOC="/opt/TKGrid";
options validvarname=any validmemname=extend;

/* 2. Conectare la LASR */
LIBNAME LASRLIB SASIOLA
    TAG=VAPUBLIC
    PORT=10031
    HOST="va.cpt-dev.eonsn.ro"
    SIGNER="http://va.cpt-dev.eonsn.ro:7980/SASLASRAuthorization";

/* 3. Verifică dacă tabela există și șterge-o dacă da */
%macro check_and_delete;
    %if %sysfunc(exist(LASRLIB.CONSUM_SILVER)) %then %do;
        proc datasets library=LASRLIB nolist;
            delete CONSUM_SILVER;
        quit;
        %put NOTE: Tabela existentă CONSUM_SILVER a fost ștearsă.;
    %end;
    %else %do;
        %put NOTE: Tabela CONSUM_SILVER nu există, se va crea una nouă.;
    %end;
%mend;
%check_and_delete;

/* 4. Creează tabela direct (nu view) */
option DBIDIRECTEXEC;

/*Aici trebuie sa facem SUMA la nivel de dizpozitive per echipament*/
proc sql;
    CREATE TABLE RAW_FILTERED_DATA as
    SELECT c.equnr, c.sernr, c.zwnummer, input(put(c.adat, z8.), yymmdd8.) AS data_citire format=date9., v_zwstand AS index,
    	   case
		    	when missing(cr.kennziff) then "gaz"
		   		when cr.kennziff = '' then "gaz"
		    	else cr.kennziff
		   end as kennziff,
    	   cr.massread,
    	   PUT(lc.vstelle, BEST12.) AS punct_de_consum_str,
    	   lc.vstelle AS punct_de_consum,
    	   cnt.datbi_d, cnt.datab_d
    FROM LASRLIB.CITIRE c
    INNER JOIN (SELECT DISTINCT equnr, zwnummer, kennziff, massread FROM LASRLIB.CONTOR_REGISTRI) cr
/*     WHERE kennziff IN ('1.8.0','3.8.0','4.8.0'))  */
        on c.equnr = cr.equnr
       and c.zwnummer = cr.zwnummer
    INNER JOIN (SELECT c.devloc, c.sernr, c.equnr, input(put(C.datab, z8.), yymmdd8.) as datab_d format=date9., input(put(C.datbi, z8.), yymmdd8.) as datbi_d format=date9.
      	        FROM LASRLIB.CONTOR C where C.devloc is not null and C.datab is not null and C.datbi is not null) cnt ON cnt.equnr = cr.equnr
      	        																									 AND today() between datab_d and datbi_d
    INNER JOIN LASRLIB.LC ON lc.devloc = cnt.devloc
    WHERE c.v_zwstand is not null
      and c.v_zwstand > 0
      and c.adat is not null
      and c.adat ne 0
    ;
quit;
/*  */
/* proc print data=RAW_FILTERED_DATA; */
/* 	where equnr = 8006013425; */
/* run; */


/* First sort the input data */
proc sort data=RAW_FILTERED_DATA;
    by equnr zwnummer kennziff data_citire;
run;

/* Calculate consumption in a temporary dataset */
data CONSUM_CALCULAT;
    set RAW_FILTERED_DATA;
    by equnr zwnummer kennziff data_citire;
    retain index_anterior;

    /* reset pentru primul record din fiecare grup */
    if first.zwnummer then index_anterior = .;

    /* calcul consum */
    if not missing(index_anterior) then
        consum = index - index_anterior;

    /* update pentru următorul rând */
    index_anterior = index;
run;

/* Sort the temporary dataset */
proc sort data=CONSUM_CALCULAT out=SORTED_DATA;
    by descending data_citire kennziff zwnummer;
run;

/* Load the sorted data into the LASR table */
data LASRLIB.CONSUM_SILVER;
    set SORTED_DATA (where=(consum is not null));
run;

proc print data=LASRLIB.CONSUM_SILVER;
	where punct_de_consum = 5003241646;
run;

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

/* Apelează macro-ul pentru înregistrare */
%registerTable(
    LIBRARY=%nrstr(/Shared Data/SAS Visual Analytics/Public/Visual Analytics Public LASR),
    REPOSID=%str(A5QI2HZ4),
    FOLDER=%nrstr(/Shared Data/SAS Visual Analytics/Public/LASR),
    TABLE=CONSUM_SILVER
);

/* 7. Mesaj final */
%put NOTE: =====================================================;
%put NOTE: Tabela CONSUM_SILVER a fost recreată cu succes!;
%put NOTE: Acum ar trebui să fie vizibilă în SAS Visual Analytics;
%put NOTE: User: bogdan-mierloiu;
%put NOTE: Data: %sysfunc(datetime(), datetime20.);
%put NOTE: =====================================================;