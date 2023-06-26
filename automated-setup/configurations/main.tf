# Configure the Confluent Provider
terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.38.0"
    }
  }
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

# spin up environment called "devnexus_env"
resource "confluent_environment" "devnexus_env" {
  display_name = "devnexus_env"
}

# spin up kafka cluster called "basic" in ksql_workshop_env (created above)
resource "confluent_kafka_cluster" "devnexus_cluster" {
  display_name = "devnexus_cluster"
  availability = "SINGLE_ZONE"
  cloud        = "AWS"
  region       = "us-east-2"
  basic {}

  environment {
    id = confluent_environment.devnexus_env.id
  }

  lifecycle {
    prevent_destroy = false
  }
}


data "confluent_schema_registry_region" "sr_region" {
  cloud   = "AWS"
  region  = "us-east-2"
  package = "ESSENTIALS"
}

resource "confluent_schema_registry_cluster" "essentials" {
  package = data.confluent_schema_registry_region.sr_region.package

  environment {
    id = confluent_environment.devnexus_env.id
  }

  region {
    id = data.confluent_schema_registry_region.sr_region.id
  }

  lifecycle {
    prevent_destroy = false
  }
}


# create a service account for ksqldb 
resource "confluent_service_account" "app-ksql-fraud-detection" {
  display_name = "app-ksql-fraud-detection"
  description  = "Service account to manage Fraud Detection Demo ksqlDB cluster"
}

# create a rolebinding for ksqldb service account (created above) to give it cluster admin access for basic cluster (created above)
resource "confluent_role_binding" "app-ksql-kafka-cluster-fraud-detection" {
  principal   = "User:${confluent_service_account.app-ksql-fraud-detection.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.devnexus_cluster.rbac_crn
}

resource "confluent_role_binding" "app-ksql-schema-registry-resource-owner" {
  principal   = "User:${confluent_service_account.app-ksql-fraud-detection.id}"
  role_name   = "ResourceOwner"
  crn_pattern = format("%s/%s", confluent_schema_registry_cluster.essentials.resource_name, "subject=*")

  lifecycle {
    prevent_destroy = false
  }
}

# create ksql cluster in env and cluster (created above) depending on the service account created above
resource "confluent_ksql_cluster" "fraud_detection_app_ksql_cluster" {
  display_name = "ksql_fraud_detection"
  csu          = 1
  kafka_cluster {
    id = confluent_kafka_cluster.devnexus_cluster.id
  }
  credential_identity {
    id = confluent_service_account.app-ksql-fraud-detection.id
  }
  environment {
    id = confluent_environment.devnexus_env.id
  }
  depends_on = [
    confluent_role_binding.app-ksql-kafka-cluster-fraud-detection,
    confluent_role_binding.app-ksql-schema-registry-resource-owner,
    confluent_schema_registry_cluster.essentials
  ]
}

# create a service account called topic manager 
resource "confluent_service_account" "devnexus-topic-manager" {
  display_name = "devnexus-topic-manager"
  description  = "Service account to manage Kafka cluster topics"
}

# create a role binding for topic manager service account (created above) that has cloud cluster admin access to basic cluster (created above)
resource "confluent_role_binding" "devnexus-topic-manager-kafka-cluster" {
  principal   = "User:${confluent_service_account.devnexus-topic-manager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.devnexus_cluster.rbac_crn
}

# create an api key for the topic manager service account (created above) 
resource "confluent_api_key" "devnexus-topic-manager-kafka-api-key" {
  display_name = "devnexus-topic-manager-kafka-api-key-instructor"
  description  = "Kafka API Key that is owned by 'devnexus-topic-manager' service account (instructor)"
  owner {
    id          = confluent_service_account.devnexus-topic-manager.id
    api_version = confluent_service_account.devnexus-topic-manager.api_version
    kind        = confluent_service_account.devnexus-topic-manager.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.devnexus_cluster.id
    api_version = confluent_kafka_cluster.devnexus_cluster.api_version
    kind        = confluent_kafka_cluster.devnexus_cluster.kind

    environment {
      id = confluent_environment.devnexus_env.id
    }
  }

  depends_on = [
    confluent_role_binding.devnexus-topic-manager-kafka-cluster
  ]
}

# create a topic called transactions using the api key (created above)
resource "confluent_kafka_topic" "transactions" {
  kafka_cluster {
    id = confluent_kafka_cluster.devnexus_cluster.id
  }
  topic_name    = "transactions"
  rest_endpoint = confluent_kafka_cluster.devnexus_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.devnexus-topic-manager-kafka-api-key.id
    secret = confluent_api_key.devnexus-topic-manager-kafka-api-key.secret
  }


}

