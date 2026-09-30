# Démo BPM Process (Flutter)

Petite application Flutter autonome qui répond à une question précise :
**comment un écran sait-il quoi afficher, et comment ça communique avec un
moteur BPM ?** — avec un moteur BPM entièrement simulé (mock), sans
backend.

```bash
flutter pub get
flutter run -d chrome   # ou macos, etc.
```

## Le process de démo

"Onboarding marchand" : deux tâches utilisateur qui s'enchaînent, puis le
moteur bifurque tout seul (passerelle exclusive) vers une approbation
automatique ou une revue manuelle, selon un score de risque qu'il calcule
lui-même.

```
[start] ──▶ (applicant_info) ──▶ (upload_document) ──▶ passerelle exclusive
               tâche écran           tâche écran         (riskScore ?)
                                                         ╱              ╲
                                                 < 70  ╱                  ╲  >= 70
                                                      ▼                    ▼
                                                [auto-approuvé]      (manual_review)
                                                    [fin]               tâche écran
                                                                       ╱        ╲
                                                                approve          reject
                                                                  ▼                ▼
                                                            [approuvé]        [refusé]
                                                               [fin]            [fin]
```

## Où regarder

- `lib/bpm_framework/` — un mini client BPM générique (`Process`, `Task`,
  `Variable`, `BpmService`, `ProcessRepository`). C'est le genre
  d'abstraction qu'un vrai client REST pour un moteur BPM (Flowable,
  Activiti, Camunda…) expose : le modèle de données de l'engine + une
  interface `BpmService` remplaçable.
- `lib/onboarding/data/mock/mock_bpm_engine.dart` — **le process
  lui-même**, écrit en Dart : chaque `case` du `switch` correspond à une
  tâche du diagramme ci-dessus, et décide où va le dossier ensuite. C'est
  ce qui, en production, serait déployé comme diagramme `.bpmn` sur le
  moteur plutôt qu'écrit dans l'app.
- `lib/onboarding/data/mock/mock_bpm_service.dart` — implémente le contrat
  `BpmService` par-dessus le moteur mocké. Tout ce qui est au-dessus (bloc,
  écrans) ne sait pas que c'est mocké : remplacer cette classe par une
  implémentation HTTP suffirait à brancher un vrai backend.
- `lib/onboarding/presentation/widgets/onboarding_task_switcher.dart` —
  **le switch d'écran** : il lit `process.activeTaskDefinitionKey` (le seul
  champ dont l'UI a besoin) et choisit l'écran à afficher.
- `lib/onboarding/presentation/widgets/process_variables_inspector.dart` —
  affiche en direct les variables du process (le "sac de données" qui
  voyage d'une tâche à l'autre), comme le ferait la console d'admin d'un
  vrai moteur BPM.
- `lib/onboarding/business_logic/onboarding_process_bloc.dart` — relaie les
  actions utilisateur vers `repository.execTask(...)`. Chaque appel
  résout l'id de la tâche active *au moment de l'appel*, jamais depuis un
  id mis en cache — un vrai moteur refuserait sinon un `complete` sur une
  tâche déjà traitée ailleurs (`MockBpmEngine` simule volontairement ce
  refus, avec le code `com-task-0002`).

## Tester

```bash
flutter test
```

`test/onboarding_process_repository_test.dart` fait tourner le process de
bout en bout (sans UI) : démarrage, les deux branches de la passerelle
(montant faible → auto-approuvé, montant élevé → revue manuelle → refus),
et les deux cas d'erreur (formulaire invalide, tâche périmée).
