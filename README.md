**Note: This project's usages are deprecated and is not under active development**


# aut-wcag-deployer

Auto WCAG Deployer: Which listens to GitHub Webhook to rebuild gh-pages.
[https://secret-sea-89054.herokuapp.com/](https://secret-sea-89054.herokuapp.com/)

## Running Locally

Make sure you have [Ruby](https://www.ruby-lang.org), [Bundler](http://bundler.io) and the [Heroku Toolbelt](https://toolbelt.heroku.com/) installed.

```sh
git clone repo
bundle
heroku local
```
Your app should now be running on [localhost:5000](http://localhost:5000/).

## Deploying to Heroku

```
heroku create or use existing containers after login using heroku login
git push heroku master
heroku open
```

## Running tests


Foreman runs rspec in watch mode `bundle exec guard -i`, alternatively run `rspec`.
