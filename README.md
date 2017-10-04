# Mysql latin1 to utf8 convert


## Install

* Install [pv](https://github.com/icetee/pv]) tool
* Install script
  ```shell
  curl https://raw.githubusercontent.com/cloudposse/mysql_fix_encoding/4.0/fix_it.sh -o /usr/local/bin/mysql_latin_utf8.sh
  chmod +x /usr/local/bin/mysql_latin_utf8.sh
  ```
## Preconditions

You should have exited db with some tables or fields in latin1 encoding.

## How to use

1) Create my.cnf file with client default options.

    **Example:**
    ```
    [client]
    database=app
    user=root
    password=1234
    host=db.example.com
    ```

2) Check SQL query that would be applied

    `$ MY_CNF=/home/{user}/my.cnf /usr/local/bin/mysql_latin_utf8.sh`

3) Run convert db with command

    `$ MY_CNF=/home/{user}/my.cnf /usr/local/bin/mysql_latin_utf8.sh | pv | sudo mysql --defaults-file=/home/{user}/.my.cnf`

## Extra

You can override default database name specified in my.cnf with env var `DB`

 **Example:**

 ```
 $ DB=new_db \
   MY_CNF=/home/{user}/my.cnf \
  /usr/local/bin/mysql_latin_utf8.sh | pv | \
  sudo mysql --defaults-file=/home/{user}/.my.cnf new_db
  ```