# iDocus

## Information Générale
Site web qui homogénise le stockage et la gestion des documents provenant de différentes sources pour en effectuer la comptabilité

* Site vitrine : https://www.idocus.com
* Documents : https://docs.idocus.com
* Application :
  - Production : https://my.idocus.com
  - Administration : https://my.idocus.com/admin
  - Administration du coffre : https://backoffice-coffre.idocus.com/coffre/
  - Traquer de bug : https://errbit.idocus.com
* Slimpay : https://prlv.idocus.com

## Traitement
- ROC (Reconnaissance Optique de Caractère)
- Regroupement
- Pré-afféctation

## Technologies :
- Linux - Debian 64bit - personnalisé
- Ruby 1.9.3p551 (2014-11-13 revision 48407) [x86_64-linux]
- Ruby on Rails 4.1.10
- MongoDB 2.4
- ImageMagick 6.5.1-0 2009-04-10 Q16 OpenMP
- Pdftk 2.02
- Poppler
- Elasticsearch 2.1.0

*Liste non exhaustive*

## Services externes :
* Fiduceo
* Ibiza
* Knowings
* Quadratus
* Dropbox
* Google Drive
* Box
* FTP

## Installation
*A venir*

## Développement

### Applications
Pré-production : https://staging.idocus.com

### Visualise les mails avec Mailcatcher
1. `gem install mailcatcher`
2. `mailcatcher`
3. Go to http://localhost:1080/
4. Envoyer les mails via smtp://localhost:1025

### Tests
Lance les tests :
```ruby
rspec spec/
```
Lance les tests avec la couverture :
```ruby
SIMPLECOV=true rspec spec/
```
