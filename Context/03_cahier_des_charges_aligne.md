# Cahier des charges — Application Compagnon Senior
## Version alignée avec le document technique, le BMC révisé et le thème du hackathon

## 1. Objectif du projet
Développer une application mobile compagnon pour personnes âgées, pensée pour un usage simple, rassurant et accessible, permettant :

- au senior de conserver son autonomie avec une interaction minimale ;
- au guardian (famille / proche aidant) de suivre la situation quotidienne, comprendre les événements importants et agir rapidement si nécessaire.

L’application doit :

- simplifier le suivi quotidien ;
- réduire la charge mentale de la famille ;
- transformer des signaux dispersés en informations utiles et actionnables ;
- améliorer la réactivité face aux situations anormales ;
- rester compatible avec un usage smartphone simple, sans matériel dédié.

---

## 2. Positionnement produit
L’application est un **compagnon de suivi quotidien et de coordination familiale**.

Elle n’est **pas** définie comme un simple détecteur de chute, ni comme un dispositif médical.

Sa proposition centrale est la suivante :

> Aider les familles à suivre simplement le quotidien d’un proche âgé, à repérer les situations anormales et à agir rapidement, grâce à une expérience très simple côté senior et plus riche côté guardian.

---

## 3. Vision fonctionnelle
Le produit repose sur deux expériences complémentaires dans une seule application :

- **Expérience Senior** : interaction minimale, faible charge cognitive, confirmations simples, rappels clairs, aide immédiate ;
- **Expérience Guardian** : tableau de bord, priorisation des alertes, vue d’ensemble, historique, configuration et suivi.

Le cœur du produit est le **suivi quotidien intelligent**.
Les incidents, y compris les incidents compatibles avec une chute, sont traités comme des **événements de vigilance** au sein d’un ensemble plus large de signaux utiles.

---

## 4. Utilisateurs cibles
### 4.1 Senior
- 60+
- autonomie partielle
- faible ou moyenne aisance technologique
- besoin de simplicité, lisibilité, rassurance et rapidité d’interaction

### 4.2 Guardian
- membre de la famille ou proche aidant
- souhaite être rassuré sans être noyé d’alertes
- a besoin de savoir rapidement :
  - si tout va bien ;
  - ce qui s’est passé ;
  - si une action est nécessaire maintenant.

---

## 5. Proposition de valeur
### Pour le senior
- interface simple et non intimidante ;
- rappels utiles ;
- actions minimales ;
- possibilité de signaler facilement qu’il va bien ou qu’il a besoin d’aide.

### Pour le guardian
- visibilité claire sur l’état global ;
- alertes contextualisées ;
- historique utile ;
- meilleure coordination et meilleure capacité de réaction.

### Valeur produit centrale
Le système transforme des événements dispersés du quotidien en un **statut compréhensible, priorisé et exploitable**.

---

## 6. Périmètre fonctionnel
### 6.1 MVP — périmètre principal
Le MVP doit couvrir :

- check-in quotidien ;
- rappels et confirmations de médicaments ;
- gestion d’incidents suspects ;
- tableau de bord guardian ;
- alertes et escalade ;
- statut global du senior.

### 6.2 Fonctionnalités complémentaires
Selon le temps disponible, le produit pourra inclure :

- zones sûres / sécurité de localisation ;
- rappels nutrition / hydratation ;
- assistance vocale simple ;
- résumés intelligents pour la famille.

### 6.3 Hors périmètre MVP
- intégrations cliniques complexes ;
- dispositif médical certifié ;
- dépendance à du hardware propriétaire ;
- assistant conversationnel avancé à grande échelle ;
- analytics prédictifs complexes.

---

## 7. Modules fonctionnels
### 7.1 Module Check-in
Objectif : permettre au senior de confirmer simplement qu’il va bien.

Fonctions :
- check-in manuel ;
- check-in planifié ;
- détection d’absence de check-in ;
- escalade au guardian si absence prolongée.

### 7.2 Module Médicaments
Objectif : soutenir la routine médicamenteuse sans complexifier l’usage.

Fonctions :
- création d’un planning ;
- rappels ;
- confirmation « pris / ignoré » ;
- remontée des oublis au guardian.

### 7.3 Module Vigilance Incident
Objectif : détecter des événements compatibles avec une situation anormale, vérifier avec le senior, puis escalader si nécessaire.

Fonctions :
- détection d’événement suspect à partir des capteurs smartphone ;
- demande de confirmation ;
- alerte au guardian si non-réponse ou urgence ;
- journalisation.

Ce module ne doit pas être décrit comme une détection parfaite de chute, mais comme une **vigilance d’incident** visant à réduire le temps de réaction.

### 7.4 Module Dashboard Guardian
Objectif : centraliser le statut et les alertes utiles.

