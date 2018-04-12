var rimraf = require('rimraf');
var express = require('express');
var bodyParser = require('body-parser');
var path = require('path');
var NodeGit = require("nodegit");
var PORT = process.env.PORT || 5000;
var { run } = require('runjs');
var ghpages = require('gh-pages');
var CONFIG = {
  PATH_DUMP: path.join(__dirname, '_dump'),
  PATH_LOCAL: path.join(__dirname, '_dump/auto-wcag'),
  PATH_SITE: path.join(__dirname, '_dump/auto-wcag/_site'),
  REPO: {
    REMOTE: 'https://github.com/auto-wcag/auto-wcag.git',
  },
  USER: {
    name: 'jkodu',
    email: 'jey.nandakumar@gmail.com'
  }
};
var LOG_TYPE = Object.freeze({
  ERROR: 0,
  INFO: 1
});
var Logger = function () {
  var logs = [];
  return function (log) {
    if (log) {
      logs.push(log);
    }
    return logs;
  }
}
express()
  .use(express.static(path.join(__dirname, 'public')))
  .use(bodyParser.json())
  .use(bodyParser.urlencoded({
    extended: true
  }))
  .set('views', path.join(__dirname, 'views'))
  .set('view engine', 'ejs')
  .get('/', function (req, res) {
    return res.render('pages/index')
  })
  .post('/deployer', function (req, res) {
    var logger = new Logger();
    logger({
      type: LOG_TYPE.INFO,
      message: 'REQUEST: Body: ' + JSON.stringify(req.body)
    });
    logger({
      type: LOG_TYPE.INFO,
      message: 'BEGIN: Cleaning dir: ' + CONFIG.PATH_DUMP
    });
    var fromBranch = req.body.fromBranch;
    var toBranch = req.body.toBranch;
    rimraf(CONFIG.PATH_DUMP, function (err) {
      if (err) {
        logger({
          type: LOG_TYPE.ERROR,
          message: 'FAIL: Cleaning dir: ' + CONFIG.PATH_DUMP
        });
        res.send(logger());
      } else {
        logger({
          type: LOG_TYPE.INFO,
          message: 'END: Cleaning dir:' + CONFIG.PATH_DUMP
        });
        NodeGit.Clone(
          CONFIG.REPO.REMOTE,
          CONFIG.PATH_LOCAL, {
            checkoutBranch: fromBranch,
            fetchOpts: {
              callbacks: {
                certificateCheck: function () {
                  return 1;
                }
              }
            }
          })
          .catch(function (err) {
            logger({
              type: LOG_TYPE.ERROR,
              message: 'FAIL: Error cloning repo: ' + err
            });
            res.send(logger());
          })
          .then(function (repo) {
            logger({
              type: LOG_TYPE.INFO,
              message: 'Respository cloned successfully: ' + repo
            });
            return;
          })
          .then(function () {
            logger({
              type: LOG_TYPE.INFO,
              message: 'Running - npm run gh-pages-build'
            })
            return run('npm run gh-pages-build');
          })
          .then(function () {
            logger({
              type: LOG_TYPE.INFO,
              message: 'Running - rm -rf node_modules/gh-pages/.cache'
            })
            return run('rm -rf node_modules/gh-pages/.cache')
          })
          .then(function () {
            logger({
              type: LOG_TYPE.INFO,
              message: 'Publishing to gh-pages'
            });
            ghpages
              .publish(CONFIG.PATH_SITE, {
                branch: toBranch,
                repo: CONFIG.REPO.REMOTE,
                message: 'Auto-generated static site from branch ' + fromBranch,
                user: {
                  name: 'jkodu',
                  email: 'jey.nandakumar@gmail.com'
                },
              }, function (err) {
                if (err) {
                  logger({
                    type: LOG_TYPE.ERROR,
                    message: 'Error publishing to git ' + err
                  });
                  res.send(logger());
                } else {
                  logger({
                    type: LOG_TYPE.INFO,
                    message: 'Published successfully to ' + CONFIG.REPO.REMOTE + ' ' + toBranch
                  });
                  res.send(logger());
                }
              });
          });
      }
    });
  })
  .listen(PORT, function () {
    console.log(`Listening on ${PORT}`);
  });