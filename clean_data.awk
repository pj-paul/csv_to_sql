{for(i=1;i<=NF;i++)
	if($i=="\"\"") $i="" #Replace empty strings with null strings
}

{for(i=1;i<=NF;i++)
	if($i=="NA") $i="" #Replace "NA" strings with null strings
}

# Edits for file assessments.csv

{ if ((FILENAME ~ "assessments[.csv]") && ($20=="NA")) 
		$20 = ""
}

# Edits for delivery file

{ if ((FILENAME ~ "delivery[.csv]") && ($7=="NA")) # Column danger_signs_at_delivery
		$7 = ""
}


# Edits for the person file
{ if ((FILENAME ~ "person[.csv]") && ($1=="f0c3d8f2256436dc0be6242a5f4f19b6")) # Column date of birth for a person
		$3 = "1983-06-01" # Only 1983 provided in the data
}


{ if ((FILENAME ~ "person[.csv]") && ($1=="d0389a1bc76a689a88be20bcacad511a")) # 
		$3 = "1975-06-01" # Only 1975 provided in the data
}

{ if ((FILENAME ~ "person[.csv]") && ($1=="2b3601ccd42dc3cf316b6639cfd49e05")) # 
		$3 = "1985-06-01" # Only 1975 provided in the data
}



{print}