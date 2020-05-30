#!/bin/bash 

# loop_populate_db: Loops over a set of csv files in a directory, creates table schemas for them, 
#  and adds them into a Postgres database.
# 
# Use cases: Typically used for cleaning csv files. 

############## Requirements ##############
# Assumes that the input data is comma-delimited and that it has a header.
# Depends on csvsql, which is part of csvkit: http://csvkit.readthedocs.org
# 

############## Usage #####################
# cd into the parent directory. The run
# bash ./Code/load_data_db.sh ./Data/DB_Dump/Raw ./Data/DB_Dump/Clean medic_mobile paulpj

# Author: http://pjpaul.info

############## Sanitize Invocation of the script #################
if [ "$#" -ne 4 ]; then
  echo "Syntax error. Insufficient arguments."
  echo "Arguments required in order: raw_file_directory clean_file_directory dbname d_user_name" >&2
  exit 1
fi

############## Helper Functions #################
PRL(){
	# Small sed wrapper to print the header line and the target line of a file
	target=$1
	file=$2
	column_name="$3"
	echo 
	echo "Line......"
	sed -n -e 1p -e ${target}p ${file}
	echo 
	echo "Column index of ${column_name}"
	head -n 1 ${file} | awk -v subj=${column_name} '{for(i=1;i<=NF;i++){if ($i == subj){ print i}} }' FS="," OFS=","
}

Clean_Empty_Strings(){
	# invoked as Clean_Empty_Strings infile infile_base output_file
	input_file=$1
	infile_base=$2

	gawk -v infile_base=${infile_base} -f ./Code/clean_data.awk FS="," OFS="," "$1" 
}


######### Process script arguments ###############
input_dir=$1
output_dir=$2
db_name=$3
user=$4
output_abs_path="$(cd "$output_dir" && pwd -P)"
parent_path="$(cd "$input_dir/../" && pwd -P)"


######## Clean ############################
start=$SECONDS
## Run the cleaning script on the raw files inside the input directory
for file in ${input_dir}/*.csv # Use file globbing to get the files
do
	name=${file##*/}; base=${name%.csv}

	echo "Cleaning empty string in... " ${name}

	set -x
	Clean_Empty_Strings ${file} ${name} > "${output_dir}/${name}"
	set +x

	head -n 5 ${file}

done

# Print time taken
duration=$(( SECONDS - start ))
echo "Cleaning the input files took" ${duration} "seconds"



########### Generate Queries #####################
echo > ./Code/query.sql # Clear out the query file.

start=$SECONDS
for clean_file in ${output_dir}/*.csv
do
	name=${clean_file##*/}; base=${name%.csv}

	# Run the schema generator on a restricted random number of csv rows, here set to 1000 rows.
	# This is to speed up the schema generation process
	echo "Generating query for.... " ${name}
	#csvsql --no-constraints --table ${base} ${file} | echo 
	head -n 1000 ${output_abs_path}/${name}  | csvsql --no-constraints --table ${base} >> ./Code/query.sql 
	echo >> ./Code/query.sql # Add an empty line for formatting
	echo "COPY ${base} FROM '${output_abs_path}/${name}' DELIMITER ',' NULL AS '' CSV HEADER;" >> ./Code/query.sql 
	echo >> ./Code/query.sql
done

# Print time taken
duration=$(( SECONDS - start ))
echo "Generating schema queries took" ${duration} "seconds"



########### Create and Load the DB ###################
echo "Creating the DB and tables"

if psql ${db_name} -c '\q' 2>&1; then
   echo "database ${db_name} exists"
   echo "Do you wish to drop this database?"
	select yn in "Yes" "No"; 
	do
	    case $yn in
	        Yes ) echo "Dropping the database" ; break;;
	        No ) echo "Exiting"; exit;;
	    esac
	done
fi

dropdb ${db_name}
createdb ${db_name}

start=$SECONDS
echo "Starting the copy process"
psql -v ON_ERROR_STOP=1 -d ${db_name} -U ${user} -a -f "./Code/query.sql"
#psql -v ON_ERROR_STOP=1 -d ${db_name} -U ${user} -a -f "./Code/queries_part2.sql"

# Print time taken
duration=$(( SECONDS - start ))
echo "Copying the DB took" ${duration} "seconds"




