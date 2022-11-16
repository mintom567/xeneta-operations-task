# Xeneta Operations Task

## Practical case: Deployable development environment

### Overview

This repo contains source code for rates-app api service developed using Python and Terraform files required for severless containerised solution on AWS using ECS and Fargate.

### Architecture Diagram
![Deployable Dev Env Architecture](./readme_images/deployable_dev_env_architecture.jpg?raw=true "Deployable Dev Env Architecture")


### Pipeline Jobs

#### pre-infra-setup:

  * This job is required for creating the AWS S3 bucket for terraform tf-state storage and AWS ECR for image publishing. This job is manual you can enable by passing `PRE_INFRA` value `true`.

#### package-and-publish
   * This stage will dockerize the application and publish the rates-api to AWS ECR with the help of `awscli` and `docker-cli` using gitlab pipeline.
   * The image will be published to the AWS ECR registry (`TAG` can be updated in the `gitlab-ci.yml` variables or even you can pass it as a manual variable before triggering the pipeline).

#### terraform-plan
  * Terraform plan will creates an execution plan with preview of changes to build the infrastructure required for deploying the service to AWS Fargate.
  * This job will also update the ECS task definition to make use of the same image which we have published in the previous **publish** stage.

#### terraform-apply
  * Terraform apply will executes the actions proposed in a Terraform plan to create, update, or destroy infrastructure.

### Tools Used
- **CI/CD** - Used gitlab-CI for performing pipeline operations with the help of shared-runners provided by gitlab(trial-verison). Currently gitlab-pipelines won't be visible in github as we are using trial version.

- **Docker** - Used docker as containerization platform that is used to package your application and all its dependencies together in the form of containers to make sure that your application works seamlessly in any environment which can be developed or tested or in production. 

- **Terraform** - Terraform allows to build, change and manage infrastructure in a safe, consistent and repetable way by defining resource configurations that you can version, reuse, and share. Also terraform supports 50+ providers, can manage infrastructure on multiple cloud platforms, terraform state allows you to track resource changes throughout your deployments.

- **RDS** - Amazon RDS makes it easy to use replication to enhance availability, scalability and reliability for workloads.

### Prerequisites for running the pipeline

 - Configure the gitlab runners for your project
 - Update the following env variables in the gitlab CICD settings: **AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_DEFAULT_REGION, DOCKER_REGISTRY**
 - Make sure that the IAM User/Role should have List,Read,Write and Tagging access for the following: VPC, ECS, ECR, RDS, ELB, EC2, S3, Cloudwatch, Secrets Manager
- Make sure to run the `pre-infra-setup` job one time for creating S3 bucket and ECR required for other jobs/stages.

#### Test the application
Make use of the AWS load balancer url from the output once after the `terraform-apply` job is completed.

Response from api-server:

curl "http://application-loadbalancer-url/"

Response from RDS showing average rates between ports:

curl "http://application-loadbalancer-url/rates?date_from=2021-01-01&date_to=2021-01-31&orig_code=CNGGZ&dest_code=EETLL"

#### Output
![Rates-api Output](./readme_images/output-rates.jpg?raw=true "Rates-api Output")

## Case: Data ingestion pipeline

### Extended service

Imagine that for providing data to fuel this service, you need to receive and insert big batches of new prices, ranging within tens of thousands of items, conforming to a similar format. Each batch of items needs to be processed together, either all items go in, or none of them do.

Both the incoming data updates and requests for data can be highly sporadic - there might be large periods without much activity, followed by periods of heavy activity.

High availability is a strict requirement from the customers.

* How would you design the system?

![Data Ingestion](./readme_images/data_ingestion.jpg?raw=true "Data Ingestion")


