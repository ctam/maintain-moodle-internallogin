#!/bin/bash
set -e

for f in *.{php,html}; do sed -i 's|/login/|/internallogin/|g' $f; done

for f in *.{php,html}; do sed -i "s|(!empty(\$CFG->alternateloginurl))|(false /* disable alternate login */ and !empty(\$CFG->alternateloginurl))|g" $f; done
for f in *.{php,html}; do sed -i "s|= get_login_url();|= str_replace('/login/', '/internallogin/', get_login_url());|g" $f; done
