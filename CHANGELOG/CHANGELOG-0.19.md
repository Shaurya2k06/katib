# [v0.19.0](https://github.com/kubeflow/katib/tree/v0.19.0) (2025-10-30)

## New Features

- feat(sdk): Support multiple pip index URLs. ([#2566](https://github.com/kubeflow/katib/pull/2566) by [@wassimbensalem](https://github.com/wassimbensalem))
- Add get_job_logs() API to Katib Python SDK ([#2580](https://github.com/kubeflow/katib/pull/2580) by [@adity1raut](https://github.com/adity1raut))
- feat: Add trial_timeout parameter to Katib tune API ([#2568](https://github.com/kubeflow/katib/pull/2568) by [@wassimbensalem](https://github.com/wassimbensalem))
- Upgrade Kubernetes Version to 1.34 ([#2573](https://github.com/kubeflow/katib/pull/2573) by [@Electronic-Waste](https://github.com/Electronic-Waste))
- Upgrade Kubernetes Version to 1.33 & Go to 1.24 ([#2572](https://github.com/kubeflow/katib/pull/2572) by [@Electronic-Waste](https://github.com/Electronic-Waste))
- Upgrade Kubernetes Version to 1.32.2 ([#2521](https://github.com/kubeflow/katib/pull/2521) by [@Electronic-Waste](https://github.com/Electronic-Waste))
- Adding out of the box support to TrainJob ([#2560](https://github.com/kubeflow/katib/pull/2560) by [@ram4444](https://github.com/ram4444))

## Bug Fixes

- fix(metrics-collector): Use strict validation to get remote image ([#2583](https://github.com/kubeflow/katib/pull/2583) by [@andreyvelich](https://github.com/andreyvelich))
- fix(controller): Fix RBAC to create TrainJobs ([#2581](https://github.com/kubeflow/katib/pull/2581) by [@andreyvelich](https://github.com/andreyvelich))
- [SDK] fix issue with serialization of LoraConfig ([#2567](https://github.com/kubeflow/katib/pull/2567) by [@Hexoplon](https://github.com/Hexoplon))
- Fix Istio sidecar injection by moving from annotations to labels ([#2527](https://github.com/kubeflow/katib/pull/2527) by [@madmecodes](https://github.com/madmecodes))
- Fix PSS restricted warnings ([#2528](https://github.com/kubeflow/katib/pull/2528) by [@akagami-harsh](https://github.com/akagami-harsh))

## Misc

- feat(release): Update Katib release script to publish SDK models ([#2584](https://github.com/kubeflow/katib/pull/2584) by [@andreyvelich](https://github.com/andreyvelich))
- chore(models): Move models into kubeflow_katib_api package ([#2579](https://github.com/kubeflow/katib/pull/2579) by [@kramaranya](https://github.com/kramaranya))
- Nominate @Electronic-Waste as Approver. ([#2574](https://github.com/kubeflow/katib/pull/2574) by [@Electronic-Waste](https://github.com/Electronic-Waste))
- Add license scan report and status ([#2564](https://github.com/kubeflow/katib/pull/2564) by [@fossabot](https://github.com/fossabot))
- chore: Bump go-containerregistry to v0.20.6 ([#2575](https://github.com/kubeflow/katib/pull/2575) by [@andreyvelich](https://github.com/andreyvelich))
- chore(deps): bump golang.org/x/oauth2 from 0.21.0 to 0.27.0 ([#2558](https://github.com/kubeflow/katib/pull/2558) by [@dependabot[bot]](https://github.com/apps/dependabot))
- feat(ci): Add Trivy Vulnerability Scan ([#2570](https://github.com/kubeflow/katib/pull/2570) by [@andreyvelich](https://github.com/andreyvelich))
- tenzen-y steps down from Katib approver role ([#2561](https://github.com/kubeflow/katib/pull/2561) by [@tenzen-y](https://github.com/tenzen-y))
- Bump golang.org/x/crypto from 0.31.0 to 0.35.0 ([#2543](https://github.com/kubeflow/katib/pull/2543) by [@dependabot[bot]](https://github.com/apps/dependabot))
- chore: Upgrade Go version to 1.23 ([#2526](https://github.com/kubeflow/katib/pull/2526) by [@tenzen-y](https://github.com/tenzen-y))
- feat(docs): Guide to report security vulnerabilities ([#2556](https://github.com/kubeflow/katib/pull/2556) by [@andreyvelich](https://github.com/andreyvelich))
- chore(docs): Add OpenSSF Badge ([#2555](https://github.com/kubeflow/katib/pull/2555) by [@andreyvelich](https://github.com/andreyvelich))
- [GSoC] Add e2e test for `tune` api with LLM hyperparameter optimization ([#2420](https://github.com/kubeflow/katib/pull/2420) by [@helenxie-bit](https://github.com/helenxie-bit))
- Bump brace-expansion in /pkg/ui/v1beta1/frontend ([#2551](https://github.com/kubeflow/katib/pull/2551) by [@dependabot[bot]](https://github.com/apps/dependabot))
- New fixing kustomize5 warning ([#2549](https://github.com/kubeflow/katib/pull/2549) by [@vikas-saxena02](https://github.com/vikas-saxena02))
- feat: add `CITATION.cff` file ([#2547](https://github.com/kubeflow/katib/pull/2547) by [@milinddethe15](https://github.com/milinddethe15))
- Bump github.com/golang-jwt/jwt/v4 from 4.5.1 to 4.5.2 ([#2533](https://github.com/kubeflow/katib/pull/2533) by [@dependabot[bot]](https://github.com/apps/dependabot))
- chore(test): Removed the no longer needed trigger-rerun-test.yaml ([#2540](https://github.com/kubeflow/katib/pull/2540) by [@hbelmiro](https://github.com/hbelmiro))
- chore(docs): Add Changelog Katib v0.18.0 ([#2537](https://github.com/kubeflow/katib/pull/2537) by [@andreyvelich](https://github.com/andreyvelich))
- Revert GHCR changes for Notebook examples ([#2536](https://github.com/kubeflow/katib/pull/2536) by [@saileshd1402](https://github.com/saileshd1402))
- [feature] move manifest image references to ghcr ([#2529](https://github.com/kubeflow/katib/pull/2529) by [@mahdikhashan](https://github.com/mahdikhashan))
- [feature] migrate docker images to ghcr ([#2520](https://github.com/kubeflow/katib/pull/2520) by [@mahdikhashan](https://github.com/mahdikhashan))
- Bump axios from 1.7.9 to 1.8.3 in /pkg/ui/v1beta1/frontend ([#2524](https://github.com/kubeflow/katib/pull/2524) by [@dependabot[bot]](https://github.com/apps/dependabot))
- Bump @babel/helpers from 7.25.0 to 7.26.10 in /pkg/ui/v1beta1/frontend ([#2523](https://github.com/kubeflow/katib/pull/2523) by [@dependabot[bot]](https://github.com/apps/dependabot))
- Support old-style TensorFlow events (tensorboard) ([#2467](https://github.com/kubeflow/katib/pull/2467) by [@garymm](https://github.com/garymm))
- Add 'KEP Usage' KEP and template link ([#2509](https://github.com/kubeflow/katib/pull/2509) by [@anishasthana](https://github.com/anishasthana))
- Add Changelog for Katib v0.18.0-rc.0 ([#2515](https://github.com/kubeflow/katib/pull/2515) by [@andreyvelich](https://github.com/andreyvelich))
- Bump Katib Python SDK to 0.18.0rc0 version ([#2514](https://github.com/kubeflow/katib/pull/2514) by [@andreyvelich](https://github.com/andreyvelich))

[Full Changelog](https://github.com/kubeflow/katib/compare/v0.18.0...v0.19.0)

