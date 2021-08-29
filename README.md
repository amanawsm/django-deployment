# django-deployment

**This is an example of how to create a minimal pipeline for Django Apps**

![Pipeline Sample Image](pipeline-sample.png)

## Requirements

* AWS CLI already configured with Administrator access 
    - Alternatively, you can use a [Cloudformation Service Role with Admin access](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-iam-servicerole.html)
* [Github Personal Token](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/) with full permissions on **admin:repo_hook and repo**

## Configuring GitHub Integration

This Pipeline is configured to look up for GitHub information stored on [EC2 System Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-paramstore.html) such as Branch, Repo, Username and OAuth Token.

Replace the placeholders with values corresponding to your GitHub Repo and Token:

```bash
aws ssm put-parameter \
    --name "/service/amanawsm/github/repo" \
    --description "Github Repository name for Cloudformation Stack django-deployment" \
    --type "String" \
    --value "repository name"

aws ssm put-parameter \
    --name "/service/amanawsm/github/token" \
    --description "Github Token for Cloudformation Stack django-deployment" \
    --type "String" \
    --value "repository personal access token"

aws ssm put-parameter \
    --name "/service/amanawsm/github/user" \
    --description "Github Username for Cloudformation Stack django-deployment" \
    --type "String" \
    --value "repository owner"

aws ssm put-parameter \
    --name "/service/amanawsm/github/branch" \
    --description "Github Username for Cloudformation Stack django-deployment" \
    --type "String" \
    --value "repository branch"
```

**NOTE:** Keep in mind that these Parameters will only be available within the same region you're deploying this Pipeline stack. Also, if these values ever change you will need to [update these parameters](https://docs.aws.amazon.com/cli/latest/reference/ssm/put-parameter.html) as well as update the "django-deployment" Cloudformation stack.

## Pipeline creation

<details>
<summary>If you don't use Python or don't want to trigger the Pipeline from the `master` branch click here...</summary>
Before we create this 3-environment Pipeline through Cloudformation you may want to change a couple of things to fit your environment/runtime:


* **CodePipeline** uses the `master` branch to trigger the CI/CD pipeline and if you want to specify another branch you can do so by updating the following section in the `pipeline.yaml` file.
```yaml
CodePipelineStack:
    Type: AWS::CodePipeline::Pipeline
    Properties:
      RoleArn:
        Fn::Join:
          - ""
          - - "arn:aws:iam::"
            - Ref: AWS::AccountId
            - ":role/"
            - Ref: CodePipelineRole
      Stages:
        - Name: Source
          Actions:
            - InputArtifacts: []
              Name: Source
              ActionTypeId:
                Category: Source
                Owner: ThirdParty
                Version: "1"
                Provider: GitHub
              OutputArtifacts:
                - Name: MyApp
              Configuration:
                Owner: !Ref GitHubRepoOwner
                Repo: !Ref GitHubRepo
                Branch: !Ref GitHubBranch
                OAuthToken: !Ref GitHubOAuthToken
              RunOrder: 1
        - Name: Deploy
          Actions:
            - Name: DeployAction
              InputArtifacts:
                - Name: MyApp
              ActionTypeId:
                Category: Deploy
                Owner: AWS
                Version: 1
                Provider: CodeDeploy
              Configuration:
                ApplicationName:
                  Ref: CodeDeployApplication
                DeploymentGroupName:
                  Ref: CodeDeployGroups
              RunOrder: 1
      ArtifactStore:
        Type: S3
        Location: !Ref ArtifactBucket
```
</details>

Run the following AWS CLI command to create your first pipeline for your SAM based Serverless App:

```bash
aws cloudformation create-stack \
    --stack-name django-deployment \
    --template-body file://pipeline.yaml \
    --capabilities CAPABILITY_NAMED_IAM
```

This may take a couple of minutes to complete, therefore give it a minute or two and then run the following command to retrieve the Git repository:

```bash
aws cloudformation describe-stacks \
    --stack-name self-deployment-codepipelinepipeline \
    --query 'Stacks[].Outputs'
```

## Release through the newly built Pipeline

Although CodePipeline will orchestrate this 3-environment CI/CD pipeline we need to learn how to integrate our toolchain to fit the following sections:

> **Source code**

All you need to do here is to initialize a local `git repository` for your existing service if you haven't done already and connect to the `git repository` that you retrieved in the previous section.

```bash
git init
```

Next, add a new Git Origin to connect your local repository to the remote repository:
* [Git Instructions for HTTPS access](https://help.github.com/articles/adding-a-remote/)

> **Build steps**

This Pipeline expects `appspec.yaml` to be at the root of this `git repository` and **CodePipeline** expects will read and execute all sections during the Build stage.

Open up `appspec.yaml` using your favourite editor and customize it to your needs - Comments have been added to guide you what's needed

> **Triggering a deployment through the Pipeline**

The Pipeline will be listening for new git commits pushed to the `master` branch (unless you changed), therefore all we need to do now is to commit to master and watch our pipeline run through:

```bash
git add . 
git commit -m "Kicking the tires of my first CI/CD pipeline"
git push origin master
```
