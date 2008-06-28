SproutCore JavaScript Framework

SproutCore is a full MVC framework written in JavaScript for building desktop-like applications on the web.  It makes building sophisticated applications for the web easier and more fun.

This package includes both the raw SproutCore source as well as a complete build system for creating JavaScript applications and JavaScript libraries.

==== Benefits

SproutCore comes loaded with a lot of features you would normally find in a full MVC desktop framework including:

1. "Bindings" that can automatically relay changes in a property from your model objects to your views.

2. A simple in-memory database for storing your models.

4. Buttons, labels, and other controls that can automatically enable, disable, change state and otherwise update themselves as your application state changes.

5. Efficient controls for rendering lists of items.

6. Efficient page loading optimized for handling large numbers of JavaScript controls.

==== Quick Start

1. To install the SproutCore build tools, just install the ruby gem:

sudo gem install sproutcore

2. Then create your first application:

sproutcore addressbook

You can now start editing your app in my_app/clients.  Each directory here is a single "page" that loads in your web browser.  You will find directories already setup for your models, views, controllers, as well as HTML, images, and other resources.

3. To see your new app, just start the sproutcore server:

cd addressbook
sc-server

Now visit: http://localhost:4020/addressbook

4. To add a new model, controller, or view use the generators:

cd addressbook
sc-gen model addressbook/contact

Now you can edit the model in clients/addressbook/models/contact.js.

5. When you are ready to deploy your app, do a static build:

cd addressbook
sc-build

Copy the files created in tmp/build to your web server and you should be ready to go.  Built SproutCore applications are static HTML files; you do not need any kind of web application server to host them.  (Of course, if you want to provide any data via Ajax, you will need a web application server for that.)

==== Documentation and Unit Testing

To get the documentation for SproutCore, you can simply visit:

http://localhost:4020/sproutcore/-docs

You can do the same with your own clients to generate documentation for them as well.

To run unit tests for your client, just visit:

http://localhost:4020/addressbook/-tests

Unit tests are automatically created whenever you generate a new view, controller, or model object.  They are automatically excluded from your build whenever you build for production.

