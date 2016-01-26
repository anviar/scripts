#!/bin/bash

USAGE="Usage:\n\t$0 [-e] [action] required_strings files
Here is:
	-e	Process considering file extensions, optional.
Actions can be:
	-a|--add string			add string at the end of filenames
	-p|--prefix string		add string at the begining of filenames
	-r|--replace string to_string	replace string to string"

if [[ -z $1 ]]
then
	echo -e "${USAGE}"
	exit 1
fi

while (( "$#" )); do
	case $1 in
		"--extension"|"-e" )
		        fextension=1
		        shift
		;;
		"--prefix"|"-p" )
			faction=Prefix
                        if [[ -z $3 ]]
                        then
				echo "Error in syntax"
                                echo -e "${USAGE}"
                                exit 1
			fi
			fstring=$2
			shift; shift
			break
		;;
		"--add"|"-a" )
			faction=Add
			if [[ -z $3 ]]
			then
				echo "Error in syntax"
                                echo -e "${USAGE}"
                                exit 1
			fi
			fstring=$2
			shift; shift
			break
		;;
		"--delete"|"-d" )
			faction=Delete
			if [[ -z $3 ]]
			then
				echo "Error in syntax"
				echo -e "${USAGE}"
				exit 1
			fi
			fstring=$2
			shift; shift
			break
		;;
		"--replace"|"-r" )
			faction=Replace
			if [[ -z $4 ]]
			then
				echo "Error in syntax"
				echo -e "${USAGE}"
				exit 1
			fi
			fstring=$2
			fstringr=$3
			shift; shift; shift
			break
		;;
		* )
			echo "Warrning: skipped input \"$1\""
			shift
		;;
	esac
done

echo "Debug: action is \"$faction\", string is \"${fstring}\" and may be \"${fstringr}\""

# processing files
for file in $@
do
	if [[ ! -f ${file} ]]
	then
		echo "Error: ${file} not found"
		continue
	fi
	case ${faction} in
		"Add" )
			if [[ ${fextension} ]]
			then
				extension=$([[ "${file}" = *.* ]] && echo ".${file##*.}" || echo '')
				mv --verbose --interactive ${file} ${file%.*}${fstring}${extension}
			else
				mv --verbose --interactive ${file} ${file}${fstring}
			fi
		;;
		"Prefix" )
			mv --verbose --interactive ${file} $(dirname ${file})/${fstring}$(basename ${file})
		;;
		"Delete" )
			if [[ ${fextension} ]]
			then
				extension=$([[ "${file}" = *.* ]] && echo ".${file##*.}" || echo '')
				fname=$(basename ${file%.*})
			else
				fname=$(basename ${file})
			fi

			if [[ "${fname}" == *${fstring}* ]]
			then
				fnamedst=$(echo ${fname}|sed s/${fstring}//g)${extension}
				mv --verbose --interactive ${file} $(dirname ${file})/${fnamedst}
			else
				echo ${file} skipped
			fi
		;;
		"Replace" )
                        if [[ ${fextension} ]]
                        then
                                extension=$([[ "${file}" = *.* ]] && echo ".${file##*.}" || echo '')
                                fname=$(basename ${file%.*})
                        else
                                fname=$(basename ${file})
                        fi

                        if [[ "${fname}" == *${fstring}* ]]
                        then
                                fnamedst=$(echo ${fname}|sed s/${fstring}/${fstringr}/g)${extension}
                                mv --verbose --interactive ${file} $(dirname ${file})/${fnamedst}
                        else
                                echo ${file} skipped
                        fi
		;;
		* )
			echo "Error: Action \"${faction}\" not implemented"
		;;
	esac
done

