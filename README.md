#USAGE

Start up using ruby app.rb
Create a new slach command in slack for /timesheet and point it to this app
Now type in /timesheet @user to remind users to fill in timesheets and punish frequent offenders

#EXPLANATION

This is a very simple API to allow slack to call us. It has 1 main endpoint / which accepts a slack /timesheets slash command message then

1. increments the number of times that a @user has been late with their timesheet
1. notifies @user that they need to complete their timesheet
1. if @user has been late too many times then deals out a punishment