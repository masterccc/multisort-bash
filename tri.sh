#!/bin/bash

mode_debug=0 #affiche les messages de debug

. heapsort.sh
#fonctions

function saveIFS(){
	savIFS="$IFS"
}
function restoreIFS(){
	IFS="$savIFS"
}

function dbmsg(){
	[[ $mode_debug -gt "0" ]] &&  >&2 echo "[DEBUG] $1"
}

function getColumn(){ #récupére la colonne $2 dans $1
	echo "$1" | cut -d\  -f$2
}

function getExtension(){ # $1 = chemin/vers/nomfichier  $2 = nomfichier
	[[ ! -f "$1" ]] && echo "UNDEFINED" && exit 0
	[[ ! `echo "$1" | grep "\."` ]] && echo "$2" || echo "$1" | rev | cut -d. -f1 | rev
}

function manualShift(){ #shift $1 avec le delimiteur [espace]
	echo "$1" | cut -d\  -f2-
}

function getNextPrioritySort(){ # Récupére la prochaine option de tri à traiter

	[[ ! "$static_PrioritySort" -le "$opt_number" ]] && echo "" && exit 1

	while [ true ]
	do
		for var in "type" "name" "size" "date" "lines" "ext" "owner" "group"
		do
			varname="tri_$var"
			if test "${!varname}" = "$static_PrioritySort"
			then

			static_PrioritySort="$static_PrioritySort"
				case "$var" in
					"type") echo "$var 1 spe $static_PrioritySort" && exit 0 ;;
					"name") echo "$var 2 str $static_PrioritySort" && exit 0 ;;
					"size") echo "$var $col_size int $static_PrioritySort" && exit 0 ;;
					"date") echo "$var $col_date int $static_PrioritySort" && exit 0 ;;
					"lines") echo "$var $col_lines int $static_PrioritySort" && exit 0 ;;
					"ext") echo "$var $col_ext str $static_PrioritySort" && exit 0 ;;
					"owner") echo "$var $col_owner str $static_PrioritySort"&& exit 0  ;;
					"group") echo "$var $col_group str $static_PrioritySort" && exit 0 ;;
				esac
			fi
		done
		static_PrioritySort="`expr $static_PrioritySort + 1`"
	done
}

function setOptions(){ #reçoit -snmpletg
	
	local i="2" #1 = type 2 = name	
	local icol="2"
	local opt="`sed -e 's/\(.\)/\1 /g' <<< \"$1\"`" #sépare les lettres
	local opt="`manualShift \"$opt\"`"
	
	for lettre in $opt
	do
		i=$[$i+1]

		case "$lettre" in
			"n") tri_name="$i" && col_name=2 && i=$[$i-1];; # colone 2 #tri name = priorité de tri de name
			"s") tri_size="$i" && col_size=$tri_size && cmdline="$cmdline $cmd_size" && headline="$headline\tsize";;
			"m") tri_date="$i" && col_date=$tri_date && cmdline="$cmdline $cmd_date" && headline="$headline\tdate";;
			"l") tri_lines="$i" && col_lines=$tri_lines && cmdline="$cmdline $cmd_lines" && headline="$headline\tlines" ;;
			"e") tri_ext="$i" && col_ext=$tri_ext && cmdline="$cmdline $cmd_ext" && headline="$headline\text" ;;
			"t") tri_type="$i" && col_type=1 && i=$[$i-1] ;;
			"p") tri_owner="$i" && col_owner=$tri_owner && cmdline="$cmdline $cmd_owner" && headline="$headline\towner";;
			"g") tri_group="$i" && col_group=$tri_group && cmdline="$cmdline $cmd_group" && headline="$headline\tgroup" ;;
			"*") echo "Unknow option <'$lettre'>" ;;
		esac
	done

	opt_number="$i"
	dbmsg "Nombre d'options(tri) : $opt_number"
}