As Data ingestion is based on variable size of dump data which is being uploaded to AWS S3 bucket manually by the user or via means of any external applications, we can't specify exact amount of compute resources inorder to process and store the data into DB. So inorder to match this variable requirement of compute resources, in the data processing section we will be using AWS Batch service backed by AWS Fargate. By using this service we will be able to queue the jobs and execute data processing task with the required compute resources. For AWS Fargate a docker image is needed to define the data processing logic, which will be pulled from AWS ECR(Elastic Container Registry). This image will be pushed to the ECR with the help of Gitlab CICD which will be triggered from the gitlab repo.
AWS Batch jobs will be triggered by an AWS Lambda function which is listening on the events that is happening on the S3 bucket, which is created to store the dump data. During the execution of AWS Batch job dump data will be pulled from Amazon S3 bucket and will be processed using AWS Fargate compute resources and the processed data will be written to Aurora DB and Aurora DB is having multiple slave DB's and a single master DB in this architecture design. An Amazon Aurora is recommended over Amazon RDS because of its availability, scalability respective to needed compute requirements. As I stated earlier, we will be having different volumes of dump data to be processed using AWS Batch jobs, so when there is a peak usage; Aurora will automatically scale up to meet the compute requirements and when the usage goes back to idle Aurora will scale down. Aurora is much more performance based as compared to RDS and it is highly recommended for High Availability and/or IOPS intensive work load. Logs and metrics will be captured by AWS Cloudwatch and respective alerts can be created during outage intervals.

* How would you set up monitoring to identify bottlenecks as the load grows?
From the initial design I have selected the AWS native services based on the chances of increasing load. AWS Batch jobs which is one of the critical component in this architecture design which is actually doing the data processing part. We will be having logs and metrics exported to AWS Cloudwatch, with this data cloudwatch will be creating alerts at the time of outages. These alerts can be replicated to AWS administrators or respective persons with the help of AWS SNS(Simple Notification Service). Cloudwatch dashboards can be effectively used to monitor AWS compute resources and DB instances.

* How can those bottlenecks be addressed in the future?

As per this architecture design I have selected AWS Fargate as the backend compute environment for processing the data. For cost cutting and in the case of lesser workload its better to use AWS Fargate but when there is a need to use more than 4 vCPUs or 30GB of memory or a GPU, its better to use AWS EC2 as the backend compute environment. With the help of EC2 autoscaling and the capability of AWS Batch to effectively maintain job queues, most of the performance bottlenecks will be cleared. We have used Aurora DB to mitigate increased workload and reduce the chances of DB downtime.

### Additional questions

Here are a few possible scenarios where the system requirements change or the new functionality is required:

<!-- 1. The batch updates have started to become very large, but the requirements for their processing time are strict. -->

2. Code updates need to be pushed out frequently. This needs to be done without the risk of stopping a data update already being processed, nor a data response being lost.

As we already implemented a CICD solution which will be creating a docker image from the latest updates that is happening on the source code, each change will be recorded and pushed as a docker image to ECR. As the AWS Batch jobs making use of these docker images, when a new image is introduced with the similar image tag that is configured on the job, from the next execution onwards, this image will be used. If we have a job already in execution which is currently running on a previous image, AWS Batch will continue to use that image to complete that execution. Because of this feature a new change in code won't stop the current data update which is being processed.

3. For development and staging purposes, you need to start up a number of scaled-down versions of the system.

The entire infra is written on terraform adhering to the concept of Infrastructre as Code(IaC). We can always make changes to the `variables.tf` file which will be acting as the configuration file for this infra. As we need a scale down version of the system, we will be replacing Aurora DB with AWS RDS, and will be using on-spot EC2 instances or AWS Fargate machines instead of AWS EC2 instances. These changes can be toggled by setting true or false value in `variables.tf` file for respective variables.
As we moved to AWS Fargate which will make drastic changes on the availabilty of compute resources and by switiching to AWS RDS we are actually taking the risk of having a bottle neck on IOPS. As we are designing a scale down version of the architecture for cost cutting we will be having only one instance of DB which will put us under the risk of data loss during disaster or data corruption.
We can also disable cloudwatch monitoring if it is not needed as the dev environment is not critical. We can also limit the max vCPU for the compute enviornment that is created for AWS Batch jobs to save compute resources and to save cost.
