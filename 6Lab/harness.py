import requests
from random import *

PICO_ECI = "LrJmBiEhiaxtFdkg1teRox"

"""Methods that deal with communicating with pico's via API"""


def create_sensor(name):
	# print('Creating sensor: %s' % name)
	res = requests.get("http://localhost:8080/sky/event/{}/1/sensor/new_sensor?name={}".format(PICO_ECI, name))
	return res.json()


def delete_sensor(name):
	# print('Deleting sensor: %s' % name)
	res = requests.get("http://localhost:8080/sky/event/{}/1/sensor/unneeded_sensor?name={}".format(PICO_ECI, name))
	return res.json()


def get_sensors():
	# print('Getting all sensors...')
	res = requests.get("http://localhost:8080/sky/cloud/{}/manage_sensors/sensors".format(PICO_ECI))
	return res.json()


def get_sensor_profile(eci):
	# print('Getting sensor profile for eci: %s' % eci)
	res = requests.get("http://localhost:8080/sky/cloud/{}/sensor_profile/get_profile".format(eci))
	return res.json()


def send_temp(eci, temp):
	# print('Sending temperature: %s to eci: %s % (temp, eci))
	requests.post("http://localhost:8080/sky/event/{}/1/wovyn/heartbeat".format(eci), json={"genericThing": {"data": {"temperature": [{"temperatureF": temp}]}}})


def get_temperatures():
	# print('Getting temperatures stored on all sensors')
	resp = requests.get("http://localhost:8080/sky/cloud/{}/manage_sensors/getTemperatures".format(PICO_ECI))
	return resp.json()


"""Helper methods for test cases"""


def create_sample_sensors():
	create_sensor('Pablo Sensor')
	create_sensor('Dustin Sensor')
	create_sensor('Big Sensor')
	create_sensor('Small Sensor')


def delete_all_sample_sensors():
	delete_sensor('Pablo Sensor')
	delete_sensor('Dustin Sensor')
	delete_sensor('Big Sensor')
	delete_sensor('Small Sensor')


def send_mock_temp_to_sensors():
	sensors = get_sensors()
	for key in sensors.keys():
		send_temp(sensors[key]["eci"], generate_random_temperature())


def generate_random_temperature():
	return randint(70, 90)


"""Test Cases"""


def test1():
	"""Tests creating 4 sensors and then deleting all four"""
	create_sample_sensors()
	sensors = get_sensors()
	assert len(sensors.keys()) == 4
	delete_all_sample_sensors()
	sensors = get_sensors()
	assert len(sensors.keys()) == 0


def test2():
	"""Tests creating 4 sensors and then trying to create a sensor w/ duplicate name"""
	create_sample_sensors()
	sensors = get_sensors()
	assert len(sensors.keys()) == 4
	create_sensor('Pablo Sensor')
	sensors = get_sensors()
	assert len(sensors.keys()) == 4
	delete_all_sample_sensors()
	sensors = get_sensors()
	assert len(sensors.keys()) == 0


def test3():
	"""Tests the sensors by ensuring they respond correctly to new temperature events"""
	create_sample_sensors()
	send_mock_temp_to_sensors()
	temps = get_temperatures()
	assert len(temps) == 4
	delete_all_sample_sensors()


def test4():
	"""Tests the sensor profile to ensure it's getting set reliably (only name and high attributes should be set)"""
	create_sample_sensors()
	sensors = get_sensors()
	for key in sensors.keys():
		sensor_profile = get_sensor_profile(sensors[key]["eci"])
		assert sensor_profile["name"] == key
		assert sensor_profile["location"] is None
		assert sensor_profile["high"] == 85.1
		assert sensor_profile["number"] is None
	delete_all_sample_sensors()


def main():
	test1()
	test2()
	test3()
	test4()


if __name__ == '__main__':
	main()
