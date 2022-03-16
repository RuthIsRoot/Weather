#!/bin/bash

# Declaración variables colores output
WHITE='\033[1;37m'
GREEN='\033[1;32m'
RED='\033[1;31m'
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
NC='\033[0m' # No Color

# Comprobamos si tenemos salida a Internet para descargar paquetes
checkInternet(){
	wget -q --tries=10 --timeout=20 --spider http://google.com
	if [[ $? -ne 0 ]]; then
			echo -e "${RED}[!]${NC} ${WHITE}No tienes salida a Internet !${NC}"
			exit 1
	fi
}

checkRequirements(){
	neededPackages=(
		jq
		wget
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
			
		echo -e "${GREEN}[*]${NC} ${WHITE}Paquetes${NC}"
		echo -e "${WHITE}=============${NC}"
		
		for missingPackage in "${missingPackages[@]}"
		do
			echo -e "${GREEN}[+]${NC} ${WHITE}${missingPackage}${NC}"
		done
		
		# Array con respuestas validas SI o NO para ejecutar instalar paquetes necesarios
		YES=(Si Yes S Y)

		# Preguntamos si queremos instalar los paquetes
		echo -e "\n${GREEN}[?]${NC}${WHITE} Quieres instalar los paquetes ? [S/n] ${NC}"
		read ANSWER

		# Si la respuesta a la pregunta anterior es SI iniciamos el proceso de Backups
		if [[ "${YES[*]}" =~ ${ANSWER} ]]; then
			for missingPackage in "${missingPackages[@]}"
			do
				echo -e "\n\t${GREEN}[*]${NC}${WHITE} Instalando${NC} ${GREEN}${missingPackage}${NC}"
				apt install -y ${missingPackage} > /dev/null 2>&1
				#FALTA ACABAR ESTO
			done
		fi
		
		
}

# Descargamos info. del tiempo si tenemos red
getData(){
	checkInternet
	wget https://worldweather.wmo.int/es/json/full_city_list.txt > /dev/null 2>&1
}

# Comprobamos que se han introducido los parametros necesarios para el script.
# También se mira que los tipos de datos entrados tengan el formato correcto.
checkParams(){
		clear
		ejemploUso=$(echo -e "${GREEN}Ejemplo de uso : ${NC}${WHITE}./weather.sh España Barcelona correo@dominio.x\n${NC}")
		checkint='^[0-9]+$'
		if [ -z "$pais" ]; then
				echo -e "${RED}[!]${NC} ${WHITE}No has pasado el ${RED}PAIS${NC} ${WHITE}por parametro\n${NC}"
				echo "${ejemploUso}"
				exit 1
		elif [ -z "$ciudad" ]; then
				echo -e "${RED}[!]${NC} ${WHITE}No has pasado la ${RED}CIUDAD${NC} ${WHITE}por parametro\n${NC}"
				echo "${ejemploUso}"
				exit 1
		elif [ -z "$mail" ]; then
				echo -e "${RED}[!]${NC} ${WHITE}No has introducido el ${RED}CORREO${NC} ${WHITE}para enviarte la información${NC}\n"
				echo "${ejemploUso}"
				exit 1
		fi
}

# Transformamos los parametros en variables
pais="$1"
ciudad="$2"
mail="$3"

# Llamamos a la función 'checkParams' pasando las variables anteriores como parametros
checkParams "$pais" "$ciudad" "$mail"

checkRequirements

# Descargamos el archivo con información del tiempo
getData
