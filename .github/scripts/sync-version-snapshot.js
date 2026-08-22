// Put the regenerated snapshot on the release-please branch through the
// GraphQL createCommitOnBranch mutation rather than `git push`: a commit that
// enters GitHub over the API with the bot GITHUB_TOKEN is signed by GitHub and
// marked Verified, where one pushed over the git protocol stays Unverified and
// a "Require signed commits" branch protection rejects it.
//
// The branch name arrives through $BRANCH_NAME and is never interpolated into
// this file, so it stays data and can never be read as JS.
const fs = require('fs');
const { execSync } = require('child_process');

const SNAPSHOT = 'test/version_test.rb.expected';

module.exports = async ({ github, context, core }) => {
  try {
    execSync(`git diff --quiet -- ${SNAPSHOT}`);
    core.info(`${SNAPSHOT} already answers for this version; nothing to commit.`);
    return;
  } catch {
    // A non-zero exit is the version having moved, which is why this runs.
  }

  const expectedHeadOid = execSync('git rev-parse HEAD').toString().trim();

  await github.graphql(
    `mutation($input: CreateCommitOnBranchInput!) {
      createCommitOnBranch(input: $input) { commit { url } }
    }`,
    {
      input: {
        branch: {
          repositoryNameWithOwner: context.payload.repository.full_name,
          branchName: process.env.BRANCH_NAME,
        },
        message: { headline: 'chore: sync the version snapshot' },
        expectedHeadOid,
        fileChanges: {
          additions: [
            {
              path: SNAPSHOT,
              contents: fs.readFileSync(SNAPSHOT).toString('base64'),
            },
          ],
        },
      },
    }
  );
};
