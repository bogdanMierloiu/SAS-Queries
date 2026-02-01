/** RECREARE TABELA REZULTATE_FRAUDA **/

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
    proc datasets library=LASRLIB nolist;
        delete REZULTATE_FRAUDA_PUBLISH REZULTATE_FRAUDA_JOINED;
    quit;
%mend;
%check_and_delete;

/* 4. Creează tabela direct (nu view) */
option DBIDIRECTEXEC;

proc sql;
    create table TMP_BILL_39 as
    select DISTINCT A.punct_de_consum,
				    A.statie,
				    A.linie,
				    A.post_de_transformare,
				    A.localitate,
				    A.judet,
				    A.subregiune,
				    A.plecare,
				    A.firida,
				    A.clasa_contract,
				    A.partener_de_afaceri_descriere
    from LASRLIB.BILL39 as A
    INNER JOIN (select max(B.NUMAR_FACTURA) AS NUMAR_FACTURA, PUNCT_DE_CONSUM
        from LASRLIB.BILL39 as B
        GROUP BY PUNCT_DE_CONSUM
        ) AS B
       ON B.NUMAR_FACTURA = A.NUMAR_FACTURA
      AND B.PUNCT_DE_CONSUM = A.PUNCT_DE_CONSUM;

	create table TMP_CI_CLEAN AS
	SELECT devloc, sursa_complexitate, MAX(complexitate_instalatie) as complexitate_instalatie
				 FROM LASRLIB.COMPLEXITATE_INSTALATIE
				GROUP BY devloc, sursa_complexitate;

    create table LASRLIB.REZULTATE_FRAUDA_JOINED as
    SELECT
        /* Coloanele existente */
        PROBABILITATE.probabilitate_de_frauda AS probabilitate_de_frauda,
        PROBABILITATE.NLC AS NLC,
        BILL39.localitate length=29 format=$29. AS localitate,
        BILL39.judet length=2 format=$2. AS judet,

        /* COLOANE NOI DIN BILL39 */
        PUT(BILL39.punct_de_consum, BEST12.) AS punct_de_consum_str,
        BILL39.punct_de_consum AS punct_de_consum,

        BILL39.subregiune AS subregiune,
        BILL39.statie AS statie,
        BILL39.linie AS linie,
        BILL39.post_de_transformare AS post_de_transformare,
        BILL39.plecare AS plecare,
        BILL39.firida AS firida,
        BILL39.clasa_contract,
        BILL39.partener_de_afaceri_descriere,

        /* Coloane calculate existente */
        CASE WHEN CNT.sparte = 1 THEN CI.complexitate_instalatie
        	 WHEN CNT.sparte = 2 THEN 1
        	 ELSE -1
        END AS complexitate_instalatie,

        LC.gps_lat, LC.gps_lon,
        /* Coloane calculate pentru geo */
        CATX(',', LC.gps_lat, LC.gps_lon) length=30
            label='Coordonate geografice' AS geo_point,

        /* ADAUGĂ COLOANE CALCULATE NOI (opțional) */
        CASE
            WHEN PROBABILITATE.probabilitate_de_frauda > 0.7 THEN 'Risc Ridicat'
            WHEN PROBABILITATE.probabilitate_de_frauda > 0.4 THEN 'Risc Mediu'
            WHEN PROBABILITATE.probabilitate_de_frauda > 0 THEN 'Risc Scăzut'
            ELSE 'Fără Date'
        END AS categorie_risc length=15,

        /* ADAUGĂ COLOANE CALCULATE NOI (opțional) */
        CASE
            WHEN PROBABILITATE.probabilitate_de_frauda > 0.7 THEN 0.7
            WHEN PROBABILITATE.probabilitate_de_frauda > 0.4 THEN 0.4
            WHEN PROBABILITATE.probabilitate_de_frauda > 0 THEN 0
        END AS categorie_risc_culoare_d,

        CASE WHEN (LC.gps_lat = 0 OR LC.gps_lon = 0) OR ( LC.gps_lat IS NULL OR LC.gps_lon IS NULL) THEN 'GPS Invalid'
            ELSE 'GPS Valid'
        END AS validare_gps length=15,

        /* Info adițional util pentru analiză */
        CATX(' - ', BILL39.statie, BILL39.linie, BILL39.post_de_transformare) length=100
            label='Traseu electric' AS traseu_electric,
        /* Timestamp pentru tracking */
        datetime() format=datetime20. AS data_actualizare,
        "&SYSUSERID" AS actualizat_de length=30,
        CASE
        	WHEN CNT.sparte = 1 THEN 'Electricitate'
        	WHEN CNT.sparte = 2 THEN 'Gaz'
        	ELSE 'N/A'
        END AS tip_energie,
        CI.sursa_complexitate AS sursa_complexitate
    FROM TMP_BILL_39 BILL39
    INNER JOIN LASRLIB.LC LC ON BILL39.punct_de_consum = LC.vstelle
    INNER JOIN LASRLIB.PROBABILITATE PROBABILITATE ON BILL39.punct_de_consum = PROBABILITATE.NLC
    INNER JOIN LASRLIB.CONTOR_GOLD CNT ON LC.devloc = CNT.devloc
	LEFT JOIN TMP_CI_CLEAN CI ON CI.devloc = LC.devloc
	;
