#!/bin/bash

# Declaración variables colores output
WHITE='\033[1;37m'
GREEN='\033[1;32m'
RED='\033[1;31m'
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
NC='\033[0m' # No Color

# Comprobamos que se han introducido los parametros necesarios para el script.
# También se mira que los tipos de datos entrados tengan el formato correcto.
checkParams(){
	clear
	ejemploUso=$(echo -e "${GREEN}Ejemplo de uso : ${NC}${WHITE}./weather.sh España Barcelona correo@dominio.x\n${NC}")
	checkint='^[0-9]+$'
	checkMail="^(([-a-zA-Z0-9\!#\$%\&\'*+/=?^_\`{\|}~]+|(\"([][,:;<>\&@a-zA-Z0-9\!#\$%\&\'*+/=?^_\`{\|}~-]|(\\\\[\\ \"]))+\"))\.)*([-a-zA-Z0-9\!#\$%\&\'*+/=?^_\`{\|}~]+|(\"([][,:;<>\&@a-zA-Z0-9\!#\$%\&\'*+/=?^_\`{\|}~-]|(\\\\[\\ \"]))+\"))@\w((-|\w)*\w)*\.(\w((-|\w)*\w)*\.)*\w{2,4}$"
		
	if [[ -z "$pais" ]]; then
			echo -e "${RED}[!]${NC} ${WHITE}No has pasado el ${RED}PAIS${NC} ${WHITE}por parametro\n${NC}"
			echo "${ejemploUso}"
			exit 1
			
	elif [[ $pais =~ $checkint ]]; then
			echo -e "${RED}[!]${NC} ${WHITE}Has pasado PAIS por parámetro (${RED}${pais}${NC}) ${WHITE}pero no puede ser un número !\n${NC}"
			echo "${ejemploUso}"
			exit 1
			
	elif [[ -z "$ciudad" ]]; then
			echo -e "${RED}[!]${NC} ${WHITE}No has pasado la ${RED}CIUDAD${NC} ${WHITE}por parametro\n${NC}"
			echo "${ejemploUso}"
			exit 1
			
	elif [[ $ciudad =~ $checkint ]]; then
			echo -e "${RED}[!]${NC} ${WHITE}Has pasado CIUDAD por parámetro (${RED}${ciudad}{NC}) ${WHITE}pero no puede ser un número !\n${NC}"
			echo "${ejemploUso}"
			exit 1
				
	
	elif [[ -z "$mail" ]]; then
			echo -e "${RED}[!]${NC} ${WHITE}No has introducido el ${RED}CORREO${NC} ${WHITE}para enviarte la información${NC}\n"
			echo "${ejemploUso}"
			exit 1
			
	elif ! [[ $mail =~ $checkMail ]]; then
			echo -e "${RED}[!]${NC} ${WHITE}El CORREO introducido (${RED}${mail}${NC}) ${WHITE}no cumple la expresión regular de un correo válido${NC}\n"
			echo "${ejemploUso}"
			exit 1
	fi
}

# Comprobamos si tenemos salida a Internet para descargar paquetes y archivos necesarios
checkInternet(){
	wget -q --tries=10 --timeout=20 --spider google.com
	if [[ $? -ne 0 ]]; then
			echo -e "${RED}[!]${NC} ${WHITE}No tienes salida a Internet !${NC}"
			exit 1
	fi
}

# Función donde si tenemos Internet, descargamos 'full_city_list'. Archivo con la información
# de las ciudades donde obtendremos el código. En la función´ 'checkInternet', si no se tiene salida
# finaliza el scrip (exit 1).
#
# Después de comprobar si tenemos red, en caso de tener, se comprueba que podemos comunicar con el 
# servidor que provee el archivo 'full_city_list'. Si podemos comunicar con el servidor, comprobamos
# si ya existe el archivo. Si existe, lo eliminamos y lo descargamos de nuevo (para mantener la info actualizada).
# Si el archivo no existe, simplemente lo descargamos
# 
# Finalmente, si no podemos comunicar con el servidor para descargar el archivo, se informa al usuario de esto.
# Si ya existe un archivo antiguo, se le pregunta si quiere seguir con este teniendo en cuenta que la info puede no
# estar actualizada.
getCityListData(){
	checkInternet
	
	wget -q --tries=10 --timeout=20 --spider worldweather.wmo.int
	if [[ $? -eq 0 ]]; then
			if [[ ! -f ./full_city_list.txt ]]; then
				wget https://worldweather.wmo.int/es/json/full_city_list.txt > /dev/null 2>&1
			else
				rm ./full_city_list.txt
				wget https://worldweather.wmo.int/es/json/full_city_list.txt > /dev/null 2>&1
			fi
	else
		echo -e "${RED}[!]${NC} ${WHITE}No hemos podido comunicar con el servidor proveedor de información !${NC}"
		if [[ ! -f ./full_city_list.txt ]]; then
			echo -e "\n\t${RED}[!]${NC} ${WHITE}No existe un archivo antiguo, no podemos ejecutar el script !${NC}"
			sleep 2
		else
			echo -e "\n\t${RED}[!]${NC} ${WHITE}Existe un archivo antiguo, es posible que la información no este actualizada !${NC}"
			echo -e "\n\t${WHITE}[*] Quieres consultar la información desactualizada ?${NC}"
	
			# Array con respuestas validas SI o NO para ejecutar instalar paquetes necesarios
			YES=(s si yes y)
			
			read ANSWER
			
			ANSWER=$(echo $ANSWER | tr '[:upper:]' '[:lower:]')

			# Si la respuesta a la pregunta anterior es SI iniciamos instalación de paquetes
			if [[ "${YES[*]}" =~ ${ANSWER} ]]; then
				echo -e "${GREEN}[*]${NC} ${WHITE}Continuando con archivo no actualizado...${NC}"
			else
				echo -e "${RED}[!]${NC} ${WHITE}Saliendo...${NC}"
				sleep 2
			fi
			sleep 2
		fi
	fi
	
}

