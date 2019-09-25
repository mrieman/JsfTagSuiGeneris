# JsfTagSuiGeneris
Scans through jsf files, adding a unique parameter to all tags. Super helpful in automation testing

## What is it?!?!?
Well, it is a JSF tool that traverses through files, and adds a unique identiier to each tag

## How does it work?!?!
It uses Regex, grep, sed, and simple bash functions.
Using Regex and grep, the script idetifies all XHTML files that have tags that need the identifier.
Next, it loops through the file and modified the header to include the JSF Passthrough tag
Next, it loops through the file and modifies the individual tags with a predefined id PLUS a number to make it unique. 

## Example?!?!?!
It changes the tag by adding ''pass:mytag="myProject_<Number>"''. 
 * Old tag: <h:outputLabel for="input1234" value="This Cool Feild" />
 * New tag: <h:outputLabel pass:mytag="myProject_x_108" for="input1234" value="This Cool Feild" />
