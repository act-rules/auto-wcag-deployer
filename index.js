const rimraf = require('rimraf');
const express = require('express');
const path = require('path');
const NodeGit = require("nodegit");
const PORT = process.env.PORT || 5000;
const { run } = require('runjs');
const ghpages = require('gh-pages');
const CONFIG = {
  PATH_DUMP: path.join(__dirname, '_dump'),
  PATH_LOCAL: path.join(__dirname, '_dump/auto-wcag'),
  PATH_SITE: path.join(__dirname, '_dump/auto-wcag/_site'),
  REPO: {
    REMOTE: 'https://80db76ffb2c2a36d675e38eff68a2af6d8c25ffc@github.com/auto-wcag/auto-wcag.git',
    BRANCH_FROM: 'refactor-pages',
    BRANCH_TO: 'test-deployer'
  }
};
express()
  .use(express.static(path.join(__dirname, 'public')))
  .set('views', path.join(__dirname, 'views'))
  .set('view engine', 'ejs')
  .get('/', (req, res) => res.render('pages/index'))
  .get('/db', (req, res) => res.render('pages/db'))
  .get('/webHookPush', (req, res) => {
    console.log('Request: ', req.url);
    console.log('Beginning rm -rf of dir - ', CONFIG.PATH_DUMP);
    rimraf(CONFIG.PATH_DUMP, () => {
      console.log('Finished Cleaning dir - ', CONFIG.PATH_DUMP);
      NodeGit.Clone(
        CONFIG.REPO.REMOTE,
        CONFIG.PATH_LOCAL, {
          checkoutBranch: CONFIG.REPO.BRANCH_FROM,
          fetchOpts: { callbacks: { certificateCheck: () => { return 1; } } }
        })
        .catch((err) => {
          console.log('ERROR: ', err);
        })
        .then((repo) => {
          console.log('Respository Cloned Successfully - ', repo);
          return repo;
        })
        .then((repo) => {
          console.log('Running - npm run deploy')
          return run('npm run deploy');
        })
        .then((repo) => {
          console.log('Publishing to gh-pages');
          ghpages.publish(
            CONFIG.PATH_SITE,
            {
              branch: CONFIG.REPO.BRANCH_TO,
              repo: CONFIG.REPO.REMOTE,
              message: 'Auto-generated static site from branch ' + CONFIG.REPO.BRANCH_FROM,
              user: {
                name: 'jkodu',
                email: 'jey.nandakumar@gmail.com'
              }
            },
            (err) => {
              if (err) {
                console.error('Error Publishing to git ', CONFIG.REPO.REMOTE, CONFIG.REPO.BRANCH_TO);
              }
              console.log('Published successfully to ', CONFIG.REPO.REMOTE, CONFIG.REPO.BRANCH_TO);
            });
        })
    });
  })
  .listen(PORT, () => {
    console.log(`Listening on ${PORT}`);
  });