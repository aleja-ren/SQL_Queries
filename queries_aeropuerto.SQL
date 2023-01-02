Repaso y cosas importantes que saber de sql

/*1. vuelos realizados por garcia*/
select C.nombre, E.vid
from Cliente C natural join Embarque E
where C.nombre='García';

/*seguimos esta estructura cuando nos piden en concreto, tenemos que usar cliente y embarque
porque nos piden los vuelos realizados, si ha embarcado es que lo ha realizado por eso usamos
embarque en vez de vuelo*/


/*2. numero de vuelos de la compañia qantas*/
--si no necesito que aparezca el nombre
select count (*) as numVuelos
from Aerolinea A natural join Vuelo V
where A.nombre='Qantas';

--si necesito que aparezca el nombre
select A.nombre, count(*) as numVuelos
from Aerolinea A natural join Vuelo V
where A.nombre='Qantas'
group by A.nombre;

/*sigo esta estructura para contar las cosas que cumplan una determinada condición, en este
caso la condición es que el nombre sea Qantas, siempre uso count para hacer el conteo
lo que hacemos con ese natural join es que a cada tupla de vuelo le añade el nombre de la 
compañía correspondiente*/


/*3. compañía con el máximo número de vuelos*/
/*tenemos que contar el numero de vuelos de cada compañía como una subquery y despues de ese conteo
obtener el que es mayor*/

/*estructura para contar el numero de vuelos de cada comapñía
siempre usamos esta estructura para obtener una tabla con el conteo
de algo (como si pusieramos los niveles de un factor y las veces que se toma
el valor de cada nivel)*/
select V.alid, count(*) as numVuelos
from Vuelo V
group by V.alid;

/*La estructura para obtener el valor maximo de una tabla es
select *
from tabla T
where T.att >= ALL (select T2.att
			from tabla T2);
*/

/*ahora de esta tabla tenemos que obtener el de mayor valor, esta tabla que he obtenido antes va 
a ser como una tabla temporal de la subquery, ponemos el group by exterior porque como queremos mostrar 
el V.alid tenemos que agruparlo*/
select V.alid, count(*) as numVuelos
from Vuelo V
group by V.alid
having count(*)  >= ALL (select count(*)
			from Vuelo V2
			group by V2.alid);

/*otra opcion es hacerlo con un with, donde la estructura cambia, primero haremos la tabla con los conteos
a la que le vamos a dar un nombre y despues ya obtendremos el maximo*/
with Nvuelos as (select V.alid, count(*) as numVuelos
				 from Vuelo V
				 group by V.alid)
select NV.alid, NV.numVuelos
from Nvuelos NV
where NV.numVuelos >= ALL (select NV2.numVuelos
				from Nvuelos N2);

/*4. las 5 compañias con el mayor numero de vuelos*/
with Nvuelos as (select V.alid, count(*) as numVuelos
			from Vuelo V
			group by V.alid)
select NV.alid, NV.numVuelos
from Nvuelos NV
where 5 > (select count(*)
		   from Nvuelos NV2
		   where NV2.numVuelos > NV.numVuelos);
--order by Nv.numVuelos [asc/desc];
--si quiero mostrarlos ordenados
/*tengo la misma tabla de antes con el conteo de los vuelos de cada compañía
busco los que tienen mas vuelos que "yo", es decir, la tupla que estoy procesando y eso tiene que ser
menor que 5, por eso la condicion es where NV2.numVuelos > NV.numVuelos*/


/*5. Pares origen-destino con al menos 2 vuelos, ordenado por nº vuelos*/
select V.origen, V.destino, count(*) as numVuelos
from Vuelo V
group by V.origen, V.destino
having count(*) >= 2
order by numVuelos desc;
/*la estructura es que hago el conteo de pares origen destino con el numero de vuelos
luego con el having me aseguro de que sea al menos 2 y finalmente lo ordeno
ese conteo que hemos hecho con select from y group by es el mismo que hemos usado otras veces*/


/*6. encontrar todos los vuelos con el vuelo y el dia que estan vacíos*/
--para que un vuelo esté vacío quiere decir que no se ha hecho ningún embarque
select V.vid, F.fecha
from Vuelo V natural join (select distinct E.fecha
							from Embarque E) F
where (V.vid, F.fecha) not in (select E.vid, E.fecha
							   from Embarque E);
