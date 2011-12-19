<%= copyright_block(namespace) %>
/*globals <%= namespace %> */

// This is the function that will start your app running.  The default
// implementation will load any fixtures you have created then instantiate
// your controllers and awake the elements on your page.
//
// As you develop your application you will probably want to override this.
// See comments for some pointers on what to do next.
//
<%= namespace %>.main = function main() {

  // Step 1: Tell your app it will load via states
  var statechart = <%= namespace %>.statechart;
  SC.RootResponder.responder.set('defaultResponder', statechart); 
  statechart.initStatechart();

  // Step 2. Set the content property on your primary controller.
  // This will make your app come alive!

  // TODO: Set the content property on your primary controller
  // ex: MyApp.contactsController.set('content', MyApp.contacts);

} ;

function main() { <%= namespace %>.main(); }
