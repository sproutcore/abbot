=====================================================================

DESCRIPTION:

JsDoc Toolkit is an automatic documentation generation tool for
JavaScript. It is written in JavaScript and is run from a command line
(or terminal) using Mozilla Rhino JavaScript engine. Using this tool
you can automatically turn JavaDoc-like comments in your JavaScript
source code into published output, such as HTML or XML.

For more information, to report a bug or to browse the technical
documentation for this tool please visit the official JsDoc Toolkit
project homepage: http://code.google.com/p/jsdoc-toolkit/

This project is based on the JSDoc.pm tool, created by Michael 
Mathews, maintained by Gabriel Reid. More information on JsDoc can
be found on the JSDoc.pm homepage: http://jsdoc.sourceforge.net/

Complete documentation on JsDoc Toolkit can be found on the project
wiki at http://code.google.com/p/jsdoc-toolkit/w/list


=====================================================================

USAGE:

Running JsDoc Toolkit on your desktop requires you to have Java
installed and the Mozilla Rhino JavaScript jar file (named "js.jar")
available. A copy of this jar file is included with the JsDoc Toolkit
distribution. To download Rhino yourself or to find out more go to 
the official Rhino web page: http://www.mozilla.org/rhino/

Before running the JsDoc Toolkit app you must change your current
working directory to the jsdoc-toolkit folder. Then follow the
examples below, or as shown on the project wiki.

On a computer running Windows a valid command line to run JsDoc
Toolkit might look like this:

 > java -jar app\js.jar app\run.js -a -t=templates\htm test\data\test.js

On Mac OS X or Linux the same command would look like this:

 $ java -jar app/js.jar app/run.js -a -t=templates/htm test/data/test.js

The above assumes your current working directory contains the app, test
and templates subdirectories from the standard JsDoc Toolkit 
distribution. If you have the js.jar file saved to a place in your
system's Java CLASSPATH, it can safely be omitted from the command.

To run JsDoc Toolkit from any directory, specify the path to the app
folder like so:

 > java -Djsdoc.dir=%BASE_DIR% -jar %RHINO% %RUN% %OPTS% %SRC_FILES%

So assuming the JsDoc Toolkit "app" directory is in "lib\jsdoc-toolkit"
you would specify that like so:

 > java -Djsdoc.dir=lib\jsdoc-toolkit <etc>

The output documentation files will be saved to a new directory named
"js_docs_out" (by default) in the current directory, or if you specify
a -d=somewhere_else option, to the somewhere_else directory.

For help (usage notes) enter this on the command line:

 > java -jar app\js.jar app\run.js -h

To run the unit tests included with JsDoc Toolkit enter this on the
command line:

 > java -jar app\js.jar test\run.js

To run any example in the included examples enter this on the
command line:

 $ java -jar app/js.jar examples/run.js -a  examples/data/whatever.js


=====================================================================

LICENSE:

Rhino (JavaScript in Java) is open source and licensed by Mozilla
under the MPL 1.1 or later/GPL 2.0 or later licenses, the text of which
is available at http://www.mozilla.org/MPL/

You can obtain the source code for Rhino via the Mozilla web site at
http://www.mozilla.org/rhino/download.html

The Tango base icon theme is licensed under the Creative Commons 
Attribution Share-Alike license. The palette is in the public domain.
For more details visit the Tango! Desktop Project page at
http://tango.freedesktop.org/Tango_Desktop_Project

JsDoc Toolkit is a larger work that uses the Rhino JavaScript engine
without modification and without any claims whatsoever. The portions of
code specific to JsDoc Toolkit are open source and licensed under the
X11/MIT License.

Copyright (c) 2007 Michael Mathews <micmath@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions: The above copyright notice and this
permission notice must be included in all copies or substantial
portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
