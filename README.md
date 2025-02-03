![Static Badge](https://img.shields.io/badge/OK-cPanel?logo=cpanel&label=cPanel&color=green)
![Static Badge](https://img.shields.io/badge/OK-Cloudflare?logo=cloudflare&label=Cloudflare&color=green)


# dynamic dns Cloudflare / CPanel
Script PowerShell per aggiornare dinamicamente i record DNS per un dominio specifico utilizzando i servizi di Cloudflare e/o cPanel. 
L'utente avvia lo script, che ottiene e visualizza l’IP corrente, chiede se aggiornare i record su Cloudflare e/o cPanel e aggiorna i record DNS solo se rileva cambiamenti nell’IP.

### Parametri di Configurazione
param: Vanno definiti i parametri iniziali, come il dominio (`domain`), il sottodominio (`subdomain`), l'IP di dominio (`domainIP` facoltativo) e mail (`email`), nonché token API (`CF_token`) per Cloudflare.

### Funzioni Principali
#### Recupero dell'IP corrente:
        Ottiene l'IP pubblico attuale utilizzando ipinfo.io e consente all'utente di confermarlo o inserirne uno personalizzato.

#### Opzioni di aggiornamento DNS:
        Chiede se aggiornare i record DNS tramite Cloudflare, cPanel, o entrambi.
        Usa i token API per autenticarsi e autorizzarsi su Cloudflare e cPanel.

#### Aggiornamento DNS con Cloudflare:
        Verifica il token API e ottiene l'ID del dominio (zone_id) su Cloudflare.
        Controlla se l'IP attuale è diverso dall’IP registrato. Se sì, aggiorna il record DNS per il dominio.
        In caso di successo o errore, fornisce feedback dettagliato all'utente.

#### Aggiornamento DNS con cPanel:
        Ottiene e decodifica i dati DNS registrati tramite chiamate all’API di cPanel.
        Verifica se l'IP pubblico è differente dall’IP registrato e, in caso positivo, invia una richiesta API per aggiornare il record DNS.
        Gestisce seriali e richieste di modifica alla zona DNS per cPanel, verificando il record SOA e gestendo eventuali errori o avvisi di aggiornamento.
