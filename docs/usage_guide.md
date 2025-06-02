# Ways to Access OCI AI Blueprints

Once you've installed OCI AI Blueprints into your tenancy (see [here](../INSTALLING_ONTO_EXISTING_CLUSTER_README.md) for the steps to install OCI AI Blueprints), you can work with OCI AI Blueprints three ways:

## **Option #1: OCI AI Blueprints UI Portal:**

1. Inside the OCI Console > Resource Manager, select the stack you created for OCI AI Blueprints

2. Go to the "Application Information" tab under Stack Details.

3. Copy the "Portal URL" into your browser

4. Upon first access, you must login - providing the "Admin Username" and "Admin Password" from the "Application Information" tab under Stack Details

## **Option #2: OCI AI Blueprints APIs via Web:**

OCI AI Blueprint's APIs are accessible via web interface. The APIs are shown as human-friendly HTML output for each OCI AI Blueprints API resource . These pages allow for easy browsing of resources, as well as forms for submitting data to the resources using `POST`, `PUT`, and `DELETE`.

1. Inside the OCI Console > Resource Manager, select the stack you created for OCI AI Blueprints

2. Go to the "Application Information" tab under Stack Details.

3. Copy the "OCI AI Blueprints API URL" into your browser

4. Upon first access, you must login - providing the "Admin Username" and "Admin Password" from the "Application Information" tab under Stack Details

5. Now, you can view and access all API endpoints for your instance of OCI AI Blueprints

## **Option #3: OCI AI Blueprints APIs via Curl/Postman**

You can interact with the APIs locally using Postman, curl or any API platform by doing the following:

1. Get your `OCI AI Blueprints API URL` (will reference this as **API URL** going forward), `Admin Usernmae` (will reference this as **username** going forward) and `Admin Password` (will reference this as **password** going forward) by following steps 1 - 3 above in Option #1
2. Once you have your username, password and API URL make a POST request to`<your-oci-ai-blueprints-api-url>/login` API to get your auth token:

```
curl --location --request POST '<your_api_url_here>/login/' \
--header 'Authorization: Token <your_token_here>' \
--form 'username="<your_username_here>"' \
--form 'password="<your_password_here>"'
```

The return JSON will be in the following format:

```
{

"token": "<your_auth_token>",

"is_new": true

}
```

3. Copy the `token` from the response
4. Now you can access any OCI AI Blueprints API by passing in this `token` for Authorization

### Curl Example

```
curl --location --request GET '<your_api_url_here>/oci_shapes/' \
--header 'Authorization: Token <your_token_here>'
```

### Postman

1. Click on the Authorization Tab for the request
2. Select Auth Type = OAuth 2.0
3. Paste your token value
4. Leave Header Prefix as "Token"

## **API Reference Documentation**

[API Reference Documentation](./api_documentation.md)
