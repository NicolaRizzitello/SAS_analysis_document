
proc import file="dati_sulla_raccolta_differenziata-2022.csv"
	 dbms=csv 
	 out=mydata
	 replace;
run;


	
data mydata;
set mydata;
	provincia = scan(societa_di_regolamentazione_dei_,1,' ');
	if provincia = "ISOLE" then provincia = "MESSINA";
run;

proc sql;
	create table tonn_diff as 
	select
		provincia,
		sum(vetro) as ton_vetro,
		sum(plastica) as ton_plastica,
		sum(cartone) as ton_cartone,
		sum(frazione_organica_umida) as ton_organico
	from mydata
	group by provincia;
quit;

proc transpose data=tonn_diff out=trans_tonn_diff;
  by provincia;
run;

data trans_tonn_diff (rename=(_NAME_ = tipo_di_rifiuto));
set trans_tonn_diff;
run;

options orientation=landscape;
options papersize=(8.3in 11.7in); /* A4 */




%let percorso = path\;
%let titolo = DIFFERENZIATA_SICILIA;
%let today = %sysfunc(today(),YYMMDD10.);
%let Time = %sysfunc(time(),time8.0); 
%let Time_HH = %scan(&Time,1,:);
%let Time_MM = %scan(&Time.,2,:);



ods word file="&percorso&titolo - &today-&Time_HH&Time_MM..docx"
		 author='USDM'
		 style=Word 
		 startpage=yes 
		 image_dpi=300 
		 options(contents='yes' toc_data='yes' toc_level='1' cant_split='no' keep_lines='yes');







ods startpage=now;
ods proclabel = "1 - Statistiche descrittive variabili continue overall e per Provincia";
title1 "1 - Statistiche descrittive variabili continue overall e per Provincia";
proc means data = mydata n nmiss min mean std p25 median p75 max maxdec=2;
	class provincia;
	var _numeric_;
	ways 0 1;
run;

ods startpage=now;
ods proclabel = "2 - Distribuzione dei rifiuti differenziati per provincia: vetro, cartone, plastica e organico";
title1 "2 - Distribuzione dei rifiuti differenziati per provincia: vetro, cartone, plastica e organico";
proc sgplot data=WORK.TRANS_TONN_DIFF;
	title height=14pt "Distribuzione dei rifiuti differenziati per provincia: vetro, cartone, plastica e organico";
	vbar provincia / response=COL1 group=tipo_di_rifiuto groupdisplay=cluster;
	xaxis label="Provincia";
	yaxis grid label="Tonnellate di Rifiuti";
run;


proc sql;
	create table mean_tonn_ps as
	select 
		provincia,
		sum(pulizia_stradale) as somma_ps,
		round(avg(pulizia_stradale),0.02) as mean_ps
	from mydata
	group by provincia
	order by mean_ps desc;
quit;

proc sql;
create table percentage_ps as 
select provincia,
    round((somma_ps/sum(somma_ps))*100,0.02) as percentage_ps
    from mean_tonn_ps;
    /*group by provincia;*/
quit;


proc sql;
create table tot_table_ps as
	select *
	from mean_tonn_ps a 
	inner join percentage_ps b 
	  on a.provincia = b.provincia;
quit;

/*data tot_table_ps;
	set tot_table_ps (drop= somma_ps  perc_ps);
run;*/

ods startpage=now;
ods proclabel = "3 - Tabella media e percentuale della pulizia stradale per provincia";
title1 "3 - Tabella media e percentuale della pulizia stradale per provincia";
proc print data = tot_table_ps;
run;

  
proc template;
	define statgraph SASStudio.Pie;
		begingraph;
		entrytitle "Distribuzione della variabile pulizia stradale per provincia" / 
			textattrs=(size=14);
		layout region;
		piechart category=provincia response=percentage_ps / 
			datalabellocation=outside;
		endlayout;
		endgraph;
	end;
run;

ods startpage=now;
ods proclabel = "4 - Grafico a torta della percentuale della pulizia stradale per provincia";
title1 "4 - Grafico a torta della percentuale della pulizia stradale per provincia";
proc sgrender template=SASStudio.Pie data=WORK.PERCENTAGE_PS;
run;

ods word close;
