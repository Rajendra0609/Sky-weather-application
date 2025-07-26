import unittest
from weather import convert_celsius_to_fahrenheit

class TestWeather(unittest.TestCase):
    def test_conversion(self):
        self.assertEqual(convert_celsius_to_fahrenheit(0), 32)
        self.assertEqual(convert_celsius_to_fahrenheit(100), 212)

if __name__ == '__main__':
    unittest.main()

