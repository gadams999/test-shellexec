# lambda-layer-boto3

Use one of these boto3 layers when you want:

```python
>>> import boto3
>>> boto3.__version__
'{{new_version}}'
```

instead of:

```python
>>> import boto3
>>> boto3.__version__
'1.7.74'
```

## Overview

This repository monitors for new versions of the python boto3 package to be published on pypi. It then builds new [Lambda layers](https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html)  and publishes them to all support AWS regions. They can be referenced from your functions to provide the latest boto3 and botocore functionality for python 2.7, 3.6, and 3.7.

For each specific python version (and one that combines all versions),  reference the public ARN when creating or modifying a new python Lambda function via the console, AWS CLI, CloudFormation template, or programmatically using an SDK. Once added, invoked Lambda functions will use the layer's version of boto3 and dependencies such as botocore.

For each version of python, there is a separate version that is published. There is also a *combined* version that contains all support versions of python, each in its own site-packages structure:

```
python
└── lib
    ├── python2.7
    │   └── site-packages
    │       ├── bin
    │       ├── boto3
    │       ├── boto3-1.9.78.dist-info
            ...
    │       ├── urllib3
    │       └── urllib3-1.24.1.dist-info
    ├── python3.6
    │   └── site-packages
    │       ├── __pycache__
    │       ├── bin
    │       ├── boto3
    │       ├── boto3-1.9.78.dist-info
            ...
    │       ├── urllib3
    │       └── urllib3-1.24.1.dist-info
    └── python3.7
        └── site-packages
            ├── __pycache__
            ├── bin
            ├── boto3
            ├── boto3-1.9.78.dist-info
            ...
            ├── urllib3
            └── urllib3-1.24.1.dist-info
```
Depending upon the python version, the specific `python/lib/pythonVERSION/` set of site-packages wil be used.


## Usage

Manually, you can reference the ARN in the region where the function resides and for the python version in use. The following are examples using the python 2.7 layer in Oregon (us-west-2) with the ARN: arn:aws:lambda:us-west-2​:123456789012:​layer:boto3-python27:3.

### Console

When creating or modifying a Lambda, you can click on the Layers icon on the Configuration page for the function, click on Add a layer at the bottom, then provide a layer version with the ARN:

![console_add_layer](../img/console_add_layer.png)

### CloudFormation

Add the Layers and ARN parameters to a function's definition in either an `AWS::Serverless:Function` or `AWS::Lambda::Function` resource type:

```yaml
Resources:
  FunctionNeedsBoto3Example:
    Type: 'AWS::Serverless::Function'
    Properties:
      CodeUri: s3://base-code-without-boto3-included/hello.zip
      Handler: lambda.handler
      Runtime: python2.7
      Layers:
        - arn:aws:lambda:us-west-2:123456789012:layer:boto3-python27:3
      Environment:
        ENV_VAR1: some_value
```

### Programmatically or CI/CD

Based on the pipeline, make a API call to return the most recent ARNs for a give region and optionally filter for a specific python/boto3 version. :bulb: Older package versions are not published in this document.


## Table of entries

<table>
    <thead>
        <tr>
            <th align="center" colspan=4>lambda-layer-boto3 Version: 1.9.78</th>
        </tr>
        <tr>
            <th>Region</th>
            <th>Version</th>
            <th>Public ARN</th>
            <th>Date Create (UTC)</th>
        </tr>
    </thead>
    <tbody><tr>
            <td> us-east-1 </td>
            <td> python2.7 </td>
            <td>arn:aws:lambda:us-east-1:904880203774:layer:boto3-python27:3 </td>
            <td>1547506967 </td><tr>
            <td> us-east-1 </td>
            <td> python3.6 </td>
            <td>arn:aws:lambda:us-east-1:904880203774:layer:boto3-python36:4 </td>
            <td>1547506955 </td><tr>
            <td> us-east-1 </td>
            <td> python3.7 </td>
            <td>arn:aws:lambda:us-east-1:904880203774:layer:boto3-python37:3 </td>
            <td>1547506981 </td><tr>
            <td> us-east-1 </td>
            <td> python2.7,python3.6,python3.7 </td>
            <td>arn:aws:lambda:us-east-1:904880203774:layer:boto3-combined:5 </td>
            <td>1547506945 </td><tr>
            <td> us-west-2 </td>
            <td> python2.7 </td>
            <td>arn:aws:lambda:us-west-2:904880203774:layer:boto3-python27:3 </td>
            <td>1547507012 </td><tr>
            <td> us-west-2 </td>
            <td> python3.6 </td>
            <td>arn:aws:lambda:us-west-2:904880203774:layer:boto3-python36:3 </td>
            <td>1547507004 </td><tr>
            <td> us-west-2 </td>
            <td> python3.7 </td>
            <td>arn:aws:lambda:us-west-2:904880203774:layer:boto3-python37:3 </td>
            <td>1547507017 </td><tr>
            <td> us-west-2 </td>
            <td> python2.7,python3.6,python3.7 </td>
            <td>arn:aws:lambda:us-west-2:904880203774:layer:boto3-combined:3 </td>
            <td>1547506995 </td></tr>
    </tbody>
</table>
