FROM ruby:3.3

WORKDIR /pruebaBuda

COPY . /pruebaBuda/

RUN bundle install

CMD ["ruby", "app.rb"]