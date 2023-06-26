import time
import random
import sys

from classes.customer import Customer 
from helpers import clients,logging

logger = logging.set_logging('customer_producer')
config = clients.config()
            

if __name__ == '__main__':
    # set up Kafka Producer for Customers
    producer = clients.producer(clients.customer_serializer())

    userids = range(5)
    # start 5s production loop
    try:
        while True:
            for userid in userids:
                key = "User_" + str(userid)
                registertime = int(time.time() * 1000)
                regionid = "Region_" + str(random.randrange(15))
                gender = random.choice(['FEMALE', 'MALE', 'OTHER', 'PREFER NOT TO ANSWER'])

                # generate Customer object
                customer = Customer(registertime, key, regionid, gender)
            
                # send data to Kafka
                print(f"Producing key {key} and value {customer.to_dict()}")
                producer.produce(config['topics']['customers'], key=str(key), value=customer) 

            producer.poll()
            producer.flush()

            time.sleep(5)
    except Exception as e:
        logger.error("Got exception %s", e)
        sys.exit()