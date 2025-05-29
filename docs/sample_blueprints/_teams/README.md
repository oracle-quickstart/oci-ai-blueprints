# Teams

#### Enforce resource quotas and fair sharing between teams using Kueue job queuing for efficient cluster utilization

Teams in OCI AI Blueprints enables administrators to enforce resource quotas and fair sharing between different organizational units, ensuring efficient allocation of GPU and CPU resources across multiple teams within a shared cluster. The system leverages Kueue, a Kubernetes job queuing system, to manage AI/ML workloads with workload queuing, prioritization, and resource-aware scheduling.

Each team functions as a logical grouping backed by a Kueue ClusterQueue and LocalQueue, with configurable nominal quotas (guaranteed resources), borrowing limits (extra resources when available), and lending limits (idle resources offered to other teams). This approach enables fair sharing, dynamic resource allocation, and improved utilization across workloads while maintaining strict resource boundaries.

The team system supports multi-tenant clusters where business units, research groups, or customers can be isolated while still sharing idle GPU/CPU capacity. Jobs are admitted based on available quotas and resource policies, with priority thresholds determining which teams can exceed their nominal quotas when extra resources are available.

Teams are particularly valuable for capacity planning, expressing organizational-level GPU budgets in code, and tracking consumption across different groups. The system automatically handles resource borrowing and lending through a shared cohort, ensuring that resources never sit idle while respecting team boundaries and priorities.

## Pre-Filled Samples

| Feature Showcase                                                                               | Title                            | Description                                                                                                                                                                                      | Blueprint File                                         |
| ---------------------------------------------------------------------------------------------- | -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------ |
| Create team with resource quotas and fair sharing policies for multi-tenant cluster management | Create Team with Resource Quotas | Creates a new team with configurable CPU, memory, and GPU quotas across multiple shapes, establishing borrowing and lending limits for fair resource sharing in multi-tenant environments.       | [create_team.json](create_team.json)                   |
| Deploy job workload within team resource boundaries using Kueue job queuing system             | Create Job with Team Assignment  | Demonstrates deploying a job workload that operates within a specific team's resource quotas, showcasing how jobs are queued and scheduled according to team policies and resource availability. | [create_job_with_team.json](create_job_with_team.json) |

---

# In-Depth Feature Overview

# Job Queuing

**Job Queuing** feature in OCI AI Blueprints leverage Kueue, a Kubernetes job queuing system, to manage AI/ML workloads more efficiently. Job Queueing introduces workload queuing, prioritization, and resource-aware scheduling, ensuring that jobs are admitted based on available quotas and resource policies. This features enables fair sharing, dynamic resource allocation, and improved utilization of GPUs across workloads.

**Teams** in OCI AI Blueprints lets admins enforce resource quotas and fair sharing between teams to decide when and where a job (batch, HPC, and AI/ML workloads) should wait or run within the cluster.

