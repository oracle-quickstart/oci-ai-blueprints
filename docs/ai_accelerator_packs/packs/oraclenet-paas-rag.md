# OracleNet RAG on OCI

#### Advanced AI-Powered Interface for Retrieval Augmented Generation

Deploy OracleNet on OCI to leverage a state-of-the-art interface for interacting with Retrieval Augmented Generation (RAG) systems. Powered by Llama-Stack, this frontend provides a seamless user experience with real-time chat, collection management, and customizable configurations.

OracleNet integrates with backend technologies like Llama-Stack, OCI Gen-AI PaaS for embeddings/inference, and Oracle 26ai for advanced vector storage capabilities.

## Key Features Showcase

| Feature                  | Description                                                                         | Benefit                                                                           |
| ------------------------ | ----------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| Real-Time Chat Interface | Streamlined chat with instant AI responses for natural and efficient communication. | Enhances user engagement with quick, context-aware interactions.                  |
| Collection Management    | Organize data across collections with Llama-Stack, OCI Gen-AI PaaS, and 26ai.       | Simplifies data handling with powerful vector storage and retrieval capabilities. |
| Comprehensive Settings   | Customize RAG configurations to tailor AI responses to specific needs.              | Provides control over information retrieval and presentation for optimal results. |
| Citation Support         | Integrated source linking ensures response accuracy and transparency.               | Builds trust by allowing users to verify the origin of information.               |

---

# In-Depth Feature Overview

## What is OracleNet?

OracleNet is a cutting-edge interface designed to enhance interaction with AI-driven Retrieval Augmented Generation systems. Built on the innovative Llama-Stack, it offers:

- **Intuitive User Interface** – A visually appealing design with smooth animations and Oracle branding.
- **Advanced AI Integration** – Leverages Llama-Stack for inference, RAG, and safety features.
- **Customizable Experience** – Adjust settings for personalized AI interactions.
- **End-to-End Functionality** – A complete solution for production-grade AI workloads.

See the upstream project for full details on Llama-Stack: [https://github.com/meta-llama/llama-stack](https://github.com/meta-llama/llama-stack)

## How to Use It

OracleNet is designed for ease of use across various scenarios:

- **Chat Interactions**: Engage with the AI through the chat interface for quick answers and insights.
- **Data Organization**: Use collection management to structure data across silos, leveraging advanced vector storage.
- **Configuration Adjustments**: Tailor RAG settings via the comprehensive settings panel for specific use cases.
- **Source Verification**: Rely on citation links to validate AI responses.

For a detailed tutorial on maximizing the frontend’s capabilities, refer to the official documentation or support resources.

## FAQs

1. **Can I integrate OracleNet with other inference engines or backend systems?**

   - Currently, it is optimized for Llama-Stack and OCI Gen-AI PaaS.

2. **How do I customize the frontend for specific organizational needs?**

   - Use the settings interface to adjust RAG configurations. For deeper customizations, consult with our support team or refer to the developer documentation.

3. **My stack failed to destroy because of a "BucketNotEmpty" error. What should I do?**

   - This is an intentional choice by the team. We use an OCI object storage bucket to backup the files uploaded to the RAG database. We know that data is precious, and it is much worse to accidentally lose wanted data, than to spend time manually deleting the objects before destroying the stack. In this we, we know that the user has intended to delete the data prior to destroying the stack. After the bucket has had all objects removed, it is simplest to just delete the bucket manually and then destroy the stack as this confirms all objects and object versions are deleted.

   The error message looks like:
   ```
   Error: 409-BucketNotEmpty, Bucket named 'paas-rag-gzaGCN-bucket' is not empty. Delete all object versions first.
   ```

   If this is not the error you receive, please reach out to our support team.

4. **What if I encounter issues during deployment or usage?**
   - Check the troubleshooting section in the documentation, verify backend service configurations, and ensure port settings are correct. Our support team is also available for assistance.
