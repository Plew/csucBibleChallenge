# GitHub Actions Deployment Setup

This document provides instructions for setting up automatic deployment to production when the `main` branch is updated.

## Overview

The deployment workflow will:
1. Trigger automatically when code is pushed to the `main` branch
2. Connect to your production server via SSH
3. Navigate to the application directory
4. Pull the latest code
5. Execute `kamal deploy` to deploy the application

## Required GitHub Secrets

You'll need to set up the following secrets in your GitHub repository settings:

### 1. SSH_PRIVATE_KEY
The private SSH key that can authenticate to your production server (philip@hetzdev).

**How to add:**
1. Go to your repository on GitHub
2. Click **Settings** > **Secrets and variables** > **Actions**
3. Click **New repository secret**
4. Name: `SSH_PRIVATE_KEY`
5. Value: The contents of your private SSH key (the one that corresponds to the public key authorized on philip@hetzdev)

### 2. SSH_HOST
The hostname or IP address of your production server.

**Value:** `hetzdev` (or the full IP/hostname if needed)

### 3. SSH_USER
The SSH user to connect as.

**Value:** `philip`

### 4. SSH_PORT (Optional)
The SSH port if different from 22.

**Value:** `22` (default, only add if you use a custom port)

### 5. KAMAL_REGISTRY_PASSWORD
Your Docker registry password/token.

**Value:** The Docker registry password (currently in `.kamal/secrets`)

### 6. RAILS_MASTER_KEY
Your Rails master key for decrypting credentials.

**Value:** The contents of `config/master.key`

## Workflow File

Create the file `.github/workflows/deploy.yml` with the following content:

```yaml
name: Deploy to Production

on:
  push:
    branches:
      - main

jobs:
  deploy:
    name: Deploy with Kamal
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v5

      - name: Set up SSH
        uses: webfactory/ssh-agent@v0.9.0
        with:
          ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}

      - name: Add server to known hosts
        run: |
          mkdir -p ~/.ssh
          ssh-keyscan -H ${{ secrets.SSH_HOST }} >> ~/.ssh/known_hosts

      - name: Deploy to production
        env:
          SSH_USER: ${{ secrets.SSH_USER }}
          SSH_HOST: ${{ secrets.SSH_HOST }}
        run: |
          ssh $SSH_USER@$SSH_HOST << 'ENDSSH'
            cd code/reverse
            git pull origin main
            kamal deploy
          ENDSSH

      - name: Deployment status
        if: success()
        run: echo "✅ Deployment completed successfully"

      - name: Deployment failed
        if: failure()
        run: |
          echo "❌ Deployment failed. Check the logs above for details."
          exit 1
```

## Setup Instructions

### Step 1: Add GitHub Secrets

1. Go to your repository: https://github.com/eleven89/reVerse
2. Navigate to **Settings** > **Secrets and variables** > **Actions**
3. Add each of the required secrets listed above

### Step 2: Create the Workflow File

Since I cannot directly modify files in `.github/workflows/` directory, you'll need to create the file manually:

1. Create a new file at `.github/workflows/deploy.yml`
2. Copy the workflow content from the "Workflow File" section above
3. Commit and push the file to your repository

### Step 3: Test the Workflow

1. After creating the workflow file, make a test commit to the `main` branch
2. Go to the **Actions** tab in your GitHub repository
3. You should see the "Deploy to Production" workflow running
4. Monitor the logs to ensure the deployment completes successfully

## Alternative: Simplified Approach with Kamal from Runner

If you prefer to run Kamal directly from the GitHub Actions runner (instead of SSH'ing to the server), you can use this alternative workflow:

```yaml
name: Deploy to Production

on:
  push:
    branches:
      - main

jobs:
  deploy:
    name: Deploy with Kamal
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v5

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: .ruby-version
          bundler-cache: true

      - name: Install Kamal
        run: gem install kamal

      - name: Set up SSH
        uses: webfactory/ssh-agent@v0.9.0
        with:
          ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}

      - name: Add server to known hosts
        run: |
          mkdir -p ~/.ssh
          ssh-keyscan -H 178.156.131.96 >> ~/.ssh/known_hosts

      - name: Create .kamal/secrets file
        run: |
          mkdir -p .kamal
          cat > .kamal/secrets << EOF
          KAMAL_REGISTRY_PASSWORD=${{ secrets.KAMAL_REGISTRY_PASSWORD }}
          RAILS_MASTER_KEY=${{ secrets.RAILS_MASTER_KEY }}
          EOF

      - name: Deploy with Kamal
        run: kamal deploy

      - name: Deployment status
        if: success()
        run: echo "✅ Deployment completed successfully"

      - name: Deployment failed
        if: failure()
        run: |
          echo "❌ Deployment failed. Check the logs above for details."
          exit 1
```

This approach:
- Runs Kamal directly from the GitHub Actions runner
- Requires only the SSH key, Docker registry password, and Rails master key as secrets
- May be more reliable as it doesn't depend on the server's git repository state

## Troubleshooting

### SSH Connection Issues
- Ensure the SSH private key has the correct permissions
- Verify the key is authorized on the production server
- Check that the hostname/IP is correct

### Kamal Deploy Failures
- Check that all required secrets are properly set
- Verify the Docker registry credentials are valid
- Ensure the production server has enough resources
- Review the Kamal logs in the Actions output

### Git Pull Issues (First Approach Only)
- Ensure the git repository on the server is clean
- Verify the main branch is tracking the correct remote

## Security Considerations

1. **Never commit secrets** to the repository - always use GitHub Secrets
2. **Rotate SSH keys** periodically for security
3. **Use deploy keys** if possible (read-only access with write access only where needed)
4. **Monitor deployments** regularly through the Actions tab
5. **Set up notifications** for failed deployments

## Recommended Approach

I recommend using the **second (simplified) approach** that runs Kamal directly from the GitHub Actions runner because:

1. It's more reliable - doesn't depend on the server's git state
2. It's cleaner - single source of truth (GitHub repository)
3. It's more secure - secrets are managed entirely by GitHub
4. It's easier to debug - all logs are in one place (GitHub Actions)

Choose the approach that best fits your workflow and comfort level.