# create a topic called transactions_suspicious using the api key (created above)
resource "confluent_kafka_topic" "transactions_suspicious" {
  kafka_cluster {
    id = confluent_kafka_cluster.devnexus_cluster.id
  }
  topic_name    = "transactions_suspicious"
  rest_endpoint = confluent_kafka_cluster.devnexus_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.devnexus-topic-manager-kafka-api-key.id
    secret = confluent_api_key.devnexus-topic-manager-kafka-api-key.secret
  }
}

# create a kafka topic called users using the api key (created above)
resource "confluent_kafka_topic" "customers" {
  kafka_cluster {
    id = confluent_kafka_cluster.devnexus_cluster.id
  }
  topic_name    = "customers"
  rest_endpoint = confluent_kafka_cluster.devnexus_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.devnexus-topic-manager-kafka-api-key.id
    secret = confluent_api_key.devnexus-topic-manager-kafka-api-key.secret
  }
}

# create a service account called "devnexus-connect-manager"
resource "confluent_service_account" "devnexus-connect-manager" {
  display_name = "devnexus-connect-manager"
  description  = "Service account to manage Kafka cluster"
}

# create a role binding to the devnexus-connect-manager service account (created above) to give it cluster admin access for basic cluster (created above)
resource "confluent_role_binding" "devnexus-connect-manager-kafka-cluster" {
  principal   = "User:${confluent_service_account.devnexus-connect-manager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.devnexus_cluster.rbac_crn
}

# create an api key for the connect-manager service account (created above)
resource "confluent_api_key" "devnexus-connect-manager-kafka-api-key" {
  display_name = "devnexus-connect-manager-kafka-api-key"
  description  = "Kafka API Key that is owned by 'devnexus-connect-manager' service account"
  owner {
    id          = confluent_service_account.devnexus-connect-manager.id
    api_version = confluent_service_account.devnexus-connect-manager.api_version
    kind        = confluent_service_account.devnexus-connect-manager.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.devnexus_cluster.id
    api_version = confluent_kafka_cluster.devnexus_cluster.api_version
    kind        = confluent_kafka_cluster.devnexus_cluster.kind

    environment {
      id = confluent_environment.devnexus_env.id
    }
  }

  depends_on = [
    confluent_role_binding.devnexus-connect-manager-kafka-cluster
  ]
}

# create a service account called "fraud-detection-application-connector"
resource "confluent_service_account" "fraud-detection-application-connector" {
  display_name = "fraud-detection-application-connector"
  description  = "Service account for Datagen Connectors"
}

# create an api key tied to the fraud-detection-application-connector service account (created above)
resource "confluent_api_key" "fraud-detection-application-connector-kafka-api-key" {
  display_name = "fraud-detection-application-connector-kafka-api-key"
  description  = "Kafka API Key that is owned by 'fraud-detection-application-connector' service account"
  owner {
    id          = confluent_service_account.fraud-detection-application-connector.id
    api_version = confluent_service_account.fraud-detection-application-connector.api_version
    kind        = confluent_service_account.fraud-detection-application-connector.kind
  }
 managed_resource {
    id          = confluent_kafka_cluster.devnexus_cluster.id
    api_version = confluent_kafka_cluster.devnexus_cluster.api_version
    kind        = confluent_kafka_cluster.devnexus_cluster.kind

    environment {
      id = confluent_environment.devnexus_env.id
    }
  }
}

# created an ACL called "fraud-detection-application-connector-describe-on-cluster" that grants the application-connector service account describe permission on the basic cluster (created above)
resource "confluent_kafka_acl" "fraud-detection-application-connector-describe-on-cluster" {
  kafka_cluster {
    id = confluent_kafka_cluster.devnexus_cluster.id
  }
  resource_type = "CLUSTER"
  resource_name = "kafka-cluster"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.fraud-detection-application-connector.id}"
  host          = "*"
  operation     = "DESCRIBE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.devnexus_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.devnexus-connect-manager-kafka-api-key.id
    secret = confluent_api_key.devnexus-connect-manager-kafka-api-key.secret
  }
}

# created an ACL called "fraud-detection-application-connector-write-on-transactions" that grants the application-connector service account write permission on the transactions topic (created above)
resource "confluent_kafka_acl" "fraud-detection-application-connector-write-on-transactions" {
  kafka_cluster {
    id = confluent_kafka_cluster.devnexus_cluster.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.transactions.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.fraud-detection-application-connector.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.devnexus_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.devnexus-connect-manager-kafka-api-key.id
    secret = confluent_api_key.devnexus-connect-manager-kafka-api-key.secret
  }
}

