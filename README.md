# Démo BPM Process (Flutter)

Petite application Flutter autonome qui répond à une question précise :
**comment un écran sait-il quoi afficher, et comment ça communique avec un
moteur BPM ?** — avec un moteur BPM entièrement simulé (mock), sans
backend, et un process pensé pour couvrir la plupart des cas qu'on
rencontre en BPM : formulaires dynamiques, tâches séquentielles, passerelle
parallèle (fork/join), tâche automatique, passerelle conditionnelle.

```bash
flutter pub get
flutter run -d chrome   # ou macos, etc.
flutter test
```

## Le JSON échangé — exemples réels

`MockBpmService` échange réellement du JSON (`jsonEncode`/`jsonDecode`, pas
juste des objets Dart passés par référence — voir plus bas). Pour ne pas
avoir à lancer l'app pour le voir, [`docs/json-examples/`](docs/json-examples)
contient de vrais payloads, **générés par le code lui-même** (pas tapés à
la main) via `dart run tool/generate_json_examples.dart` :

| Fichier | Ce qu'il montre |
|---|---|
| [`01-start.json`](docs/json-examples/01-start.json) | Démarrage : une tâche active (`applicant_info`), avec son formulaire (4 champs, dont un `select`) |
| [`02-parallel-split-two-active-tasks.json`](docs/json-examples/02-parallel-split-two-active-tasks.json) | Après soumission du formulaire : **deux tâches actives en même temps** (passerelle parallèle) |
| [`03-one-branch-done-join-still-pending.json`](docs/json-examples/03-one-branch-done-join-still-pending.json) | Une branche complétée, l'autre encore en attente — la jointure n'a pas encore eu lieu |
| [`04-join-complete-risk-screening-service-task.json`](docs/json-examples/04-join-complete-risk-screening-service-task.json) | Les deux branches faites : tâche automatique (`"type": "userTask"` → ici service task, `"form": null`) |
| [`05-auto-approved-end.json`](docs/json-examples/05-auto-approved-end.json) | Fin de process, auto-approuvé (`"activeTask": []`, `"isEnded": true`) |
| [`06-manual-review-required.json`](docs/json-examples/06-manual-review-required.json) | Score de risque élevé → bascule vers `manual_review` |
| [`07-rejected-end.json`](docs/json-examples/07-rejected-end.json) | Refusé après revue manuelle, avec le motif |
| [`08-form-validation-error.json`](docs/json-examples/08-form-validation-error.json) | Erreur métier : formulaire incomplet |
| [`09-stale-task-error.json`](docs/json-examples/09-stale-task-error.json) | Erreur métier : id de tâche périmé (`com-task-0002`) |

Exemple — juste après le démarrage (`01-start.json`), une seule tâche
active avec son formulaire :

```json
{
  "processInstanceId": "onboarding-1",
  "processDefinitionKey": "merchant_onboarding_demo",
  "isEnded": false,
  "startTime": "2026-09-30T16:56:33.414895",
  "processVariables": {
    "applicantName": null,
    "applicantEmail": null,
    "requestedAmount": null,
    "channel": null,
    "riskScore": null,
    "reviewDecision": null
  },
  "activeTask": [
    {
      "id": "onboarding-1-task-1",
      "taskDefinitionKey": "applicant_info",
      "name": "Informations demandeur",
      "type": "userTask",
      "form": {
        "fields": [
          { "key": "applicantName", "label": "Nom du demandeur", "type": "text", "required": true },
          { "key": "applicantEmail", "label": "E-mail", "type": "email", "required": true },
          { "key": "requestedAmount", "label": "Montant demandé", "type": "number", "required": true },
          {
            "key": "channel",
            "label": "Canal de la demande",
            "type": "select",
            "required": true,
            "options": [
              { "value": "online", "label": "En ligne" },
              { "value": "agence", "label": "En agence" }
            ]
          }
        ]
      }
    }
  ]
}
```

(champs tronqués ici pour la lisibilité — le fichier complet a tout,
`processVariables` répété dans chaque tâche inclus, exactement comme le
produit `Process.toJson`.)

Et `02-parallel-split-two-active-tasks.json` — le même process, une fois le
formulaire ci-dessus soumis : `"activeTask"` contient maintenant **deux**
tâches (`upload_id_document` et `upload_proof_of_address`), chacune avec
son propre formulaire, actives en même temps :

```json
{
  "activeTask": [
    { "taskDefinitionKey": "upload_id_document", "form": { "fields": [{ "key": "idDocument", "type": "document", "required": true }] } },
    { "taskDefinitionKey": "upload_proof_of_address", "form": { "fields": [{ "key": "proofOfAddress", "type": "document", "required": true }] } }
  ]
}
```

Pour régénérer ces fichiers après une modification du moteur :

```bash
dart run tool/generate_json_examples.dart
```

## Le process de démo

"Onboarding marchand" :

```
[start]
   │
   ▼
(applicant_info)  tâche utilisateur, FORMULAIRE
   │
   ▼
⟨passerelle parallèle⟩ ─────────────────┐
   │                                    │
   ▼                                    ▼
(upload_id_document)          (upload_proof_of_address)   tâches utilisateur, FORMULAIRE
   │                                    │
   └────────────────┬───────────────────┘
                     ▼
              ⟨jointure⟩  — attend les DEUX branches
                     │
                     ▼
             (risk_screening)   tâche automatique — sans formulaire
                     │
                     ▼
             ⟨passerelle exclusive⟩  riskScore ?
                ╱                          ╲
            < 70                          >= 70
              ▼                              ▼
        [auto-approuvé]                (manual_review)   tâche utilisateur, FORMULAIRE
            [fin]                        ╱          ╲
                                    approve          reject
                                      ▼                  ▼
                                [approuvé]          [refusé]
                                   [fin]                [fin]
```

