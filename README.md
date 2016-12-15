## FreeAgent Scripts

Ruby scripts for querying/modifying the data in a FreeAgent account.

### Configuration

* Scripts in this project are intended to be run on your local machine.
* So you need to create a `.env` file in the project root directory:

```
CLIENT_ID=<OAuth-client-ID>
CLIENT_SECRET=<OAuth-client-secret>
REFRESH_TOKEN=<OAuth-refresh-token>
ACCESS_TOKEN=<OAuth-access-token>
```

* You should be able to set these environment variables using the values stored in the secure note named "FreeAgent API - Go Free Range app" in the shared 1Password vault.
* The first pair of (client-related) values refer to the "Go Free Range" app (visit "App URL" in the secure note for more details).
* The second pair of (user-related) values refer to the "FreeAgent Reporting" user whose credentials are stored in the shared 1Password vault.
* It should be possible to just use the latter tokens without any further authorization, because the refresh token should never expire. However, if it turns out that this doesn't work then follow the instructions in the "Authorization" section below.
* The permissions granted to the scripts in this project are those assigned to the "FreeAgent Reporting" user mentioned above. You might need to change the permissions if your script needs access to different parts of the FreeAgent API.
* You can see the apps authorized by the currently logged in user via the FreeAgent settings: https://freerange.freeagent.com/settings/authorized_apps.

### Authorization

* Visit the "Authorization URL" stored in the secure note named "FreeAgent API - Go Free Range app" in the shared 1Password vault.
* In "Step 1" on the left-hand side set the "Input your own scopes" text field to any string and click the "Authorize APIs" button.
* Login as the "FreeAgent Reporting" user and approve the "Go Free Range" app.
* In "Step 2" you should now have an "Authorization code".
* Click the "Exchange authorization code for tokens" button.
* This should obtain a "Refresh token" and an "Access token" and take you to "Step 3".
* You'll need to select "Step 2" again to see these values.

## Monthly Timeslips Report

See https://github.com/freerange/business/wiki/Record-the-time-worked-per-project.

By default this will generate a CSV report for _last_ month which is probably what you want if you are working on the Harmonia task:

```
bundle exec ruby monthly-timeslips-report.rb
```

However, you can supply a reference date as a command-line argument in order to generate the report for another month:

```
bundle exec ruby monthly-timeslips-report.rb 2016-01-01
```

* Running this script reports the time recorded against all "active" projects for two hard-coded users (James M & Chris R).
* The script does not attempt to look-up the users via the API, because this requires more powerful permissions.
* For ease of integration with the existing spreadsheet, the time for each project is calculated in fractions of days.
* The format of the output is: month/year, project name, person's first name, time worked (in days).
