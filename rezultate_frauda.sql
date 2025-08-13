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
    %if %sysfunc(exist(LASRLIB.REZULTATE_FRAUDA_PUBLISH)) %then %do;
        proc datasets library=LASRLIB nolist;
            delete REZULTATE_FRAUDA_PUBLISH;
        quit;
        %put NOTE: Tabela existentă REZULTATE_FRAUDA_PUBLISH a fost ștearsă.;
    %end;
    %else %do;
        %put NOTE: Tabela REZULTATE_FRAUDA_PUBLISH nu există, se va crea una nouă.;
    %end;
%mend;
%check_and_delete;

/* 4. Creează tabela direct (nu view) */
option DBIDIRECTEXEC;

proc sql;
    create table LASRLIB.REZULTATE_FRAUDA_PUBLISH as
    SELECT
        /* Coloanele existente */
        PROBABILITATE.probabilitate_de_frauda AS probabilitate_de_frauda,
        PROBABILITATE.NLC AS NLC,
        BILL39.localitate length=29 format=$29. AS localitate,
        BILL39.judet length=2 format=$2. AS judet,

        /* COLOANE NOI DIN BILL39 */
        BILL39.punct_de_consum AS punct_de_consum,
        BILL39.subregiune AS subregiune,
        BILL39.statie AS statie,
        BILL39.linie AS linie,
        BILL39.post_de_transformare AS post_de_transformare,
        BILL39.plecare AS plecare,
        BILL39.firida AS firida,
        BILL39.clasa_contract,

        /* Coloane calculate existente */
        CI.complexitate_instalatie AS complexitate_instalatie,
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

        CASE
            WHEN LC.gps_lat = 0 OR LC.gps_lon = 0 THEN 'GPS Invalid'
            ELSE 'GPS Valid'
        END AS validare_gps length=15,

        /* Info adițional util pentru analiză */
        CATX(' - ', BILL39.statie, BILL39.linie, BILL39.post_de_transformare) length=100
            label='Traseu electric' AS traseu_electric,

        /* Timestamp pentru tracking */
        datetime() format=datetime20. AS data_actualizare,
        "&SYSUSERID" AS actualizat_de length=30,
        CASE
        	WHEN CNT.sparte = 1 THEN 'electric'
        	WHEN CNT.sparte = 2 THEN 'gaz'
        	ELSE 'N/A'
        END AS tip_energie
    FROM
        LASRLIB.BILL39 BILL39
    INNER JOIN
        LASRLIB.LC LC
            ON BILL39.punct_de_consum = LC.vstelle
    INNER JOIN
        LASRLIB.PROBABILITATE PROBABILITATE
            ON BILL39.punct_de_consum = PROBABILITATE.NLC
    INNER JOIN
    	LASRLIB.CONTOR CNT
    		ON LC.devloc = CNT.devloc
	INNER JOIN LASRLIB.COMPLEXITATE_INSTALATIE CI ON CI.devloc = LC.devloc
/*     AICI SE FACE JOIN DE TIP LEFT CU AMBELE TABELA GAZE + ELECTRIC length=8 format=BEST12. */
    WHERE
         PROBABILITATE.probabilitate_de_frauda > 0;
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