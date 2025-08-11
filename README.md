# Jenkins Infra (JCasC + Job DSL + Packer + Terraform)

## Quick start
1. **Bake AMI**
   ```bash
   cd packer
   packer init .
   packer build -var 'region=us-east-1' jenkins.pkr.hcl
   ```

2. **Launch with Terraform**
   ```bash
   cd ../terraform
   terraform init
   terraform apply      -var vpc_id=vpc-xxxx      -var subnet_id=subnet-xxxx      -var instance_profile_name=ec2-jenkins-role      -var key_name=your-keypair
   ```

3. Open the `jenkins_url` from outputs. First boot already has:
   - JCasC applied
   - AWS creds (Use EC2 instance profile → Assume JenkinS3Role)
   - Seed job created (not auto-built). Run it to generate jobs from `git@github.com:isstephen/infra-jenkins.git`.

### Notes
- Place your GitHub private key at `/var/lib/jenkins/.ssh/github` on the instance (or switch to Deploy Key / HTTPS).- To avoid /tmp low-space offline, service override sets `-Djava.io.tmpdir=/var/lib/jenkins/tmp`.- If you prefer `withAWS` pipeline step, install `pipeline-aws` plugin (already commented in plugins.txt).
