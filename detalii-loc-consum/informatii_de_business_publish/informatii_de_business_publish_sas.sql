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
    %if %sysfunc(exist(LASRLIB.INFORMATII_DE_BUSINESS_PUBLISH)) %then %do;
        proc datasets library=LASRLIB nolist;
            delete INFORMATII_DE_BUSINESS_PUBLISH;
        quit;
        %put NOTE: Tabela existentă INFORMATII_DE_BUSINESS_PUBLISH a fost ștearsă.;
    %end;
    %else %do;
        %put NOTE: Tabela INFORMATII_DE_BUSINESS_PUBLISH nu există, se va crea una nouă.;
    %end;
%mend;
%check_and_delete;

/* 4. Creează tabela direct (nu view) */
option DBIDIRECTEXEC;

/*Aici trebuie sa facem SUMA la nivel de dizpozitive per echipament*/
proc sql;
    CREATE TABLE TMP_BILL_39 as
    SELECT DISTINCT A.punct_de_consum, numar_instalatie,
				    A.statie,
				    A.linie,
				    A.post_de_transformare,
				    A.localitate,
				    A.judet, strada,
				    A.subregiune,
				    A.plecare,
				    A.firida,
				    A.clasa_contract, partener_de_afaceri,
				    A.partener_de_afaceri_descriere, categorie_tarif, tip_facturare, invoicing_party, nivel_tensiune, urban_rural
    FROM LASRLIB.BILL39 as A
    INNER JOIN (select max(B.NUMAR_FACTURA) AS NUMAR_FACTURA, PUNCT_DE_CONSUM
        from LASRLIB.BILL39 as B
        GROUP BY PUNCT_DE_CONSUM
        ) AS B
       ON B.NUMAR_FACTURA = A.NUMAR_FACTURA
      AND B.PUNCT_DE_CONSUM = A.PUNCT_DE_CONSUM;

    CREATE TABLE LASRLIB.INFORMATII_DE_BUSINESS_PUBLISH as
    SELECT PUT(b.punct_de_consum, BEST12.) AS punct_de_consum_str,
    	   b.punct_de_consum AS punct_de_consum,
    	   b.numar_instalatie,
           b.partener_de_afaceri, b.partener_de_afaceri_descriere,
    	   p.partner, p.name, p.reg_number, p.cif_number,
    	   b.clasa_contract, b.categorie_tarif, b.tip_facturare, b.invoicing_party,
    	   b.judet, b.localitate, b.strada, b.subregiune, p.region, p.region_name, p.city,
    	   b.nivel_tensiune, b.urban_rural, p.ind_sector, p.ind_sector_desc
    FROM TMP_BILL_39 b
    INNER JOIN LASRLIB.PARTNER p ON b.partener_de_afaceri = p.partner
    ;
quit;

proc print data=LASRLIB.INFORMATII_DE_BUSINESS_PUBLISH;
	where punct_de_consum = 5001689479;
run;

/* proc print data=LASRLIB.INFORMATII_DE_BUSINESS_PUBLISH; */
/* 	where equnr = 8006013425 AND consum IS NOT NULL; */
/* run; */

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
    TABLE=INFORMATII_DE_BUSINESS_PUBLISH
);

/* 7. Mesaj final */
%put NOTE: =====================================================;
%put NOTE: Tabela INFORMATII_DE_BUSINESS_PUBLISH a fost recreată cu succes!;
%put NOTE: Acum ar trebui să fie vizibilă în SAS Visual Analytics;
%put NOTE: User: bogdan-mierloiu;
%put NOTE: Data: %sysfunc(datetime(), datetime20.);
%put NOTE: =====================================================;