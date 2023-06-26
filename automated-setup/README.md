# Devnexus Workshop Automated Setup
Code to allow attendees of the Devnexus Atlanta Confluent Cloud Workshop to automatically deploy the resources created in the workshop. 

#### Pre-Requisites

###### Download the CLI and login to Confluent Cloud

Download the CLI following the directions [here](https://docs.confluent.io/confluent-cli/current/install.html).     
Login to Confluent Cloud: 
```
confluent login --save
```
###### Ensure Terraform 0.14+ is installed

Install Terraform version manager [tfutils/tfenv](https://github.com/tfutils/tfenv)

Alternatively, install the [Terraform CLI](https://learn.hashicorp.com/tutorials/terraform/install-cli?_ga=2.42178277.1311939475.1662583790-739072507.1660226902#install-terraform)

To ensure you're using the acceptable version of Terraform you may run the following command:
```
terraform version
```
Your output should resemble: 
```
Terraform v0.14.0 # any version >= v0.14.0 is OK
```

###### Create a Cloud API Key 

1. Open the Confluent Cloud Console
2. In the top right menu, select "Cloud API Keys"
3. Choose "Add Key" and select "Granular Access"
4. For Service Account, select "Create a New One" and name is <YOUR_NAME>-terraform-workshop-SA
5. Download your key
6. In the top right menu, select "Accounts & Access", select "Access" tab
7. Click on the organization and select "Add Role Assignment" 
8. Select the account you created (service account) and select "Organization Admin". Click Save

###### Download this repo

```
git clone https://github.com/danicafine/devnexus-kafka/
cd devnexus-kafka/automated-setup
```


## Set Up Workshop Resources 
In the setup of the workshop you will be provisioning the following resources: 
- An environment 
- A Kafka cluster 
- A ksqlDB cluster 
- Three topics 
- Two Datagen Source connectors to simulate mock data in the topics you created. 
- Necessary service accounts, API keys and ACLs. 

```
cd ksql-fraud-detection/configurations
```

Set variables in env.sh file and run: 
```
source env.sh
```

Install the confluent providers from the configuration.
```
terraform init
```

Validate terraform changes
```
terraform validate
```

Apply terraform changes to deploy resources
```
terraform apply
```

## Set Up ksqlDB Queries

For the next portion of the workshop, navigate to the [https://confluent.cloud/](Confluent Cloud Dashboard) and navigate to your cluster. On the left-hand menu you'll see a tab for "ksqlDB". Select it and choose the application that was provisioned using the terraform script. Navigate to the editor tab and run the following queries to set up an application to detect fraudulent transactions:       

First, create a stream called "transactions" built on top of the transactions topic.     
```
CREATE STREAM transactions WITH (
    KAFKA_TOPIC = 'transactions',
    VALUE_FORMAT = 'AVRO'
);
```

Second, create a table called "customers" built on top of the customers topic.     

```
CREATE TABLE customers (
    userid STRING PRIMARY KEY,
    registertime BIGINT,
    regionid STRING,
    gender STRING
) WITH (
    KAFKA_TOPIC = 'customers',
    VALUE_FORMAT = 'AVRO'
);
```

Create a stream based on the customers table and transactions stream.    

```
CREATE STREAM transactions_enriched AS
    SELECT *
    FROM transactions t
    LEFT JOIN customers c
        ON t.user_id = c.userid
    EMIT CHANGES;
```

Create a table of suspicious transactions.    

```
CREATE TABLE transactions_suspicious with ( KAFKA_TOPIC = 'transactions_suspicious',
    VALUE_FORMAT = 'AVRO') AS
    select t_user_id, count(T_TRANSACTION_ID) as cnt from TRANSACTIONS_ENRICHED 
    WINDOW TUMBLING (SIZE 60 seconds)
    GROUP BY t_user_id
    having count(T_TRANSACTION_ID)>4
    EMIT CHANGES;
```



