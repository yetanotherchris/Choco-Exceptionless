# Choco-Exceptionless
Chocolately package for a self-hosted exceptionless installation.

### Requirements

- IIS
- Windows Server 2008 (it's only been tested on 2012 r2 however)
- Powershell 4
- You will need to restart once completed, for the .NET 4.6 installation to complete.

### What it does

This package installs the following dependencies via Powershell (it uses `choco install` instead of dependencies):

- .NET 4.6
- MongoDB 3.0.3
- ElasticSearch 1.7
- Java SDK

The package creates a website that binds to port 80, updates the configuration files to point to `localhost` and puts the MongoDB database and binaries inside the chocolately folder (a fix for the MongoDB package which currently [Dec 2015] is broken)

### Parameters

- /port - The website port to use, default is 80.
- /mongoDataDir - The data directory to put the mongo binaries and database, for example "D:"
- /websiteDomain - The domain that the site binds to, default is "localhost".

Example:

    choco install Exceptionless -packageParameters "/port:82 /mongoDataDir:'D:' /websiteDomain:'www.example.com'"