function getFileList(){ #$1 = repertoire à parcourir
	
	local liste=""

	for element in "$1"/*
	do
	    #type nom taille date lignes extension proprio groupe
	    cmdfile="$cmdline"
	    local fichier=""
	   	name="`basename $element`" #basename pour éviter d'avoir le chemin complet)

	   	if [ -d "$element" ]
	   	then
	   		echo -n "d $name "
	   		
	   		cmdfile="echo $cmdfile"
	   		eval $cmdfile
			fichier="d" && [[ "$recursif" -gt "0" ]] && getFileList "$element" #dossier	
			continue
		fi


		[[ -f "$element" ]] && fichier="-" #fichier
		[[ -L "$element" ]] && fichier="l" #lien sym.
		[[ -b "$element" ]] && fichier="b" #bloc
		[[ -c "$element" ]] && fichier="c" #car
		[[ -p "$element" ]] && fichier="p" #pipe
		[[ -S "$element" ]] && fichier="s" #socket

		fichier="$fichier $name" 
		
		#options déja lues donc on ajoute le nom/type DEVANT
		
		cmdfile="$fichier $cmdfile"
		cmdfile="echo $cmdfile"
		cmdfile="`echo $cmdfile | sed 's/ \{2,\}/ /'`"
		
		eval "$cmdfile"
		
	done 
}

function getLinesNumber(){
	# renvoie le nombre de lignes d'un fichier  ou UNDEFINED si dossier
	[[ -f "$1" ]] && wc -l < "$1" || echo "UNDEFINED"
}


function getlinewithcolequals(){ #retourne la ligne de la liste $1 dont la colonne $2 vaut $3

	savIFS="$IFS"
	IFS="
"
	for element in $1
	do
		[[ "`echo \"$element\" | cut -d\  -f$2 `" = "$3" ]] && echo "$element" && IFS="$savIFS" && exit 0
	done
}


function triCol(){

	#$1 = liste à trier
	#$2 = colonne à partir de laquelle effectuer le tri
	#$3 = type de la colonne

	liste="$1"

	values="`echo "$liste" | cut -d\  -f$2`"
	values="`echo $values | sed 's/\n/ /g' `" # ex:  "45 12 4 15 32 5"
	values=`echo $values | sed 's/UNDEFINED/-1/g'`

	echo "envoie au tri : <$values>" >> log
	[[ "$3" = "int" ]] && values="`heapSortNb $values`" 
	[[ "$3" = "spe" ]] && values="`heapSortFile $values`"
	[[ "$3" = "str" ]] && values="`heapSortWords $values`"

	values="`echo $values | tr '\n' ' '`"
	values="`echo $values | sed 's/-1/UNDEFINED/g'`"

	[[ "$tri_decroissant" -gt "0" ]] && values="`heapSortReverse $values`"

	for element in $values
	do
		lin=`getlinewithcolequals "$liste" "$2" "$element"` # on récupérer la ligne dont la colonne 2 == $element
		tri="`echo -e \"$tri\n$lin\"`" 
		liste="`echo \"$liste\" | sed '0,/'"$lin"'/{/'"$lin"'/d;}'`"
	done

	echo "$tri"
}


function setNextSort(){

	#dbmsg "static_PrioritySort avant : $static_PrioritySort"
	next_sort="`getNextPrioritySort`"
	next_sort_col="`echo $next_sort | cut -d\  -f2`"
	next_sort_type="`echo $next_sort | cut -d\  -f3`"
	next_sort_name="`echo $next_sort | cut -d\  -f1`"
	static_PrioritySort="`echo $next_sort | cut -d\  -f4`"
	static_PrioritySort="`expr $static_PrioritySort + 1`"

}

function groupit(){

	#regroupes les elements de la liste $1 à partir de la colone n°$2
	local begin=1

	IFS="
"

	for line in $1
	do
		local value="`echo $line | cut -d\  -f$2 `"
		[ "$begin" = "1" ] && lliste="$line" && old="$value" && begin="0" && continue
		
		if [ "$value" = "$old" ] 
		then
			lliste="`echo -e \"$lliste\n$line\"`"
		else
			lliste="$lliste:"
			lliste="`echo -e \"$lliste$line\"`"
			old="$value"
		fi
	done

	echo "$lliste"
}

function init_default_sort(){
	opt_number=3
	tri_name=3
}


function makeatablepliz(){
	echo -e "$headline"

	IFS="
"
	if [ "$tri_date" -gt "0" ]
		then
		for line in $liste_triee
		do

			ts="`echo $line | sed -e 's/.*\([0-9]\{10\}\).*/\1/'`"
			ladate="`date -d @$ts +"%d\&%m\&%Y"_%H:%M:%S`"
			echo "$line" | sed 's/\([0-9]\{10\}\)/'"$ladate"'/g' | sed 's/\&/\//g'

		done
		else
			for line in $liste_triee
		do
			echo "$line"
		done
	fi
}


#valeurs par défaut

recursif=0
tri_decroissant=0
cible=""