Chaque case du diagramme ci-dessus a un équivalent direct dans le code —
voir `lib/onboarding/data/mock/mock_bpm_engine.dart`.

## Concepts BPM couverts

- **Tâches utilisateur séquentielles** — `applicant_info` puis, après la
  jointure, `manual_review` si nécessaire.
- **Formulaires dynamiques** — chaque tâche transporte un
  `FormDefinition` (liste de champs typés : texte, e-mail, nombre, select,
  document…) que l'UI rend génériquement (`DynamicFormView`), sans écran
  codé en dur par tâche. Ajouter un champ à une tâche = modifier le
  moteur, pas Flutter.
- **Passerelle parallèle (fork/join)** — après `applicant_info`, deux
  tâches sont actives *en même temps* (`process.activeTask` contient alors
  deux éléments). Le process n'avance qu'une fois les deux complétées,
  indépendamment et dans n'importe quel ordre.
- **Tâche automatique (service task)** — `risk_screening` ne montre aucun
  formulaire : le moteur calcule lui-même le score de risque. Rien à
  soumettre, juste un écran "traitement en cours…" qui fait avancer le
  process tout seul après un court délai.
- **Passerelle exclusive (gateway conditionnel)** — `risk_screening`
  bifurque automatiquement vers une approbation auto ou `manual_review`
  selon le score calculé.
- **Erreurs métier** — un formulaire incomplet est refusé par le moteur
  (`form-validation`), une tâche déjà traitée ailleurs est refusée aussi
  (`com-task-0002`), comme le ferait un vrai moteur BPM.
- **Une vraie couche JSON comme source de données** — `MockBpmService` ne
  se contente pas de renvoyer des objets Dart : il `jsonEncode` la réponse
  du moteur, puis la `jsonDecode` et la re-parse (`Process.fromJson`),
  exactement comme le ferait un client HTTP (Dio, `package:http`…) face à
  une vraie API. L'écran affiche même ce JSON brut en direct (panneau
  "Réponse JSON brute (simulée)"), pour le voir circuler réellement plutôt
  que de le décrire.

Volontairement **non couvert** (pour garder la démo lisible) : timers /
échéances, sous-processus, tâches en boucle (multi-instance), événements
signal/message. Le mécanisme pour les ajouter serait le même : un nouveau
`task_definition_key`, une entrée dans `_formFor`/`_taskName`, un `case`
dans `MockBpmEngine.completeTask` et, si besoin, dans
`OnboardingTaskSwitcher`.

## Où regarder

- `lib/bpm_framework/` — un mini client BPM générique (`Process`, `Task`,
  `Variable`, `FormDefinition`, `BpmService`, `ProcessRepository`). C'est
  le genre d'abstraction qu'un vrai client REST pour un moteur BPM
  (Flowable, Activiti, Camunda…) expose.
- `lib/onboarding/data/mock/mock_bpm_engine.dart` — **le process
  lui-même**, écrit en Dart : chaque `case` correspond à une tâche du
  diagramme, et décide où va le dossier ensuite (y compris la logique de
  fork/join en `Set<String>` de clés actives). C'est ce qui, en
  production, serait déployé comme diagramme `.bpmn` sur le moteur plutôt
  qu'écrit dans l'app.
- `lib/onboarding/data/mock/mock_bpm_service.dart` — implémente le contrat
  `BpmService` par-dessus le moteur mocké, **en passant réellement par du
  JSON** (`jsonEncode` puis `jsonDecode` + `Process.fromJson`) plutôt que
  de renvoyer les objets du moteur tels quels. Tout ce qui est au-dessus
  (bloc, écrans) ne sait pas que c'est mocké : remplacer cette classe par
  une implémentation HTTP suffirait à brancher un vrai backend, sans
  changer la forme des données.
- `lib/onboarding/presentation/widgets/dynamic_form_view.dart` — le rendu
  **générique** d'un formulaire à partir de sa définition.
- `lib/onboarding/presentation/widgets/onboarding_task_switcher.dart` —
  **le switch d'écran** : il lit `process.activeTask` (une liste, pas une
  seule tâche — c'est ce qui permet la passerelle parallèle) et choisit
  le(s) écran(s) à afficher.
- `lib/onboarding/presentation/widgets/process_variables_inspector.dart` —
  affiche en direct les variables du process (le "sac de données" qui
  voyage d'une tâche à l'autre), comme le ferait la console d'admin d'un
  vrai moteur BPM.
- `lib/onboarding/business_logic/onboarding_process_bloc.dart` — relaie
  les actions utilisateur vers `repository.execTask(...)` via un seul
  événement générique (`SubmitTaskForm`), commun à toutes les tâches à
  formulaire. Chaque appel résout l'id de la tâche active *au moment de
  l'appel*, jamais depuis un id mis en cache — un vrai moteur refuserait
  sinon un `complete` sur une tâche déjà traitée ailleurs
  (`MockBpmEngine` simule volontairement ce refus, avec le code
  `com-task-0002`).

## Tester

```bash
flutter test
```

`test/onboarding_process_repository_test.dart` fait tourner le process de
bout en bout (sans UI) : démarrage, le fork parallèle (vérifie que
`process.activeTask` contient bien deux tâches, que compléter l'une laisse
l'autre intacte avec le même id, et que la jointure n'avance qu'une fois
les deux faites), la tâche automatique, les deux branches de la passerelle
exclusive (montant faible → auto-approuvé, montant élevé → revue manuelle
→ refus), et les deux cas d'erreur (formulaire invalide, tâche périmée).
