<%= copyright_block(namespace_class_name) %>
/*globals <%= namespace %> */

/** @class

  (Document your Model here)

  @extends <%= base_class_name || 'SC.Record' %>
  @version 0.1
*/
<%= namespace_class_name %> = <%= base_class_name || 'SC.Record' %>.extend(
/** @scope <%= namespace_class_name %>.prototype */ {

  // TODO: Add your own code here.

});
