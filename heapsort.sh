#!/bin/bash

supprime1erElem(){
	#Fonction qui supprime le 1er élément de la liste fournie en paramètre et qui renvoie cette liste.
	#on découpe la liste par des espaces et on récupère la nouvelle liste à partir du 2eme élément
	[[ "$#" -eq 1 ]] && echo "" && return || echo "$*" | cut -d\  -f2- 
}
donne1erElem(){
	#A partir d'une liste constituée d'au moins 1 élément, on retourne le 1er élément
	echo "$1"
}

nbreElemList(){
	#Fonction qui compte le nombre d'éléments dans la liste fournie en paramètre
	local sav="$*"
	set -- $1
	echo "$#"
	set -- $sav
}

leftSon(){
	#La fonction reçoit un parametre un nombre qui correspond à l'indice d'une valeur. Elle retourne l'indice du fils gauche de cette valeur
	echo $[ $1 * 2 ]
}

rightSon(){
	#La fonction reçoit un parametre un nombre qui correspond à l'indice d'une valeur. Elle retourne l'indice du fils droit de cette valeur
	echo $[ $1 * 2 + 1]
}

father(){
	#La fonction reçoit un parametre un nombre qui correspond à l'indice d'une valeur. Elle retourne l'indice du pere de cette valeur
	echo $[ $1 / 2 ]
}

getVal(){
	#$1 contient l'indice. À partir de $2, on a la liste de valeurs. On retourne la valeur située à l'indice $1. Les valeurs de la liste peuvent être des nombres ou des mots. Retourne 0 si l'indice ne peut pas correspondre à la liste
	
	local indice=$[$1+1]
	[[ "$#" -gt 0 ]] && echo "${!indice}" || echo 0
}

setVal(){
	#dans $1 il y a l'indice de la valeur que l'on souhaite modifier. Dans $2 il a la nouvelle valeur et à partir de $3 il y a la liste des valeurs. On retourne la liste avec la valeur modifiée
	local val=$2
	local indice=$1

	shift
	shift
	list="$*"

	local newList=""
	local i=1
	local elem
	[[ $indice -eq 1 ]] && list=`supprime1erElem $list`&& echo "$val $list" && return #cas où l'indice vaut 1 et que l'on souhaite donc modifie le 1er élément
	while [ $i -lt $indice ]
	do
		elem=`donne1erElem $list`
		[[ $i -eq 1 ]] && newList="$elem" || newList="$newList $elem"
		list=`supprime1erElem $list`
		i=$[$i+1]
	done
	newList="$newList $val"
	list=`supprime1erElem $list`
	echo "$newList $list"
}	

swap(){
	#$1 contient l'indice à échanger avec l'indice fourni par $2. La liste démarre à $3. On ne peut pas faire de grep à cause des doublons. Ce switch fonctionne si les valeurs de la liste sont des nombres ou des mots
	local indice1="$1"
	local indice2="$2"
	shift
	shift
	local list="$*"
	local val1=`getVal $indice1 $list`
	local val2=`getVal $indice2 $list`
	list=`setVal $indice1 $val2 $list`
	list=`setVal $indice2 $val1 $list`
	echo "$list"
}

addToHeap(){
	#ajoute l'élément $1 à la liste démarrant à $2. On considère que la liste est déjà un tas. On retourne le tas avec le nouvel élément ajouté
	local elem=$1
	shift
	local list="$*"
	list="$list $elem" #on met l'élément à la fin
	local i=$["$#"+1]

	local father=`father $i`
	while [ $i -gt 1 ] && [ `getVal $father $list` -lt `getVal $i $list` ]
	do
		list=`swap $i $father $list`
		i=`father $i`
		father=`father $i`
	done
	echo "$list"
}

addToHeapWords(){
	#ajoute l'élément $1 à la liste démarrant à $2. On considère que la liste est déjà un tas. On retourne le tas avec le nouvel élément ajouté
	local elem=$1
	local list=`supprime1erElem $*`
	list="$list $elem" #on met l'élément à la fin
	local i=`nbreElemList "$list"`
	local father=`father $i`
	while [ $i -gt 1 ] && [ `getVal $father $list` \< `getVal $i $list` ]
	do
		list=`swap $i $father $list`
		i=`father $i`
		father=`father $i`
	done
	echo "$list"
}

createHeapWords(){
	#Permet de créer un tas à partir d'une liste donnée en paramètre. Les éléments de la liste sont des mots.
	local list=`supprime1erElem $*`
	local nbreElem=`nbreElemList "$list"`
	local list2=$1
	local val
	while [ $nbreElem -gt 0 ]
	do
		val=`getVal 1 $list`
		list2=`addToHeapWords $val $list2`
		list=`supprime1erElem $list`
		nbreElem=`nbreElemList "$list"`
	done
	echo "$list2"
}


