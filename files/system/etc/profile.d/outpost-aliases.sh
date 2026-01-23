#!/usr/bin/env sh

# CAC / smart card
alias scan='pcsc_scan'
alias reader-list='opensc-tool -l'
alias cac-info='opensc-tool --info'
alias cac-drivers='opensc-tool -D'

# NSS / Firefox
alias nss-modules='modutil -list -dbdir "sql:$HOME/.pki/nssdb"'

# Trust
alias trust-dod='trust list | grep -i dod'
alias trust-refresh='sudo update-ca-trust'
