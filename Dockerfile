FROM ruby:2.3.1
ENV PROJECT_DIR=/app
WORKDIR $PROJECT_DIR
ADD Gemfile .
ADD Gemfile.lock .
RUN bundle install
ADD . .
CMD RACK_ENV=production bundle exec puma -C config/puma.rb
