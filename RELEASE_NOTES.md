# Release Notes

The following document contains release notes. Each section will detail added features, what has changed, and what has been fixed. Release notes for the previous 5 releases will be maintained in this document. Click the dropdown next to a release to see its associated notes.

TODO (This file is intended to serve as a template for now):
<details>
<summary><strong>1.0.0</strong></summary>

### Added Features
 - Multinode inference
   - description one
   - description two
 - Blueprints can utilize RDMA connectivity between nodes
   - my description one
   - my description two

### Changed
 - Kuberay replaced by LeaderWorkerSet
 - MLFlow, Prometheus, and Grafana now use persistent volume claims instead of local storage
 - Anchored all versions of helm installs to specific versions which can be found [here](docs/versioning/QuickStartVersions.md).

### Fixed
 - Fixed an issue with mlflow deployments where all mlflow experiments would fail because "Experiment 1" did not exist - bug in mlflow and using :memory: as the runs database.
</details>