# Función donde comprobamos que el usuario tenga instalado en el sistema los paquetes 
# necesarios para ejecutar el script. En caso de no contar con estos, se pregunta
# al usuario si quiere instalarlos.
checkRequirements(){
	echo -e "${GREEN}[*]${NC} ${WHITE}Comprobando requisitos...\n${NC}"

	neededPackages=(
		jq
		wget
		#mailutils
	)
		
	missingPackages=()
		
	for package in "${neededPackages[@]}"
	do
		dpkg -s $package > /dev/null 2>&1
		
		if [[ $? -ne 0 ]]; then
			missingPackages+=($package)
		fi
		
	done
		
	if [ ${#missingPackages[@]} -ne 0 ]; then
		echo -e "${RED}[!]${NC} ${WHITE}Faltan paquetes para ejecutar el script !\n${NC}"
			
		echo -e "${GREEN}[*]${NC} ${WHITE}Paquetes a instalar${NC}"
		echo -e "${WHITE}=======================${NC}"
		
		for missingPackage in "${missingPackages[@]}"
		do
			echo -e "${GREEN}[+]${NC} ${WHITE}${missingPackage}${NC}"
		done
		
		# Array con respuestas validas SI o NO para ejecutar instalar paquetes necesarios
		YES=(s si yes y)

		# Preguntamos si queremos instalar los paquetes
		echo -e "\n${GREEN}[?]${NC}${WHITE} Quieres instalar los paquetes ? [S/n] ${NC}"
		read ANSWER
		
		ANSWER=$(echo $ANSWER | tr '[:upper:]' '[:lower:]')

		# Si la respuesta a la pregunta anterior es SI iniciamos instalación de paquetes
		if [[ "${YES[*]}" =~ ${ANSWER} ]]; then
			checkInternet
			for missingPackage in "${missingPackages[@]}"
			do
				echo -e "\t${GREEN}[*]${NC}${WHITE} Instalando${NC} ${GREEN}${missingPackage}${NC}"
				apt install -y ${missingPackage} > /dev/null 2>&1
				if [[ $? -eq 0 ]]; then
					echo -e "\n\t\t${GREEN}[+]${NC}${WHITE} Paquete ${NC}${GREEN}${missingPackage}${NC} ${WHITE}instalado${NC}\n"
				else
					echo -e "\n\t\t${RED}[!]${NC}${WHITE} No se ha podido instalar${NC} ${RED}${missingPackage}${NC}\n"
				fi
			done
			clear
			checkRequirements
		else
			echo -e "\n\tt${RED}[!]${NC}${WHITE} Has decidido no instalar las dependencias para ejecutar el script\n${NC}"
			sleep 3
			clear
			exit 1
		fi
	else
		echo -e "\t${GREEN}[*]${NC} ${WHITE}Requisitos disponibles\n${NC}"
		getCityListData
	fi
	
	sleep 1
}

# Función donde obtenemos el código de la ciudad según los parametros entrados.
# Una vez se obtiene el código, se descarga el archivo .xml que corresponde al código 
# de la ciudad extraido 
getData(){
	echo -e "${GREEN}[*]${NC} ${WHITE}Descargando información de ciudad...\n${NC}"
	sleep 1

	IN=$(grep -iF "\"${pais}\";\"${ciudad}\"" full_city_list.txt)
	
	if [[ $? -ne 0 ]]; then
		echo -e "\t${RED}[!]${NC} ${WHITE}No hemos encontrado ninguna coincidencia.\n\n\tAsegurate que has introducido los valores correctamente :"
		echo -e "\n\t\t${GREEN}PAIS${NC} : ${WHITE}${pais}${NC}\n\n\t\t${GREEN}CIUDAD${NC} : ${WHITE}${ciudad}${NC}"
		echo -e "\n\t${GREEN}[*]${NC} ${WHITE}INFO : Mayus. y minus. no influyen en la busqueda.${NC}\n"
		exit 1
	else
		echo -e "\t${GREEN}[*]${NC} ${WHITE}Información de ciudad obtenida${NC}\n"
	fi
	
	IFS=';' read -ra OUTPUT <<< "$IN"
	AUXCODE="${OUTPUT[2]}"
	
	CODE=$(echo "${AUXCODE}" | cut -d '"' -f 2)
	
	checkInternet
	
	url="http://wwis.aemet.es/es/json/${CODE}_es.xml"
	
	if [[ ! -f "${CODE}_es.xml" ]]; then
        wget "${url}" > /dev/null 2>&1
	else
		rm ${CODE}_es.xml
		wget "${url}" > /dev/null 2>&1
	fi

	# Sanitizamos
    cat ${CODE}_es.xml | jq >> aux
    mv aux ${CODE}_es.xml
	
	printWeather "${CODE}"
} 

# Función donde se pregunta al usuario cuantos dias quieres mostrar el tiempo (max. 4)
# se realizan ciertas comprobaciones de errores básicas y se imprime el resultado del tiempo
# de los días indicado.
#
# Esta función recibe el código de la ciudad por parametro pasada en la función 'getData()'
printWeather(){
	echo -e "${GREEN}[*]${NC} ${WHITE}Introduce número de días a mostrar el tiempo : (4 max.)\n${NC}"
	echo -e "${GREEN}[*]${NC} ${WHITE}1 = Hoy | 2 = Mañana | 3 = Pasado Mañana | 4 = Pasado Pasado Mañana${NC}\n"
	read -p "Elige una opción : " DIAS_MOSTRAR

	checkint='^[0-9]+$'
	
	while ! [[ $DIAS_MOSTRAR =~ $checkint ]];
	do
		clear
		echo -e "${RED}[!]${NC} ${GREEN}$DIAS_MOSTRAR${NC} ${WHITE}No es un número o es un número inferior a 0!\n${NC}"
		echo -e "${GREEN}[*]${NC} ${WHITE}Introduce número de días a mostrar el tiempo : (4 max.)${NC}\n"
		echo -e "${GREEN}[*]${NC} ${WHITE}1 = Hoy | 2 = Mañana | 3 = Pasado Mañana | 4 = Pasado Pasado Mañana${NC}\n"
		read -p "Elige una opción : " DIAS_MOSTRAR
	done

	if [[ $DIAS_MOSTRAR -gt 4 ]]; then
		echo -e "${RED}[!]${NC} ${WHITE}Has excedido el número máximo de días a mostrar (4 max.) !${NC} Has introducido : ${GREEN}($DIAS_MOSTRAR)\n${NC}${WHITE}días${NC}"
		echo -e "${RED}[!]${NC} ${WHITE}Saliendo...${NC}"
		exit 1
	fi
	
	clear
	
	DIAS_MOSTRAR="$(($DIAS_MOSTRAR-1))"
	x=0
	while [ $x -le $DIAS_MOSTRAR ]
	do
		FECHA=$(cat ${CODE}_es.xml | jq '.city.forecast.forecastDay['${x}'].forecastDate')
		TIEMPO=$(cat ${CODE}_es.xml | jq '.city.forecast.forecastDay['${x}'].weather')
		MAXTEMP=$(cat ${CODE}_es.xml | jq '.city.forecast.forecastDay['${x}'].maxTemp')
		MINTEMP=$(cat ${CODE}_es.xml | jq '.city.forecast.forecastDay['${x}'].minTemp')

		echo -e "\n\t ${GREEN}[*]${NC} ${WHITE}Mostrando información del día ${NC}${GREEN}${FECHA}${NC}"
		echo -e "\n\t\t${GREEN}[*]${NC} ${WHITE}Tiempo : ${TIEMPO}${NC}"
		echo -e "\n\t\t${GREEN}[*]${NC} ${WHITE}Temperatura Maxima : ${MAXTEMP}${NC}"
		echo -e "\n\t\t${GREEN}[*]${NC} ${WHITE}Temperatura Minima : ${MINTEMP}${NC}\n"
		
		x=$(( $x + 1 ))
	done
	
	read -n 1 -s -r -p "Presiona cualquiera tecla para cerrar el script..."
	
	echo -e "\n"
}

# Transformamos los parametros en variables
pais="$1"
ciudad="$2"
mail="$3"

# Llamamos a la función 'checkParams' pasando las variables anteriores como parametros
checkParams "$pais" "$ciudad" "$mail"

# Llamamos a la función 'checkRequirements' donde comprobamos que se tienen los
# paquetes necesarios para ejecutar el script instalados. Si no estan instalados
# se pregunta al usuario si quiere instalarlos.
checkRequirements

# Descargamos el archivo .xml correspondienta a los valores entrados.
getData "$pais" "$ciudad" "$mail"
