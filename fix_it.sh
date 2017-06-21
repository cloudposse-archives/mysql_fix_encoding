#!/usr/bin/env bash

proccess_change_field() {
  local TABLE=$1
  local FIELD_RAW=$2

  local PARSE_FIELD="^\`([a-zA-Z0-9_-]*)\`\s(varchar\(\d*\)|\w*text)(.*),?$"


  if echo $FIELD_RAW | grep -E '(varchar\(|text\s)' > /dev/null ;
  then
   echo $FIELD_RAW | perl -p -e "s/$PARSE_FIELD/ALTER TABLE $TABLE CHANGE \`\1\` \`\1\` \2 CHARACTER SET latin1; /g"
   echo $FIELD_RAW | perl -p -e "s/$PARSE_FIELD/ALTER TABLE $TABLE CHANGE \`\1\` \`\1\` \2; /g" | \
        sed "s/\svarchar(/ varbinary(/g" | \
        sed "s/\slongtext;/ longblob;/g" | \
        sed "s/\smediumtext;/ mediumblob;/g" | \
        sed "s/\stext;/ blob;/g" | \
        sed "s/\stinytext;/ tinyblob;/g"
   echo $FIELD_RAW | perl -p -e "s/$PARSE_FIELD/ALTER TABLE $TABLE CHANGE \`\1\` \`\1\` \2 CHARACTER SET utf8; /g"
  fi
}

proccess_enum_field() {
  local TABLE=$1
  local FIELD_RAW=$2

  local PARSE_FIELD="^\`([a-zA-Z_-]*)\`(\senum\([\'\w*\',?]+\))([^,]*),?$"


  if echo $FIELD_RAW | grep -E '(enum\(|set\()' > /dev/null ;
  then
   echo $FIELD_RAW | perl -p -e "s/$PARSE_FIELD/ALTER TABLE $TABLE CHANGE \`\1\` \`\1\` \2 CHARACTER SET utf8 \3; /g"
  fi
}

proccess_drop_fulltext() {
  local TABLE=$1
  local FIELD_RAW=$2

  local PARSE_FIELD="^FULLTEXT\sKEY\s\`([a-zA-Z_-]*)\`\s(\((\`[a-zA-Z_-]*\`,?)+?\)),?$"


  if echo $FIELD_RAW | grep -iE 'FULLTEXT\sKEY' > /dev/null ;
  then
   echo $FIELD_RAW | perl -p -e "s/$PARSE_FIELD/DROP INDEX \`\1\` ON $TABLE;  ; /g"
  fi
}

proccess_create_fulltext() {
  local TABLE=$1
  local FIELD_RAW=$2

  local PARSE_FIELD="^FULLTEXT\sKEY\s\`([a-zA-Z_-]*)\`\s(\((\`[a-zA-Z_-]*\`,?)+?\)),?$"


  if echo $FIELD_RAW | grep -iE 'FULLTEXT\sKEY' > /dev/null ;
  then
   echo $FIELD_RAW | perl -p -e "s/$PARSE_FIELD/ALTER TABLE $TABLE ADD FULLTEXT INDEX \`\1\` \2;/g"
  fi
}

convert_table() {
  local TABLE=$1
  declare -a FIELDS
  readarray FIELDS < <( $mysql -e "SHOW CREATE TABLE $TABLE \G")

  tLen=${#FIELDS[@]}

  for FIELD in "${FIELDS[@]:3:($tLen-4)}"; do
     proccess_drop_fulltext $TABLE "$FIELD"
  done

  for FIELD in "${FIELDS[@]:3:($tLen-4)}"; do
    proccess_change_field $TABLE "$FIELD"
  done

  for FIELD in "${FIELDS[@]:3:($tLen-4)}"; do
    proccess_enum_field $TABLE "$FIELD"
  done

  for FIELD in "${FIELDS[@]:3:($tLen-4)}"; do
     proccess_create_fulltext $TABLE "$FIELD"
  done

  echo "ALTER TABLE $TABLE CHARACTER SET utf8;"
}

convert_field() {
  local TABLE=$1
  local FIELD=$2

  local FIELD_RAW=$($mysql -e "SHOW CREATE TABLE ${TABLE}\G" | grep "\`${FIELD}\`")
  proccess_change_field $TABLE "$FIELD_RAW"
}


mysql="sudo mysql --defaults-file=/root/.my.cnf"

readarray -t TABLES < <($mysql -e "SHOW TABLE STATUS WHERE Collation='latin1_swedish_ci'\G" | grep Name | sed  's/Name://g' | awk '{$1=$1;print}')

for TABLE in "${TABLES[@]}"; do
  convert_table $TABLE
done

readarray -t TABLE_FIELDS < <($mysql -e "SELECT CONCAT(TABLE_NAME, '|', COLUMN_NAME) as DATA FROM information_schema.columns WHERE CHARACTER_SET_NAME = 'latin1' AND TABLE_SCHEMA=DATABASE()\G" | grep DATA | sed  's/DATA://g' | awk '{$1=$1;print}')

for TABLE_FIELD in "${TABLE_FIELDS[@]}"; do
  convert_field $(echo $TABLE_FIELD | cut -d'|' -f1) $(echo $TABLE_FIELD | cut -d'|' -f2)
done