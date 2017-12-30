FROM ruby:2.3.1
ENV PROJECT_DIR=/app
WORKDIR $PROJECT_DIR
RUN git clone git@github.com:zhenhuanlee/website2.0.git \
 && bundle install \
CMD ['RAKE_ENV=production', 'puma', '-C', 'config/puma.rb']
