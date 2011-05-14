<%= copyright_block(namespace_class_name) %>
/*globals <%= namespace %> */

/** @class

  (Document Your View Here)

  @extends <%= base_class_name || 'SC.View' %>
*/
<%= namespace_class_name %> = <%= base_class_name || 'SC.View' %>.extend(
/** @scope <%= namespace_class_name %>.prototype */ {

  // TODO: Add your own code here.

});
