find * -type f -exec grep -H 'pgAdmin .* - PostgreSQL Tools' {} \; | grep "settings.ini" | cut -f1 -d":" | rev | cut -f1 -d'/' | rev