createHeap(){
	#Permet de créer un tas à partir d'une liste donnée en paramètre. Les éléments de la liste sont des nombres.
	local list=`supprime1erElem $*`
	local nbreElem=$[ "$#" - 1 ]

	local list2=$1
	local val
	while [ $nbreElem -gt 0 ]
	do
		val=`getVal 1 $list`
		list2=`addToHeap $val $list2`
		list=`supprime1erElem $list`
		nbreElem=`nbreElemList "$list"`
	done
	echo "$list2"
}

removeLastElem(){
	#fonction qui supprime le dernier élément d'un tas
	local list2=$1
	shift
	while [ $# -gt 1 ]
	do
		list2="$list2 $1"
		shift
	done
	echo "$list2"
}

maxHeap(){
	#Fonction qui enlève le max du tas fourni en paramètre et qui réorganise le tas. Les éléments sont des nombres.
	local nbElem="$#"
	local list=`swap 1 $nbElem $*`
	
	#on supprime le maximum
	list=`removeLastElem $list`
	nbElem=`nbreElemList "$list"`
	
	#on réorganise le tas
	local i=1
	local j
	local fin=0
	local lSon
	local rSon
	while [ $fin -eq 0 ] && [ $i -le $[$nbElem/2] ]
	do
		lSon=`leftSon $i`
		rSon=`rightSon $i`
		if [ $lSon -eq $nbElem ] || [ `getVal $lSon $list` -gt `getVal $rSon $list` ]
		then
			j=$lSon
		else
			j=$rSon
		fi
		if [ `getVal $i $list` -gt `getVal $j $list` ]
		then
			fin=1
		fi
		if [ $fin -eq 0 ]
		then
			list=`swap $i $j $list`
		fi
		i=$j
	done
	echo "$list"
}

maxHeapWords(){
	#Fonction qui enlève le max du tas fourni en paramètre et qui réorganise le tas. Les éléments sont des mots
	local nbElem=`nbreElemList "$*"`
	local list=`swap 1 $nbElem $*`
	#on supprime le maximuum
	list=`removeLastElem $list`
	nbElem=`nbreElemList "$list"`
	#on réorganise le tas
	local i=1
	local j
	local fin=0
	local lSon
	local rSon
	while [ $fin -eq 0 ] && [ $i -le `expr $nbElem / 2` ]
	do
		lSon=`leftSon $i`
		rSon=`rightSon $i`
		if [ $lSon -eq $nbElem ] || [ `getVal $lSon $list` \> `getVal $rSon $list` ]
		then
			j=$lSon
		else
			j=$rSon
		fi
		if [ `getVal $i $list` \> `getVal $j $list` ]
		then
			fin=1
		fi
		if [ $fin -eq 0 ]
		then
			list=`swap $i $j $list`
		fi
		i=$j
	done
	echo "$list"
}

heapSortWords(){
	#tri par tas sur des mots. Retourne la liste dans l'ordre alphabétique
	local max
	local list2=""
	local n=`nbreElemList "$*"`
	#on crée le tas
	local tas=`createHeapWords $*`
	#on trie le tas
	while [ $n -ge 1 ]
	do
		list2="`getVal 1 $tas` $list2"
		tas=`maxHeapWords $tas`
		n=`expr $n - 1`
	done
	echo "$list2"
}

heapSortNb(){
	#tri par tas sur des nombres. Retourne la liste dans l'ordre croissant
	local max
	local list2=""
	local n="$#"
	
	#on crée le tas
	local tas=`createHeap $*`
	
	#on trie le tas
	while [ $n -ge 1 ]
	do
		list2="`getVal 1 $tas` $list2"
		tas=`maxHeap $tas`
		n=$[$n-1]
	done
	echo "$list2"
}

heapSortReverse(){
	#Fonction qui donne l'ordre inverse.
	local i
	local reverse=""
	for i in $*
	do
		reverse="$i $reverse"
	done
	echo "$reverse"
}

heapSortFile(){
	#Fonction qui trie suivant le type de fichier
	local list=$*
	list=`echo "$list" | tr 'd' '1' | tr '-' '2' | tr 'l' '3' | tr 'b' '4' | tr 'c' '5' | tr 'p' '6' | tr 's' '7'` 
	list=`heapSortNb $list`
	list=`echo "$list" | tr '1' 'd' | tr '2' '-' | tr '3' 'l' | tr '4' 'b' | tr '5' 'c' | tr '6' 'p' | tr '7' 's'`
	echo "$list"
}