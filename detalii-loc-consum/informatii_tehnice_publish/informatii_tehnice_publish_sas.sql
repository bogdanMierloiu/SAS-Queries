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
    %if %sysfunc(exist(LASRLIB.INFORMATII_TEHNICE_PUBLISH)) %then %do;
        proc datasets library=LASRLIB nolist;
            delete INFORMATII_TEHNICE_PUBLISH;
        quit;
        %put NOTE: Tabela existentă INFORMATII_TEHNICE_PUBLISH a fost ștearsă.;
    %end;
    %else %do;
        %put NOTE: Tabela INFORMATII_TEHNICE_PUBLISH nu există, se va crea una nouă.;
    %end;
%mend;
%check_and_delete;

/* 4. Creează tabela direct (nu view) */
option DBIDIRECTEXEC;

proc sql;
    CREATE TABLE TMP_BILL_39 as
    SELECT DISTINCT A.punct_de_consum,
    				A.numar_instalatie,
				    A.statie,
				    A.linie,
				    A.post_de_transformare,
				    A.localitate,
				    A.judet, A.strada,
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

    CREATE TABLE CONTOR_CLEAN AS
    SELECT devloc,
           equnr,
           sparte,
           matnr,
           matnr_desc,
           sernr,
           gertyptxtl AS tip_contor,
           ami_am_active,
           datab,
           datbi,
           input(put(datab, z8.), yymmdd8.) AS datab_date format=date9.,
      	   input(put(datbi, z8.), yymmdd8.) AS datbi_date format=date9.
    from LASRLIB.CONTOR
    where devloc IS NOT NULL
    and datab IS NOT NULL
    and datbi IS NOT NULL
    AND today() between CALCULATED datab_date and CALCULATED datbi_date;

    CREATE TABLE LASRLIB.INFORMATII_TEHNICE_PUBLISH AS
    SELECT PUT(bill39.punct_de_consum, BEST12.) AS punct_de_consum_str,
    	   bill39.punct_de_consum 				AS punct_de_consum,
    	   loc_consum.devloc 					AS loc_dispozitiv,
    	   loc_consum.address					AS adresa,
    	   loc_consum.gps_lat 					AS gps_latitudine,
    	   loc_consum.gps_lon 					AS gps_longitudine,
    	   loc_consum.vbsart 					AS tip_punct_consum_cod,
    	   loc_consum.vbsart_desc	 			AS tip_punct_consum_desc,
    	   loc_consum.anzpers 					AS nr_persoane,
    	   instalatie.anlage					AS instalatie,
    	   instalatie.sparte 					AS divizie,
    	   instalatie.sparte_desc 				AS divizie_desc,
    	   instalatie.tariftyp 					AS categorie_tarif,
    	   instalatie.tariftyp_desc 			AS categorie_tarif_desc,
    	   instalatie.grid_id 					AS grila_cod,
    	   instalatie.grid_name 				AS grid_name,
    	   instalatie.grid_level 				AS nivel_retea,
    	   instalatie.scenario_desc 			AS scenariu_furnizare_desc,
    	   contor.equnr 						AS nr_echipament,
    	   contor.matnr 						AS material,
    	   contor.matnr_desc 					AS material_descriere,
    	   contor.sernr 						AS nr_serie,
    	   contor.tip_contor,
    	   contor.datab_date 					AS valabil_de_la,
    	   contor.datbi_date 					AS valabil_pana_la,
    	   CASE WHEN contor.ami_am_active IS NOT NULL THEN contor.ami_am_active ELSE 'N/A' END AS am_activ_inactiv
    FROM TMP_BILL_39 bill39
    INNER JOIN LASRLIB.LC loc_consum ON bill39.punct_de_consum = loc_consum.vstelle
    INNER JOIN LASRLIB.INSTALATIE instalatie ON bill39.numar_instalatie = instalatie.anlage
    INNER JOIN CONTOR_CLEAN contor ON contor.devloc = loc_consum.devloc;
quit;

proc print data=CONTOR_CLEAN;
where devloc = 7000954262;
run;

proc print data=LASRLIB.INFORMATII_TEHNICE_PUBLISH;
	where punct_de_consum = 5001689479;
run;

/* proc print data=LASRLIB.INFORMATII_TEHNICE_PUBLISH; */
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
    TABLE=INFORMATII_TEHNICE_PUBLISH
);

/* 7. Mesaj final */
%put NOTE: =====================================================;
%put NOTE: Tabela INFORMATII_TEHNICE_PUBLISH a fost recreată cu succes!;
%put NOTE: Acum ar trebui să fie vizibilă în SAS Visual Analytics;
%put NOTE: User: bogdan-mierloiu;
%put NOTE: Data: %sysfunc(datetime(), datetime20.);
%put NOTE: =====================================================;