/*     AICI SE FACE JOIN DE TIP LEFT CU AMBELE TABELA GAZE + ELECTRIC length=8 format=BEST12. */
/*     WHERE PROBABILITATE.probabilitate_de_frauda > 0; -- schimba cu ce vrei ❤👌*/
quit;

proc sql;
    create table LASRLIB.REZULTATE_FRAUDA_PUBLISH as
    select a.*
    from LASRLIB.REZULTATE_FRAUDA_JOINED a
    inner join (
        select punct_de_consum,
               max(complexitate_instalatie) as max_complexitate_instalatie
        from LASRLIB.REZULTATE_FRAUDA_JOINED
        group by punct_de_consum
    ) b
    on a.punct_de_consum = b.punct_de_consum
   and a.complexitate_instalatie = b.max_complexitate_instalatie;
quit;


/* 5. Verifică că tabela s-a creat cu succes */
%macro verify_table;
    %if %sysfunc(exist(LASRLIB.REZULTATE_FRAUDA_PUBLISH)) %then %do;
        proc sql;
            select count(*) as total_records format=comma12.
            from LASRLIB.REZULTATE_FRAUDA_PUBLISH;
        quit;

        proc contents data=LASRLIB.REZULTATE_FRAUDA_PUBLISH;
        run;

        %put NOTE: Tabela REZULTATE_FRAUDA_PUBLISH a fost creată cu succes!;
    %end;
    %else %do;
        %put ERROR: Tabela REZULTATE_FRAUDA_PUBLISH nu s-a putut crea!;
    %end;
%mend;
%verify_table;

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

proc sql;
  /* grupăm pe cheie și numărăm câte rânduri ies */
  create table rezultate_frauda_dup as
  select
      punct_de_consum,
      count(*) as nr_randuri
  from LASRLIB.REZULTATE_FRAUDA_PUBLISH
  group by punct_de_consum
  having nr_randuri > 1;
quit;

proc sql;
  /* cautare dupa punct de consum */
  create table rezultate_frauda_search as
  select *
  from LASRLIB.REZULTATE_FRAUDA_PUBLISH
  where punct_de_consum = 5001656721;
quit;

/* vezi primele cazuri cu probleme */
proc print data=rezultate_frauda_dup (obs=20);
run;

proc print data=rezultate_frauda_search (obs=20);
run;


/* Apelează macro-ul pentru înregistrare */
%registerTable(
    LIBRARY=%nrstr(/Shared Data/SAS Visual Analytics/Public/Visual Analytics Public LASR),
    REPOSID=%str(A5QI2HZ4),
    FOLDER=%nrstr(/Shared Data/SAS Visual Analytics/Public/LASR),
    TABLE=REZULTATE_FRAUDA_PUBLISH
);

/* 7. Mesaj final */
%put NOTE: =====================================================;
%put NOTE: Tabela REZULTATE_FRAUDA_PUBLISH a fost recreată cu succes!;
%put NOTE: Acum ar trebui să fie vizibilă în SAS Visual Analytics;
%put NOTE: User: bogdan-mierloiu;
%put NOTE: Data: %sysfunc(datetime(), datetime20.);
%put NOTE: =====================================================;