tri_name=0
tri_size=0 
tri_date=0
tri_lines=0
tri_ext=0
tri_type=0
tri_owner=0
tri_group=0

col_type=1
col_name=2
col_size=0 
col_date=0
col_lines=0
col_ext=0
col_owner=0
col_group=0

#commandes pour créer les colonnes
cmd_date='`stat -c "%Y" "$element"`'
cmd_size='`du -b "$element" | head -n 1 |  cut -f1`'
cmd_lines='`getLinesNumber "$element"`'
cmd_ext='`getExtension "$element" "$name"`'
cmd_owner='`stat -c "%U" "$element"`'
cmd_group='`stat -c "%G" "$element"`'

#autres variables

static_PrioritySort=1
cmdline=""
headline="type\tname"

#Récupération des parametres
while test "$#" -gt "0"
do
	dbmsg "Lecture option : <$1>"
	case "$1" in
	"-R") recursif=1 ;;
	"-d") tri_decroissant=1 ;;
	-[nsmletpg]*) setOptions "$1" ;;
	*) cible="$1" #dossier
	esac
	shift
done

#gestion d'erreurs 

[[ -z "$cible" ]] && echo "usage : ./$0 [-R] [-d] [-nsmleptg] rep" && exit 1
[[ ! -d "$cible" ]] && echo "<$cible> n'est pas un répertoire." && exit 1

#Debug - affichage des parametres

dbmsg "recursif : $recursif tri_decroissant : $tri_decroissant"
dbmsg "cible : $cible"

[[ "$opt_number" -eq 0 ]] && init_default_sort && echo "Tri par défaut : trier par nom"



dbmsg "tri_name=$tri_name"
dbmsg "tri_size=$tri_size"
dbmsg "tri_date=$tri_date"
dbmsg "tri_lines=$tri_lines"
dbmsg "tri_ext=$tri_ext"
dbmsg "tri_type=$tri_type"
dbmsg "tri_owner=$tri_owner"
dbmsg "tri_group=$tri_group"

dbmsg "col_name=$col_name"
dbmsg "col_size=$col_size"
dbmsg "col_date=$col_date"
dbmsg "col_lines=$col_lines"
dbmsg "col_ext=$col_ext"
dbmsg "col_type=$col_type"
dbmsg "col_owner=$col_owner"
dbmsg "col_group=$col_group"

# Début du programme principal

saveIFS
setNextSort # MàJ des variables next_sort_*

#On applique le premier tri ici :
dbmsg "Critère du tri principal : $next_sort (colone $next_sort_col) ($next_sort_type)"

liste_elements=`getFileList "$cible"` # récupére les fichiers à trier

dbmsg "liste non triée : <$liste_elements>"

liste_triee="`triCol \"$liste_elements\" \"$next_sort_col\" \"$next_sort_type\"`"

#Fin du premier tri

dbmsg "=========== PREMIER TRI ================"
dbmsg "$liste_triee"
dbmsg "========================================"

#Pour chaque autre tri :

dbmsg "bla $static_PrioritySort $opt_number" 

while [ "$static_PrioritySort" -le "$opt_number" ]
do
	dbmsg "=========== AVANT TRI ================"
	dbmsg "$liste_triee"
	#On crée des sous_listes à partir de la grosse liste
	#et ce, en fonction de la colonne triée precedemment
	dbmsg "Groupement par $next_sort"
	souslistes="`groupit \"$liste_triee\" \"$next_sort_col\"`"

	setNextSort # MàJ des variables next_sort_*
	dbmsg "Critère du tri suivant : $next_sort"
	tmp_liste=""
	saveIFS
	IFS=":"

	for sliste in $souslistes
	do

		IFS=" "
		nblines="`echo \"$sliste\" | wc -l`"
		
		#une seule ligne -> pas de tri, on ajoute à la liste triée
		[[ "$nblines" = "1" ]] && tmp_liste="`echo -e \"$tmp_liste\n$sliste\"`" && continue
	
		#sinon on envoie la liste au tri et on l'ajoute à la liste triée :
		tmp_tri="`triCol \"$sliste\" \"$next_sort_col\" \"$next_sort_type\"`"
		tmp_liste="`echo -e \"$tmp_liste\"\"$tmp_tri\n\"`"
	done
	liste_triee="$tmp_liste"

	dbmsg "=========== APRES TRI ================"
	dbmsg "$liste_triee"

done


#Affichage de la liste des fichiers


makeatablepliz | column -t