Fonctions :
- statut global ;
- alertes actives ;
- timeline récente ;
- accès rapide aux actions de suivi ;
- lecture claire par priorité.

### 7.5 Module Location Safety (optionnel)
Objectif : gérer des zones sûres avec consentement explicite.

Fonctions :
- définition de zones ;
- alerte sortie de zone ;
- partage conditionnel de dernière localisation.

### 7.6 Couche IA
Objectif : rendre le produit plus utile, plus clair et plus accessible.

Fonctions MVP recommandées :
- priorisation des alertes ;
- résumés simples pour le guardian ;
- text-to-speech / assistance vocale simple.

Fonctions futures :
- companion conversationnel ;
- apprentissage de schémas ;
- personnalisation des rappels.

---

## 8. Logique métier globale
Le système doit fonctionner selon la logique suivante :

1. les modules génèrent des événements ;
2. les événements sont centralisés ;
3. un moteur de règles attribue une priorité ;
4. le statut global du senior est mis à jour ;
5. seules les alertes utiles sont remontées au guardian ;
6. le senior continue d’interagir avec un minimum d’effort.

---

## 9. Statut global
Le guardian doit disposer d’un statut global simple et explicable :

- **OK** : aucun signal préoccupant ;
- **À surveiller** : un ou plusieurs signaux nécessitent de l’attention ;
- **Action requise** : incident non résolu, urgence ou répétition d’événements critiques.

Le statut global doit être dérivé de règles métier lisibles, pas d’une boîte noire incompréhensible.

---

## 10. Expérience Senior
### Principes UX
- très faible charge cognitive ;
- interaction minimale ;
- gros boutons ;
- texte lisible ;
- parcours courts ;
- support audio possible ;
- vocabulaire simple ;
- pas de menus profonds.

### Actions principales
- « Je vais bien » ;
- « J’ai besoin d’aide » ;
- confirmer un rappel ;
- confirmer ou annuler un incident suspect.

---

## 11. Expérience Guardian
### Besoins prioritaires
Le guardian doit pouvoir comprendre rapidement :
- l’état général du senior ;
- les alertes actives ;
- les événements récents ;
- les actions à entreprendre.

### Éléments principaux
- dashboard synthétique ;
- liste d’alertes ;
- historique / timeline ;
- paramètres modules ;
- gestion des préférences d’escalade.

---

## 12. Contraintes d’accessibilité
Le produit doit respecter les principes suivants :

- lisibilité élevée ;
- zones tactiles larges ;
- contraste élevé ;
- mots simples ;
- interactions limitées par écran ;
- possibilité d’assistance vocale ;
- expérience utilisable même par un senior peu à l’aise avec le numérique.

---

## 13. Contraintes techniques
### Architecture recommandée
- application mobile modulaire ;
- communication orientée événements ;
- backend en modular monolith pour le MVP.

### Contraintes clés
- pas de dépendance à du matériel propriétaire ;
- support d’un fonctionnement dégradé en faible connectivité ;
- pas de couplage fort entre modules ;
- explicabilité des workflows critiques ;
- journalisation traçable des événements importants.

---

## 14. Confidentialité, consentement et sécurité
Le produit doit intégrer :

- lien explicite entre senior et guardian ;
- contrôle sur les fonctions optionnelles ;
- consentement pour la localisation et les données partagées ;
- transparence sur les données collectées ;
- positionnement non médical clair.

---

## 15. Alertes
Les alertes doivent être :

- limitées ;
- pertinentes ;
- priorisées ;
- compréhensibles ;
- explicables.

Catégories :
- information ;
- warning ;
- critical.

Le produit ne doit pas inonder le guardian d’alertes inutiles.

---

## 16. Positionnement du module incident
Le module incident doit être présenté comme :

- un support de vigilance ;
- une détection d’événement suspect ;
- une aide à la réduction du temps de réaction.

Il ne doit pas être présenté comme :

- une garantie de détection de chute ;
- un système médical ;
- une surveillance infaillible.

---

## 17. Adaptation locale et contexte d’usage
Le produit doit être compatible avec :

- une adoption numérique inégale ;
- un usage smartphone simple ;
- des besoins de langage clair ;
- une possible adaptation au dialecte tunisien ;
- des familles cherchant surtout du suivi clair et de la réactivité.

---

## 18. Modèle économique
### Free
- check-in ;
- rappels essentiels ;
- dashboard basique ;
- alertes de base.

### Plus
- historique enrichi ;
- paramètres avancés ;
- options de sécurité supplémentaires.

### Premium
- résumés intelligents ;
- assistance vocale enrichie ;
- companion IA ;
- priorisation avancée.

---

## 19. Vision finale
> Une application compagnon senior centrée sur le suivi quotidien, la coordination familiale et les alertes utiles, avec une expérience simple pour le senior, une lecture claire pour la famille et des modules de vigilance extensibles.
