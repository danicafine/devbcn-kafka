import time
import random

from classes.customer import Customer 
from classes.customermask import CustomerMask
from helpers import clients,logging

from confluent_kafka.error import SerializationError

logger = logging.set_logging('customer_streaming')
config = clients.config()
    

if __name__ == '__main__':
    # set up Kafka Consumer for Users
    consumer = clients.consumer(clients.customer_deserializer(), 'consumer-group-customermask', [config['topics']['customers']])
    
    # set up Kafka Producer for UserMask
    producer = clients.producer(clients.customermask_serializer())

    # start consumption loop
    try:
        while True:
            msg = consumer.poll(1.0)

            if msg is None:
                logger.info("Did not fetch a message.")
            else:
                # received a message
                customer = msg.value()
                print(f"Consuming key {customer.userid} and value {customer.to_dict()}")

                # generate customermask object
                customermask = CustomerMask(customer.registertime, customer.userid, customer.regionid)
            
                # send data to Kafka
                print(f"Producing key {customer.userid} and value {customermask.to_dict()}")
                producer.produce(config['topics']['customermasks'], key=str(customer.userid), value=customermask) 

                producer.poll()
                producer.flush()

            time.sleep(5)
    except SerializationError as e:
        # report malformed record, discard results, continue polling 
        logger.error("Message deserialization failed %s", e)
        raise    
    except Exception as e:
        logger.error("Got other exception %s", e)     
    finally:
        consumer.close()
