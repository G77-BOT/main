from __future__ import absolute_import, unicode_literals
import os
from celery import Celery

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'EcoSphereExchangeAPP.settings')

app = Celery('EcoSphereExchangeAPP')

# Load task modules from all registered Django app configs
app.config_from_object('django.conf:settings', namespace='CELERY')

app.conf.update(
    broker_url=os.getenv('CELERY_BROKER_URL', 'redis://localhost:6379/0'),
    result_backend=os.getenv('CELERY_RESULT_BACKEND', 'redis://localhost:6379/0'),
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
    timezone='UTC',
    enable_utc=True,
    task_annotations={
        '*': {'rate_limit': '10/s', 'time_limit': 300},  # 10 tasks per second, 5-min time limit
    },
)

# Automatically discover tasks
app.autodiscover_tasks()

# Task retry logic with error handling
@app.task(bind=True, max_retries=3, default_retry_delay=30)
def some_task(self, *args, **kwargs):
    try:
        # Task logic here
        pass
    except Exception as exc:
        raise self.retry(exc=exc)
