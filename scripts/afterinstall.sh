cd /home/ubuntu/venv/
source bin/activate
cd /home/ubuntu/hvd-hrs
if [ "$DEPLOYMENT_GROUP_NAME" == "Staging" ]; then
  sudo cp .env.dev .env
elif [ "$DEPLOYMENT_GROUP_NAME" == "Production" ]; then
  sudo cp .env.prod .env
fi
# Install packages
pip install -r requirements.txt
# Collect static files
python manage.py collectstatic --noinput
# Apply database migrations
echo "Apply database migrations"
python manage.py migrate
deactivate
sudo chown -R ubuntu:ubuntu /home/ubuntu/hvd-hrs