/*quiero los vuelos y las fechas con ese producto cartesiano que hago donde tengo tambien sus fechas
de normal no tenemos las fechas porque no es un atributo de vuelo a ese producto cartesiano le llamo F
y ahora quiero que solo aquellas donde el vid y la fecha (obtenida en el prod cartesiano) no estén en la tabla
embarque porque eso quiere decir que el vuelo estrá vacío*/

/*7. personas (cid,nombre) que han viajado en su cumpleaños
pista: utilizar extract(<day|month|year> FROM c.fdn)*/
select C.cid, C.nombre
from Embarque E natural join Cliente C
where extract(day from E.fecha) = extract(day from C.fdn) and extract(month from E.fecha) = extract(month from C.fdn);


/*8. compañía con el máximo número de viajeros*/
--queremos ver el numero de personas que han embarcado por compañía
with NEmbarcados as(select V.alid, count(*) as numEmb
					 from Embarque E natural join Vuelo V
					 group by v.alid)
select NE.alid, NE.numEmb
from NEmbarcados NE
where NE.numEmb >= ALL (select NE2.numEmb
						 from NEmbarcados NE2);


/*9. Personas (cid,nombre) que no tienen tarjeta de Qantas, pero es en la que más han viajado*/
--queremos el numero de vuelos con cada aerolinea por cada persona
--y una vez tenemos eso quiero el que mas veces ha volado con qantas (alid) sin tener tarjeta
with Nvuelos as(select E.cid,V.alid,count(*) as numVuelos
				 from Vuelo V natural join Embarque E
				 group by E.cid, V.alid)
select C.cid, C.nombre, NV.alid, NV.numVuelos
from Cliente C natural join Nvuelos NV
where NV.numVuelos >= ALL (select NV2.numVuelos
						   from Nvuelos NV2
						   where NV.cid = NV2.cid) --maximo numero de vuelos que hace una persona sea la aerolinea que sea 
--ahora buscamos que sea para la aerolinea qantas
and NV.alid='01QA'
--y ahora que no tenga tarjeta de fidelidad para la aerolinea
and C.tarjAlid <> '01QA';


/*10. Personas que visitaron más ciudades (aeropuertos) en un periodo (fini,ffin)*/
--fini ffin son fechas que nos dan
--primero queremos una tabla intermedia con los aeropuertos que ha visitado cada persona
with Sitios as(select E.cid, A.apid
from Embarque E natural join Aeropuerto A
group by E.cid, A.apid)
select S.cid, count(*) as numA
from Sitios S
group by S.cid
having count(*) >= ALL(select count(*)
					  from Sitios S2
					  group by S2.cid);


/*11. Lista ordenada de aeropuertos y su rango; rango=nº total de vuelos con origen en el aeropuerto; 
si dos empatan deben tener el mismo rango, y el siguiente número no aparecer*/
WITH NVuelos as (SELECT V.origen AS apid, count(*) as nvu
				 FROM Vuelo V
				 GROUP BY V.origen ) --en este with hacemos la tabla donde ponemos el origen y los vuelos (es decir su rango)
SELECT NV.apid, (SELECT count(*)+1
				 FROM NVuelos NV2
				 WHERE NV2.nvu > NV.nvu) as rank --columna más a proyección aparte de las que queremos, construyendo un rango descendente
--para cada tupla, cuantos hay en la tabla que tengan un valor mayor que el mio
--pregunto en una clase cuantos tienen mas nota más alta que la mía pues mi rango es núm que levantan la mano + 1
FROM NVuelos NV
ORDER BY rank desc;



--COMO SERIA PARA BUSCAR LAS 3 COMPAÑÍAS CON EL MENOR NUMERO DE VUELOS
--necesitamos una tabla con las compañías y el número de vuelos de cada una
with Nvuelos as (select V.alid, count(*) as nvu
				from Vuelo V
				group by V.alid)
select NV.alid, NV.nvu
from Nvuelos NV
where 3 >= (select count(*)
			 from Nvuelos NV2
			 where NV2.nvu < NV.nvu);

--COMO SERIA PARA BUSCAR LA AEROLINEA CON EL MINIMO NUMERO DE VUELOS
with Nvuelos as (select V.alid, count(*) as nvu
				from Vuelo V
				group by V.alid)
select NV.alid, NV.nvu
from Nvuelos NV
where NV.nvu >= ALL(select count(*)
			 from Nvuelos NV2
			 group by NV2.alid);
