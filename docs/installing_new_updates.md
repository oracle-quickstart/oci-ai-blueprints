# Installing New Updates

## Overview

OCI AI Blueprints team will release new versions of it's control-plane and frontend images once new features have been developed and thoroughly tested. In order to use the latest version of OCI AI Blueprints in your environment, apply the following steps.

### Steps:

1.  In OCI Console > Resource Manager > Stacks
2.  Choose the stack that was used to deploy OCI AI Blueprints originally
3.  Make sure you have chosen the correct stack by clicking on "Variables" in the lower left corner underneath the "Resources" section. Verify the variables correspond to the OCI AI Blueprints instance you are wanting to update.
4.  Verify that the API URL matches underneath the "Application Information" tab.
5.  After successful verification that this is the correct stack, click "Apply" (in the button group near the top of the page containing Edit / Plan / Destroy / More Actions buttons)
6.  A new Job in the stack will be created. Wait for this Job to finish
7.  Once the Job is finished and no errors occurred, the Job will show State = "Succeeded"
8.  At this point, your OCI AI Blueprints environment has been successfully updated and contains all the latest features

### Technical Background

Since the OCI AI Blueprints stack uses the "latest" image tag for all applications, when applying the stack again - Resource Manager pulls the latest image and applies it to your OKE cluster. No restart is needed since the deployments are restarted during the "Apply" phase.

### Error Handling

If errors occurs during the update process, please reach out to Vishnu Kammari at [vishnu.kammari@oracle.com](mailto:vishnu.kammari@oracle.com) or Grant Neuman at [grant.neuman@oracle.com](mailto:grant.neuman@oracle.com).
