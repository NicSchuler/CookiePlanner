# CookiePlanner

This App is deployed under [nschuler.shinyapps.io/CookiePlanner_V0_3/](https://nschuler.shinyapps.io/CookiePlanner_V0_3/).

## What it is for
Having cookies at christmas is beautiful. However, avoiding foodwaste due to unused ingredients left over while baking can be difficult if you plan to bake multiple recipes. Especially for eggs, where some recipes require more egg whites and others more egg yolks, there is a substantial risk of creating left overs.

This is exactly where the CookiePlanner comes into play: You can upload a file with all of your recipes, specify the ingredients which you want to scale and see in real time how much of which ingredient you would need. By doing so you can easily adjust the quantities per recipe until you are happy with the total amount of ingredients which you will use.

## How to use it
1. Download the input file [Input_Excel_Empty_Template.xlsx](https://github.com/NicSchuler/CookiePlanner/raw/main/Input_Excel_Empty_Template.xlsx)
2. Fill out the input file (i.e. enter your ingredients and then your recipes). If you need an example, you find it as [Input_Excel_Example.xlsx](https://github.com/NicSchuler/CookiePlanner/raw/main/Input_Excel_Example.xlsx)
3. Save the two sheets with ingredients and recipes as CSV with UTF-8 encoding, decimal separator must be "." (*this is a workaround needed due to an unresolved issue with some excel uploads to shinyapps.io. Please refer to [this guide](https://support.meistertask.com/hc/en-us/articles/4406395262354-How-Do-I-Encode-My-CSV-File-Using-the-UTF-8-Format-) on how to save files as CSV with encoding UTF-8.*)
4. Open the app under [nschuler.shinyapps.io/CookiePlanner_V0_3/](https://nschuler.shinyapps.io/CookiePlanner_V0_3/)
5. Upload the input files you filled out and load it
6. Go to the tab "Plan cookies" and enter the quantities in the input table