# created an ACL called "fraud-detection-application-connector-write-on-customers" that grants the application-connector service account write permission on the customers topic (created above)
resource "confluent_kafka_acl" "fraud-detection-application-connector-write-on-customers" {
  kafka_cluster {
    id = confluent_kafka_cluster.devnexus_cluster.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.customers.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.fraud-detection-application-connector.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.devnexus_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.devnexus-connect-manager-kafka-api-key.id
    secret = confluent_api_key.devnexus-connect-manager-kafka-api-key.secret
  }
}

# created an ACL called "fraud-detection-application-connector-create-on-data-preview-topics" that grants the application-connector service account create permission on the preview topics 
resource "confluent_kafka_acl" "fraud-detection-application-connector-create-on-data-preview-topics" {
  kafka_cluster {
    id = confluent_kafka_cluster.devnexus_cluster.id
  }
  resource_type = "TOPIC"
  resource_name = "data-preview"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.fraud-detection-application-connector.id}"
  host          = "*"
  operation     = "CREATE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.devnexus_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.devnexus-connect-manager-kafka-api-key.id
    secret = confluent_api_key.devnexus-connect-manager-kafka-api-key.secret
  }
}

# created an ACL called "fraud-detection-application-connector-write-on-data-preview-topics" that grants the application-connector service account write permission on the preview topics 
resource "confluent_kafka_acl" "fraud-detection-application-connector-write-on-data-preview-topics" {
  kafka_cluster {
    id = confluent_kafka_cluster.devnexus_cluster.id
  }
  resource_type = "TOPIC"
  resource_name = "data-preview"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.fraud-detection-application-connector.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.devnexus_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.devnexus-connect-manager-kafka-api-key.id
    secret = confluent_api_key.devnexus-connect-manager-kafka-api-key.secret
  }
}

# create a connector called "transactions_source" that creates a datagen connector called "DatagenSourceConnector_transactions" using the transactions quickstart of datagen and writes to the transactions topic (depends on acls above)
resource "confluent_connector" "transactions_source" {
  environment {
    id = confluent_environment.devnexus_env.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.devnexus_cluster.id
  }

  config_nonsensitive = {
    "connector.class"          = "DatagenSource"
    "name"                     = "DatagenSourceConnector_transactions"
    "kafka.auth.mode"          = "SERVICE_ACCOUNT"
    "kafka.service.account.id" = confluent_service_account.fraud-detection-application-connector.id
    "kafka.topic"              = confluent_kafka_topic.transactions.topic_name
    "output.data.format"       = "AVRO"
    "quickstart"               = "TRANSACTIONS"
    "tasks.max"                = "1"
  }

  depends_on = [
    confluent_kafka_acl.fraud-detection-application-connector-describe-on-cluster,
    confluent_kafka_acl.fraud-detection-application-connector-write-on-transactions,
    confluent_kafka_acl.fraud-detection-application-connector-create-on-data-preview-topics,
    confluent_kafka_acl.fraud-detection-application-connector-write-on-data-preview-topics,
  ]
}

# create a connector called "customers_source" that creates a datagen connector called "DatagenSourceConnector_customers" using the users quickstart of datagen and writes to the customers topic (depends on acls above)
resource "confluent_connector" "customers_source" {
  environment {
    id = confluent_environment.devnexus_env.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.devnexus_cluster.id
  }

  config_nonsensitive = {
    "connector.class"          = "DatagenSource"
    "name"                     = "DatagenSourceConnector_customers"
    "kafka.auth.mode"          = "SERVICE_ACCOUNT"
    "kafka.service.account.id" = confluent_service_account.fraud-detection-application-connector.id
    "kafka.topic"              = confluent_kafka_topic.customers.topic_name
    "output.data.format"       = "AVRO"
    "quickstart"               = "USERS"
    "tasks.max"                = "1"
  }

  depends_on = [
    confluent_kafka_acl.fraud-detection-application-connector-describe-on-cluster,
    confluent_kafka_acl.fraud-detection-application-connector-write-on-customers,
    confluent_kafka_acl.fraud-detection-application-connector-create-on-data-preview-topics,
    confluent_kafka_acl.fraud-detection-application-connector-write-on-data-preview-topics,
  ]
}

#create a schema registry api key 


#spin up an API key with global access on the cluster 
