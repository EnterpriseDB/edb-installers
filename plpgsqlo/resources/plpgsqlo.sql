CREATE OR REPLACE FUNCTION plpgsqlo_call_handler()
 RETURNS language_handler AS
'$libdir/plpgsqlo', 'plpgsqlo_call_handler'
 LANGUAGE 'c' VOLATILE
 COST 1;
ALTER FUNCTION plpgsqlo_call_handler() OWNER TO $SUPERUSER;

CREATE OR REPLACE FUNCTION plpgsqlo_validator(oid)
 RETURNS void AS
'$libdir/plpgsqlo', 'plpgsqlo_validator'
 LANGUAGE 'c' VOLATILE
 COST 1;
ALTER FUNCTION plpgsqlo_validator(oid) OWNER TO $SUPERUSER;

CREATE TRUSTED PROCEDURAL LANGUAGE 'plpgsqlo'
 HANDLER plpgsqlo_call_handler
 VALIDATOR plpgsqlo_validator;
ALTER LANGUAGE plpgsqlo OWNER TO $SUPERUSER;
