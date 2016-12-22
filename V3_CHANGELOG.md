## v2 à v3 updates
* Mise à jour des librairies externes lorsque possible
* Vérification des anomalies de sécurité remontées (beaucoup de faux positifs)
* Migration de MongoDB à MySQL
* Ré-Architecturage du code source
* Amélioration globale de la qualité du code (lisibilité ...)

## Ré-Architecturage du code source
* Ajout de nouveaux services pour délester les controllers et les models
* Ré-architecturage des process de production (disponibles dans modules/)
* Mise en place de Sidekiq pour lancer les tâches en asynchrone. Sidekiq Scheduler accompagné de la class JobOrchestrator remplace l'ancien manager

## Warnings : modification rollbackées
* Les fichiers sont toujours sous forme de fichiers plats car leur exploitation sur une plate-forme type stockage objet cause trop de problèmes avec le process de production actuel
* Rails 5 a été rollbacké en version 4.2.7 suite à de gros problèmes de stabilité et de fuites mémoires en environnement de production
* Le process de récupération des XML d'écriture avait été parallèlisé mais retour en arrière car trop d'accès disques
* Le process de récupération Ibiza avait été parallèlisé mais retour en arrière car échecs sur l'API
* Il ne faut surtout pas parallèliser les envois sur les API de stockage externe type Dropbox, Google Drive ... Cela génère beaucoup trop d'échecs de connexion (Query limit sur l'API) et nous avons eu le droit à plusieurs périodes où l'API nous rejetait par la suite toutes les requêtes

# Tips pour la montée en charge
* Supprimer Fiduceo (mange des ressources que nous ne devrions pas dépenser)
* Changer le process de production (API to API au lieu de fichiers statiques)
* Revenir aux fichiers clouds suite au changement du process de production
* Résoudre le problème de parallélisation avec Ibiza
