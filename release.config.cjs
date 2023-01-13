/* eslint-disable no-template-curly-in-string */
module.exports = {
    branches: ['main'],
    plugins: [
      '@semantic-release/commit-analyzer',
      '@semantic-release/release-notes-generator',
      [
        '@semantic-release/changelog',
        {
          changelogFile: 'CHANGELOG.md',
        },
      ],
      [
        '@semantic-release/npm',
        {
          npmPublish: false,
        },
      ],
      /*[
        'semantic-release-github-pullrequest',
        {
          assets: ['CHANGELOG.md', 'package.json', 'package-lock.json'],
          baseRef: 'main',
        },
      ],*/
      '@semantic-release/github',
    ],
  }