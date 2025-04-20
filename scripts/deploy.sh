#!/bin/bash

set -e 

APP_DIR="/var/www/pink-collar-backend"
PRODUCTION_KEY="/home/ubuntu/production.key"
DEVELOPMENT_KEY="/home/ubuntu/development.key"


echo "Current user: $(whoami)"

sudo -u ubuntu -H bash <<EOF
echo "Current user: $(whoami)"
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
echo "Using Ruby version: $(ruby -v)"


#echo "Switching to ruby 2.6.10"

export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

#rbenv shell 2.6.10

echo "Starting deployment script..."

cd $APP_DIR

export RAILS_ENV=production
echo "Running bundle install..."
#RAILS_ENV=production bundle install
gem install bundler && bundle install --without development test

# Setup credentials
echo "Copying production and development keys..."
#mkdir -p $APP_DIR/config/credentials/
sudo cp $PRODUCTION_KEY $APP_DIR/config/credentials/production.key
sudo cp $DEVELOPMENT_KEY $APP_DIR/config/credentials/development.key

echo "Setting correct ownership and permissions..."
#sudo chown -R ubuntun:ubuntu $APP_DIR
#chmod -R 755 $APP_DIR

# Check if the database exists before running db:create
echo "Checking if database exists..."
if ! bundle exec rails db:migrate:status > /dev/null 2>&1; then
    echo "Database does not exist. Running rails db:create..."
    bundle exec rails db:create
fi

# Run migrations
echo "Running migrations..."
RAILS_ENV=production  bundle exec rails db:migrate

# Precompile assets
# echo "Precompiling assets..."
# bundle exec rails assets:precompile

#echo "switching back to ruby 3.3.6"

#rbenv shell 3.3.6

#restart nginx
sudo systemctl restart nginx

echo "Deployment completed successfully!"
EOF