Each bucket (a _team_) has hard _nominal quotas_, soft _borrowing_ / _lending_ limits, an optional _priority threshold_, and a friendly name you reference in any job blueprint.  
Behind the scenes, the blueprint engine uses Kueue and wires up a `ClusterQueue`, `LocalQueue`, and a `Cohort` so workloads from different teams share idle capacity fairly while respecting their quotas. ([Kueue Docs](https://kueue.sigs.k8s.io/docs/overview/))

**Note: Make sure that your OCI AI Blueprints instance has been updated since 5/16/25 to ensure that the Kueue operator is installed.**

---

## What is a "Team"?

Including `recipe_mode: team` and the `team` object to a blueprint creates a new team.  
Submitting one:

1.  Creates a **ClusterQueue** that owns the quotas for your team — CPU, memory, GPU counts per shape. ([Kueue Docs](https://kueue.sigs.k8s.io/docs/overview/))
2.  Creates a namespaced **LocalQueue** so jobs in that namespace can enqueue against the ClusterQueue. ([Kueue Docs](https://kueue.sigs.k8s.io/docs/overview/))
3.  Joins that ClusterQueue to a **Cohort** so it can _borrow_ unused quota from sibling queues and _lend_ when idle. All teams share the same cohort across the entire blueprint engine ([Kueue Docs](https://kueue.sigs.k8s.io/docs/overview/))

---

## When should I use Teams?

- **Multi-tenant clusters** – isolate business units, research groups, or customers while still sharing idle GPU/CPU.
- **Fair-share batch environments** – let high-priority jobs pre-empt low-priority work within quota rules.
- **Capacity planning** – express org-level GPU budgets in code and track consumption with teams

---

## Core Concepts

**Team**

`ClusterQueue` + `LocalQueue` + `Namespace`

A **Team** is a logical grouping backed by a Kueue `ClusterQueue` (defining its `nominalQuota`, `lendingLimit`, and `borrowingLimit`) plus a corresponding `LocalQueue` in a dedicated Kubernetes `Namespace`, which together guarantee each team's reserved capacity and enable it to borrow or lend idle resources within the shared cluster.

- **Example:**  
  If you create a team called **"research"** with a `nominalQuota` of 10 GPUs, a `borrowingLimit` of 4 GPUs, and a `lendingLimit` of 4 GPUs, OCI AI Blueprints will spin up a `ClusterQueue` named "research-cluster-queue" configured with those limits and a `LocalQueue` named "research-local-queue" in the
  "research-namespace" `namespace`. Any job you submit in that namespace automatically enters the "research-local-queue" `LocalQueue`, giving it up to 10 GPUs guaranteed, the ability to borrow up to 4 GPUs when others are idle, and the willingness to lend up to 4 GPUs back to the cohort when it has idle capacity.

**Nominal Quota**
The `nominalQuota` is the guaranteed amount of resources reserved for a team that it can always use, independent of other teams' activity.

- **Example:**  
  If **Team A** has a `nominalQuota` of 10 GPUs, those 10 GPUs are always exclusively available to Team A before any borrowing or lending is considered.

**Borrowing Limit**

The `borrowingLimit` is the maximum extra resources a team may temporarily use beyond its nominal quota when there's idle capacity in the cluster.

- **Example:**  
  If **Team A** has a `nominalQuota` of 10 GPUs and a `borrowingLimit` of 4 GPUs, it can consume up to 14 GPUs whenever other teams aren't using theirs, but no more.

**Lending Limit**

The `lendingLimit` is the maximum idle resources a team is willing to offer into the shared pool for other teams to borrow.

- **Example:**  
  If **Team A** has a `nominalQuota` of 10 GPUs but is only using 6, and its `lendingLimit` is 4 GPUs, then up to 4 of its unused GPUs become available for others to borrow.

**Priority Threshold**

The `priorityThreshold` set at the team level assigns a single priority value to all of that team's workloads and determines which teams' jobs may exceed their nominal quotas when extra resources are available.

- **Example:**  
  If **Team A** has `priorityThreshold: 100` and **Team B** has `priorityThreshold: 50`, then when idle GPUs exist, Team A's workloads (priority 100) will be allowed to borrow first; Team B's workloads (priority 50) can borrow only if resources remain after Team A has taken theirs.

**Cohort**

A **Cohort** is the single, cluster-wide sharing group that all teams belong to, enabling them to borrow from and lend to one another according to their configured borrowing and lending limits.

- **Example:**  
  If **Team A** and **Team B** are both in the cluster cohort, then when Team A has idle GPUs it can lend up to its lending limit, and Team B can borrow from that shared pool (up to its borrowing limit), and vice versa — ensuring resources never sit idle in the cluster.

---

## Team Blueprint Schema (`recipe_mode: "team"`)

```json
{
  "recipe_mode": "team",
  "deployment_name": "team_creation",
  "team": {
    "team_name": "random_team",
    "priority_threshold": 100,
    "quotas": [
      {
        "shape_name": "BM.GPU.H100.8",
        "cpu_nominal_quota": "10",
        "cpu_borrowing_limit": "4",
        "cpu_lending_limit": "4",
        "mem_nominal_quota": "10",
        "mem_borrowing_limit": "4",
        "mem_lending_limit": "4",
        "gpu_nominal_quota": "10",
        "gpu_borrowing_limit": "4",
        "gpu_lending_limit": "4"
      }
    ]
  }
}
```

### Parameter Reference

Field

Description

`team_name`

Friendly name; becomes the `ClusterQueue` and `LocalQueue` name.

`priority_threshold`

Minimum workload priority allowed to borrow quota when nominal is exhausted.

`quotas[]`

List of shapes and per-resource quotas. Values are strings but parsed as quantities (e.g., `"10"` → `10`).

`*_nominal_quota`

Hard cap always available to this team.

`*_borrowing_limit`

Extra units the team may _borrow_ from cohort siblings when idle capacity exists.

`*_lending_limit`

Idle units this team is willing to _lend_ to others.

---

## Using a Team in a Job Blueprint

Once a team exists, reference it from any job:

```jsonc
{
  "recipe_mode": "job",
  "deployment_name": "job_deployment",
  "recipe_node_shape": "VM.GPU.A10.2",
  "recipe_team_info": { "team_name": "random_team" },
  ...
}

```

The blueprint engine:

1.  Adds the `kueue.x-k8s.io/queue-name` label so Kueue enqueues the Workload into the correct `LocalQueue`.
2.  Leaves pod scheduling to the default kube-scheduler once the Workload is **admitted** by Kueue.

---

## FAQ

**Q: Can a team's `borrowing_limit` exceed its `nominal_quota`?**  
A: Yes. Kueue allows `borrowingLimit` to be any non-negative quantity; it simply caps _how much_ the queue may exceed its nominal quota when idle resources are available.

**Q: What happens if multiple jobs exceed their team's quota at the same priority?**  
A: They queue FIFO inside the `LocalQueue`. When capacity frees up, Kueue admits them in order while honoring priority and borrowing rules.

**Q: How do I delete a team?**  
A: Undeploy the deployment you created to create the team. Make sure to undeploy all workloads for that team first.

---
