
#TP2

#Partie 1 : Architecture Messagerie d'Entreprise 
# 1.1 Création des Comptes Dirigeants

# Création de l'OU Direction 
New-ADOrganizationalUnit -Name "Direction" -Path "DC=test,DC=local" -ErrorAction SilentlyContinue

# Définition des quotas personnalisés
$IssueWarningQuota = 2GB
$ProhibitSendQuota = 2.5GB
$ProhibitSendReceiveQuota = 3GB

#importer une session depuis le serveur exchange* 
$cred= Get-credential 
$Session1 = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://srv-exch01.test.local/PowerShell/ -Authentication Kerberos -Credential $cred 
Import-PSSession $Session1 -DisableNameChecking 

#importer les commandes Powershell AD si vous souhaitez utiliser des commandes comme get-aduser, new-aduser… 
$cred= Get-credential 
$session2 = New-PSSession -ComputerName dc.test.local -Credential $cred 

Import-PSSession -Session $session2 -Module ActiveDirectory -allowClobber 

# Création des utilisateurs avec boîte aux lettres

# Création de la boîte aux lettres
New-Mailbox -Name "Marie Dubois" -UserPrincipalName "m.dubois@test.local" -OrganizationalUnit "OU=Direction,DC=test,DC=local" `
  -FirstName "Marie" -LastName "Dubois" -DisplayName "Marie Dubois" `
  -Password (ConvertTo-SecureString "abc.123" -AsPlainText -Force)

# Modification des attributs AD
Set-User "Marie Dubois" -City "Montréal" -StateOrProvince "Québec" -Title "Directrice Générale" -Department "Direction"
Set-Mailbox "Marie Dubois" `
  -IssueWarningQuota $IssueWarningQuota `
  -ProhibitSendQuota $ProhibitSendQuota `
  -ProhibitSendReceiveQuota $ProhibitSendReceiveQuota `
  -HiddenFromAddressListsEnabled $true

# Activation de l’archivage
Enable-MailboxArchive -Identity "Marie Dubois"

# Créer la boîte aux lettres
New-Mailbox -Name "Jean Tremblay" -UserPrincipalName j.tremblay@test.local -OrganizationalUnit "Direction" `
 -FirstName "Jean" -LastName "Tremblay" -DisplayName "Jean Tremblay" `
 -Password (ConvertTo-SecureString "abc.123" -AsPlainText -Force) -ResetPasswordOnNextLogon $false

# Ajouter les attributs utilisateur
Set-User -Identity j.tremblay@test.local -City "Montréal" -StateOrProvince "Québec" `
 -Title "Directeur Informatique" -Department "IT"


# Appliquer les quotas personnalisés
Set-Mailbox -Identity j.tremblay@test.local -UseDatabaseQuotaDefaults $false `
 -IssueWarningQuota 2048MB `
 -ProhibitSendQuota 2560MB `
 -ProhibitSendReceiveQuota 3072MB

# Activer l’archivage
Enable-Mailbox -Archive -Identity j.tremblay@test.local

# Masquer de la liste d’adresses
Set-Mailbox -Identity j.tremblay@test.local -HiddenFromAddressListsEnabled $true

