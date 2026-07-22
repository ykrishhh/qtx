# Fish completions for QTX security toolkit

complete -c scan -f
complete -c recon -f
complete -c audit -f
complete -c ssl -f
complete -c hashid -f
complete -c logs -f
complete -c vuln -f
complete -c wifi -f
complete -c dirbrute -f
complete -c nikto -f

complete -c scan -l help -d "Show scan help"
complete -c recon -l help -d "Show recon help"
complete -c ssl -l help -d "Show ssl-check help"
complete -c vuln -l help -d "Show vuln-check help"
complete -c wifi -l help -d "Show wifi-recon help"
complete -c dirbrute -l help -d "Show dir-brute help"
complete -c nikto -l help -d "Show nikto-scan help"
