# Updating Deployed AI Accelerator Packs

This guide will discuss how to upgrade an already deployed AI Accelerator Pack to the latest version. 

## Steps:

1. Download the latest version of the accerator pack:

Go to: https://github.com/oracle-quickstart/oci-ai-blueprints/releases/tag/starter-packs and find the zip which corresponds to your pack:

- aiQEnterpriseSearch.zip - GPU-based RAG system
- vehicleRouteOptimizer.zip - Vehicle Route Plan Optimizer 
- videoSearchSummarization.zip - Video Search and Summarization
- aiQGenAIPowered.zip - PaaS based RAG system

Click on the zip you want to download to download it.

2. Go to your existing stack in the console:

- Ensure you are in the region you deployed the Accelerator Pack to
- Click Navigation Menu (top left hamburger) -> Developer Services -> Resource Manager -> Stacks
- Click your deployed stack

3. Click "Edit" which is a dropdown:

- Edit stack
- Where it says "Drop a .zip file" click "Browse"
- Find your downloaded file and select "upload"
- Click "Next"

4. If you want to leave all fields as is, and just apply the upgrade, leave as is and click "Next"

- **Note**: You cannot change the fields:
  - "Deployment Size"
  - "Worker Node Availability Domain"

These are not upgradeable - IE they require the resource to be destroyed and recreated by the resource manager. If that is desired, please destroy the stack and apply in the new region.

5. **Do not** click "Run apply" box. It is important to run a "plan" job to ensure the upgrade does not introduce any breaking changes to your current stack. Click "Save Changes".

6. Click "Plan" -> "Plan" which will create a plan job.

  - If the plan job does not succeed, either post in the #oci-ai-accelerator-packs slack channel for internal, or reach out to your Oracle team for help.
  - Investigate the plan to determine that no important resources will be destroyed. If so, reach out for help.

7. If the plan succeeds, go back to "Stack Details" and run "Apply" -> "Apply"

8. When the upgrade completes, your upgrade has been successfully applied!


