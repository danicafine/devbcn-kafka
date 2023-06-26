from confluent_kafka import SerializingProducer, DeserializingConsumer
from confluent_kafka.error import SerializationError
from confluent_kafka.serialization import StringSerializer, StringDeserializer
from confluent_kafka.schema_registry import SchemaRegistryClient
from confluent_kafka.schema_registry.avro import AvroSerializer, AvroDeserializer

from classes.customer import Customer
from classes.transaction import Transaction
from classes.customermask import CustomerMask

import yaml


def config():
	# fetches the configs from the available file
	with open('./config/config.yaml', 'r') as config_file:
		config = yaml.load(config_file, Loader=yaml.CLoader)

		return config


def sr_client():
	# set up schema registry
	sr_conf = config()['schema-registry']
	sr_client = SchemaRegistryClient(sr_conf)

	return sr_client


def customer_deserializer():
	return AvroDeserializer(
		schema_registry_client = sr_client(),
		schema_str = Customer.get_schema(),
		from_dict = Customer.dict_to_customer
		)


def transaction_deserializer():
	return AvroDeserializer(
		schema_registry_client = sr_client(),
		schema_str = Pageview.get_schema(),
		from_dict = Pageview.dict_to_transaction
		)


def customer_serializer():
	return AvroSerializer(
		schema_registry_client = sr_client(),
		schema_str = Customer.get_schema(),
		to_dict = Customer.customer_to_dict
		)


def transaction_serializer():
	return AvroSerializer(
		schema_registry_client = sr_client(),
		schema_str = Transaction.get_schema(),
		to_dict = Transaction.transaction_to_dict
		)


def customermask_serializer():
	return AvroSerializer(
		schema_registry_client = sr_client(),
		schema_str = CustomerMask.get_schema(),
		to_dict = CustomerMask.customermask_to_dict
		)


def producer(value_serializer):
	producer_conf = config()['kafka']
	producer_conf.update({ 'value.serializer': value_serializer })
	return SerializingProducer(producer_conf)


def consumer(value_deserializer, group_id, topics):
	consumer_conf = config()['kafka']
	consumer_conf.update({'value.deserializer': value_deserializer,
		'group.id': group_id
	})

	consumer = DeserializingConsumer(consumer_conf)
	consumer.subscribe(topics)

	return consumer