# Frequently Asked Questions (FAQ) about AI Accelerator Packs 

1. **Is this a new OCI managed service?**  
   No, it's not a new OCI service. It's rather a solution that brings all necessary OCI services to deliver business value to the customer with a very simplified experience. Removes the guesswork and any friction to integrate services and OSS components to build an AI application.

2. **Are they available in all OCI public regions including DRCC?**  
   They are available in all OCI public regions today. Note that regions where these can be deployed are dependent on what GPUs and required services are supported. DRCC is in our roadmap but not supported yet.

3. **Technically can you explain what are the moving parts of this accelerator pack deployment package?**  
   Each AI accelerator deployment package is a `.zip` file OCI resource manager template. This `.zip` file has two main modules:  
   1. OCI Service Creator & Manifest  
   2. Internal OCI AI Blueprints Manifest  
   The external OCI service module provisions all OCI-level services needed for this work (e.g., OKE, OCI Gen AI Services, Oracle 26 AI services, etc.), then passes the AI app configuration and toggle parameters specific to the app to the OCI AI Blueprints engine. AI Blueprints deploys the app into OKE, sets necessary AI optimizations to the software, deploys GPU resources with necessary CUDA drivers, and downloads the containers, models, datasets, etc. It also creates an external endpoint for the apps to be accessible. A combination of this delivers end-to-end, one-click deployment and easy management experience.

   ![Manifest Of Ai Packs](/docs/ai_accelerator_packs/media/manifest-packaging.png)


4. **How are resources billed?**  
   Each pack has a Bill Of Materials (BOM) listing for each OCI SKU (AI service offering, OCPU, object storage, etc.) with negotiated unit prices based on reservation duration. Usage is invoiced based on the existing SKU meters.

5. **What is the cost to deploy and run OCI AI Accelerator Packs?**  
   Only the compute, storage, networking, and OCI services which each accelerator pack is using. All of this is deployed in the customer's tenancy. Besides this, some accelerator packs use Nvidia Enterprise AI Software that is billed at 25% on top of GPUs running these solutions.

6. **How fast can customers start?**  
   GPU capacity typically lands in a few hours; first Blueprint deployment takes less than 30 minutes.

7. **How is this different from NVAIE Blueprints?**  
    NVIDIA AI for Enterprise blueprints are not customized for OCI, nor do they use OCI-native services. NVAIE on OCI has too much technical friction for customers without a high level of AI knowledge and know-how to make sense of how to put them together and solve a business problem with AI. OCI AI Accelerator Packs combine the OCI services with NVAIE to create a native experience.

8. **How is this different from OCI AI Blueprints?**  
    OCI AI Blueprints only address one part of the AI application development lifecycle; they are geared towards deploying and managing an AI app, and they require GPUs as underlying infrastructure. OCI AI Accelerator Packs provide everything else, including Oracle AI services, that are needed for customers to create AI solutions to solve different use cases. They both complement each other, and AI Blueprints are contained in the Accelerator Packs.

9. **Can these deployments be integrated with standard deployment practices like Terraform?**  
    Yes, all deployments are packaged today as OCI Resource Manager templates and will be made available to download and customize through open-source GitHub repo. OCI Resource Manager templates use Terraform to deploy OCI resources; customers can easily integrate the same scripts to existing DevOps practices.

10. **What GPUs are needed to run these accelerator packs?**  
    Most accelerator packs are optimized to use Nvidia A10, A100 40/80 GB and L40S GPUs. Customers can also deploy them using OCI Gen AI Services where GPUs are not required.

11. **How will support work?**  
    Product team will support the solution with a dedicated global team, with no SLOs and SLAs attached for the full solution. However, the individual building blocks like OCI Services, Compute and NVAIE software all have SLOs and SLA attached.

12. **What about security and compliance?**  
    The Accelerator Packs are tenancy-isolated; data stays in-region and in-tenancy. You can attached any policies on top of this to control access and traffic flow.

14. **How do customers load LLMs?**  
    AI Blueprints allows: (1) pulling open-source LLMs directly from Hugging Face, or (2) leveraging proprietary models from Object Storage.

15. **Are accelerator packs customizable? Can customers swap BM and VM shapes?**  
    Customers can replace any GPU in the Starter Pack with another GPU shape which is not in the Accelerator Pack; however, negotiated discounts apply only to the shapes they purchased via Accelerator Packs.
