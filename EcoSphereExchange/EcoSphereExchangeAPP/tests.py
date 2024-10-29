from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from .models import Product
import factory

# Factory for Product
class ProductFactory(factory.Factory):
    class Meta:
        model = Product
    name = factory.Faker('word')
    price = factory.Faker('random_number', digits=2)

class ProductAPITestCase(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.product = ProductFactory.create(name="Test Product", price=9.99)

    def test_get_products(self):
        response = self.client.get('/api/products/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['name'], self.product.name)
        self.assertEqual(float(response.data[0]['price']), float(self.product.price))

    def test_get_nonexistent_product(self):
        response = self.client.get('/api/products/999/')  # Assuming 999 doesn't exist
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_create_product_authenticated(self):
        # Example for authentication (if needed)
        # self.client.login(username='user', password='password')
        response = self.client.post('/api/products/', {
            'name': 'New Product',
            'price': 19.99
        })
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_create_product_invalid(self):
        response = self.client.post('/api/products/', {
            'name': '',
            'price': -10  # Invalid price
        })
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def tearDown(self):
        self.product.delete()  # Cleanup if needed

