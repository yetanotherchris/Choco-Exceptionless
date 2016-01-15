This Chocolately package installs Exceptionless as a self-hosted instance, following the instructions from:

https://github.com/exceptionless/Exceptionless/wiki/Self-Hosting

The package will install Exceptionless, including ElasticSearch/JDK8 and .NET 4.6. You will need to install IIS first and restart once the package install is complete.

### Customised usage

Note: **All argument values should be wrapped in a single quote if they contain anything except numbers/letters.**

- websitePort - The website port to use, default is 80.
- websiteDomain - The domain that the site binds to, default is "localhost".

Example:

    `choco install Exceptionless -packageParameters "/websitePort:82 /websiteDomain:'www.example.com'"`