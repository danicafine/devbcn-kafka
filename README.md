# DevBCN Building Streaming Data Pipelines Workshop Materials

The following are materials for running basic Apache Kafka Python clients and stream processing samples to interact with Confluent Cloud clusters and Schema Registry. We've also included ksqlDB statements for you to manually execute in the Confluent Cloud ksqlDB editor to run a real-time fraud detection application. 

Please ensure that all of the workshop [prerequisites](prerequisites.md) have been met before proceeding with the exercises.

## Workshop Instructions 

These workshop instructions assume that you have followed along with the workshop slides (located at `devbcn_workshop_slides.pdf`, to be posted after the workshop) and have already done the following:

 - [ ] Created a Confluent Cloud Cluster and set up a cluster API key
 - [ ] Enabled Schema Registry and set up a Schema Registry API key
 - [ ] Started the Customers DataGen Connector
 - [ ] Started the Transactions DataGen Connector
 - [ ] Created a `customersmasks` topic for the stream processing script

If you would like to run this at home and automate all of the above, see the At Home Instructions section below.

### Python Configurations

For your convenience, a config file has been created in the `./config` directory as `config.yaml.sample`. To get started, update the API Key and Secret parameters as well as the Schema Registry API Key and Secret. Also confirm that your bootstrap server is properly set. Without these, the clients will not be able to connect to your cluster.

### Running

Before running these commands, remember to run `pip install -r requirements.txt`. 

Keep in mind that the producer and consumer clients have been set up to interact with the `customers` topic on Confluent Cloud but we have provided all of the `.avsc` files for you to interact with the `transactions` topic as well.

 - Execute producer code by running: `python3 customer_producer.py`
 - In a separate terminal window, execute the consumer code by running:  `python3 customer_consumer.py`
 - We have also included a small streaming example that transforms the events in the `customers` topic by masking a field. Not that you should have a producer running before you start the streaming example. You can execute the stream processing script by running: `python3 customer_streaming.py` 

### Altering Python Clients

This sample repository is meant to provide an easy sandbox environment to interact with consumers and producers. Review the [producer](https://docs.confluent.io/platform/current/installation/configuration/producer-configs.html) and [consumer](https://docs.confluent.io/platform/current/installation/configuration/consumer-configs.html) configuration parameters from the workshop and those included in `./config/config.yaml`.

You may also choose to create a `transactions` producer and consumer or update the `./helpers/clients.py` file to include additional datasets and schemas.

## At Home Instructions

See the automated setup [instructions](automated-setup/README.md) for further details.