# Création de la boîte aux lettres pour Sophie Martin
New-Mailbox -Name "Sophie Martin" -UserPrincipalName s.martin@test.local `
 -OrganizationalUnit "test.local/Direction" `
 -Password (ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force) `
 -FirstName Sophie -LastName Martin -DisplayName "Sophie Martin" -Alias s.martin

# Mise à jour des propriétés utilisateur : ville, province, titre, département
Set-User -Identity "Sophie Martin" `
 -City "Laval" `
 -StateOrProvince "Québec" `
 -Title "Directrice Ressources Humaines" `
 -Department "RH"

# Définir les quotas personnalisés 
Set-Mailbox -Identity s.martin@test.local -UseDatabaseQuotaDefaults $false -IssueWarningQuota 2048MB -ProhibitSendQuota 2560MB -ProhibitSendReceiveQuota 3072MB
               
# Activer la boîte aux lettres d'archivage
Enable-Mailbox -Identity "Sophie Martin" -Archive

# Masquer la boîte aux lettres des listes d’adresses globales
Set-Mailbox -Identity s.martin@test.local -HiddenFromAddressListsEnabled $true

#1.2 Gestion des Comptes Temporaires
# Création de l'utilisateur dans l'OU Direction (tu peux modifier le chemin si besoin)
New-ADUser -Name "Consultant Externe" `
 -SamAccountName "c.externe" `
 -UserPrincipalName "c.externe@test.local" `
 -Path "OU=Direction,DC=test,DC=local" `
 -AccountPassword (ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force) `
 -Enabled $true `
 -State "Québec" `
 -GivenName "Consultant" `
 -Surname "Externe"
 
#Activation de boite avec qotas de 500 MB
Enable-Mailbox -Identity "Consultant Externe"

Set-Mailbox -Identity "Consultant Externe" `
 -UseDatabaseQuotaDefaults $false `
 -IssueWarningQuota 450MB `
 -ProhibitSendQuota 475MB `
 -ProhibitSendReceiveQuota 500MB
 
#Définir une expiration du compte dans 90 jours
$expireDate = (Get-Date).AddDays(90)
Set-ADUser -Identity "c.externe" -AccountExpirationDate $expireDate

# 1.3 Infrastructure de Boîtes Partagées

# Créer la boîte partagée Support Technique
New-Mailbox -Shared -Name "support" -DisplayName "Support Technique" -Alias "support" -PrimarySmtpAddress support@test.local

# Créer la boîte partagée Recrutement
New-Mailbox -Shared -Name "recrutement" -DisplayName "Recrutement" -Alias "recrutement" -PrimarySmtpAddress recrutement@test.local

# --- Droits sur la boîte Support ---

# Contrôle total + Envoi en tant que pour Marie Dubois
Add-MailboxPermission -Identity support@test.local -User "m.dubois" -AccessRights FullAccess -InheritanceType All
Add-ADPermission -Identity (Get-Mailbox support@test.local).DistinguishedName -User "m.dubois" -ExtendedRights "Send As"

# Contrôle total pour Jean Tremblay
Add-MailboxPermission -Identity support@test.local -User "j.tremblay" -AccessRights FullAccess -InheritanceType All

# Lecture seule pour Sophie Martin
Add-MailboxPermission -Identity support@test.local -User "s.martin" -AccessRights ReadPermission -InheritanceType All

# --- Droits sur la boîte Recrutement ---

# Contrôle total + Envoi de la part de pour Sophie Martin
Add-MailboxPermission -Identity recrutement@test.local -User "s.martin" -AccessRights FullAccess -InheritanceType All
Set-Mailbox -Identity recrutement@test.local -GrantSendOnBehalfTo @{Add="s.martin"}

# Lecture seule + Envoi en tant que pour Marie Dubois
Add-MailboxPermission -Identity recrutement@test.local -User "m.dubois" -AccessRights ReadPermission -InheritanceType All
Add-ADPermission -Identity (Get-Mailbox recrutement@test.local).DistinguishedName -User "m.dubois" -ExtendedRights "Send As"

#################################################################################################

#Partie 2 : Groupes de Distribution Avancés
#2.1 Groupes Dynamiques
# Groupe dynamique : direction-quebec@test.local
New-DynamicDistributionGroup -Name "direction-quebec" `
  -DisplayName "Direction Québec" `
  -Alias "direction-quebec" `
  -PrimarySmtpAddress "direction-quebec@test.local" `
  -RecipientFilter { (RecipientType -eq "UserMailbox") -and (Department -eq "Direction") -and (StateOrProvince -eq "Québec") }

# Groupe dynamique : employes-montreal@test.local
New-DynamicDistributionGroup -Name "employes-montreal" `
  -DisplayName "Employés Montréal" `
  -Alias "employes-montreal" `
  -PrimarySmtpAddress "employes-montreal@test.local" `
  -RecipientFilter { (RecipientType -eq "UserMailbox") -and (City -eq "Montréal") }

#2.2 Groupes Statiques

 # Créer le groupe statique "equipe-leadership"
New-DistributionGroup -Name "equipe-leadership" `
  -DisplayName "Équipe Leadership" `
  -Alias "equipe-leadership" `
  -PrimarySmtpAddress "equipe-leadership@test.local" `
  -Members "m.dubois@test.local", "j.tremblay@test.local", "s.martin@test.local" `
  -MemberJoinRestriction Closed `
  -MemberDepartRestriction Closed

# Autoriser uniquement les membres à envoyer au groupe
Set-DistributionGroup -Identity "equipe-leadership@test.local" -RequireSenderAuthenticationEnabled $true
Set-DistributionGroup -Identity "equipe-leadership@test.local" -AcceptMessagesOnlyFromSendersOrMembers "m.dubois@test.local","j.tremblay@test.local","s.martin@test.local"
###################################################################################################################

#Partie 3 : Automatisation et Gestion en Masse 
#Crée l’OU Employes
New-ADOrganizationalUnit -Name "Employes" -Path "DC=test,DC=local"
#Crée les groupes IT, RH, Finance et Marketing
New-ADGroup -Name "IT" -GroupScope Global -Path "DC=test,DC=local"
New-ADGroup -Name "RH" -GroupScope Global -Path "DC=test,DC=local"
New-ADGroup -Name "Finance" -GroupScope Global -Path "DC=test,DC=local"
New-ADGroup -Name "Marketing" -GroupScope Global -Path "DC=test,DC=local"

#SCRIPT 

$csvPath = "C:\Users\administrateur.TEST\Desktop\employes.csv"
$employes = Import-Csv -Path $csvPath

foreach ($emp in $employes) { 
    $prenom = $emp.Prenom
    $nom = $emp.Nom
    $upn = "$prenom.$nom@test.local"
    $nomComplet = "$prenom $nom"
    $ou = "OU=Employes,DC=test,DC=local"
    $sam = "$prenom.$nom"
    $password = ConvertTo-SecureString "abc.123" -AsPlainText -Force

    New-ADUser -Name $nomComplet `
               -GivenName $prenom `
               -Surname $nom `
               -SamAccountName $sam `
               -UserPrincipalName $upn `
               -Path $ou `
               -AccountPassword $password `
               -City $emp.Ville `
               -State $emp.Province `
               -Title $emp.Titre `
               -Department $emp.Departement `
               -Enabled $true `
               -ChangePasswordAtLogon $true

    $groupe = $emp.Departement
    Add-ADGroupMember -Identity $groupe -Members $sam
}

#################################################################################################

#Partie 4 :  Gestion des Bases de Données
#Créer la base de données BaseEntreprise

New-MailboxDatabase -Name "BaseEntreprise" -Server "srv-exch01" -EdbFilePath "C:\ExchangeDatabases\BaseEntreprise\BaseEntreprise.edb" -LogFolderPath "C:\ExchangeDatabases\BaseEntreprise\Logs"

# Monter la base de données et configurer le montage automatique au démarrage
Set-MailboxDatabase BaseEntreprise -MountAtStartup:$true 

#Déplacer toutes les boîtes aux lettres créées vers BaseEntreprise
#Active les boîtes aux lettres Exchange pour ces utilisateurs 
Get-ADUser -Filter * -SearchBase "OU=Employes,DC=test,DC=local" | ForEach-Object {
    Enable-Mailbox -Identity $_.SamAccountName -Database "BaseEntreprise"
}
#Déplacer les boîtes aux lettres existantes vers BaseEntreprise
Get-Mailbox -OrganizationalUnit "OU=Employes,DC=test,DC=local" | New-MoveRequest -TargetDatabase "BaseEntreprise"

#Définir les quotas au niveau de la base
Set-MailboxDatabase -Identity "BaseEntreprise" `
  -IssueWarningQuota 800MB `
  -ProhibitSendQuota 1GB `
  -ProhibitSendReceiveQuota 1229MB

 
 
