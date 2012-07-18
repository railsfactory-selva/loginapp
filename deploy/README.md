# Deploy

It is assumed the server has already been provisioned, and all application deps have been installed by chef.
This is a interim solution until chef deploys the application.

## Usage

Deploy the application.
Your key will need added to the deploy user.  See the silverlining team for accesss.  Chef manages accounts for this project.

    $ rake <environment> vlad:deploy

## How it works

When executing the command above the following occurs.

* Rake loads lib/tasks/vlad.rake.  This is where you initialize vlad.
* Rake tasks in deploy/tasks/ are loaded.
* Vlad begins executing built-in and user defined tasks on the remote server(s).
* Eventually the application is checked out and services are restarted.

Vlad is light-weight, and intended to be simple.  Start defining tasks in deploy/tasks/app.rake, and move them to seperate files if necessary.
