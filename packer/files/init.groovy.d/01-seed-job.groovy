// Creates a Pipeline seed job that reads Job DSL from your GitHub repo.
// NOTE: We do NOT auto-build at startup to avoid script-approval/sandbox issues.
// After first boot, run the seed job manually.
import jenkins.model.Jenkins
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition

def j = Jenkins.instance
if (j.getItem('seed-job') == null) {
  def script = '''
pipeline {
  agent any
  options { timestamps(); disableConcurrentBuilds() }
  triggers { pollSCM('H/5 * * * *') }   // or switch to webhook
  stages {
    stage('Checkout DSL') {
      steps {
        checkout([$class: 'GitSCM',
          userRemoteConfigs: [[url: 'git@github.com:isstephen/infra-jenkins.git', credentialsId: 'github-ssh']],
          branches: [[name: '*/main']]
        ])
      }
    }
    stage('Generate Jobs via DSL') {
      steps {
        jobDsl targets: 'dsl/**/*.groovy',
              removedJobAction: 'IGNORE',
              removedViewAction: 'IGNORE',
              lookupStrategy: 'SEED_JOB',
              sandbox: false   // keep false to avoid "run as user" requirement; approve scripts once via UI
      }
    }
  }
}
'''.stripIndent()

  def job = new WorkflowJob(j, 'seed-job')
  job.setDefinition(new CpsFlowDefinition(script, true))
  j.putItem(job)
  println "Created seed-job"
}
