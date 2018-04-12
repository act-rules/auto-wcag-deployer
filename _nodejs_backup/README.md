# auto-wcag-deployer
Web hook to deploy gh-pages


## About
A Node.js app using [Express 4](http://expressjs.com/), which both listens to a web-hook from GitHub to listen to changes and deploy to `gh-pages`.

## Hosting
The application is hosted on heroku - 

## About Heroku
This application supports the [Getting Started with Node on Heroku](https://devcenter.heroku.com/articles/getting-started-with-nodejs) article - check it out.

## Running Locally
Make sure you have [Node.js](http://nodejs.org/) and the [Heroku CLI](https://cli.heroku.com/) installed.

```sh
 -- clone repo
$ cd your-directory
$ npm install
$ npm start
```

Your app should now be running on [localhost:5000](http://localhost:5000/).

## Deploying to Heroku

```
$ heroku create
$ git push heroku master
$ heroku open
```
or

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)
