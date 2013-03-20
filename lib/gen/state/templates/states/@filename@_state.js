<%= copyright_block(namespace) %>
/*globals <%= namespace %> */

/** @class

  (Document Your State Here)

  @extends <%= base_class_name || 'SC.State' %>
  @version 0.1
*/
<%= namespace_class_name %> = <%= base_class_name || 'SC.State' %>.extend(
/** @scope <%= namespace_class_name %>.prototype */ {

  // TODO: Add your own code here.

  enterState: function() {
    <%= namespace %>.mainPage.get('mainPane').append();
  },

  exitState: function() {
    <%= namespace %>.mainPage.get('mainPane').remove();
  }

});
