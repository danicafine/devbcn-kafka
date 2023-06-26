from classes.customer import Customer 
from helpers import clients,logging

from confluent_kafka.error import SerializationError

logger = logging.set_logging('customer_consumer')
config = clients.config()
    

if __name__ == '__main__':
    # set up Kafka Consumer for Customers
    consumer = clients.consumer(clients.customer_deserializer(), 'consumer-group-customers', [config['topics']['customers']])

    # start consumption loop
    try:
        while True:
            msg = consumer.poll(1.0)

            if msg is None:
                logger.info("Did not fetch a message.")
            else:
                # received a message
                print(f"Consuming key {msg.value().userid} and value {msg.value().to_dict()}")

    except SerializationError as e:
        # report malformed record, discard results, continue polling 
        logger.error("Message deserialization failed %s", e)
        raise    
    except Exception as e:
        logger.error("Got other exception %s", e)     
    finally:
        consumer.close()
