SELECT d.datname as "Name",
               pg_catalog.pg_get_userbyid(d.datdba) as "Owner",
               pg_catalog.pg_encoding_to_char(d.encoding) as "Encoding",
               d.datcollate as "Collate",
               d.datctype as "Ctype",
               pg_catalog.array_to_string(d.datacl, E'\n') AS "Access privileges"
        FROM pg_catalog.pg_database d
        ORDER BY 1;
